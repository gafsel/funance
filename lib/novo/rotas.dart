import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/observability/app_logger.dart';
import 'caminhos.dart';
import 'dados/provedores.dart';
import 'modelo/modelos.dart';
import 'telas/casca.dart';
import 'telas/categorias.dart';
import 'telas/conferencia.dart';
import 'telas/conta.dart';
import 'telas/distribuicao.dart';
import 'telas/empresa.dart';
import 'telas/entrar.dart';
import 'telas/fatura.dart';
import 'telas/fechamento.dart';
import 'telas/meta.dart';
import 'telas/organizacao.dart';
import 'telas/pecas.dart';
import 'telas/relatorios.dart';
import 'telas/revisao.dart';

/// Navegação por endereço.
///
/// A casca (menu e seções) é sempre a rota de baixo; o endereço dela é o da
/// seção aberta. As telas de detalhe são empilhadas por cima, cada uma com o
/// seu endereço. Ao recarregar, a pilha é refeita a partir do endereço: a
/// casca e, se for o caso, o detalhe por cima.

const _caminhosDasSecoes = {
  Secao.inicio: '/',
  Secao.lancamentos: '/lancamentos',
  Secao.empresa: '/empresa',
  Secao.metas: '/metas',
  Secao.relatorios: '/relatorios',
  Secao.fechamento: '/fechamento',
  Secao.mais: '/mais',
};

String caminhoDaSecao(Secao secao) => _caminhosDasSecoes[secao]!;

/// A seção de um endereço; nula quando o endereço não é de seção.
Secao? secaoDoCaminho(String caminho) {
  final partes = partesDoCaminho(caminho);
  if (partes.isEmpty) return Secao.inicio;
  if (partes.length > 1) return null;
  for (final e in _caminhosDasSecoes.entries) {
    if (e.value == '/${partes.single}') return e.key;
  }
  return null;
}

/// A tela de detalhe de um endereço; nula quando o endereço não é de detalhe.
Widget? telaDoCaminho(String caminho) {
  final p = partesDoCaminho(caminho);
  return switch (p) {
    ['conta', final id] => TelaConta(contaId: id),
    ['cartao', final id] => _PorId<Conta>(
        provedor: contasProvider,
        achar: (x) => x.id == id,
        tela: (cartao) => TelaCartao(cartao: cartao),
        ausente: 'Este cartão não existe mais.',
      ),
    ['fatura', final cartaoId, final faturaId] => _PorId<Conta>(
        provedor: contasProvider,
        achar: (x) => x.id == cartaoId,
        tela: (cartao) => TelaFatura(cartao: cartao, faturaId: faturaId),
        ausente: 'Esta fatura não existe mais.',
      ),
    ['meta', final id] => TelaMeta(metaId: id),
    ['fechamento', final mes] => TelaFechamento(mes: mes),
    ['contato', final id] => _PorId<Contraparte>(
        provedor: contrapartesProvider,
        achar: (x) => x.id == id,
        tela: (contato) => TelaContraparte(contraparte: contato),
        ausente: 'Este cliente ou fornecedor não existe mais.',
      ),
    ['categorias'] => const TelaCategorias(),
    ['distribuicao'] => const TelaDistribuicao(),
    ['revisao'] => const TelaRevisao(),
    ['organizar'] => const TelaOrganizacao(),
    ['conferencia'] => const TelaConferencia(),
    ['mais', 'empresa'] => Scaffold(appBar: AppBar(title: const Text('Empresa')), body: const TelaEmpresa()),
    ['mais', 'relatorios'] => const TelaRelatorios(embutida: false),
    _ => null,
  };
}

Route<void> _rota(String nome, Widget tela) => MaterialPageRoute<void>(
      settings: RouteSettings(name: nome),
      builder: (_) => Portao(detalhe: tela is! Casca, child: tela),
    );

