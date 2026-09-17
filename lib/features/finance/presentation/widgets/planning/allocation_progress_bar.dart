import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/animated_double.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

/// A barra de uma pool: planejado por cima, real por baixo e a linha da meta
/// atravessando as duas.
///
/// São três leituras no mesmo espaço porque a pergunta é comparativa — "o que
/// eu planejei é muito?" só tem resposta ao lado da meta, e "o que eu gastei é
/// muito?" só ao lado do planejado. Empilhar em três barras separadas obriga
/// o olho a medir distância entre gráficos.
class AllocationProgressBar extends ConsumerWidget {
  const AllocationProgressBar({super.key, required this.allocation});

  final CategoryAllocation allocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressOf = FinanceViewProviders.planning503020AllocationProgress(
      allocation,
    );
    final isOver = ref.watch(progressOf.select((state) => state.isOver));
    final currentPercentage = ref.watch(
      progressOf.select((state) => state.currentPercentage),
    );
    final actualPercentage = ref.watch(
      progressOf.select((state) => state.actualPercentage),
    );
    final statusColor = isOver ? Colors.red : Colors.green;

    return LayoutBuilder(
      builder: (context, box) {
        final maxWidth = box.maxWidth;
        final progressWidth = maxWidth * (currentPercentage.clamp(0.0, 1.0));
        final actualWidth = maxWidth * (actualPercentage.clamp(0.0, 1.0));
        final idealX = (maxWidth * allocation.idealPercentage).clamp(
          0.0,
          maxWidth,
        );

        return Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 24,
                  margin: EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                // Barra de Planejado
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      curve: Curves.bounceOut,
                      duration: Duration(milliseconds: 300),
                      height: 24,
                      margin: EdgeInsets.only(top: 14),
                      width: progressWidth,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    AnimatedDouble.percent(
                      currentPercentage,
                      duration: Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize: 10,
                        color: statusColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                // Barra de Real
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      curve: Curves.bounceOut,
                      duration: Duration(milliseconds: 300),
                      height: 24,
                      margin: EdgeInsets.only(top: 14),
                      width: actualWidth,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    AnimatedDouble.percent(
                      actualPercentage,
                      duration: Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                // Linha da Meta
                Positioned(
                  left: idealX - 30,
                  top: 0,
                  bottom: 0,
                  child: SizedBox(
                    width: 60,
                    child: Column(
                      children: [
                        Text(
                          context.l10n.planning503020TargetPercent(
                            allocation.idealPercentage.asPercent(
                              locale: context.locale,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
