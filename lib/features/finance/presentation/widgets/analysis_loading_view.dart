import 'dart:async';
import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/l10n/app_localizations.dart';

class AnalysisLoadingView extends StatefulWidget {
  final String? title;
  final String? description;
  final Duration firstPhaseDuration;
  final Duration totalDuration;
  final Stream<UploadProgressModel?>? progressStream;

  const AnalysisLoadingView({
    super.key,
    this.title,
    this.description,
    this.firstPhaseDuration = const Duration(minutes: 1),
    this.totalDuration = const Duration(minutes: 5),
    this.progressStream,
  });

  @override
  State<AnalysisLoadingView> createState() => _AnalysisLoadingViewState();
}

class _AnalysisLoadingViewState extends State<AnalysisLoadingView>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _progressController;
  double _currentProgress = 0.0;
  Timer? _secondPhaseTimer;
  // Só usamos a assinatura para cancelar, então o tipo do elemento é irrelevante.
  StreamSubscription<void>? _progressSubscription;
  UploadStatus? _currentStatus;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: widget.firstPhaseDuration,
    );

    if (widget.progressStream != null) {
      _progressSubscription = widget.progressStream!.listen((data) {
        if (mounted && data != null) {
          setState(() {
            _currentProgress = data.progress;
            _currentStatus = data.status;
          });
        }
      });
    } else {
      _progressController.addListener(() {
        setState(() {
          _currentProgress = _progressController.value * 0.90;
        });
      });

      _progressController.forward().then((_) {
        _startSecondPhase();
      });
    }
  }

  void _startSecondPhase() {
    final remainingDuration = widget.totalDuration - widget.firstPhaseDuration;
    if (remainingDuration.isNegative || remainingDuration == Duration.zero) {
      setState(() {
        _currentProgress = 1.0;
      });
      return;
    }

    const interval = Duration(milliseconds: 100);
    final totalSteps = remainingDuration.inMilliseconds / interval.inMilliseconds;
    int currentStep = 0;

    _secondPhaseTimer = Timer.periodic(interval, (timer) {
      if (mounted) {
        currentStep++;
        setState(() {
          final ratio = currentStep / totalSteps;
          _currentProgress = 0.90 + (0.10 * ratio);
        });

        if (currentStep >= totalSteps) {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _progressController.dispose();
    _secondPhaseTimer?.cancel();
    _progressSubscription?.cancel();
    super.dispose();
  }

  /// Texto de cada fase da análise do extrato.
  static String? _messageFor(AppLocalizations l10n, UploadStatus? status) =>
      switch (status) {
        UploadStatus.reading => l10n.uploadStatusReading,
        UploadStatus.extracting => l10n.uploadStatusExtracting,
        UploadStatus.searching => l10n.uploadStatusSearching,
        UploadStatus.preparing => l10n.uploadStatusPreparing,
        UploadStatus.completed => l10n.uploadStatusCompleted,
        UploadStatus.error => l10n.uploadStatusError,
        null => null,
      };

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
                // A frase vem do STATUS, traduzida aqui. O campo `message` do
                // documento de upload é escrito em português tanto pelo app
                // quanto pela função de extração: mostrá-lo cru era a única
                // tela do app que ignorava o idioma do usuário.
                _messageFor(l10n, _currentStatus) ??
                    l10n.accountAnalysisProcessing,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.pureWhite.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
