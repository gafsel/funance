import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_selection/account_labels.dart';
import 'package:funances/features/finance/presentation/widgets/account_selection/account_option_tiles.dart';
import 'package:funances/features/finance/presentation/widgets/account_selection/account_owner_header.dart';
import 'package:funances/features/finance/presentation/widgets/account_selection/institution_group_card.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/core/presentation/retry.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_spacing.dart';

class AccountSelectionScreen extends ConsumerWidget {
  final String title;
  final String? excludeAccountId;
  final ValueChanged<AccountModel?> onAccountSelected;
  final bool showClearOption;
  final bool showAddOption;

  /// Tipos de conta que a tela oferece. `null` = todas.
  ///
  /// Existe porque há vínculo que só faz sentido com um tipo: uma meta de
  /// quitar dívida presa a uma conta corrente nunca sairia do lugar — o
  /// servidor calcula a amortização pelos saldos da conta de dívida.
  final Set<AccountType>? allowedTypes;

  const AccountSelectionScreen({
    super.key,
    required this.title,
    this.excludeAccountId,
    required this.onAccountSelected,
    this.showClearOption = false,
    this.showAddOption = true,
    this.allowedTypes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(AccountViewProviders.all);
    final membersAsync = ref.watch(WorkspaceViewProviders.members);
    final userId = ref.watch(AuthDomainProviders.currentUser)?.id;

    return accountsAsync.when(
      data: (accounts) {
        return membersAsync.when(
          data: (members) {
            final filteredAccounts = accounts
                .where(
                  (acc) =>
                      acc.id != excludeAccountId &&
                      (allowedTypes == null ||
                          allowedTypes!.contains(acc.type)),
                )
                .toList();

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  // Com filtro de tipo, lista vazia precisa dizer isso: sem a
                  // mensagem o usuário via um painel em branco e não sabia que
                  // faltava criar a conta certa.
                  if (filteredAccounts.isEmpty &&
                      (!showClearOption || allowedTypes != null))
                    Padding(
                      padding: AppSpacing.allXl,
                      child: Center(child: Text(l10n.noAccountsFound)),
                    )
                  else
                    Flexible(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final List<Widget> slivers = [];
                          final isSmall = constraints.layout.isCompact;
                          final gridPadding = isSmall
                              ? AppSpacing.sm
                              : AppSpacing.md;
                          final gridSpacing = gridPadding;
                          // O `/2` era fixo: num painel de 1400px a grade
                          // virava DOIS cartões de ~680px. O número de colunas
                          // agora sai da largura disponível, com a mesma régua
                          // de 350px do `ResponsiveForm`. O mínimo continua 2
                          // para que celular e tablet fiquem exatamente como
                          // estão hoje.
                          final available =
                              constraints.maxWidth - (gridPadding * 2);
                          final columns = (available / 350).floor().clamp(2, 4);
                          final itemWidth =
                              (available - gridSpacing * (columns - 1)) /
                              columns;

                          // 1. Identificar todos os titulares possíveis no workspace
                          // Queremos colocar o usuário logado primeiro.
                          final List<UserModel> sortedMembers = List.from(
                            members,
                          );
                          if (userId != null) {
                            sortedMembers.sort((a, b) {
                              if (a.id == userId) return -1;
                              if (b.id == userId) return 1;
                              return (a.displayName ?? "")
                                  .toLowerCase()
                                  .compareTo(
                                    (b.displayName ?? "").toLowerCase(),
                                  );
                            });
                          }

                          // Para cada titular
                          for (final member in sortedMembers) {
                            final isMe = member.id == userId;

                            // Filtrar contas que pertencem a este titular
                            final ownerAccounts = filteredAccounts
                                .where(
                                  (acc) => acc.ownerIds.contains(member.id),
                                )
                                .toList();

                            if (ownerAccounts.isEmpty) continue;

                            final ownerHeader = isMe
                                ? l10n.accountsMine
                                : l10n.accountsOfMember(
                                    member.displayName ?? '',
                                  );

                            // Adicionar SliverHeader para o titular
                            slivers.add(
                              SliverToBoxAdapter(
                                child: AccountOwnerHeader(
                                  title: ownerHeader,
                                  member: member,
                                ),
                              ),
                            );

                            // Agrupar contas deste titular por Institution (BankLogo)
                            final Map<BankLogo, List<AccountModel>>
                            accountsByBank = {};
                            for (final acc in ownerAccounts) {
                              accountsByBank
                                  .putIfAbsent(acc.bankLogo, () => [])
                                  .add(acc);
                            }

                            // Ordenar as instituições por nome
                            final sortedBanks = accountsByBank.keys.toList()
                              ..sort((a, b) {
                                if (a == BankLogo.none) return 1;
                                if (b == BankLogo.none) return -1;
                                return institutionName(
                                  a,
                                  l10n,
                                ).compareTo(institutionName(b, l10n));
                              });

                            final List<Widget> ownerWidgets = [];

                            for (final bank in sortedBanks) {
                              final bankAccounts = accountsByBank[bank]!;
                              bankAccounts.sort(
                                (a, b) => a.name.toLowerCase().compareTo(
                                  b.name.toLowerCase(),
                                ),
                              );

                              if (bank == BankLogo.none) {
                                for (final acc in bankAccounts) {
                                  ownerWidgets.add(
                                    StandaloneAccountCard(
                                      account: acc,
                                      onAccountSelected: onAccountSelected,
                                      isSmall: isSmall,
                                    ),
                                  );
                                }
                              } else {
                                ownerWidgets.add(
                                  InstitutionGroupCard(
                                    bank: bank,
                                    accounts: bankAccounts,
                                    onAccountSelected: onAccountSelected,
                                    isSmall: isSmall,
                                  ),
                                );
                              }
                            }

                            slivers.add(
                              SliverPadding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: gridPadding,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Wrap(
                                    spacing: gridSpacing,
                                    runSpacing: gridSpacing,
                                    children: ownerWidgets.map((w) {
                                      return SizedBox(
                                        width: itemWidth,
                                        child: w,
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            );
                          }

                          // E para as contas sem titular (compartilhadas)
                          final sharedAccounts = filteredAccounts
                              .where((acc) => acc.ownerIds.isEmpty)
                              .toList();

                          if (sharedAccounts.isNotEmpty) {
                            final sharedHeader = l10n.accountsShared;

                            slivers.add(
                              SliverToBoxAdapter(
                                child: AccountOwnerHeader(title: sharedHeader),
                              ),
                            );

                            final Map<BankLogo, List<AccountModel>>
                            accountsByBank = {};
                            for (final acc in sharedAccounts) {
                              accountsByBank
                                  .putIfAbsent(acc.bankLogo, () => [])
                                  .add(acc);
                            }

                            final sortedBanks = accountsByBank.keys.toList()
                              ..sort((a, b) {
                                if (a == BankLogo.none) return 1;
                                if (b == BankLogo.none) return -1;
                                return institutionName(
                                  a,
                                  l10n,
                                ).compareTo(institutionName(b, l10n));
                              });

                            final List<Widget> sharedWidgets = [];

                            for (final bank in sortedBanks) {
                              final bankAccounts = accountsByBank[bank]!;
                              bankAccounts.sort(
                                (a, b) => a.name.toLowerCase().compareTo(
                                  b.name.toLowerCase(),
                                ),
                              );

                              if (bank == BankLogo.none) {
                                for (final acc in bankAccounts) {
                                  sharedWidgets.add(
                                    StandaloneAccountCard(
                                      account: acc,
                                      onAccountSelected: onAccountSelected,
                                      isSmall: isSmall,
                                    ),
                                  );
                                }
                              } else {
                                sharedWidgets.add(
                                  InstitutionGroupCard(
                                    bank: bank,
                                    accounts: bankAccounts,
                                    onAccountSelected: onAccountSelected,
                                    isSmall: isSmall,
                                  ),
                                );
                              }
                            }

                            slivers.add(
                              SliverPadding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: gridPadding,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Wrap(
                                    spacing: gridSpacing,
                                    runSpacing: gridSpacing,
                                    children: sharedWidgets.map((w) {
                                      return SizedBox(
                                        width: itemWidth,
                                        child: w,
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            );
                          }

                          slivers.add(
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              sliver: SliverToBoxAdapter(
                                child: Column(
                                  children: [
                                    if (showAddOption) ...[
                                      const Divider(),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: AddAccountOption(
                                          isSmall: isSmall,
                                        ),
                                      ),
                                    ],
                                    if (showClearOption) ...[
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: ClearAccountOption(
                                          onCleared: () =>
                                              onAccountSelected(null),
                                          isSmall: isSmall,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );

                          slivers.add(
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).padding.bottom + 16,
                              ),
                            ),
                          );

                          return CustomScrollView(
                            shrinkWrap: true,
                            slivers: slivers,
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => const Padding(
            padding: AppSpacing.allXl,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Padding(
            padding: AppSpacing.allXl,
            child: ErrorView.forError(
              context,
              err,
              onRetry: () => Retry.members(ref),
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: AppSpacing.allXl,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: AppSpacing.allXl,
        child: ErrorView.forError(
          context,
          err,
          onRetry: () => Retry.accounts(ref),
        ),
      ),
    );
  }
}
