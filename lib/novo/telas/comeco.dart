import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../firebase_ambiente.dart';
import '../dados/provedores.dart';
import '../dados/repositorio.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../regras/leitura_frase.dart';
import '../regras/montar.dart';
import '../tema/tema_novo.dart';
import 'pecas.dart';

const _uuid = Uuid();

/// Começo em quatro perguntas: para quem é, onde está o dinheiro, quanto
/// entra e o que já tem dia certo para sair. Com isso o app já consegue
/// mostrar o "livre para gastar" e o primeiro degrau do caminho.
class TelaComeco extends ConsumerStatefulWidget {
  const TelaComeco({super.key, this.podeVoltar = false});
  final bool podeVoltar;

  @override
  ConsumerState<TelaComeco> createState() => _TelaComecoState();
}

class _TelaComecoState extends ConsumerState<TelaComeco> {
  final _nome = TextEditingController();
  final _conta = TextEditingController();
  final _saldo = TextEditingController();
  final _renda = TextEditingController();
  final _diaDaRenda = TextEditingController(text: '5');
  final _fixas = TextEditingController();
  String _tipo = 'pessoal';
  bool _criando = false;
  String? _erro;

  @override
  void dispose() {
    for (final c in [_nome, _conta, _saldo, _renda, _diaDaRenda, _fixas]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _criar() async {
    final hoje = ref.read(hojeProvider);
    final mes = hoje.substring(0, 7);
    final nome = _nome.text.trim();
    final conta = _conta.text.trim();
    if (nome.isEmpty) return setState(() => _erro = 'Dê um nome para este espaço.');
    if (conta.isEmpty) return setState(() => _erro = 'Diga o nome da conta que você mais usa.');
    final saldoTexto = _saldo.text.trim();
    final saldo = saldoTexto.isEmpty ? 0 : (lerCentavos(saldoTexto.replaceFirst('-', '')) ?? 0) * (saldoTexto.startsWith('-') ? -1 : 1);
    final renda = lerCentavos(_renda.text);
    final dia = (int.tryParse(_diaDaRenda.text) ?? 5).clamp(1, 31);

    setState(() {
      _criando = true;
      _erro = null;
    });
    try {
      final resposta = await funcoesDoAmbiente
          .httpsCallable('criarEspaco')
          .call<Map<Object?, Object?>>({'nome': nome, 'tipo': _tipo});
      final espacoId = resposta.data['espacoId'] as String;
      final repo = Repositorio(FirebaseFirestore.instance, espacoId);
      final autor = ref.read(authProvider).valueOrNull?.uid;

      const contaId = 'principal';
      var principal = Conta(id: contaId, nome: conta, tipo: 'corrente', saldoInicialCentavos: saldo, saldoInicialData: hoje);

      final ctx = ContextoDeLeitura(hoje: hoje, contas: [principal], categorias: const [], contaPadraoId: contaId);
      final montagens = <Montagem>[
        if (renda != null)
          montar(
            Leitura(
              tipo: 'entrada',
              descricao: _tipo == 'empresa' ? 'Faturamento' : 'Salário',
              valorCentavos: renda,
              data: diaNoMes(mes, dia),
              contaId: contaId,
              categoriaId: _tipo == 'empresa' ? 'vendas' : 'salario',
              recorrente: true,
              efetivado: diaNoMes(mes, dia).compareTo(hoje) <= 0,
            ),
            conta: principal,
            novoId: _uuid.v4,
            autorId: autor,
          ),
        for (final (_, lida) in lerTexto(_fixas.text, ctx))
          if (lida != null)
            montar(
              lida.copiar(tipo: 'saida', recorrente: true, contaId: () => contaId, parcelas: () => null, efetivado: lida.data.compareTo(hoje) <= 0),
              conta: principal,
              novoId: _uuid.v4,
              autorId: autor,
            ),
      ];
      // O saldo informado é o de HOJE: já inclui o que aconteceu neste mês.
      // O saldo inicial é recuado para o dia 1 descontando esses lançamentos,
      // para que o saldo de hoje no app seja exatamente o que a pessoa disse.
      final jaAconteceu = montagens
          .expand((m) => m.lancamentos)
          .where((l) => l.efetivado)
          .fold<int>(0, (s, l) => s + (l.ehEntrada ? l.valorCentavos : -l.valorCentavos));
      principal = Conta(id: contaId, nome: conta, tipo: 'corrente', saldoInicialCentavos: saldo - jaAconteceu, saldoInicialData: '$mes-01');
      await repo.gravarConta(contaId, {
        'nome': conta, 'tipo': 'corrente', 'icone': null, 'cor': null, 'banco': null,
        'saldoInicialCentavos': principal.saldoInicialCentavos, 'saldoInicialData': principal.saldoInicialData, 'arquivada': false,
        'limiteCentavos': null, 'diaFechamento': null, 'diaVencimento': null, 'taxaJuros': null,
        'donos': [?autor],
      });
      if (montagens.isNotEmpty) await repo.salvar(montagens, loteId: _uuid.v4(), autorId: autor);

      await lembrarEspaco(ref, espacoId);
      if (mounted && widget.podeVoltar) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _criando = false;
          _erro = 'Não foi possível criar agora. Confira a conexão e tente de novo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);

    Widget pergunta(int n, String titulo, String ajuda, List<Widget> campos) => Padding(
          padding: const EdgeInsets.only(bottom: Espacos.g),
          child: Cartao(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('PERGUNTA $n DE 4', style: Textos.sobrancelha(context)),
                const SizedBox(height: 2),
                Text(titulo, style: texto.titleMedium),
                const SizedBox(height: Espacos.xp),
                Text(ajuda, style: texto.bodySmall),
                const SizedBox(height: Espacos.m),
                ...campos,
              ],
            ),
          ),
        );

    final valor = [FilteringTextInputFormatter.allow(RegExp(r'[-\d.,]'))];

    return Scaffold(
      appBar: widget.podeVoltar ? AppBar(title: const Text('Novo espaço')) : null,
      body: SafeArea(
        child: Pagina(
              larguraMaxima: 520,
              centralizada: true,
              filhos: [
                if (!widget.podeVoltar) ...[
                  Row(children: [const Marca(tamanho: 28), const SizedBox(width: 8), Text('funances', style: Textos.marca(context, tamanho: 20))]),
                  const SizedBox(height: Espacos.xg),
                  Text('Vamos começar', style: texto.headlineMedium),
                  const SizedBox(height: 2),
                  Text('Quatro perguntas. Dá para mudar tudo depois.', style: texto.bodyMedium?.copyWith(color: c.tinta2)),
                  const SizedBox(height: Espacos.g),
                ],
                pergunta(1, 'Para quem é este espaço?', 'Dinheiro pessoal e de empresa ficam em espaços separados.', [
                  Segmentos<String>(
                    opcoes: const [('pessoal', 'Para mim ou minha casa'), ('empresa', 'Para a empresa')],
                    valor: _tipo,
                    aoMudar: (v) => setState(() => _tipo = v),
                  ),
                  const SizedBox(height: Espacos.m),
                  TextField(
                    controller: _nome,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: 'Nome', hintText: _tipo == 'empresa' ? 'Nome da empresa' : 'Casa, Família Silva…'),
                  ),
                ]),
                pergunta(2, 'Onde está o seu dinheiro hoje?', 'Só a conta que você mais usa. As outras, e os cartões, entram depois.', [
                  TextField(controller: _conta, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nome da conta', hintText: 'Nubank, Itaú, Carteira…')),
                  const SizedBox(height: Espacos.m),
                  TextField(
                    controller: _saldo,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    inputFormatters: valor,
                    decoration: const InputDecoration(labelText: 'Saldo de hoje', prefixText: r'R$ ', helperText: 'Pode ser aproximado. Você acerta no primeiro fechamento.'),
                  ),
                ]),
                pergunta(3, _tipo == 'empresa' ? 'Quanto costuma entrar por mês?' : 'Quanto você recebe por mês?', 'É a base do "livre para gastar". Se varia, use um mês comum.', [
                  Row(children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _renda,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: valor,
                        decoration: const InputDecoration(labelText: 'Valor', prefixText: r'R$ '),
                      ),
                    ),
                    const SizedBox(width: Espacos.m),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _diaDaRenda,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(labelText: 'Dia do mês'),
                      ),
                    ),
                  ]),
                ]),
                pergunta(4, 'O que tem dia certo para sair todo mês?', 'Uma conta por linha, com o valor e o dia. Só as maiores já bastam.', [
                  TextField(
                    controller: _fixas,
                    minLines: 3,
                    maxLines: 8,
                    decoration: const InputDecoration(hintText: 'aluguel 2000 dia 5\ninternet 120 dia 10\nacademia 99 dia 15'),
                  ),
                ]),
                if (_erro != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Espacos.m),
                    child: Text(_erro!, style: texto.bodyMedium?.copyWith(color: c.problema)),
                  ),
                Acoes(filhos: [
                  FilledButton(onPressed: _criando ? null : _criar, child: Text(_criando ? 'Criando…' : 'Começar')),
                  if (!widget.podeVoltar) TextButton(onPressed: sair, child: const Text('Sair desta conta')),
                ]),
              ],
        ),
      ),
    );
  }
}
