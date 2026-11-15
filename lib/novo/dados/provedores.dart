import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelo/modelos.dart';
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

final lancamentosDoMesProvider = StreamProvider.family<List<Lancamento>, String>((ref, mes) {
  final repo = ref.watch(repositorioProvider);
  return repo == null ? Stream.value(const []) : repo.lancamentosDoMes(mes);
});

final atrasadosProvider = StreamProvider<List<Lancamento>>((ref) {
  final repo = ref.watch(repositorioProvider);
  return repo == null ? Stream.value(const []) : repo.atrasados(ref.watch(hojeProvider));
});

/// Lançamentos do mês corrente e do anterior: base do Início e do que o
/// leitor de frases "aprende".
final recentesProvider = Provider<List<Lancamento>>((ref) {
  final mes = ref.watch(hojeProvider).substring(0, 7);
  return [
    ...ref.watch(lancamentosDoMesProvider(mes)).valueOrNull ?? const <Lancamento>[],
    ...ref.watch(lancamentosDoMesProvider(somarMeses(mes, -1))).valueOrNull ?? const <Lancamento>[],
  ];
});

final livreProvider = Provider<LivreParaGastar>((ref) {
  final hoje = ref.watch(hojeProvider);
  return calcularLivre(
    hoje: hoje,
    lancamentos: ref.watch(lancamentosDoMesProvider(hoje.substring(0, 7))).valueOrNull ?? const [],
    metas: ref.watch(metasProvider).valueOrNull ?? const [],
  );
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
  final deUso = contas.where((c) => c.ehDeUso).toList();
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
    ));
