import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';

/// Admin panelga kirish ekrani.
/// Oddiy foydalanuvchilar login ekranidan bu yerga o'tmaydi —
/// bu ekranga faqat to'g'ridan-to'g'ri manzil orqali (masalan sozlamalar
/// ichidagi yashirin tugma yoki "/admin" route) kirish mumkin.
/// Xavfsizlik: parol Firebase Auth'da saqlanadi (hech qachon kodda emas),
/// kirishdan keyin Firestore'dagi role="admin" tekshiriladi.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _authService = AuthService();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      Fluttertoast.showToast(msg: 'Login va parolni kiriting');
      return;
    }
    setState(() => _loading = true);
    try {
      await _authService.adminLogin(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Kirish rad etildi: admin huquqi yo\'q yoki ma\'lumot xato');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 56),
                const SizedBox(height: 8),
                const Text(
                  'Dizzy.tv Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Admin login (email)'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Parol',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _loading
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : ElevatedButton(
                        onPressed: _login,
                        child: const Text('Admin sifatida kirish'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
