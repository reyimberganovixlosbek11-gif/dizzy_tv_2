import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    _nameCtrl.text = data?['name'] ?? '';
    _photoCtrl.text = data?['photoUrl'] ?? '';
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (_nameCtrl.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Ismni kiriting');
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameCtrl.text.trim(),
        'photoUrl': _photoCtrl.text.trim(),
      });
      if (mounted) {
        Fluttertoast.showToast(msg: 'Profil yangilandi');
        Navigator.pop(context);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Xatolik yuz berdi');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilni tahrirlash')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.surface,
                      backgroundImage: _photoCtrl.text.trim().isNotEmpty ? NetworkImage(_photoCtrl.text.trim()) : null,
                      child: _photoCtrl.text.trim().isEmpty
                          ? const Icon(Icons.person, size: 44, color: AppColors.textSecondary)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(hintText: 'Ism'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _photoCtrl,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(hintText: 'Profil rasmi URL (ixtiyoriy)'),
                  ),
                  const SizedBox(height: 24),
                  _saving
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : ElevatedButton(onPressed: _save, child: const Text('Saqlash')),
                ],
              ),
      ),
    );
  }
}
