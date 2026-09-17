import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_durations.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/widgets/simple_markdown.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class CoachingSlidesScreen extends ConsumerStatefulWidget {
  const CoachingSlidesScreen({super.key, required this.coaching});

  final CoachingModel coaching;

  @override
  ConsumerState<CoachingSlidesScreen> createState() =>
      _CoachingSlidesScreenState();
}

class _CoachingSlidesScreenState extends ConsumerState<CoachingSlidesScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _iconAnimationController;

  /// Largura máxima da coluna do slide.
  ///
  /// Era `800` repetido em três `ConstrainedBox` — o único 800 solto que
  /// sobrou no app depois que os breakpoints viraram um corte só. É a largura
  /// de conteúdo do layout médio, e não um breakpoint: o slide é sangria
  /// total em qualquer largura, o que ele limita é a linha de texto.
  static const double _columnMaxWidth = 720;

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // O ícone do slide pulsa para sempre. Quem pediu menos movimento não
    // recebe um laço infinito rodando atrás do texto que veio ler.
    if (AppDurations.reduceMotion(context)) {
      _iconAnimationController.stop();
    } else if (!_iconAnimationController.isAnimating) {
      _iconAnimationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildSlides(context));
  }

  /// Rotas internas que um slide pode acionar. A IA pode alucinar um
  /// `actionPath` fora deste conjunto; nesse caso o botão não é exibido.
  /// Precisa ser a MESMA lista de `coaching_action_path.model.ts` no backend
  /// (ver functions/README.md, "Rotas do coaching").
  static const _allowedActionPaths = {
    '/',
    '/planning',
    '/planning-50-30-20',
    '/goals/form',
    '/accounts/form',
    '/transactions/form',
    '/category-details',
    '/workspace/categories',
    '/workspace/accounts',
    '/workspace/badges',
    '/coaching/history',
  };

  static bool _isAllowedActionPath(String? path) {
    if (path == null) return false;
    final normalized = Uri.tryParse(path)?.path ?? path;
    return _allowedActionPaths.contains(normalized);
  }

  /// A tinta de tudo que pousa sobre a cor do slide.
  ///
  /// A cor do slide vem da IA e é sempre saturada e escura; o papel desta
  /// tinta é o mesmo de [AppColors.inkInverse] em qualquer bloco de jogo —
  /// por isso é ela, e não um `Colors.white` solto.
  static const Color _onSlide = AppColors.inkInverse;

  Widget _buildSlides(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final slides = widget.coaching.slides;

    if (slides.isEmpty) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.psychology_outlined, size: 48),
              AppSpacing.gapMd,
              Text(l10n.coachingNoSlides),
              AppSpacing.gapMd,
              FilledButton(
                onPressed: () => context.pop(),
                child: Text(l10n.coachingSlideFinish),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemCount: slides.length,
          itemBuilder: (context, index) {
            final slide = slides[index];
            final Color slideColor = slide.color.asColor();
            final Color? secondaryColor = slide.secondaryColor?.asColor();

            return Container(
              decoration: BoxDecoration(
                gradient: secondaryColor != null
                    ? LinearGradient(
                        colors: [slideColor, secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: secondaryColor == null ? slideColor : null,
              ),
              child: Stack(
                children: [
                  // Ícones decorativos de fundo
                  ..._buildBackgroundIcons(slide),

                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _columnMaxWidth,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildAnimatedIcon(slide),
                            const SizedBox(height: AppSpacing.xxxl),
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: _onSlide,
                              ),
                            ),
                            AppSpacing.gapLg,
                            SimpleMarkdown(
                              data: slide.message,
                              textAlign: TextAlign.center,
                              onTapLink: (href) {
                                // Só abre links http(s) válidos — a IA pode
                                // gerar URLs malformadas ou de outros esquemas.
                                final uri = Uri.tryParse(href);
                                if (uri != null &&
                                    (uri.scheme == 'https' ||
                                        uri.scheme == 'http')) {
                                  launchUrl(uri);
                                }
                              },
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: _onSlide,
                              ),
                              linkStyle: theme.textTheme.bodyLarge?.copyWith(
                                color: _onSlide,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: _onSlide,
                              ),
                            ),
                            if (slide.actionLabel != null &&
                                _isAllowedActionPath(slide.actionPath)) ...[
                              AppSpacing.gapXl,
                              ElevatedButton(
                                onPressed: () {
                                  final router = GoRouter.of(context);
                                  router.pop();
                                  router.push(slide.actionPath!);
                                },
                                style: _onSlideButtonStyle(
                                  slideColor,
                                  vertical: AppSpacing.md,
                                ),
                                child: Text(slide.actionLabel!),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Indicadores de progresso
        Positioned(
          top: AppSpacing.xxl + AppSpacing.lg,
          left: 0,
          right: 0,
          child: Center(
            child: Padding(
              padding: AppSpacing.hMd,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _columnMaxWidth),
                child: Row(
                  children: List.generate(
                    slides.length,
                    (index) => Expanded(
                      child: Container(
                        height: AppSpacing.xxs,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? _onSlide
                              : _onSlide.withValues(alpha: 0.38),
                          borderRadius: AppRadius.brXs,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Botão Fechar
        Positioned(
          top: AppSpacing.xxl + AppSpacing.xl,
          right: AppSpacing.md,
          child: IconButton(
            tooltip: l10n.closeButton,
            icon: const Icon(Icons.close, color: _onSlide, size: 30),
            onPressed: () => context.pop(),
          ),
        ),

        // Navegação
        Positioned(
          bottom: AppSpacing.xxl + AppSpacing.xxs,
          left: 0,
          right: 0,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _columnMaxWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: () => _pageController.previousPage(
                          duration: AppDurations.respectingMotion(
                            context,
                            AppDurations.celebrate,
                          ),
                          curve: AppDurations.curve,
                        ),
                        style: TextButton.styleFrom(foregroundColor: _onSlide),
                        child: Text(l10n.coachingSlideBack),
                      )
                    else
                      const SizedBox.shrink(),
                    ElevatedButton(
                      onPressed: () {
                        if (_currentPage < slides.length - 1) {
                          _pageController.nextPage(
                            duration: AppDurations.respectingMotion(
                              context,
                              AppDurations.celebrate,
                            ),
                            curve: AppDurations.curve,
                          );
                        } else {
                          context.pop();
                        }
                      },
                      style: _onSlideButtonStyle(
                        slides[_currentPage].color.asColor(),
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(
                        _currentPage < slides.length - 1
                            ? l10n.coachingSlideNext
                            : l10n.coachingSlideFinish,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// O botão claro que pousa sobre a cor do slide: a inversão é o destaque.
  ButtonStyle _onSlideButtonStyle(Color slideColor, {required double vertical}) {
    return ElevatedButton.styleFrom(
      backgroundColor: _onSlide,
      foregroundColor: slideColor,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: vertical,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brPill),
    );
  }

  List<Widget> _buildBackgroundIcons(SlideModel slide) {
    final Set<String> uniqueIcons = {slide.icon, ...slide.icons};
    final iconsList = uniqueIcons.toList();
    final random = math.Random(slide.title.hashCode);

    return [
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          // Numa janela estreita a grade de 3 colunas empilha ícones de 200px
          // uns sobre os outros; numa larga, 3 colunas deixam o meio vazio.
          final gridCols = switch (constraints.layout) {
            AppLayout.compact => 2,
            AppLayout.medium => 3,
            AppLayout.wide => 4,
          };
          final gridRows = (12 / gridCols).ceil();

          return Stack(
            children: List.generate(12, (index) {
              final iconName = iconsList[index % iconsList.length];
              final size = 80 + random.nextDouble() * 120;

              final col = index % gridCols;
              final row = index ~/ gridCols;

              final cellWidth = width / gridCols;
              final cellHeight = height / gridRows;

              // Posição baseada na célula da grade + um deslocamento aleatório
              final left =
                  (col * cellWidth) +
                  (random.nextDouble() * (cellWidth - size));
              final top =
                  (row * cellHeight) +
                  (random.nextDouble() * (cellHeight - size));

              return Positioned(
                top: top,
                left: left,
                child: Opacity(
                  opacity: 0.08,
                  child: Transform.rotate(
                    angle: random.nextDouble() * 0.5 - 0.25, // Rotação leve
                    child: Icon(
                      iconName.asIcon(orElse: Icons.tips_and_updates),
                      size: size,
                      color: _onSlide,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    ];
  }

  Widget _buildAnimatedIcon(SlideModel slide) {
    final iconData = slide.icon.asIcon(orElse: Icons.tips_and_updates);
    final icon = Icon(iconData, size: 110, color: _onSlide);

    // Com "reduzir movimento" o ícone é só um ícone: sem laço, sem halo
    // pulsante e sem `AnimatedBuilder` reconstruindo o slide a 60fps.
    if (AppDurations.reduceMotion(context)) return icon;

    // Usar uma curva para tornar a animação mais dinâmica
    final CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: _iconAnimationController,
      curve: Curves.easeInOut,
    );

    return AnimatedBuilder(
      animation: curvedAnimation,
      builder: (context, child) {
        double dx = 0.0;
        double dy = 0.0;
        double scale = 1.0;
        double opacity = 1.0;
        double rotation = 0.0;

        switch (slide.animationType) {
          case 'bounce':
            // Bounce mais pronunciado
            final bounceVal = math.sin(curvedAnimation.value * math.pi);
            dy = -40 * bounceVal;
            scale = 1.0 + (0.1 * bounceVal);
            break;
          case 'pulse':
            // Pulso mais forte
            scale = 1.0 + 0.25 * curvedAnimation.value;
            break;
          case 'fade':
            // Fade com maior amplitude
            opacity = 0.3 + 0.7 * curvedAnimation.value;
            break;
          case 'zoom':
            // Zoom in e out mais visível
            scale = 0.7 + 0.6 * curvedAnimation.value;
            break;
          case 'slide':
            // Slide lateral com leve rotação
            dx = 30 * math.sin(curvedAnimation.value * 2 * math.pi);
            rotation = 0.15 * math.sin(curvedAnimation.value * 2 * math.pi);
            break;
          default:
            // Animação padrão: pulso leve com rotação
            scale = 1.0 + 0.1 * curvedAnimation.value;
            rotation = 0.05 * math.sin(curvedAnimation.value * 2 * math.pi);
        }

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _onSlide.withValues(
                          alpha: 0.2 * curvedAnimation.value,
                        ),
                        blurRadius: 20 * curvedAnimation.value,
                        spreadRadius: 5 * curvedAnimation.value,
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: icon,
    );
  }
}
