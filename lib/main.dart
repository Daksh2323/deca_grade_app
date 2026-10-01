import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'services/analytics_service.dart';
import 'services/crash_reporting_service.dart';
import 'services/update_checker.dart';
import 'screens/splash_screen.dart';
import 'screens/dev/seed_screen.dart';
import 'screens/dev/mascot_test_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/mobile_login_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/profile_completion_screen.dart';
import 'screens/main/main_wrapper.dart';

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Lock orientation to portrait
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      // ⭐ STRONGER IMMERSIVE - Only show status bar at top
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [SystemUiOverlay.top],
      );

      // Set status bar style
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      );

      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        FlutterError.onError = (FlutterErrorDetails details) {
          FlutterError.presentError(details);
          unawaited(
            CrashReportingService.instance.recordFatal(
              details.exception,
              details.stack ?? StackTrace.current,
            ),
          );
        };
        unawaited(AnalyticsService.instance.logAppOpen());
      } catch (error) {
        debugPrint('Firebase init error in release mode: $error');
      }

      runApp(const DecaGradeApp());
    },
    (Object error, StackTrace stack) {
      debugPrint('UNHANDLED ASYNC ERROR: $error');
      debugPrint(stack.toString());
      unawaited(CrashReportingService.instance.recordFatal(error, stack));
    },
  );
}

class DecaGradeApp extends StatefulWidget {
  const DecaGradeApp({super.key});

  @override
  State<DecaGradeApp> createState() => _DecaGradeAppState();
}

class _DecaGradeAppState extends State<DecaGradeApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _updateChecker = UpdateChecker();
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setImmersiveMode();
    _authSubscription = AuthService().authStateChanges.listen(_handleAuthState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForUpdate());
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _handleAuthState(User? user) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final navigator = _navigatorKey.currentState;
      if (navigator == null) return;

      final routeName = ModalRoute.of(navigator.context)?.settings.name;
      if (routeName == '/mobile-login' ||
          routeName == '/otp-verification' ||
          routeName == '/profile-completion' ||
          routeName == '/home') {
        return;
      }

      if (user == null) {
        navigator.pushNamedAndRemoveUntil('/login', (_) => false);
        return;
      }

      navigator.pushNamedAndRemoveUntil('/home', (_) => false);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-apply immersive mode when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _setImmersiveMode();
      unawaited(_checkForUpdate());
    }
  }

  Future<void> _checkForUpdate() async {
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    await _updateChecker.checkForUpdate(context);
  }

  Future<void> _setImmersiveMode() async {
    // Hide navigation bar, keep status bar
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top],
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DecaGrade',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/mobile-login': (context) => const MobileLoginScreen(),
        '/otp-verification': (context) => const OtpVerificationScreen(),
        '/profile-completion': (context) => const ProfileCompletionScreen(),
        '/home': (context) => const MainWrapper(),
        '/dev-seed': (context) => const SeedScreen(),
        '/mascot-preview': (context) => const MascotTestScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return const MainWrapper();
      },
    );
  }
}
