import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/widgets/simple_markdown.dart';
import 'package:funances/core/utils/icons_extension.dart';
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

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildSlides(context)
    );
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

  Widget _buildSlides(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final slides = widget.coaching.slides;

    if (slides.isEmpty) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.psychology_outlined, size: 48),
              const SizedBox(height: 16),
              Text(l10n.coachingNoSlides),
              const SizedBox(height: 16),
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
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildAnimatedIcon(slide),
                            const SizedBox(height: 48),
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              linkStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                            if (slide.actionLabel != null &&
                                _isAllowedActionPath(slide.actionPath)) ...[
                              const SizedBox(height: 32),
                              ElevatedButton(
                                onPressed: () {
                                  final router = GoRouter.of(context);
                                  router.pop();
                                  router.push(slide.actionPath!);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: slideColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 6,
                                  shadowColor: Colors.black.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                child: Text(
                                  slide.actionLabel!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
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
          top: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Row(
                  children: List.generate(
                    slides.length,
                    (index) => Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? Colors.white
                              : Colors.white38,
                          borderRadius: BorderRadius.circular(2),
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
          top: 70,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () => context.pop(),
          ),
        ),

        // Navegação
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: Text(
                          l10n.coachingSlideBack,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    ElevatedButton(
                      onPressed: () {
                        if (_currentPage < slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          context.pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: slides[_currentPage].color.asColor(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
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

  List<Widget> _buildBackgroundIcons(SlideModel slide) {
    final Set<String> uniqueIcons = {slide.icon, ...slide.icons};
    final iconsList = uniqueIcons.toList();
    final random = math.Random(slide.title.hashCode);

    return [
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Stack(
            children: List.generate(12, (index) {
              final iconName = iconsList[index % iconsList.length];
              final size = 80 + random.nextDouble() * 120;

              // Divide a tela em uma grade imaginária para melhor distribuição
              final gridCols = 3;
              final gridRows = 4;
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
                      color: Colors.white,
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
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(
                          alpha: 0.2 * curvedAnimation.value,
                        ),
                        blurRadius: 20 * curvedAnimation.value,
                        spreadRadius: 5 * curvedAnimation.value,
                      ),
                    ],
                  ),
                  child: Icon(iconData, size: 110, color: Colors.white),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
