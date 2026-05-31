import 'dart:async';
import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/l10n/app_localizations.dart';

class AnalysisLoadingView extends StatefulWidget {
  final String? title;
  final String? description;

  const AnalysisLoadingView({
    super.key,
    this.title,
    this.description,
  });

  @override
  State<AnalysisLoadingView> createState() => _AnalysisLoadingViewState();
}

class _AnalysisLoadingViewState extends State<AnalysisLoadingView>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _progressController;
  double _currentProgress = 0.0;
  Timer? _recursiveTimer;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    _progressController.addListener(() {
      setState(() {
        _currentProgress = _progressController.value * 0.95;
      });
    });

    _progressController.forward().then((_) {
      _startRecursiveProgress();
    });
  }

  void _startRecursiveProgress() {
    _recursiveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          final remaining = 1.0 - _currentProgress;
          _currentProgress += remaining * 0.5;
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _progressController.dispose();
    _recursiveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepTurquoise,
            AppColors.vibrantTeal,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone animado
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * 3.14159,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.successGold.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.psychology,
                        size: 64,
                        color: AppColors.successGold,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
              // Título
              Text(
                widget.title ?? l10n.accountAnalyzing,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Descrição
              Text(
                widget.description ?? l10n.accountAnalysisDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.pureWhite.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 48),
              // Indicador de progresso Linear
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: _currentProgress,
                  backgroundColor: AppColors.deepTurquoise,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.successGold),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.accountAnalysisProcessing,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.pureWhite.withValues(alpha: 0.7),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
