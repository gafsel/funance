import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/utils/error_messages.dart';
import 'package:funances/core/form/manual_form.dart';
import 'package:funances/core/form/password_form_field.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/auth/presentation/controller/login_form_notifier.dart';
import 'package:funances/features/auth/presentation/model/auth_view_model.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

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

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;

    var rightSideTheme = Theme.of(context);
    final leftSideTheme = Theme.of(context).copyWith(
      textTheme: AppTheme.darkTextTheme,
      inputDecorationTheme: rightSideTheme.inputDecorationTheme.copyWith(
        labelStyle: const TextStyle(color: AppColors.paleGold),
        hintStyle: TextStyle(color: AppColors.pureWhite.withValues(alpha: 0.5)),
        prefixIconColor: AppColors.paleGold,
      ),
    );

    final isMobile = !isDesktop && !isTablet;

    if (isMobile) {
      rightSideTheme = leftSideTheme;
    }

    return Scaffold(
      body: Container(
        decoration: isMobile
            ? BoxDecoration(gradient: AppGradients.backgroundGradient)
            : null,
        child: Row(
          children: [
            if (isDesktop || isTablet)
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppGradients.backgroundGradient,
                  ),
                  child: Theme(
                    data: leftSideTheme,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/logo/logo-horizontal.png',
                            height: 60,
                          ),
                          const SizedBox(height: 24),
                          Stack(
                            children: [
                              Text(
                                l10n.loginTitle,
                                style: leftSideTheme.textTheme.displayMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4,
                                    ),
                              ),
                              // Efeito de borda branca simulado (poderia ser feito com CustomPainter para ficar idêntico ao banner)
                              Text(
                                l10n.loginTitle,
                                style: leftSideTheme.textTheme.displayMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4,
                                      foreground: Paint()
                                        ..style = PaintingStyle.stroke
                                        ..strokeWidth = 1
                                        ..color = AppColors.pureWhite,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.loginSubtitle,
                            textAlign: TextAlign.center,
                            style: leftSideTheme.textTheme.displaySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              flex: 1,
              child: Theme(
                data: rightSideTheme,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Theme(
                        data: isMobile ? rightSideTheme : rightSideTheme,
                        child: Container(
                          padding: isMobile ? const EdgeInsets.all(24) : null,
                          child:
                              ManualForm<
                                LoginFormState,
                                UserModel,
                                LoginFormNotifier
                              >(
                                AuthViewProviders.form,
                                formBuilder: (context, snapshot) {
                                  final state = snapshot.model;
                                  final notifier = snapshot.notifier;
                                  final isSignUp = state.isSignUp;
                                  final v = context.validations;

                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (isMobile) ...[
                                        Image.asset(
                                          'assets/logo/logo-horizontal.png',
                                          height: 48,
                                        ),
                                        const SizedBox(height: 32),
                                      ],
                                      Text(
                                        isSignUp
                                            ? l10n.registerButton
                                            : l10n.loginButton,
                                        style: rightSideTheme
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isSignUp
                                            ? l10n.loginSubtitle
                                            : l10n.loginSubtitle,
                                        style: rightSideTheme
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      const SizedBox(height: 32),
                                      if (isSignUp) ...[
                                        TextFormField(
                                          initialValue: state.displayName,
                                          decoration: InputDecoration(
                                            labelText: l10n.displayNameLabel,
                                            prefixIcon: const Icon(
                                              Icons.person_outline,
                                            ),
                                          ),
                                          onChanged: notifier.updateDisplayName,
                                          validator: v.all([
                                            v.notEmpty(),
                                            v.length(max: 150, min: 3),
                                          ]),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                      TextFormField(
                                        initialValue: state.email,
                                        decoration: InputDecoration(
                                          labelText: l10n.emailLabel,
                                          prefixIcon: const Icon(
                                            Icons.email_outlined,
                                          ),
                                        ),
                                        onChanged: notifier.updateEmail,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: v.all([
                                          v.notEmpty(),
                                          v.email(),
                                          v.length(max: 150),
                                        ]),
                                      ),
                                      const SizedBox(height: 16),
                                      PasswordFormField(
                                        initialValue: state.password,
                                        decoration: InputDecoration(
                                          labelText: l10n.passwordLabel,
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                          ),
                                        ),
                                        onChanged: (password) => notifier
                                            .updatePassword(password ?? ""),
                                        validator: v.all([
                                          v.notEmpty(),
                                          if (isSignUp) v.securePassword(),
                                        ]),
                                      ),
                                      const SizedBox(height: 24),
                                      LoadingButton.elevated(
                                        onPressed: (loading) async {
                                          if (snapshot.validate()) {
                                            await loading(notifier.submit());
                                          }
                                        },
                                        child: Text(
                                          (isSignUp
                                                  ? l10n.registerButton
                                                  : l10n.loginButton)
                                              .toUpperCase(),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Divider(
                                              color: isMobile
                                                  ? AppColors.pureWhite
                                                        .withValues(alpha: 0.2)
                                                  : null,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Text(
                                              l10n.orDivider,
                                              style: TextStyle(
                                                color: isMobile
                                                    ? AppColors.pureWhite
                                                          .withValues(alpha: 0.6)
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: isMobile
                                                  ? AppColors.pureWhite
                                                        .withValues(alpha: 0.2)
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      LoadingButton.outlineIcon(
                                        onPressed: (loading) => loading(notifier.signInWithGoogle()),
                                        icon: Image.asset(
                                          'assets/logo/google.png',
                                          height: 20,
                                        ),
                                        label: Text(l10n.googleLoginButton),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: isMobile
                                              ? AppColors.pureWhite
                                              : AppColors.deepTurquoise,
                                          side: BorderSide(
                                            color: isMobile
                                                ? AppColors.pureWhite
                                                : AppColors.vibrantTeal,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextButton(
                                        onPressed: notifier.toggleSignUp,
                                        child: Text(
                                          state.isSignUp
                                              ? l10n.loginLink
                                              : l10n.registerLink,
                                          style: TextStyle(
                                            color: isMobile
                                                ? AppColors.successGold
                                                : AppColors.deepTurquoise,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      Text(
                                        l10n.loginTermsNotice,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isMobile
                                              ? AppColors.pureWhite.withValues(
                                                  alpha: 0.5,
                                                )
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