/// Rota de um endereço: a casca para os de seção, o detalhe para os de
/// detalhe. Endereço desconhecido cai no início.
Route<dynamic> gerarRota(RouteSettings settings) {
  final nome = settings.name ?? '/';
  final tela = telaDoCaminho(nome);
  if (tela != null) return _rota(nome, tela);
  return _rota(secaoDoCaminho(nome) == null ? '/' : nome, const Casca());
}

/// O endereço em que o app foi aberto. É dele que sai a seção inicial.
String caminhoDeAbertura = '/';

/// A pilha de quando o app abre (ou recarrega) num endereço: a casca embaixo
/// e, se o endereço for de detalhe, a tela dele por cima.
List<Route<dynamic>> rotasIniciais(String inicial) {
  caminhoDeAbertura = inicial;
  AppLogger.info('Aberto em "$inicial"', name: 'rotas');
  final tela = telaDoCaminho(inicial);
  if (tela == null) return [gerarRota(RouteSettings(name: inicial))];
  return [_rota('/', const Casca()), _rota(inicial, tela)];
}

/// Põe o endereço na barra do navegador sem empilhar tela nem criar entrada
/// no histórico. Usado quando a seção muda dentro da casca.
void publicarCaminho(String caminho) =>
    SystemNavigator.routeInformationUpdated(uri: Uri(path: caminho), replace: true);

/// Ao voltar de um detalhe para a casca, o navegador mostraria o endereço
/// com que a casca foi criada, e não o da seção que está aberta. Este
/// observador conserta isso.
class ObservadorDeRotas extends NavigatorObserver {
  ObservadorDeRotas(this.secaoAtual);
  final Secao Function() secaoAtual;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null && previousRoute.isFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) => publicarCaminho(caminhoDaSecao(secaoAtual())));
    }
  }
}

/// Toda tela passa por aqui: enquanto o app descobre quem está entrando
/// mostra a abertura; sem ninguém, a tela de entrar; e as telas de detalhe
/// esperam os espaços carregarem antes de aparecer.
class Portao extends ConsumerStatefulWidget {
  const Portao({super.key, required this.child, this.detalhe = false});
  final Widget child;
  final bool detalhe;

  @override
  ConsumerState<Portao> createState() => _PortaoState();
}

class _PortaoState extends ConsumerState<Portao> {
  @override
  void initState() {
    super.initState();
    // Aberto direto num detalhe, a casca de baixo ainda não foi montada:
    // o espaço lembrado precisa ser recuperado aqui também.
    espacoLembrado().then((id) {
      if (id != null && mounted && ref.read(espacoEscolhidoProvider) == null) {
        ref.read(espacoEscolhidoProvider.notifier).state = id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessao = ref.watch(authProvider);
    return sessao.when(
      loading: () => const TelaDeAbertura(),
      error: (_, _) => const TelaEntrar(),
      data: (usuario) {
        if (usuario == null) return const TelaEntrar();
        if (!widget.detalhe) return widget.child;
        final espacos = ref.watch(espacosProvider);
        if (espacos.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        // Sem espaço não há detalhe para mostrar: a casca cuida do começo.
        return ref.watch(espacoAtualProvider) == null ? const Casca() : widget.child;
      },
    );
  }
}

/// Telas que recebem o objeto inteiro (um cartão, um cliente), montadas a
/// partir do id que veio no endereço.
class _PorId<T> extends ConsumerWidget {
  const _PorId({required this.provedor, required this.achar, required this.tela, required this.ausente});
  final ProviderListenable<AsyncValue<List<T>>> provedor;
  final bool Function(T) achar;
  final Widget Function(T) tela;
  final String ausente;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lista = ref.watch(provedor);
    final achado = (lista.valueOrNull ?? <T>[]).where(achar).firstOrNull;
    if (achado != null) return tela(achado);
    return Scaffold(
      appBar: AppBar(),
      body: lista.isLoading ? const Center(child: CircularProgressIndicator()) : Vazio(ausente),
    );
  }
}
