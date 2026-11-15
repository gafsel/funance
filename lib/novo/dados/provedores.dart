import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelo/modelos.dart';
import '../regras/caminho.dart';
import '../regras/empresa.dart';
import '../regras/distribuicao.dart';
import '../regras/formatos.dart';
import '../regras/leitura_frase.dart';
import '../regras/livre.dart';
import 'repositorio.dart';

final authProvider = StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

Future<void> sair() => FirebaseAuth.instance.signOut();

/// O dia de hoje no relógio do aparelho. Provedor para os testes fixarem.
final hojeProvider = Provider<String>((ref) => chaveDoDia(DateTime.now()));

/// Espaços de que a pessoa participa.
final espacosProvider = StreamProvider<List<Espaco>>((ref) {
  final uid = ref.watch(authProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  final db = FirebaseFirestore.instance;
  return db.collectionGroup('membros').where('uid', isEqualTo: uid).snapshots().asyncMap((s) async {
    final espacos = <Espaco>[];
    for (final vinculo in s.docs) {
      final ref = vinculo.reference.parent.parent;
      if (ref == null) continue;
      final doc = await ref.get();
      final dados = doc.data();
      if (dados != null) espacos.add(Espaco.deMapa(doc.id, dados));
    }
    espacos.sort((a, b) => a.tipo == b.tipo ? a.nome.compareTo(b.nome) : (a.ehEmpresa ? 1 : -1));
    return espacos;
  });
});

const _chaveDoEspaco = 'novo.espacoAtual';

/// Id do espaço escolhido; `null` usa o primeiro da lista.
final espacoEscolhidoProvider = StateProvider<String?>((ref) => null);

Future<void> lembrarEspaco(WidgetRef ref, String id) async {
  ref.read(espacoEscolhidoProvider.notifier).state = id;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_chaveDoEspaco, id);
}

Future<String?> espacoLembrado() async =>
    (await SharedPreferences.getInstance()).getString(_chaveDoEspaco);

final espacoAtualProvider = Provider<Espaco?>((ref) {
  final espacos = ref.watch(espacosProvider).valueOrNull ?? const [];
  if (espacos.isEmpty) return null;
  final escolhido = ref.watch(espacoEscolhidoProvider);
  return espacos.where((e) => e.id == escolhido).firstOrNull ?? espacos.first;
});

final repositorioProvider = Provider<Repositorio?>((ref) {
  final espaco = ref.watch(espacoAtualProvider);
  return espaco == null ? null : Repositorio(FirebaseFirestore.instance, espaco.id);
});

StreamProvider<List<T>> _colecao<T>(Stream<List<T>> Function(Repositorio) de) =>
    StreamProvider<List<T>>((ref) {
      final repo = ref.watch(repositorioProvider);
      return repo == null ? Stream.value(const []) : de(repo);
    });

final contasProvider = _colecao<Conta>((r) => r.contas());
final categoriasProvider = _colecao<Categoria>((r) => r.categorias());
final metasProvider = _colecao<Meta>((r) => r.metas());
final faturasProvider = _colecao<Fatura>((r) => r.faturas());
final resumosProvider = _colecao<ResumoMes>((r) => r.resumos());
final membrosProvider = _colecao<Membro>((r) => r.membros());
final entradaProvider = _colecao<ItemEntrada>((r) => r.entradaPendente());
final contrapartesProvider = _colecao<Contraparte>((r) => r.contrapartes());

final regrasProvider = _colecao<Regra>((r) => r.regras());
final fechamentosProvider = _colecao<Fechamento>((r) => r.fechamentos());

/// Saldo de cada conta no fim de um mês, pelos resumos do servidor.
final saldosNoFimDoMesProvider = Provider.family<Map<String, int>, String>((ref, mes) {
  final resumos = ref.watch(resumosProvider).valueOrNull ?? const <ResumoMes>[];
  final ultimoDia = diaNoMes(mes, 31);
  return {
    for (final c in ref.watch(contasProvider).valueOrNull ?? const <Conta>[])
      c.id: (c.saldoInicialData == null || c.saldoInicialData!.compareTo(ultimoDia) <= 0 ? c.saldoInicialCentavos : 0) +
          resumos.where((r) => r.mes.compareTo(mes) <= 0).fold<int>(0, (s, r) => s + (r.deltaPorConta[c.id] ?? 0)),
  };
});

final lancamentosDoMesProvider = StreamProvider.family<List<Lancamento>, String>((ref, mes) {
  final repo = ref.watch(repositorioProvider);
  return repo == null ? Stream.value(const []) : repo.lancamentosDoMes(mes);
});

