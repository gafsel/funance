import 'package:funances/core/observability/app_logger.dart';
import 'package:funances/features/finance/domain/models/automatic_transaction_model.dart';

/// Um documento cru da coleção `automatic_transactions`.
typedef RawTransactionDoc = ({String id, Map<String, dynamic>? data});

/// Lê as pendências DOCUMENTO A DOCUMENTO.
///
/// A leitura era um `.map().toList()` sobre a coleção inteira: qualquer
/// documento ilegível derrubava a lista toda com uma exceção, e quem tivesse
/// UMA notificação malformada não conseguia consolidar nenhuma. A rodada
/// anterior consertou o caso conhecido — a categoria embutida sem `name` —
/// tornando `CategoryModel.fromJson` tolerante, mas isso trata um sintoma: o
/// mesmo documento carrega `suggestedAccount`, datas, enums e um
/// `runtimeType` de união, e cada um deles pode chegar quebrado do leitor de
/// notificação, que é um processo fora do controle do app.
///
/// A fronteira é aqui. Um documento que não parseia é PULADO e registrado com
/// o id; os outros passam. A alternativa — tolerar campo a campo em cada
/// modelo — nunca termina, e cada modelo novo entra com a exposição de volta.
///
/// [onInvalid] existe para que quem chama decida o que fazer com o que foi
/// pulado; o padrão é registrar em [AppLogger.error], que é o que permite
/// descobrir que uma tela "funcionando" está engolindo documento desde a
/// semana passada.
List<AutomaticTransactionModel> parsePendingTransactions(
  Iterable<RawTransactionDoc> docs, {
  void Function(String id, Object error, StackTrace stack)? onInvalid,
}) {
  final parsed = <AutomaticTransactionModel>[];

  for (final doc in docs) {
    final data = doc.data;
    if (data == null) {
      _report(
        doc.id,
        StateError('documento sem dados'),
        StackTrace.current,
        onInvalid,
      );
      continue;
    }

    try {
      parsed.add(AutomaticTransactionModel.fromJson(data));
    } catch (error, stack) {
      _report(doc.id, error, stack, onInvalid);
    }
  }

  return parsed;
}

void _report(
  String id,
  Object error,
  StackTrace stack,
  void Function(String, Object, StackTrace)? onInvalid,
) {
  if (onInvalid != null) {
    onInvalid(id, error, stack);
    return;
  }

  // O id entra na mensagem; o CONTEÚDO do documento não. Ele carrega
  // descrição de compra e valor, e o relatório de erro não é lugar para isso.
  AppLogger.error(
    'automatic_transactions: documento ilegível ignorado ($id)',
    error,
    stack,
  );
}
