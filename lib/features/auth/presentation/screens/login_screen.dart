import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/exceptions/business_exception.dart';
import '../../../../core/utils/error_messages.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(authNotifierProvider.notifier);
    bool success;

    if (_isSignUp) {
      success = await notifier.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _displayNameController.text.trim(),
      );
    } else {
      success = await notifier.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }

    if (!success && mounted) {
      final error = ref.read(authNotifierProvider).error;
      String message = AppLocalizations.of(context)!.errorUnknown;
      if (error is BusinessException) {
        message = error.code.message(context);
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AsyncLoading;

    // Tema customizado para áreas escuras
    final darkContentTheme = Theme.of(context).copyWith(
      textTheme: AppTheme.darkTextTheme,
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
            labelStyle: const TextStyle(color: AppColors.paleGold),
            hintStyle: TextStyle(color: AppColors.pureWhite.withValues(alpha: 0.5)),
            prefixIconColor: AppColors.paleGold,
          ),
    );

    return Scaffold(
      body: Row(
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
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.paleGold,
                                    letterSpacing: 4,
                                  ),
                            ),
                            // Efeito de borda branca simulado (poderia ser feito com CustomPainter para ficar idêntico ao banner)
                            Text(
                              l10n.loginTitle,
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
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
                    data: !isDesktop && !isTablet ? darkContentTheme : Theme.of(context),
                    child: Container(
                      decoration: !isDesktop && !isTablet
                          ? BoxDecoration(gradient: AppGradients.backgroundGradient)
                          : null,
                      padding: !isDesktop && !isTablet ? const EdgeInsets.all(24) : null,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!isDesktop && !isTablet) ...[
                              Image.asset(
                                'assets/logo/logo-horizontal.png',
                                height: 48,
                              ),
                              const SizedBox(height: 32),
                            ],
                            Text(
                              _isSignUp ? l10n.registerButton : l10n.loginButton,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isSignUp ? l10n.loginSubtitle : l10n.loginSubtitle,
                            ),
                            const SizedBox(height: 32),
                            if (_isSignUp) ...[
                              TextFormField(
                                controller: _displayNameController,
                                decoration: InputDecoration(
                                  labelText: l10n.displayNameLabel,
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                                validator: (value) =>
                                    value?.isEmpty ?? true ? l10n.fieldRequired : null,
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: l10n.emailLabel,
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? l10n.fieldRequired : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: l10n.passwordLabel,
                                prefixIcon: const Icon(Icons.lock_outline),
                              ),
                              obscureText: true,
                              validator: (value) =>
                                  (value?.length ?? 0) < 6 ? l10n.shortPassword : null,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.deepTurquoise,
                                      ),
                                    )
                                  : Text((_isSignUp ? l10n.registerButton : l10n.loginButton).toUpperCase()),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: Divider(color: !isDesktop && !isTablet ? AppColors.pureWhite.withValues(alpha: 0.2) : null)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    l10n.orDivider,
                                    style: TextStyle(
                                      color: !isDesktop && !isTablet ? AppColors.pureWhite.withValues(alpha: 0.6) : Colors.grey,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: !isDesktop && !isTablet ? AppColors.pureWhite.withValues(alpha: 0.2) : null)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                                      final success = await ref
                                          .read(authNotifierProvider.notifier)
                                          .signInWithGoogle();
                                      if (!success && mounted) {
                                        final error = ref.read(authNotifierProvider).error;
                                        String message = l10n.errorUnknown;
                                        if (error is BusinessException) {
                                          message = error.code.message(context);
                                        }
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(
                                            content: Text(message),
                                            duration: const Duration(seconds: 5),
                                          ),
                                        );
                                      }
                                    },
                              icon: Image.asset('assets/logo/logo.png', height: 20),
                              label: Text(l10n.googleLoginButton),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: !isDesktop && !isTablet ? AppColors.pureWhite : AppColors.deepTurquoise,
                                side: BorderSide(color: !isDesktop && !isTablet ? AppColors.pureWhite : AppColors.vibrantTeal),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => setState(() => _isSignUp = !_isSignUp),
                              child: Text(
                                _isSignUp ? l10n.loginLink : l10n.registerLink,
                                style: TextStyle(
                                  color: !isDesktop && !isTablet ? AppColors.successGold : AppColors.deepTurquoise,
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
                                color: !isDesktop && !isTablet ? AppColors.pureWhite.withValues(alpha: 0.5) : Colors.grey,
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
    );
  }
}
