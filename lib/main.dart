import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:funances/features/onboarding/presentation/provider.dart';
import 'package:funances/features/workspace/presentation/controller/invite_providers.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:funances/features/workspace/presentation/screens/invite_list_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'core/exceptions/business_exception.dart';
import 'core/utils/error_messages.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', ''), Locale('en', '')],
      theme: AppTheme.theme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final workspaceState = ref.watch(WorkspaceViewProviders.workspace);
    final inviteState = ref.watch(inviteNotifierProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // 1. Aguarda carregamento inicial de tudo
          if (workspaceState.isLoading ||
              !workspaceState.initialLoadDone ||
              inviteState.isLoading ||
              !inviteState.initialLoadDone) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 2. Se houver convites pendentes, mostra a tela de convites
          if (inviteState.pendingInvites.isNotEmpty) {
            return const InviteListScreen();
          }

          // 3. Se não tem workspaces ou está no onboarding e ainda não finalizou
          if (workspaceState.availableWorkspaces.isEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            );
          }

          // 4. Se tem workspaces, vai para o dashboard
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) {
        String message = e.toString();
        if (e is BusinessException) {
          message = e.code.message(context);
        }
        return Scaffold(body: Center(child: Text(message)));
      },
    );
  }
}
