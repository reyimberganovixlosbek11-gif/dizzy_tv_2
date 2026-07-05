import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/movie_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/movie_card.dart';
import '../movie/movie_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _firestoreService = FirestoreService();
  final _searchCtrl = TextEditingController();

  String? _selectedGenre;
  int? _selectedYear;
  String? _selectedCountry;
  double? _selectedMinRating;

  List<MovieModel> _results = [];
  bool _loading = false;
  bool _searched = false;

  final List<String> _years = List.generate(30, (i) => '${DateTime.now().year - i}');
  final List<double> _ratings = [9, 8, 7, 6, 5];

  Future<void> _runSearch() async {
    setState(() => _loading = true);
    final results = await _firestoreService.searchMovies(
      keyword: _searchCtrl.text,
      genre: _selectedGenre,
      year: _selectedYear,
      country: _selectedCountry,
      minRating: _selectedMinRating,
    );
    setState(() {
      _results = results;
      _loading = false;
      _searched = true;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedGenre = null;
      _selectedYear = null;
      _selectedCountry = null;
      _selectedMinRating = null;
      _searchCtrl.clear();
      _results = [];
      _searched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qidiruv')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _runSearch(),
                decoration: InputDecoration(
                  hintText: 'Kino nomini kiriting...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.tune, color: AppColors.primary),
                    onPressed: () => _openFilterSheet(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_selectedGenre != null || _selectedYear != null || _selectedCountry != null || _selectedMinRating != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        children: [
                          if (_selectedGenre != null) Chip(label: Text(_selectedGenre!), backgroundColor: AppColors.surface),
                          if (_selectedYear != null) Chip(label: Text('${_selectedYear}'), backgroundColor: AppColors.surface),
                          if (_selectedCountry != null) Chip(label: Text(_selectedCountry!), backgroundColor: AppColors.surface),
                          if (_selectedMinRating != null) Chip(label: Text('${_selectedMinRating}+ ⭐'), backgroundColor: AppColors.surface),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Tozalash', style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (!_searched) {
      return const Center(
        child: Text('Kino nomini yozing yoki filtr tanlang', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    if (_results.isEmpty) {
      return const Center(child: Text('Hech narsa topilmadi', style: TextStyle(color: AppColors.textSecondary)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.6,
      ),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final movie = _results[i];
        return MovieCard(
          movie: movie,
          width: double.infinity,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
          ),
        );
      },
    );
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filtrlar', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  StreamBuilder<List<GenreModel>>(
                    stream: _firestoreService.genres(),
                    builder: (context, snap) {
                      final genres = snap.data ?? [];
                      return _FilterDropdown<String>(
                        label: 'Janr',
                        value: _selectedGenre,
                        items: genres.map((g) => g.name).toList(),
                        onChanged: (v) => setModalState(() => _selectedGenre = v),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _FilterDropdown<String>(
                    label: 'Yili',
                    value: _selectedYear?.toString(),
                    items: _years,
                    onChanged: (v) => setModalState(() => _selectedYear = v != null ? int.parse(v) : null),
                  ),
                  const SizedBox(height: 12),
                  _FilterDropdown<String>(
                    label: 'Reyting',
                    value: _selectedMinRating?.toString(),
                    items: _ratings.map((r) => r.toString()).toList(),
                    onChanged: (v) => setModalState(() => _selectedMinRating = v != null ? double.parse(v) : null),
                  ),
                  const SizedBox(height: 12),
                  _FilterDropdown<String>(
                    label: 'Davlat',
                    value: _selectedCountry,
                    items: const ['O\'zbekiston', 'AQSH', 'Turkiya', 'Koreya', 'Hindiston', 'Rossiya'],
                    onChanged: (v) => setModalState(() => _selectedCountry = v),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                      _runSearch();
                    },
                    child: const Text('Qo\'llash'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: AppColors.surfaceLight,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: AppColors.textPrimary))))
          .toList(),
      onChanged: onChanged,
    );
  }
}
