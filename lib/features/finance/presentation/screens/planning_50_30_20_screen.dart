import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/widgets/money_form_field.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class Planning503020Screen extends ConsumerStatefulWidget {
  const Planning503020Screen({super.key});

  @override
  ConsumerState<Planning503020Screen> createState() => _Planning503020ScreenState();
}

class _Planning503020ScreenState extends ConsumerState<Planning503020Screen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(FinanceViewProviders.planning503020);
    final l10n = context.l10n;
    final currencyFormat = NumberFormat.simpleCurrency(locale: context.locale);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.planning503020Title),
        actions: [
          IconButton(
            onPressed: state.isSubmitting
                ? null
                : () async {
                    await ref.read(FinanceViewProviders.planning503020.notifier).submit();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Salvo com sucesso!')),
                      );
                    }
                  },
            icon: state.isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;
          
          final essentialItems = state.items.where((i) => i.category.allocation == CategoryAllocation.essential).toList();
          final comfortItems = state.items.where((i) => i.category.allocation == CategoryAllocation.comfort).toList();
          final investmentItems = state.items.where((i) => i.category.allocation == CategoryAllocation.investment).toList();

          // Calculando renda total prevista (simplificado: soma de todos os planejamentos se tivéssemos acesso fácil, 
          // mas aqui vamos focar na soma das despesas planejadas para referência ou usar um valor fixo se o sistema permitir.
          // Para o 50-30-20, o ideal é baseado no TOTAL planejado para o mês.
          final totalPlanned = state.items.fold<double>(0, (sum, item) => sum + item.effectiveAmount);
          final totalActual = state.items.fold<double>(0, (sum, item) => sum + item.actualAmount);
          final totalIncome = state.totalIncomes;
          
          final actualPercentage = totalIncome > 0 ? (totalActual / totalIncome) : 0.0;
          final percentageFormat = NumberFormat.percentPattern(context.locale);
          
          final header = Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.planning503020SummaryIncome,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Text(
                            currencyFormat.format(state.totalIncomes),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.planning503020SummaryExpense,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Text(
                            currencyFormat.format(totalPlanned),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: totalPlanned > state.totalIncomes ? Colors.red : null,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.planning503020SummaryActual,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Text(
                            '${currencyFormat.format(totalActual)} (${percentageFormat.format(actualPercentage)})',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: totalActual > state.totalIncomes ? Colors.red : AppColors.darkNavy,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          if (isMobile) {
            return Column(
              children: [
                header,
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    children: [
                      _PoolWidget(
                        title: l10n.planning503020Essential,
                        description: l10n.planning503020EssentialDesc,
                        items: essentialItems,
                        idealPercentage: 0.5,
                        totalPlanned: totalPlanned,
                        totalIncome: totalIncome,
                        allocation: CategoryAllocation.essential,
                      ),
                      _PoolWidget(
                        title: l10n.planning503020Comfort,
                        description: l10n.planning503020ComfortDesc,
                        items: comfortItems,
                        idealPercentage: 0.3,
                        totalPlanned: totalPlanned,
                        totalIncome: totalIncome,
                        allocation: CategoryAllocation.comfort,
                      ),
                      _PoolWidget(
                        title: l10n.planning503020Investment,
                        description: l10n.planning503020InvestmentDesc,
                        items: investmentItems,
                        idealPercentage: 0.2,
                        totalPlanned: totalPlanned,
                        totalIncome: totalIncome,
                        allocation: CategoryAllocation.investment,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: _currentPage == index ? Theme.of(context).primaryColor : Colors.grey,
                      ),
                    )),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              header,
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _PoolWidget(
                        title: l10n.planning503020Essential,
                        description: l10n.planning503020EssentialDesc,
                        items: essentialItems,
                        idealPercentage: 0.5,
                        totalPlanned: totalPlanned,
                        totalIncome: totalIncome,
                        allocation: CategoryAllocation.essential,
                      ),
                    ),
                    Expanded(
                      child: _PoolWidget(
                        title: l10n.planning503020Comfort,
                        description: l10n.planning503020ComfortDesc,
                        items: comfortItems,
                        idealPercentage: 0.3,
                        totalPlanned: totalPlanned,
                        totalIncome: totalIncome,
                        allocation: CategoryAllocation.comfort,
                      ),
                    ),
                    Expanded(
                      child: _PoolWidget(
                        title: l10n.planning503020Investment,
                        description: l10n.planning503020InvestmentDesc,
                        items: investmentItems,
                        idealPercentage: 0.2,
                        totalPlanned: totalPlanned,
                        totalIncome: totalIncome,
                        allocation: CategoryAllocation.investment,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PoolWidget extends ConsumerWidget {
  final String title;
  final String description;
  final List<CategoryPlanning503020Item> items;
  final double idealPercentage;
  final double totalPlanned;
  final double totalIncome;
  final CategoryAllocation allocation;

  const _PoolWidget({
    required this.title,
    required this.description,
    required this.items,
    required this.idealPercentage,
    required this.totalPlanned,
    required this.totalIncome,
    required this.allocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currencyFormat = NumberFormat.simpleCurrency(locale: context.locale);
    
    final currentTotal = items.fold<double>(0, (sum, item) => sum + item.effectiveAmount);
    final currentActual = items.fold<double>(0, (sum, item) => sum + item.actualAmount);
    final idealValue = totalIncome * idealPercentage;
    final currentPercentage = totalIncome > 0 ? (currentTotal / totalIncome) : 0.0;
    final actualPercentage = totalIncome > 0 ? (currentActual / totalIncome) : 0.0;
    final percentageFormat = NumberFormat.percentPattern(context.locale);
    
    // Indica se está dentro da meta (não ultrapassa o ideal)
    final isWithinRange = currentTotal <= idealValue;
    final isOver = currentTotal > idealValue;

    return DragTarget<String>(
      onAccept: (categoryId) {
        ref.read(FinanceViewProviders.planning503020.notifier).moveCategory(categoryId, allocation);
      },
      builder: (context, candidateData, rejectedData) {
        final statusColor = isOver ? Colors.red : Colors.green;

        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                        Icon(
                          isOver ? Icons.warning : Icons.check_circle,
                          size: 20,
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, box) {
                        final maxWidth = box.maxWidth;
                        final progressWidth = maxWidth * (currentPercentage.clamp(0.0, 1.0));
                        final actualWidth = maxWidth * (actualPercentage.clamp(0.0, 1.0));
                        final idealX = maxWidth * idealPercentage;

                        return Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                // Barra de Planejado
                                Container(
                                  height: 24,
                                  width: progressWidth,
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                // Barra de Real
                                Container(
                                  height: 24,
                                  width: actualWidth,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                // Linha da Meta
                                Positioned(
                                  left: idealX - 1,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 2,
                                    color: AppColors.darkNavy,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  percentageFormat.format(actualPercentage),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                ),
                                Text(
                                  'Meta: ${percentageFormat.format(idealPercentage)}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  percentageFormat.format(currentPercentage),
                                  style: TextStyle(fontSize: 10, color: statusColor.withOpacity(0.7)),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.planning503020Actual(currencyFormat.format(currentActual)),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              l10n.planning503020Total(currencyFormat.format(currentTotal)),
                              style: TextStyle(
                                color: statusColor.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          currencyFormat.format(idealValue),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty 
                  ? Center(child: Text(l10n.planning503020EmptyPool, style: Theme.of(context).textTheme.bodySmall))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _CategoryCard(item: item);
                      },
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final CategoryPlanning503020Item item;

  const _CategoryCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currencyFormat = NumberFormat.simpleCurrency(locale: context.locale);
    final isOverGeneral = item.generalAmount > 0;
    final actualOverLimit = isOverGeneral ? item.actualAmount > item.generalAmount : item.actualAmount > item.specificAmount;
    final specificOverLimit = isOverGeneral && item.specificAmount > item.generalAmount;

    return Draggable<String>(
      data: item.category.id,
      feedback: Material(
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Text(item.category.name),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: _card(context, l10n, currencyFormat, actualOverLimit, specificOverLimit, ref)),
      child: _card(context, l10n, currencyFormat, actualOverLimit, specificOverLimit, ref),
    );
  }

  Widget _card(BuildContext context, AppLocalizations l10n, NumberFormat currencyFormat, bool actualOverLimit, bool specificOverLimit, WidgetRef ref) {
    final hasAlert = specificOverLimit;
    return Card(
      elevation: 4,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.category.color.asColor().withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.category.icon.asIcon(),
                    color: item.category.color.asColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.category.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkNavy),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MoneyFormField(
              initialValue: item.generalAmount > 0 ? item.generalAmount : null,
              decoration: InputDecoration(
                labelText: 'Limite Mensal',
                fillColor: Colors.grey.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                ref.read(FinanceViewProviders.planning503020.notifier).updateAmount(item.category.id, value ?? 0.0);
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.planning503020ActualLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.darkNavy.withOpacity(0.7)),
                ),
                Text(
                  currencyFormat.format(item.actualAmount),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: actualOverLimit ? Colors.red : AppColors.darkNavy,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Já previsto:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.darkNavy.withOpacity(0.7)),
                ),
                Text(
                  currencyFormat.format(item.specificAmount),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: specificOverLimit ? Colors.red : AppColors.darkNavy,
                      ),
                ),
              ],
            ),
            if (hasAlert) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l10n.planning503020AlertSpecificGreater,
                        style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
