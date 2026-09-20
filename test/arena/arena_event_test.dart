import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_submit_flow.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';

/// O golpe que chega atrasado.
///
/// O gasto acontece no formulário de lançamento; a cena que deveria reagir a
/// ele está desmontada, porque o usuário não está na Home. A POC 1 tentou
/// resolver isso mostrando o dano quando o estado do Firestore voltasse — e o
/// aprendizado foi que **dano que chega horas depois perde a força**.
///
/// O conserto é guardar o FATO no momento em que ele acontece e gastá-lo no
/// primeiro quadro em que a cena existe de novo. Estes testes guardam as duas
/// metades: quem decide que houve um evento, e a promessa de que ele é
/// consumido uma vez só.

TransactionFormState _form({
  required OrderType type,
  required InstallmentStatus status,
  double amount = 120,
  String? orderId,
  InstallmentType installmentType = InstallmentType.single,
  TransactionAmountType amountType = TransactionAmountType.total,
  int? installmentCount,
}) => TransactionFormState(
  formType: TransactionFormType.order,
  orderId: orderId,
  type: type,
  installmentType: installmentType,
  amountType: amountType,
  installmentCount: installmentCount,
  amount: amount,
  dueDate: DateTime(2026, 9, 23),
  status: status,
);

/// O caminho normal: gasto saindo da conta corrente.
ArenaPendingEvent? _evento(
  TransactionFormState form, {
  AccountType? conta = AccountType.checking,
}) => arenaEventFor(form, conta);

void main() {
  group('o que vira evento', () {
    test('despesa realizada fere os heróis', () {
      final event = _evento(
        _form(type: OrderType.expense, status: InstallmentStatus.paid),
      );

      expect(event?.damage, 120);
      expect(event?.healed, 0);
    });

    test('receita recebida cura', () {
      final event = _evento(
        _form(type: OrderType.income, status: InstallmentStatus.settled),
      );

      expect(event?.healed, 120);
      expect(event?.damage, 0);
    });

    test('AGENDAMENTO não é saída de caixa: vira monstro, não dano', () {
      // Um lançamento pendente não tira dinheiro hoje. Ele entra na conta do
      // monstro pela via normal (a consulta da semana) e é lá que ele tem de
      // aparecer — animar dano aqui cobraria duas vezes pelo mesmo real.
      expect(
        _evento(
          _form(type: OrderType.expense, status: InstallmentStatus.pending),
        ),
        isNull,
      );
    });

    test('transferência não é nem dano nem cura', () {
      // O dinheiro continua no workspace: a soma das contas líquidas não
      // muda, e uma barra que tremesse sem mudar de tamanho mentiria.
      expect(
        _evento(
          _form(type: OrderType.transfer, status: InstallmentStatus.paid),
        ),
        isNull,
      );
    });

    test('edição de lançamento antigo não é saída nova', () {
      expect(
        _evento(
          _form(
            type: OrderType.expense,
            status: InstallmentStatus.paid,
            orderId: 'order-1',
          ),
        ),
        isNull,
      );
    });

    test('compra NO CARTÃO não fere os heróis', () {
      // A barra dos heróis É o caixa. Animar dano numa compra de cartão faria
      // o número descer e a barra não andar — a pior combinação possível.
      // Ela chega depois, somada, como a fatura.
      expect(
        _evento(
          _form(type: OrderType.expense, status: InstallmentStatus.paid),
          conta: AccountType.creditCard,
        ),
        isNull,
      );
    });

    test('gasto de conta de investimento fere: é caixa', () {
      expect(
        _evento(
          _form(type: OrderType.expense, status: InstallmentStatus.paid),
          conta: AccountType.investment,
        )?.damage,
        120,
      );
    });

    test('sem saber a conta, não anima nada', () {
      // Melhor não animar do que animar errado: a lista de contas ainda pode
      // estar carregando quando o save acontece.
      expect(
        _evento(
          _form(type: OrderType.expense, status: InstallmentStatus.paid),
          conta: null,
        ),
        isNull,
      );
    });

    test('parcelado: o golpe é o valor da PARCELA, não o da compra', () {
      // Um sofá de R$ 3.600 em 12× tirou R$ 300 do caixa neste mês.
      // Anunciar R$ 3.600 seria um número que a barra nunca vai andar.
      final event = _evento(
        _form(
          type: OrderType.expense,
          status: InstallmentStatus.paid,
          amount: 3600,
          installmentType: InstallmentType.installment,
          amountType: TransactionAmountType.total,
          installmentCount: 12,
        ),
      );

      expect(event?.damage, 300);
    });

    test('quando o usuário digita o valor da parcela, ele já é o golpe', () {
      final event = _evento(
        _form(
          type: OrderType.expense,
          status: InstallmentStatus.paid,
          amount: 300,
          installmentType: InstallmentType.installment,
          amountType: TransactionAmountType.installment,
          installmentCount: 12,
        ),
      );

      expect(event?.damage, 300);
    });

    test('valor zero não gera evento', () {
      expect(
        _evento(
          _form(
            type: OrderType.expense,
            status: InstallmentStatus.paid,
            amount: 0,
          ),
        ),
        isNull,
      );
    });
  });

  group('o evento guardado', () {
    test('é lido UMA vez: a segunda leitura vem vazia', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(ArenaViewProviders.pendingEvent.notifier);

      notifier.push(const ArenaPendingEvent(damage: 89.9));

      expect(notifier.take()?.damage, 89.9);
      expect(
        notifier.take(),
        isNull,
        reason:
            'um golpe anima uma vez; se ficasse guardado, toda volta para a '
            'Home repetiria o mesmo dano',
      );
    });

    test('sobrevive à Arena sair da tela', () {
      // O provider NÃO é `autoDispose` de propósito: quem lança um gasto está
      // no formulário, e a cena só existe de novo depois. Um provider que
      // morresse com a tela perderia exatamente o evento que ele guarda.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(ArenaViewProviders.pendingEvent.notifier)
          .push(const ArenaPendingEvent(healed: 6000));

      // Uma leitura nova, como a de uma cena recém-montada.
      expect(container.read(ArenaViewProviders.pendingEvent)?.healed, 6000);
    });
  });
}
