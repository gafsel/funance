import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/user/presentation/widgets/user_avatar.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/core/widgets/error_view.dart';

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
                      (allowedTypes == null || allowedTypes!.contains(acc.type)),
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
                      padding: const EdgeInsets.all(32.0),
                      child: Center(child: Text(l10n.noAccountsFound)),
                    )
                  else
                    Flexible(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final List<Widget> slivers = [];
                          final isSmall = constraints.maxWidth < 600;
                          final gridPadding = isSmall ? 12.0 : 16.0;
                          final gridSpacing = isSmall ? 12.0 : 16.0;
                          final itemWidth = (constraints.maxWidth - (gridPadding * 2) - gridSpacing) / 2;

                          // 1. Identificar todos os titulares possíveis no workspace
                          // Queremos colocar o usuário logado primeiro.
                          final List<UserModel> sortedMembers = List.from(members);
                          if (userId != null) {
                            sortedMembers.sort((a, b) {
                              if (a.id == userId) return -1;
                              if (b.id == userId) return 1;
                              return (a.displayName ?? "").toLowerCase().compareTo((b.displayName ?? "").toLowerCase());
                            });
                          }

                          // Para cada titular
                          for (final member in sortedMembers) {
                            final isMe = member.id == userId;
                            
                            // Filtrar contas que pertencem a este titular
                            final ownerAccounts = filteredAccounts
                                .where((acc) => acc.ownerIds.contains(member.id))
                                .toList();
                            
                            if (ownerAccounts.isEmpty) continue;

                            final ownerHeader = isMe
                                ? l10n.accountsMine
                                : l10n.accountsOfMember(
                                    member.displayName ?? '',
                                  );

                            // Adicionar SliverHeader para o titular
                            slivers.add(
                              _buildOwnerHeader(context, ownerHeader, member),
                            );

                            // Agrupar contas deste titular por Institution (BankLogo)
                            final Map<BankLogo, List<AccountModel>> accountsByBank = {};
                            for (final acc in ownerAccounts) {
                              accountsByBank.putIfAbsent(acc.bankLogo, () => []).add(acc);
                            }

                            // Ordenar as instituições por nome
                            final sortedBanks = accountsByBank.keys.toList()
                              ..sort((a, b) {
                                if (a == BankLogo.none) return 1;
                                if (b == BankLogo.none) return -1;
                                return _getInstitutionName(a).compareTo(_getInstitutionName(b));
                              });

                            final List<Widget> ownerWidgets = [];

                            for (final bank in sortedBanks) {
                              final bankAccounts = accountsByBank[bank]!;
                              bankAccounts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                              if (bank == BankLogo.none) {
                                for (final acc in bankAccounts) {
                                  ownerWidgets.add(
                                    _buildOutrosAccountCard(context, acc, l10n, isSmall: isSmall),
                                  );
                                }
                              } else {
                                ownerWidgets.add(
                                  _buildInstitutionContainer(context, bank, bankAccounts, l10n, isSmall: isSmall),
                                );
                              }
                            }

                            slivers.add(
                              SliverPadding(
                                padding: EdgeInsets.symmetric(horizontal: gridPadding),
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
                              _buildOwnerHeader(context, sharedHeader, null),
                            );

                            final Map<BankLogo, List<AccountModel>> accountsByBank = {};
                            for (final acc in sharedAccounts) {
                              accountsByBank.putIfAbsent(acc.bankLogo, () => []).add(acc);
                            }

                            final sortedBanks = accountsByBank.keys.toList()
                              ..sort((a, b) {
                                if (a == BankLogo.none) return 1;
                                if (b == BankLogo.none) return -1;
                                return _getInstitutionName(a).compareTo(_getInstitutionName(b));
                              });

                            final List<Widget> sharedWidgets = [];

                            for (final bank in sortedBanks) {
                              final bankAccounts = accountsByBank[bank]!;
                              bankAccounts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                              if (bank == BankLogo.none) {
                                for (final acc in bankAccounts) {
                                  sharedWidgets.add(
                                    _buildOutrosAccountCard(context, acc, l10n, isSmall: isSmall),
                                  );
                                }
                              } else {
                                sharedWidgets.add(
                                  _buildInstitutionContainer(context, bank, bankAccounts, l10n, isSmall: isSmall),
                                );
                              }
                            }

                            slivers.add(
                              SliverPadding(
                                padding: EdgeInsets.symmetric(horizontal: gridPadding),
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
                                        child: _buildAddAccountOption(
                                          context,
                                          l10n,
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
                                        child: _buildClearOption(context, l10n, isSmall: isSmall),
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
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(32.0),
            child: ErrorView.forError(
              context,
              err,
              onRetry: () => ref.invalidate(WorkspaceViewProviders.members),
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: ErrorView.forError(
          context,
          err,
          onRetry: () => ref.invalidate(AccountViewProviders.all),
        ),
      ),
    );
  }

  Widget _buildOwnerHeader(BuildContext context, String title, UserModel? member) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (member != null) ...[
                  UserAvatar(
                    displayName: member.displayName,
                    photoUrl: member.photoUrl,
                    radius: 12,
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  const Icon(Icons.people_outline, size: 24),
                  const SizedBox(width: 8),
                ],
                Text(
                  title.toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const Divider(height: 8, thickness: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildInstitutionContainer(
    BuildContext context,
    BankLogo bank,
    List<AccountModel> accounts,
    AppLocalizations l10n, {
    required bool isSmall,
  }) {
    final theme = Theme.of(context);
    final bankName = _getInstitutionName(bank);
    final paddingVal = isSmall ? 10.0 : 16.0;
    final logoSize = isSmall ? 32.0 : 40.0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(paddingVal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: isSmall ? 8 : 12,
              runSpacing: isSmall ? 6 : 8,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(isSmall ? 8 : 10),
                  child: Image.asset(
                    'assets/logos/${bank.name}.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: logoSize,
                      height: logoSize,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.account_balance,
                        color: theme.colorScheme.primary,
                        size: isSmall ? 20 : 24,
                      ),
                    ),
                  ),
                ),
                Text(
                  bankName,
                  style: (isSmall ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmall ? 8 : 12),
            const Divider(height: 1),
            SizedBox(height: isSmall ? 6 : 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: accounts.indexed.map((entry) {
                final idx = entry.$1;
                final acc = entry.$2;
                final typeIconSize = isSmall ? 26.0 : 32.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (idx > 0) Divider(height: isSmall ? 12 : 16),
                    InkWell(
                      onTap: () => onAccountSelected(acc),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isSmall ? 4 : 8,
                          horizontal: isSmall ? 4 : 8,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: typeIconSize,
                              height: typeIconSize,
                              decoration: BoxDecoration(
                                color: acc.color.asColor().withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getAccountTypeIcon(acc.type),
                                color: acc.color.asColor(),
                                size: isSmall ? 15 : 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getAccountTypeName(acc.type, l10n),
                                    style: (isSmall
                                            ? theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              )
                                            : theme.textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ))
                                        ?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    acc.name,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              size: isSmall ? 16 : 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutrosAccountCard(
    BuildContext context,
    AccountModel account,
    AppLocalizations l10n, {
    required bool isSmall,
  }) {
    final theme = Theme.of(context);
    final paddingVal = isSmall ? 10.0 : 16.0;
    final logoSize = isSmall ? 32.0 : 40.0;
    
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: () => onAccountSelected(account),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(paddingVal),
          child: Row(
            children: [
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  color: account.color.asColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isSmall ? 8 : 10),
                ),
                child: Icon(
                  account.icon.asIcon(),
                  color: account.color.asColor(),
                  size: isSmall ? 18 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: (isSmall
                              ? theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                )
                              : theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ))
                          ?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getAccountTypeName(account.type, l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                size: isSmall ? 16 : 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClearOption(BuildContext context, AppLocalizations l10n, {required bool isSmall}) {
    final theme = Theme.of(context);
    final paddingVal = isSmall ? 10.0 : 16.0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: paddingVal),
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: isSmall ? 16 : 20,
          child: Icon(Icons.clear_all, color: Colors.grey, size: isSmall ? 20 : 24),
        ),
        title: Text(
          l10n.clear,
          style: isSmall ? theme.textTheme.bodyMedium : theme.textTheme.titleSmall,
        ),
        onTap: () => onAccountSelected(null),
      ),
    );
  }

  Widget _buildAddAccountOption(BuildContext context, AppLocalizations l10n, {required bool isSmall}) {
    final theme = Theme.of(context);
    final paddingVal = isSmall ? 10.0 : 16.0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: paddingVal),
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: isSmall ? 16 : 20,
          child: Icon(Icons.add, color: Colors.grey, size: isSmall ? 20 : 24),
        ),
        title: Text(
          l10n.accountCreateTitle,
          style: isSmall ? theme.textTheme.bodyMedium : theme.textTheme.titleSmall,
        ),
        onTap: () {
          context.push('/accounts/form');
        },
      ),
    );
  }

  IconData _getAccountTypeIcon(AccountType type) {
    switch (type) {
      case AccountType.checking:
        return Icons.wallet_outlined;
      case AccountType.creditCard:
        return Icons.credit_card_outlined;
      case AccountType.investment:
        return Icons.trending_up_outlined;
      case AccountType.debt:
        return Icons.trending_down_outlined;
    }
  }

  String _getAccountTypeName(AccountType type, AppLocalizations l10n) {
    switch (type) {
      case AccountType.checking:
        return l10n.accountTypeChecking;
      case AccountType.investment:
        return l10n.accountTypeInvestment;
      case AccountType.creditCard:
        return l10n.accountTypeCreditCard;
      case AccountType.debt:
        return l10n.accountTypeDebt;
    }
  }

  String _getInstitutionName(BankLogo logo) {
    switch (logo) {
      case BankLogo.none:
        return "Outros";
      case BankLogo.nubank:
        return "Nubank";
      case BankLogo.inter:
        return "Inter";
      case BankLogo.itau:
        return "Itaú";
      case BankLogo.bradesco:
        return "Bradesco";
      case BankLogo.santander:
        return "Santander";
      case BankLogo.bb:
        return "Banco do Brasil";
      case BankLogo.caixa:
        return "Caixa";
      case BankLogo.c6:
        return "C6 Bank";
      case BankLogo.xp:
        return "XP Investimentos";
      case BankLogo.btg:
        return "BTG Pactual";
      case BankLogo.visa:
        return "Visa";
      case BankLogo.mastercard:
        return "Mastercard";
      case BankLogo.elo:
        return "Elo";
      case BankLogo.amex:
        return "American Express";
    }
  }
}
