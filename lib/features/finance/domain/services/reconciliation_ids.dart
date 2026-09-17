import 'package:funances/core/money/money.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';

/// Ids DETERMINÍSTICOS da conciliação.
///
/// `confirmReconciliation` gerava `Uuid().v4()` a cada chamada — para o
/// documento de resumo e para cada lançamento criado. Sem nenhuma guarda de
/// idempotência, um duplo toque no botão ou um retry offline confirmava a
/// mesma conciliação duas vezes: lançamentos duplicados no extrato, parcelas
/// liquidadas duas vezes e DOIS documentos em `reconciliations` — que é
/// justamente o gatilho de XP no servidor.
///
/// A saída para isso é o id vir do CONTEÚDO, e não de um sorteio: a mesma
/// linha do mesmo extrato, na mesma conta, sempre produz o mesmo id, e a
/// segunda confirmação sobrescreve em vez de duplicar.
abstract final class ReconciliationIds {
  /// FNV-1a de 64 bits, em hexadecimal.
  ///
  /// Não é criptografia — é só um resumo estável e curto o bastante para ser
  /// um id de documento. Escolhido para não acrescentar dependência ao
  /// pacote por causa de um hash não-criptográfico.
  static String stableHash(String input) {
    // Offset basis e primo do FNV-1a de 64 bits, dentro do Int64 do Dart.
    var hash = BigInt.parse('14695981039346656037');
    final prime = BigInt.parse('1099511628211');
    final mask = (BigInt.one << 64) - BigInt.one;

    for (final byte in input.codeUnits) {
      hash = (hash ^ BigInt.from(byte)) & mask;
      hash = (hash * prime) & mask;
    }

    return hash.toRadixString(16).padLeft(16, '0');
  }

  /// A chave de uma linha do extrato: conta, data, valor em centavos e
  /// descrição.
  ///
  /// A data entra só como dia — a hora que o parser do extrato inventa (meio
  /// dia, por convenção do conversor) não é informação do documento, e duas
  /// leituras do mesmo PDF não podem produzir chaves diferentes por causa
  /// dela.
  static String statementItemKey(
    String accountId,
    ReconciliationTransaction transaction,
  ) {
    final date =
        '${transaction.date.year}-'
        '${transaction.date.month.toString().padLeft(2, '0')}-'
        '${transaction.date.day.toString().padLeft(2, '0')}';
    final cents = transaction.amount.asMoney.cents;

    return '$accountId|$date|$cents|${transaction.description.trim()}|'
        '${transaction.type.name}';
  }

  /// Id do lançamento criado a partir de cada linha do extrato, na MESMA
  /// ordem da lista de casamentos. `null` onde o casamento não tem linha de
  /// extrato (item que só existe no sistema).
  ///
  /// A chave-base sozinha não basta: um extrato com dois cafés de R$ 5 no
  /// mesmo dia, mesma descrição e mesmo tipo produz DUAS linhas com a mesma
  /// chave — e, com o mesmo id, o segundo `set` sobrescrevia o primeiro. O
  /// usuário confirmava dois gastos e via um só, enquanto o resumo dizia que
  /// tinha criado dois.
  ///
  /// Então cada linha ganha o seu número de OCORRÊNCIA dentro do conjunto de
  /// linhas idênticas: a primeira `#0`, a segunda `#1`. A contagem é feita
  /// sobre TODAS as linhas de extrato do casamento, independentemente do
  /// status — assim marcar uma delas como ignorada não renumera as outras, e
  /// reconfirmar o mesmo extrato produz exatamente os mesmos ids.
  static List<String?> orderIdsFor(
    String accountId,
    List<ReconciliationMatch> matches,
  ) {
    final ocorrencias = <String, int>{};

    return matches.map((match) {
      final transaction = match.documentTransaction;
      if (transaction == null) return null;

      final base = statementItemKey(accountId, transaction);
      final ocorrencia = ocorrencias.update(
        base,
        (vistas) => vistas + 1,
        ifAbsent: () => 0,
      );

      return 'rec-${stableHash('$base|#$ocorrencia')}';
    }).toList();
  }

  /// Id do documento de resumo da conciliação.
  ///
  /// É o resumo de um EXTRATO inteiro numa conta: reconfirmar o mesmo extrato
  /// grava no mesmo documento. As chaves são ordenadas para que a ordem em
  /// que o parser devolveu as linhas não mude o id.
  static String summaryIdFor(
    String accountId,
    List<ReconciliationMatch> matches,
  ) {
    // Ordenar preserva a MULTIPLICIDADE: duas linhas idênticas entram duas
    // vezes, e um extrato com dois cafés não tem o mesmo resumo de um com um.
    final chaves =
        matches
            .map((m) => m.documentTransaction)
            .nonNulls
            .map((tx) => statementItemKey(accountId, tx))
            .toList()
          ..sort();

    // Extrato sem nenhuma linha de documento (só itens do sistema) ainda
    // precisa de um id: o da conta basta, porque não há conteúdo a resumir.
    return 'rec-${stableHash(chaves.isEmpty ? accountId : chaves.join('\n'))}';
  }
}
