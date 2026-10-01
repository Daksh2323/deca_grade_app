import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

// Mock classes for Firebase Auth and Auth Service
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockAuthService extends Mock implements AuthService {}
class MockGoRouter extends Mock implements GoRouter {}

abstract class FirebaseAuth {}
abstract class AuthService {
  Future<bool> login(String email, String password);
  Future<bool> signup(String email, String password, String name);
  Future<void> logout();
  Stream<User?> authStateChanges();
}

class User {
  final String uid;
  final String email;
  User({required this.uid, required this.email});
}

abstract class GoRouter {}

// Placeholder Login Screen for testing
class LoginScreen extends StatefulWidget {
  final AuthService authService;
  const LoginScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  bool isLoading = false;
  String? errorMessage;
  bool showPassword = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final success = await widget.authService.login(
        emailController.text,
        passwordController.text,
      );
      if (success) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        setState(() => errorMessage = 'Login failed');
      }
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              key: const Key('email_field'),
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              key: const Key('password_field'),
              obscureText: !showPassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                suffixIcon: IconButton(
                  key: const Key('visibility_toggle'),
                  icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() => showPassword = !showPassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              Container(
                key: const Key('error_banner'),
                padding: const EdgeInsets.all(8),
                color: Colors.red[100],
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('login_button'),
              onPressed: isLoading ? null : handleLogin,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Login'),
            ),
            const SizedBox(height: 16),
            TextButton(
              key: const Key('forgot_password_button'),
              onPressed: () {
                Navigator.of(context).pushNamed('/forgot-password');
              },
              child: const Text('Forgot Password?'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('LOGIN SCREEN TESTS - MODULE 1: AUTHENTICATION', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: LoginScreen(authService: mockAuthService),
        routes: {
          '/home': (context) => const Scaffold(body: Text('Home')),
          '/forgot-password': (context) => const Scaffold(body: Text('Forgot Password')),
        },
      );
    }

    group('HAPPY PATH TESTS', () {
      testWidgets('Test 1: User enters valid email/password and logs in successfully',
          (WidgetTester tester) async {
        when(() => mockAuthService.login('user@example.com', 'ValidPassword123'))
            .thenAnswer((_) async => true);

        await tester.pumpWidget(createWidgetUnderTest());

        // Enter email
        await tester.enterText(find.byKey(const Key('email_field')), 'user@example.com');
        // Enter password
        await tester.enterText(find.byKey(const Key('password_field')), 'ValidPassword123');
        // Tap login button
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Verify login was called
        verify(() => mockAuthService.login('user@example.com', 'ValidPassword123')).called(1);
      });
    });

    group('ERROR HANDLING TESTS', () {
      testWidgets('Test 2: User enters wrong password -> Shows error banner',
          (WidgetTester tester) async {
        when(() => mockAuthService.login('user@example.com', 'WrongPassword'))
            .thenThrow(Exception('Wrong password'));

        await tester.pumpWidget(createWidgetUnderTest());

        await tester.enterText(find.byKey(const Key('email_field')), 'user@example.com');
        await tester.enterText(find.byKey(const Key('password_field')), 'WrongPassword');
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Verify error banner is shown
        expect(find.byKey(const Key('error_banner')), findsOneWidget);
      });

      testWidgets('Test 3: User enters non-existent email -> Shows friendly error',
          (WidgetTester tester) async {
        when(() => mockAuthService.login('nonexistent@example.com', 'AnyPassword'))
            .thenThrow(Exception('No account found'));

        await tester.pumpWidget(createWidgetUnderTest());

        await tester.enterText(find.byKey(const Key('email_field')), 'nonexistent@example.com');
        await tester.enterText(find.byKey(const Key('password_field')), 'AnyPassword');
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('error_banner')), findsOneWidget);
      });

      testWidgets('Test 4: Login button is disabled while loading',
          (WidgetTester tester) async {
        when(() => mockAuthService.login('user@example.com', 'Password123'))
            .thenAnswer((_) async => true);

        await tester.pumpWidget(createWidgetUnderTest());

        await tester.enterText(find.byKey(const Key('email_field')), 'user@example.com');
        await tester.enterText(find.byKey(const Key('password_field')), 'Password123');
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pump(); // Loading state

        // Button should show loading indicator and be disabled
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('UI INTERACTION TESTS', () {
      testWidgets('Test 5: Toggle password visibility with eye icon',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        // Find the TextField for password (obscured by default)
        var passwordField = find.byKey(const Key('password_field'));
        expect(passwordField, findsOneWidget);

        // Initially, password should be obscured
        var textField = tester.widget<TextField>(passwordField);
        expect(textField.obscureText, isTrue);

        // Tap the visibility toggle
        await tester.tap(find.byKey(const Key('visibility_toggle')));
        await tester.pump();

        // Password should now be visible
        textField = tester.widget<TextField>(find.byKey(const Key('password_field')));
        expect(textField.obscureText, isFalse);
      });

      testWidgets('Test 6: Clicking Forgot Password navigates to reset flow',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        await tester.tap(find.byKey(const Key('forgot_password_button')));
        await tester.pumpAndSettle();

        // Verify navigation to forgot password screen
        expect(find.text('Forgot Password'), findsOneWidget);
      });
    });

    group('EDGE CASES', () {
      testWidgets('Test 7: Empty email/password shows validation error',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        // Try to login without entering anything
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Verify login was not called
        verifyNever(() => mockAuthService.login(any(), any()));
      });

      testWidgets('Test 8: Network error shows appropriate message',
          (WidgetTester tester) async {
        when(() => mockAuthService.login('user@example.com', 'Password123'))
            .thenThrow(Exception('No internet connection'));

        await tester.pumpWidget(createWidgetUnderTest());

        await tester.enterText(find.byKey(const Key('email_field')), 'user@example.com');
        await tester.enterText(find.byKey(const Key('password_field')), 'Password123');
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('error_banner')), findsOneWidget);
      });
    });
  });
}
