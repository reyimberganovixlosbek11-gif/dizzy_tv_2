import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_nav_screen.dart';
import 'screens/admin/admin_login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DizzyTvApp());
}

class DizzyTvApp extends StatelessWidget {
  const DizzyTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dizzy.tv',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Oddiy foydalanuvchi va admin bir xil ilova ichida,
      // lekin admin panelga faqat shu maxsus route orqali kiriladi:
      routes: {
        '/admin': (context) => const AdminLoginScreen(),
      },
      home: const AuthGate(),
    );
  }
}

/// Foydalanuvchi login qilganmi yo'qmi tekshirib, mos ekranga yo'naltiradi
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData) {
          return const MainNavScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