/// Agendados de hoje até 60 dias à frente, mais os que já venceram.
final previstosProvider = StreamProvider<List<Lancamento>>((ref) {
  final repo = ref.watch(repositorioProvider);
  return repo == null ? Stream.value(const []) : repo.previstos(ate: somarDias(ref.watch(hojeProvider), 60));
});

/// Os agendados que já venceram.
final atrasadosProvider = Provider<AsyncValue<List<Lancamento>>>((ref) {
  final hoje = ref.watch(hojeProvider);
  return ref.watch(previstosProvider).whenData((todos) => [for (final l in todos) if (l.data.compareTo(hoje) < 0) l]);
});

final _ultimosFeitosProvider = _colecao<Lancamento>((r) => r.ultimosFeitos());

/// Lançamentos recentes: o mês corrente inteiro e os últimos feitos antes
/// dele. Base do que o leitor de frases "aprende" e do reconhecimento do que
/// já foi lançado.
final recentesProvider = Provider<List<Lancamento>>((ref) {
  final mes = ref.watch(hojeProvider).substring(0, 7);
  final porId = {
    for (final l in ref.watch(_ultimosFeitosProvider).valueOrNull ?? const <Lancamento>[]) l.id: l,
    for (final l in ref.watch(lancamentosDoMesProvider(mes)).valueOrNull ?? const <Lancamento>[]) l.id: l,
  };
  return porId.values.toList();
});

final marcasProvider = StreamProvider<Map<String, Mapa>>((ref) {
  final repo = ref.watch(repositorioProvider);
  return repo == null ? Stream.value(const {}) : repo.marcas();
});

/// As metas estão pausadas neste mês? (escolha do "mês apertado")
final metasPausadasProvider = Provider<bool>((ref) {
  final mes = ref.watch(hojeProvider).substring(0, 7);
  return ref.watch(marcasProvider).valueOrNull?.containsKey('pausa-$mes') ?? false;
});

final livreProvider = Provider<LivreParaGastar>((ref) {
  final hoje = ref.watch(hojeProvider);
  return calcularLivre(
    hoje: hoje,
    lancamentos: ref.watch(lancamentosDoMesProvider(hoje.substring(0, 7))).valueOrNull ?? const [],
    metas: ref.watch(metasProvider).valueOrNull ?? const [],
    metasPausadas: ref.watch(metasPausadasProvider),
  );
});

/// Caixa previsto para os próximos 30 dias, nas contas de uso.
final caixaPrevistoProvider = Provider<CaixaPrevisto>((ref) {
  final contas = {
    for (final c in ref.watch(contasProvider).valueOrNull ?? const <Conta>[])
      if (!c.arquivada && c.ehDeUso) c.id,
  };
  final saldos = ref.watch(saldosProvider);
  return preverCaixa(
    hoje: ref.watch(hojeProvider),
    caixaHojeCentavos: contas.fold<int>(0, (s, id) => s + (saldos[id] ?? 0)),
    contasDeUso: contas,
    previstos: ref.watch(previstosProvider).valueOrNull ?? const [],
  );
});

/// Categorias que representam a retirada do dono.
final proLaboreIdsProvider = Provider<Set<String>>((ref) => {
      for (final c in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[])
        if (normalizar(c.nome).replaceAll(RegExp(r'[^a-z]'), '').contains('prolabore')) c.id,
    });

final caminhoProvider = Provider<List<Degrau>>((ref) {
  final hoje = ref.watch(hojeProvider);
  return calcularCaminho(DadosDoCaminho(
    hoje: hoje,
    ehEmpresa: ref.watch(espacoAtualProvider)?.ehEmpresa ?? false,
    contas: ref.watch(contasProvider).valueOrNull ?? const [],
    saldos: ref.watch(saldosProvider),
    resumos: ref.watch(resumosProvider).valueOrNull ?? const [],
    faturas: ref.watch(faturasProvider).valueOrNull ?? const [],
    metas: ref.watch(metasProvider).valueOrNull ?? const [],
    fechamentos: ref.watch(fechamentosProvider).valueOrNull ?? const [],
    lancamentosDoMes: ref.watch(lancamentosDoMesProvider(hoje.substring(0, 7))).valueOrNull ?? const [],
    categoriaProLaboreIds: ref.watch(proLaboreIdsProvider),
    previstoProximos30Centavos: ref.watch(caixaPrevistoProvider).minimoCentavos,
  ));
});

