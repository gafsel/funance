import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/features/coaching/presentation/providers/coaching_providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class CoachingSlidesScreen extends ConsumerStatefulWidget {
  const CoachingSlidesScreen({super.key});

  @override
  ConsumerState<CoachingSlidesScreen> createState() => _CoachingSlidesScreenState();
}

class _CoachingSlidesScreenState extends ConsumerState<CoachingSlidesScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _iconAnimationController;

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
    final state = ref.watch(CoachingViewProviders.coachingNotifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: state.error != null
          ? _buildError(state.error!, l10n)
          : state.latestCoaching != null
              ? _buildSlides(state.latestCoaching!, l10n)
              : Center(child: Text(l10n.coachingNoData)),
    );
  }

  Widget _buildError(String error, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              l10n.coachingError,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => ref.read(CoachingViewProviders.coachingNotifier.notifier).generateCoaching(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n.retry),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(l10n.onboardingBack),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlides(CoachingModel coaching, AppLocalizations l10n) {
    final slides = coaching.slides;
    if (slides.isEmpty) {
      return _buildError(l10n.coachingNoSlides, l10n);
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
                            MarkdownBody(
                              data: slide.message,
                              selectable: true,
                              onTapLink: (text, href, title) {
                                if (href != null) {
                                  launchUrl(Uri.parse(href));
                                }
                              },
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                                a: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                ),
                                textAlign: WrapAlignment.center,
                              ),
                            ),
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
                          color: index <= _currentPage ? Colors.white : Colors.white38,
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
                        child: Text(l10n.coachingSlideBack,
                            style: const TextStyle(color: Colors.white)),
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
                            horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      child: Text(_currentPage < slides.length - 1
                          ? l10n.coachingSlideNext
                          : l10n.coachingSlideFinish),
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

    return List.generate(10, (index) {
      final iconName = iconsList[index % iconsList.length];
      return Positioned(
        top: random.nextDouble() * 800,
        left: random.nextDouble() * 400,
        child: Opacity(
          opacity: 0.05,
          child: Icon(
            iconName.asIcon(orElse: Icons.tips_and_updates),
            size: 100 + random.nextDouble() * 100,
            color: Colors.white,
          ),
        ),
      );
    });
  }

  Widget _buildAnimatedIcon(SlideModel slide) {
    final iconData = slide.icon.asIcon(orElse: Icons.tips_and_updates);

    return AnimatedBuilder(
      animation: _iconAnimationController,
      builder: (context, child) {
        double dx = 0.0;
        double dy = 0.0;
        double scale = 1.0;
        double opacity = 1.0;

        switch (slide.animationType) {
          case 'bounce':
            dy = -20 * _iconAnimationController.value;
            break;
          case 'pulse':
            scale = 1.0 + 0.1 * _iconAnimationController.value;
            break;
          case 'fade':
            opacity = 0.6 + 0.4 * _iconAnimationController.value;
            break;
          case 'zoom':
            scale = 0.8 + 0.4 * _iconAnimationController.value;
            break;
          case 'slide':
            dx = 10 * math.sin(_iconAnimationController.value * 2 * math.pi);
            break;
          default:
            scale = 1.0 + 0.05 * _iconAnimationController.value;
        }

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Icon(
                iconData,
                size: 100,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
