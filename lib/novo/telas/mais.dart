import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../tema/tema_novo.dart';
import 'casca.dart';
import 'categorias.dart';
import 'conta.dart';
import 'empresa.dart';
import 'fatura.dart';
import 'fechamento.dart';
import 'formulario.dart';
import 'pecas.dart';
import 'relatorios.dart';
import 'revisao.dart';

/// Contas e cadastros: o que se configura de vez em quando. No celular é
/// também a porta para o Fechamento e a visão da Empresa.
class TelaMais extends ConsumerWidget {
  const TelaMais({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contas = ref.watch(contasProvider).valueOrNull ?? const <Conta>[];
    final saldos = ref.watch(saldosProvider);
    final usuario = ref.watch(authProvider).valueOrNull;
    final atual = ref.watch(espacoAtualProvider);
    final c = Cores.de(context);
    final mesa = ehMesa(context);
    final membros = ref.watch(membrosProvider).valueOrNull ?? const <Membro>[];
    final eu = usuario?.uid;
    int ordem(Conta x) => x.donos.contains(eu) && !x.conjunta ? 0 : (x.donos.contains(eu) ? 1 : 2);
    final ativas = contas.where((x) => !x.arquivada).toList()
      ..sort((a, b) {
        final o = ordem(a).compareTo(ordem(b));
        if (o != 0) return o;
        final banco = (a.banco ?? 'zz').compareTo(b.banco ?? 'zz');
        return banco != 0 ? banco : a.nome.compareTo(b.nome);
      });
    final empresa = atual?.ehEmpresa ?? false;
    final seta = Icon(Icons.chevron_right_rounded, size: 18, color: c.tinta3);

    final blocoContas = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloDeSecao('Contas e cartões', semTopo: true),
        if (ativas.isEmpty)
          const Cartao(padding: EdgeInsets.zero, child: Vazio('Nenhuma conta neste espaço.'))
        else
          Lista(filhos: [
            for (final x in ativas)
              Linha(
                antes: SeloDaConta(conta: x, membros: membros),
                titulo: x.nome,
                detalhe: [rotulosDeConta[x.tipo] ?? x.tipo, titularidade(x, membros, eu)].where((p) => p.isNotEmpty).join(' · '),
                direita: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(reais(saldos[x.id] ?? 0), style: Textos.valor(context)),
                  const SizedBox(width: 4),
                  seta,
                ]),
                aoTocar: () => x.ehCartao ? abrirCartao(context, x) : abrirConta(context, x.id),
              ),
          ]),
      ],
    );

    final blocoOrganizar = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloDeSecao('Organizar', semTopo: mesa),
        Lista(filhos: [
          if (!mesa && empresa)
            Linha(
              titulo: 'Empresa',
              detalhe: 'Caixa previsto, clientes e resultado',
              direita: seta,
              aoTocar: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => Scaffold(appBar: AppBar(title: const Text('Empresa')), body: const TelaEmpresa()),
              )),
            ),
          if (!mesa)
            Linha(
              titulo: 'Relatórios',
              detalhe: 'Para onde o dinheiro foi, mês a mês',
              direita: seta,
              aoTocar: () => Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => const TelaRelatorios(embutida: false))),
            ),
          if (!mesa)
            Linha(
              titulo: 'Fechamento do mês',
              detalhe: 'Conferir cada conta com o extrato',
              direita: seta,
              aoTocar: () => abrirFechamento(context),
            ),
          Linha(
            titulo: empresa ? 'Centros de custo e limites' : 'Categorias e limites',
            detalhe: 'Nomes e teto mensal, se quiser',
            direita: seta,
            aoTocar: () => abrirCategorias(context),
          ),
          Linha(
            titulo: 'Revisão da semana',
            detalhe: 'Cinco minutos para nada se acumular',
            direita: seta,
            aoTocar: () => abrirRevisao(context),
          ),
        ]),
        const TituloDeSecao('Você'),
        Lista(filhos: [
          Linha(titulo: usuario?.displayName ?? usuario?.email ?? 'Conta', detalhe: usuario?.displayName != null ? usuario?.email : null),
          Linha(titulo: 'Sair', direita: Icon(Icons.logout_rounded, size: 18, color: c.tinta3), aoTocar: sair),
        ]),
      ],
    );

    if (mesa) {
      return Pagina(filhos: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: blocoContas),
            const SizedBox(width: Espacos.xg),
            Expanded(child: blocoOrganizar),
          ],
        ),
      ]);
    }
    return Pagina(filhos: [blocoContas, blocoOrganizar]);
  }
}

/// Leva a uma seção da casca a partir de qualquer tela.
void irPara(WidgetRef ref, Secao secao) => ref.read(secaoProvider.notifier).state = secao;