final saldosProvider = Provider<Map<String, int>>((ref) {
  final hoje = ref.watch(hojeProvider);
  final resumos = ref.watch(resumosProvider).valueOrNull ?? const <ResumoMes>[];
  final doMes = ref.watch(lancamentosDoMesProvider(hoje.substring(0, 7))).valueOrNull ?? const <Lancamento>[];
  return {
    for (final c in ref.watch(contasProvider).valueOrNull ?? const <Conta>[])
      c.id: saldoDaConta(conta: c, hoje: hoje, resumos: resumos, lancamentosDoMes: doMes),
  };
});

/// Conta usada quando a frase não cita nenhuma: a de uso mais usada
/// recentemente, ou a primeira corrente.
final contaPadraoProvider = Provider<String?>((ref) {
  final contas = (ref.watch(contasProvider).valueOrNull ?? const <Conta>[]).where((c) => !c.arquivada);
  final eu = ref.watch(authProvider).valueOrNull?.uid;
  final todasDeUso = contas.where((c) => c.ehDeUso).toList();
  // Entre as contas de uso, as de quem está lançando vêm antes.
  final minhas = todasDeUso.where((c) => c.donos.contains(eu)).toList();
  final deUso = minhas.isEmpty ? todasDeUso : minhas;
  if (deUso.isEmpty) return contas.firstOrNull?.id;
  final uso = <String, int>{};
  for (final l in ref.watch(recentesProvider)) {
    uso[l.contaId] = (uso[l.contaId] ?? 0) + 1;
  }
  deUso.sort((a, b) => (uso[b.id] ?? 0).compareTo(uso[a.id] ?? 0));
  return deUso.first.id;
});

final contextoDeLeituraProvider = Provider<ContextoDeLeitura>((ref) => ContextoDeLeitura(
      hoje: ref.watch(hojeProvider),
      contas: ref.watch(contasProvider).valueOrNull ?? const [],
      categorias: ref.watch(categoriasProvider).valueOrNull ?? const [],
      aprendido: aprenderCategorias(ref.watch(recentesProvider)),
      contaPadraoId: ref.watch(contaPadraoProvider),
      membros: ref.watch(membrosProvider).valueOrNull ?? const [],
      euId: ref.watch(authProvider).valueOrNull?.uid,
    ));

/// Nome de cada conta como aparece nas listas. Quando duas contas têm o
/// mesmo nome (o Nubank de cada um), o titular vai junto.
final nomesDasContasProvider = Provider<Map<String, String>>((ref) {
  final contas = ref.watch(contasProvider).valueOrNull ?? const <Conta>[];
  final membros = ref.watch(membrosProvider).valueOrNull ?? const <Membro>[];
  final eu = ref.watch(authProvider).valueOrNull?.uid;
  final vezes = <String, int>{};
  for (final c in contas) {
    if (!c.arquivada) vezes[normalizar(c.nome)] = (vezes[normalizar(c.nome)] ?? 0) + 1;
  }
  String dono(Conta c) {
    if (c.donos.isEmpty) return '';
    if (c.conjunta) return 'conjunta';
    if (c.donos.single == eu) return 'sua';
    return membros.where((m) => m.uid == c.donos.single).firstOrNull?.primeiroNome ?? '';
  }

  return {
    for (final c in contas)
      c.id: (vezes[normalizar(c.nome)] ?? 0) > 1 && dono(c).isNotEmpty ? '${c.nome} (${dono(c)})' : c.nome,
  };
});

/// Quantas vezes cada conta foi usada nos lançamentos recentes.
final usoDasContasProvider = Provider<Map<String, int>>((ref) {
  final uso = <String, int>{};
  for (final l in ref.watch(recentesProvider)) {
    uso[l.contaId] = (uso[l.contaId] ?? 0) + 1;
    final destino = l.contaDestinoId;
    if (destino != null) uso[destino] = (uso[destino] ?? 0) + 1;
  }
  return uso;
});

/// Como a renda se divide entre essencial, estilo de vida e futuro, e o que
/// o app aponta. Nulo enquanto não há renda para comparar.
final diagnosticoProvider = Provider<Diagnostico?>((ref) {
  final categorias = {
    for (final c in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) c.id: c,
  };
  return diagnosticar(
    resumos: ref.watch(resumosProvider).valueOrNull ?? const <ResumoMes>[],
    categorias: categorias,
    mesAtual: ref.watch(hojeProvider).substring(0, 7),
    referencia: referenciaDe(ref.watch(marcasProvider).valueOrNull?['distribuicao']?['referencia'] as String?),
    nomeDe: (id) => categorias[id]?.nome ?? 'Sem categoria',
  );
});
