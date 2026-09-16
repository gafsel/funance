import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

/// Conduz o lançamento em duas telas: categoria e formulário.
///
/// Antes havia um passo intermediário que listava as parcelas pendentes da
/// categoria, alimentado por uma consulta assíncrona ao abrir o wizard: o
/// usuário passava por quatro telas para registrar uma despesa e o passo
/// aparecia ou não conforme o resultado da consulta. Quitar um agendamento
/// continua no lugar certo (extrato, detalhe da parcela e folha de pagamento),
/// e registrar virou um caminho previsível.
class TransactionWizardNotifier extends StateNotifier<TransactionWizardState> {
  TransactionWizardNotifier(super.state) {
    // Transferência não tem categoria escolhível: a categoria virtual vem dos
    // tipos das contas, resolvida no serviço.
    if (state.type == OrderType.transfer) {
      state = state.copyWith(step: TransactionWizardStep.form);
    }
  }

  void selectCategory(CategoryModel category) {
    state = state.copyWith(
      selectedCategory: category,
      step: TransactionWizardStep.form,
    );
  }
}
