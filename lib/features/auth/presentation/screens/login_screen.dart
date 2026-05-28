import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/exceptions/business_exception.dart';
import '../../../../core/utils/error_messages.dart';
import '../providers/auth_providers.dart';

import 'package:funances/features/auth/presentation/providers/login_form_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  static final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginFormProvider);
    final notifier = ref.read(loginFormProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;
    
    ref.listen(loginFormProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        final authState = ref.read(authNotifierProvider);
        String message = l10n.errorUnknown;
        
        authState.whenOrNull(
          error: (error, stack) {
            if (error is BusinessException) {
              message = error.code.message(context);
            } else {
              message = error.toString();
            }
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });

    final isLoading = state.isLoading;
    final isSignUp = state.isSignUp;

    // Tema customizado para áreas escuras
    final darkContentTheme = Theme.of(context).copyWith(
      textTheme: AppTheme.darkTextTheme,
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
          labelStyle: const TextStyle(color: AppColors.paleGold),
          hintStyle: TextStyle(color: AppColors.pureWhite.withValues(alpha: 0.5)),
          prefixIconColor: AppColors.paleGold,
        ),
    );

    final isMobile = !isDesktop && !isTablet;
    
    return Scaffold(
      body: Container(
        decoration: isMobile ? BoxDecoration(gradient: AppGradients.backgroundGradient) : null,
        child: Row(
          children: [
            if (isDesktop || isTablet)
              Expanded(
                flex: 1,
                child: Theme(
                  data: darkContentTheme,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppGradients.backgroundGradient,
                    ),
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
                                style: darkContentTheme.textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4,
                                    ),
                              ),
                              // Efeito de borda branca simulado (poderia ser feito com CustomPainter para ficar idêntico ao banner)
                              Text(
                                l10n.loginTitle,
                                style: darkContentTheme.textTheme.displayMedium?.copyWith(
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
                            style: darkContentTheme.textTheme.displaySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              flex: 1,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Theme(
                      data: isMobile ? darkContentTheme : darkContentTheme,
                      child: Container(
                        padding: isMobile ? const EdgeInsets.all(24) : null,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (isMobile) ...[
                                Image.asset(
                                  'assets/logo/logo-horizontal.png',
                                  height: 48,
                                ),
                                const SizedBox(height: 32),
                              ],
                              Text(
                                isSignUp ? l10n.registerButton : l10n.loginButton,
                                style: darkContentTheme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isSignUp ? l10n.loginSubtitle : l10n.loginSubtitle,
                                style: darkContentTheme.textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 32),
                              if (isSignUp) ...[
                                TextFormField(
                                  initialValue: state.displayName,
                                  decoration: InputDecoration(
                                    labelText: l10n.displayNameLabel,
                                    prefixIcon: const Icon(Icons.person_outline),
                                  ),
                                  onChanged: notifier.updateDisplayName,
                                  validator: (value) =>
                                      value?.isEmpty ?? true ? l10n.fieldRequired : null,
                                ),
                                const SizedBox(height: 16),
                              ],
                              TextFormField(
                                initialValue: state.email,
                                decoration: InputDecoration(
                                  labelText: l10n.emailLabel,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                                onChanged: notifier.updateEmail,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) =>
                                    value?.isEmpty ?? true ? l10n.fieldRequired : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                initialValue: state.password,
                                decoration: InputDecoration(
                                  labelText: l10n.passwordLabel,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                ),
                                onChanged: notifier.updatePassword,
                                obscureText: true,
                                validator: (value) =>
                                    (value?.length ?? 0) < 6 ? l10n.shortPassword : null,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: isLoading ? null : () {
                                  if (_formKey.currentState!.validate()) {
                                    notifier.submit();
                                  }
                                },
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.deepTurquoise,
                                        ),
                                      )
                                    : Text((isSignUp ? l10n.registerButton : l10n.loginButton).toUpperCase()),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: isMobile ? AppColors.pureWhite.withValues(alpha: 0.2) : null)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      l10n.orDivider,
                                      style: TextStyle(
                                        color: isMobile ? AppColors.pureWhite.withValues(alpha: 0.6) : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: isMobile ? AppColors.pureWhite.withValues(alpha: 0.2) : null)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : () => notifier.signInWithGoogle(),
                                icon: Image.asset('assets/logo/logo.png', height: 20),
                                label: Text(l10n.googleLoginButton),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isMobile ? AppColors.pureWhite : AppColors.deepTurquoise,
                                  side: BorderSide(color: isMobile ? AppColors.pureWhite : AppColors.vibrantTeal),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: notifier.toggleSignUp,
                                child: Text(
                                  state.isSignUp ? l10n.loginLink : l10n.registerLink,
                                  style: TextStyle(
                                    color: isMobile ? AppColors.successGold : AppColors.deepTurquoise,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'Ao entrar, você concorda com nossos Termos de Serviço e Política de Privacidade.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isMobile ? AppColors.pureWhite.withValues(alpha: 0.5) : Colors.grey,
                                ),
                              ),
                            ],
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
