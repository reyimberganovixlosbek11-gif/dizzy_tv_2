import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/firestore_service.dart';
import '../../models/movie_model.dart';
import '../../theme/app_theme.dart';

/// Kino qo'shish yoki tahrirlash formasi.
/// Poster/Video fayllarning o'zi bu yerda yuklanmaydi — Firebase Storage'ga
/// (poster) va Cloudflare R2'ga (video) qo'lda yuklab, ularning ochiq
/// URL manzili shu formaga kiritiladi. Poster URL kiritilgach, pastda
/// jonli preview ko'rsatiladi.
class AdminMovieFormScreen extends StatefulWidget {
  final MovieModel? movie; // null bo'lsa - yangi kino qo'shish
  const AdminMovieFormScreen({super.key, this.movie});

  @override
  State<AdminMovieFormScreen> createState() => _AdminMovieFormScreenState();
}

class _AdminMovieFormScreenState extends State<AdminMovieFormScreen> {
  final _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _posterCtrl;
  late TextEditingController _bannerCtrl;
  late TextEditingController _videoCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _ratingCtrl;
  late TextEditingController _durationCtrl;

  String _quality = 'HD';
  bool _isActive = true;
  bool _isBanner = false;
  bool _isTrending = false;
  bool _isNew = false;
  bool _isPopular = false;
  bool _isRecommended = false;
  Set<String> _selectedGenres = {};
  bool _saving = false;

  bool get _isEditing => widget.movie != null;

  @override
  void initState() {
    super.initState();
    final m = widget.movie;
    _titleCtrl = TextEditingController(text: m?.title ?? '');
    _descCtrl = TextEditingController(text: m?.description ?? '');
    _posterCtrl = TextEditingController(text: m?.posterUrl ?? '');
    _bannerCtrl = TextEditingController(text: m?.bannerUrl ?? '');
    _videoCtrl = TextEditingController(text: m?.videoUrl ?? '');
    _yearCtrl = TextEditingController(text: m?.year.toString() ?? DateTime.now().year.toString());
    _countryCtrl = TextEditingController(text: m?.country ?? '');
    _ratingCtrl = TextEditingController(text: m?.rating.toString() ?? '0');
    _durationCtrl = TextEditingController(text: m?.durationMinutes.toString() ?? '0');
    _quality = m?.quality ?? 'HD';
    _isActive = m?.isActive ?? true;
    _isBanner = m?.isBanner ?? false;
    _isTrending = m?.isTrending ?? false;
    _isNew = m?.isNew ?? false;
    _isPopular = m?.isPopular ?? false;
    _isRecommended = m?.isRecommended ?? false;
    _selectedGenres = Set.from(m?.genres ?? []);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_posterCtrl.text.trim().isEmpty || _videoCtrl.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Poster va Video URL kiritilishi shart');
      return;
    }
    setState(() => _saving = true);
    try {
      final data = MovieModel(
        id: widget.movie?.id ?? '',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        posterUrl: _posterCtrl.text.trim(),
        bannerUrl: _bannerCtrl.text.trim(),
        videoUrl: _videoCtrl.text.trim(),
        year: int.tryParse(_yearCtrl.text) ?? DateTime.now().year,
        genres: _selectedGenres.toList(),
        country: _countryCtrl.text.trim(),
        rating: double.tryParse(_ratingCtrl.text) ?? 0,
        durationMinutes: int.tryParse(_durationCtrl.text) ?? 0,
        quality: _quality,
        viewsCount: widget.movie?.viewsCount ?? 0,
        isActive: _isActive,
        isBanner: _isBanner,
        isTrending: _isTrending,
        isNew: _isNew,
        isPopular: _isPopular,
        isRecommended: _isRecommended,
        createdAt: widget.movie?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await _firestoreService.updateMovie(widget.movie!.id, data.toMap());
      } else {
        await _firestoreService.addMovie(data);
      }
      if (mounted) {
        Fluttertoast.showToast(msg: _isEditing ? 'Kino yangilandi' : 'Kino qo\'shildi');
        Navigator.pop(context);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Xatolik yuz berdi, qayta urinib ko\'ring');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Kinoni tahrirlash' : 'Kino qo\'shish')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Poster preview
              if (_posterCtrl.text.trim().isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: _posterCtrl.text.trim(),
                      height: 200,
                      width: 140,
                      fit: BoxFit.cover,
                      errorWidget: (c, u, e) => Container(
                        height: 200,
                        width: 140,
                        color: AppColors.surface,
                        child: const Icon(Icons.broken_image, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _field('Kino nomi', _titleCtrl, required: true),
              _field('Tavsif', _descCtrl, maxLines: 4, required: true),
              _field('Poster URL (Firebase Storage)', _posterCtrl, required: true, onChanged: () => setState(() {})),
              _field('Banner URL (bosh sahifa uchun, ixtiyoriy)', _bannerCtrl),
              _field('Video URL (Cloudflare R2)', _videoCtrl, required: true),
              Row(
                children: [
                  Expanded(child: _field('Yili', _yearCtrl, keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('Davomiyligi (daq)', _durationCtrl, keyboardType: TextInputType.number)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _field('Davlat', _countryCtrl)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('Reyting (0-10)', _ratingCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                ],
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _quality,
                dropdownColor: AppColors.surfaceLight,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Sifat', labelStyle: TextStyle(color: AppColors.textSecondary)),
                items: ['SD', 'HD', 'FHD', '4K']
                    .map((q) => DropdownMenuItem(value: q, child: Text(q, style: const TextStyle(color: AppColors.textPrimary))))
                    .toList(),
                onChanged: (v) => setState(() => _quality = v!),
              ),
              const SizedBox(height: 20),
              const Text('Janrlar', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<List<GenreModel>>(
                stream: _firestoreService.genres(),
                builder: (context, snap) {
                  final genres = snap.data ?? [];
                  if (genres.isEmpty) {
                    return const Text('Avval Kategoriyalar bo\'limida janr qo\'shing', style: TextStyle(color: AppColors.textSecondary));
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: genres.map((g) {
                      final selected = _selectedGenres.contains(g.name);
                      return FilterChip(
                        label: Text(g.name),
                        selected: selected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textSecondary),
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selectedGenres.add(g.name);
                            } else {
                              _selectedGenres.remove(g.name);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text('Sozlamalar', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              _switchTile('Faol (foydalanuvchilarga ko\'rinadi)', _isActive, (v) => setState(() => _isActive = v)),
              _switchTile('Bosh sahifa banneri', _isBanner, (v) => setState(() => _isBanner = v)),
              _switchTile('Trend', _isTrending, (v) => setState(() => _isTrending = v)),
              _switchTile('Yangi', _isNew, (v) => setState(() => _isNew = v)),
              _switchTile('Mashhur', _isPopular, (v) => setState(() => _isPopular = v)),
              _switchTile('Tavsiya etilgan', _isRecommended, (v) => setState(() => _isRecommended = v)),
              const SizedBox(height: 24),
              _saving
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ElevatedButton(
                      onPressed: _save,
                      child: Text(_isEditing ? 'Saqlash' : 'Qo\'shish'),
                    ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool required = false, int maxLines = 1, TextInputType? keyboardType, VoidCallback? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary),
        onChanged: (_) => onChanged?.call(),
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: AppColors.textSecondary)),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Majburiy maydon' : null : null,
      ),
    );
  }

  Widget _switchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
