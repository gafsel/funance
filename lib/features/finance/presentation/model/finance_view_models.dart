import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/models/virtual_category.dart';
import 'package:uuid/uuid.dart';


// ─────────────────────────────────────────────────────────────────────────────
// Modelos de apresentação de finanças.
//
// Eram 522 linhas num arquivo só: planejamento, wizard de lançamento, estado
// do formulário (310 linhas sozinho), totais da lista e a consulta do
// histórico. Os dois `part` abaixo separam as duas leituras sem multiplicar
// arquivos gerados — o freezed continua produzindo UM `.freezed.dart` para a
// biblioteca inteira.
// ─────────────────────────────────────────────────────────────────────────────

part 'finance_view_models.freezed.dart';
part 'finance_view_models_planning.dart';
part 'finance_view_models_transaction.dart';
