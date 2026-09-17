import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/form/manual_form.dart';
import 'package:funances/core/form/password_form_field.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/error_messages.dart';
import 'package:funances/features/auth/presentation/controller/login_form_notifier.dart';
import 'package:funances/features/auth/presentation/model/auth_view_model.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/user/domain/models/user_model.dart';

/// A porta de entrada.
///
/// Em compacto é uma coluna só, sobre o gradiente do cofre. A partir de 600px
/// abre em duas: o herói à esquerda e o formulário à direita.
///
/// O que mudou nesta passada, e por quê:
///
/// * O layout era decidido por `MediaQuery` global, com três faixas (600 e
///   900) que não existiam em nenhum outro lugar do app. Agora é
///   `LayoutBuilder` + o breakpoint compartilhado — e, como a tela não divide
///   espaço com rail nenhum, os dois dariam o mesmo resultado; o que importa
///   é ter UM corte.
/// * Em 800px o slogan era ilegível: ~11px cinza sobre o gradiente escuro,
///   porque o `darkTextTheme` daquele tempo não definia tamanho de fonte
///   nenhum e o estilo caía no padrão do Material. A escala agora existe.
/// * O formulário não era centralizado na coluna dele: ficava colado à
///   esquerda com ~250px de vazio à direita. Era o `Center` externo somado ao
///   `padding` de 32 e ao `ConstrainedBox` — agora a coluna centraliza de
///   verdade.
/// * As cores por lado eram escolhidas com um ternário `isMobile` em cada
///   widget (divisor, texto do divisor, botão do Google, link, termos). O
///   lado escuro agora é um TEMA (`AppTheme.onGame`), e nenhum widget
///   precisa saber sobre o que está pousado.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // O login por redirect recarrega a página inteira: quem pediu o login já
    // não existe para receber o erro. Se o Google devolveu uma recusa, ela
    // chega por aqui — sem isso, esta tela reaparecia muda e o usuário não
    // tinha como saber por que não entrou.
    ref.listen(AuthDomainProviders.redirectError, (_, next) {
      final ErrorCode? code = next.valueOrNull;
      if (code == null || code.isInformational) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(code.message(context))));
    });

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final split = !constraints.layout.isCompact;

          if (!split) {
            return DecoratedBox(
              decoration: const BoxDecoration(
                gradient: AppGradients.background,
              ),
              child: Theme(
                data: AppTheme.onGame(context),
                child: const _LoginForm(showLogo: true),
              ),
            );
          }

          return Row(
            children: [
              const Expanded(child: _LoginHero()),
              const Expanded(child: _LoginForm(showLogo: false)),
            ],
          );
        },
      ),
    );
  }
}

/// O lado escuro: marca e promessa.
class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: Theme(
        data: AppTheme.onGame(context),
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final palette = context.palette;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: AppSpacing.allXl,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/logo/logo-horizontal.png',
                        height: 64,
                        fit: BoxFit.contain,
                      ),
                      AppSpacing.gapLg,
                      Text(
                        l10n.loginTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: palette.onGame,
                        ),
                      ),
                      AppSpacing.gapSm,
                      Text(
                        l10n.loginSubtitle,
                        textAlign: TextAlign.center,
                        // `bodyLarge` e não `displaySmall`: é uma frase para
                        // ler, não um segundo título competindo com a marca.
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: palette.onGame2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({required this.showLogo});

  /// Em coluna única a marca não tem um herói próprio e entra acima do
  /// formulário.
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.allXl,
        child: Align(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ManualForm<LoginFormState, UserModel, LoginFormNotifier>(
              AuthViewProviders.form,
              formBuilder: (context, snapshot) {
                final state = snapshot.model;
                final notifier = snapshot.notifier;
                final isSignUp = state.isSignUp;
                final v = context.validations;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showLogo) ...[
                      Image.asset(
                        'assets/logo/logo-horizontal.png',
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                      AppSpacing.gapXl,
                    ],
                    Text(
                      isSignUp ? l10n.registerButton : l10n.loginButton,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: palette.ink,
                      ),
                    ),
                    // A promessa só entra aqui quando esta coluna é a única:
                    // em duas colunas o herói ao lado já a diz, e a frase
                    // aparecia DUAS VEZES na mesma tela — uma sob a marca,
                    // outra sob o "Entrar". `showLogo` é o mesmo sinal para
                    // as duas coisas porque é a mesma pergunta: esta coluna
                    // carrega a marca?
                    if (showLogo) ...[
                      AppSpacing.gapXs,
                      Text(
                        l10n.loginSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.ink2,
                        ),
                      ),
                    ],
                    AppSpacing.gapXl,
                    if (isSignUp) ...[
                      TextFormField(
                        initialValue: state.displayName,
                        decoration: InputDecoration(
                          labelText: l10n.displayNameLabel,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        onChanged: notifier.updateDisplayName,
                        validator: v.all([
                          v.notEmpty(),
                          v.length(max: 150, min: 3),
                        ]),
                      ),
                      AppSpacing.gapMd,
                    ],
                    TextFormField(
                      initialValue: state.email,
                      decoration: InputDecoration(
                        labelText: l10n.emailLabel,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      onChanged: notifier.updateEmail,
                      keyboardType: TextInputType.emailAddress,
                      validator: v.all([
                        v.notEmpty(),
                        v.email(),
                        v.length(max: 150),
                      ]),
                    ),
                    AppSpacing.gapMd,
                    PasswordFormField(
                      initialValue: state.password,
                      decoration: InputDecoration(
                        labelText: l10n.passwordLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      onChanged: (password) =>
                          notifier.updatePassword(password ?? ''),
                      validator: v.all([
                        v.notEmpty(),
                        if (isSignUp) v.securePassword(),
                      ]),
                    ),
                    AppSpacing.gapLg,
                    LoadingButton.elevated(
                      onPressed: (loading) async {
                        if (snapshot.validate()) {
                          await loading(notifier.submit());
                        }
                      },
                      child: Text(
                        (isSignUp ? l10n.registerButton : l10n.loginButton)
                            .toUpperCase(),
                      ),
                    ),
                    AppSpacing.gapMd,
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: AppSpacing.hMd,
                          child: Text(
                            l10n.orDivider,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: palette.ink3,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    AppSpacing.gapMd,
                    LoadingButton.outlineIcon(
                      onPressed: (loading) =>
                          loading(notifier.signInWithGoogle()),
                      icon: Image.asset('assets/logo/google.png', height: 20),
                      label: Text(l10n.googleLoginButton),
                    ),
                    AppSpacing.gapMd,
                    TextButton(
                      onPressed: notifier.toggleSignUp,
                      child: Text(
                        state.isSignUp ? l10n.loginLink : l10n.registerLink,
                      ),
                    ),
                    AppSpacing.gapXl,
                    Text(
                      l10n.loginTermsNotice,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.ink3,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
