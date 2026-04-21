import 'dart:async';
import 'package:flutter/material.dart';
import 'package:red_cristiana/core/widgets/network_error_view.dart';
import 'package:red_cristiana/features/media/data/media_video_service.dart';
import 'package:red_cristiana/features/media/presentation/screens/app_video_player_screen.dart';
import 'package:red_cristiana/features/media/presentation/screens/series_detail_screen.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  final ScrollController _resultsScrollController = ScrollController();
  Timer? _searchDebounce;

  static const int _pageSize = 20;

  bool _isLoadingMore = false;
  bool _hasMoreResults = true;
  int _currentOffset = 0;

  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  final TextEditingController searchController = TextEditingController();

  String selectedTab = 'todos';

  List<Map<String, dynamic>> currentItems = [];
  List<Map<String, dynamic>> continueWatchingSeries = [];

  List<Map<String, dynamic>> featuredMovies = [];
  List<Map<String, dynamic>> featuredSeries = [];
  List<Map<String, dynamic>> featuredPreachings = [];
  List<Map<String, dynamic>> featuredTestimonies = [];

  List<Map<String, dynamic>> suggestedMovies = [];
  List<Map<String, dynamic>> suggestedSeries = [];
  List<Map<String, dynamic>> suggestedPreachings = [];
  List<Map<String, dynamic>> suggestedTestimonies = [];

  List<Map<String, dynamic>> searchResults = [];

  @override
  void initState() {
    super.initState();
    _resultsScrollController.addListener(_onResultsScroll);
    _loadMedia();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _resultsScrollController.removeListener(_onResultsScroll);
    _resultsScrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
        errorMessage = '';
      });

      final data = await MediaVideoService.getMediaHome();

      if (!mounted) return;

      setState(() {
        featuredMovies = List<Map<String, dynamic>>.from(data['featuredMovies'] ?? []);
        featuredSeries = List<Map<String, dynamic>>.from(data['featuredSeries'] ?? []);
        featuredPreachings =
        List<Map<String, dynamic>>.from(data['featuredPreachings'] ?? []);
        featuredTestimonies =
        List<Map<String, dynamic>>.from(data['featuredTestimonies'] ?? []);

        suggestedMovies =
        List<Map<String, dynamic>>.from(data['suggestedMovies'] ?? []);
        suggestedSeries =
        List<Map<String, dynamic>>.from(data['suggestedSeries'] ?? []);
        suggestedPreachings =
        List<Map<String, dynamic>>.from(data['suggestedPreachings'] ?? []);
        suggestedTestimonies =
        List<Map<String, dynamic>>.from(data['suggestedTestimonies'] ?? []);

        continueWatchingSeries =
        List<Map<String, dynamic>>.from(data['continueWatchingSeries'] ?? []);

        isLoading = false;
      });

      if (selectedTab != 'todos' || searchController.text.trim().isNotEmpty) {
        await _reloadPagedContent();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage =
        'No pudimos cargar películas. Verifica tu conexión o revisa la configuración de Media.';
      });
    }
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _fuzzyContains(String text, String query) {
    final normalizedText = _normalizeText(text);
    final normalizedQuery = _normalizeText(query);

    if (normalizedQuery.isEmpty) return true;
    if (normalizedText.contains(normalizedQuery)) return true;

    final queryWords = normalizedQuery.split(' ').where((e) => e.isNotEmpty).toList();
    final textWords = normalizedText.split(' ').where((e) => e.isNotEmpty).toList();

    for (final q in queryWords) {
      final found = textWords.any((w) {
        if (w.contains(q) || q.contains(w)) return true;

        final diff = (w.length - q.length).abs();
        if (diff > 1) return false;

        int mismatches = 0;
        final minLen = w.length < q.length ? w.length : q.length;

        for (int i = 0; i < minLen; i++) {
          if (w[i] != q[i]) mismatches++;
          if (mismatches > 1) return false;
        }

        mismatches += diff;
        return mismatches <= 1;
      });

      if (!found) return false;
    }

    return true;
  }

  String _currentCategory() {
    switch (selectedTab) {
      case 'peliculas':
        return 'movie';
      case 'series':
        return 'series';
      case 'predicas':
        return 'preaching';
      case 'testimonios':
        return 'testimony';
      case 'todos':
      default:
        return 'all';
    }
  }

  Future<void> _reloadPagedContent() async {
    _resetPagination();
    await _loadMoreResults(reset: true);
  }

  Future<void> _loadMoreResults({bool reset = false}) async {
    if (_isLoadingMore) return;
    if (!_hasMoreResults && !reset) return;

    final query = searchController.text.trim();

    setState(() {
      _isLoadingMore = true;
      if (reset) {
        currentItems = [];
        if (query.isNotEmpty) {
          searchResults = [];
        }
      }
    });

    try {
      final result = await MediaVideoService.getMediaPage(
        category: _currentCategory(),
        limit: _pageSize,
        offset: reset ? 0 : _currentOffset,
        searchQuery: query,
      );

      final fetched = List<Map<String, dynamic>>.from(result);

      final filtered = query.isEmpty
          ? fetched
          : fetched.where((item) {
        final title = item['title']?.toString() ?? '';
        final description = item['description']?.toString() ?? '';
        return _fuzzyContains(title, query) || _fuzzyContains(description, query);
      }).toList();

      setState(() {
        if (reset) {
          currentItems = filtered;
          searchResults = filtered;
          _currentOffset = fetched.length;
        } else {
          currentItems.addAll(filtered);
          if (query.isNotEmpty) {
            searchResults.addAll(filtered);
          }
          _currentOffset += fetched.length;
        }

        _hasMoreResults = fetched.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _resetPagination() {
    _currentOffset = 0;
    _hasMoreResults = true;
    currentItems = [];
  }

  void _onResultsScroll() {
    if (!_resultsScrollController.hasClients) return;

    final position = _resultsScrollController.position;
    if (position.pixels < position.maxScrollExtent - 300) return;

    _loadMoreResults();
  }

  void _changeTab(String value) async {
    FocusScope.of(context).unfocus();

    setState(() {
      selectedTab = value;
    });

    if (_resultsScrollController.hasClients) {
      _resultsScrollController.jumpTo(0);
    }

    await _reloadPagedContent();
  }

  Widget _miniHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D47A1),
            Color(0xFF1565C0),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.live_tv_rounded, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Películas, series y más',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: searchController,
        onChanged: (_) {
          _searchDebounce?.cancel();
          _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
            if (!mounted) return;
            await _reloadPagedContent();
          });
        },
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar películas, series, prédicas o testimonios...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
            onPressed: () async {
              searchController.clear();
              FocusScope.of(context).unfocus();
              await _reloadPagedContent();
            },
            icon: const Icon(Icons.close),
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _chip(String value, String label) {
    final isSelected = selectedTab == value;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => _changeTab(value),

        backgroundColor: Colors.white,
        selectedColor: const Color(0xFFDCEBFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Future<void> _openMovie(Map<String, dynamic> movie) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppVideoPlayerScreen(
          title: movie['title']?.toString() ?? 'Contenido',
          description: movie['description']?.toString() ?? '',
          videoUrl: movie['video_url']?.toString() ?? '',
        ),
      ),
    );
  }

  Future<void> _openSeries(Map<String, dynamic> seriesItem) async {
    final seriesId = seriesItem['id']?.toString();
    if (seriesId == null || seriesId.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeriesDetailScreen(seriesId: seriesId),
      ),
    );

    _loadMedia();
  }

  Widget _contentCard(
      Map<String, dynamic> item, {
        required String label,
        required IconData icon,
        required VoidCallback onTap,
        Color accent = const Color(0xFF0D47A1),
      }) {
    final title = item['title']?.toString() ?? '';
    final description = item['description']?.toString() ?? '';
    final thumb = item['thumbnail_url']?.toString() ?? '';
    final featured = item['is_featured'] == true;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                thumb.isNotEmpty
                    ? Image.network(
                  thumb,
                  width: double.infinity,
                  height: 132,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity,
                    height: 132,
                    color: Colors.grey.shade300,
                    child: Icon(icon, size: 44),
                  ),
                )
                    : Container(
                  width: double.infinity,
                  height: 132,
                  color: Colors.grey.shade300,
                  child: Icon(icon, size: 44),
                ),
                if (featured)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Destacado',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
                      ),
                    ),
                  ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.1,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridCard(
      Map<String, dynamic> item, {
        required String label,
        required IconData icon,
        required VoidCallback onTap,
        Color accent = const Color(0xFF0D47A1),
      }) {
    final title = item['title']?.toString() ?? '';
    final description = item['description']?.toString() ?? '';
    final thumb = item['thumbnail_url']?.toString() ?? '';
    final featured = item['is_featured'] == true;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                thumb.isNotEmpty
                    ? Image.network(
                  thumb,
                  width: double.infinity,
                  height: 135,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 135,
                    color: Colors.grey.shade300,
                    child: Center(child: Icon(icon, size: 42)),
                  ),
                )
                    : Container(
                  height: 135,
                  color: Colors.grey.shade300,
                  child: Center(child: Icon(icon, size: 42)),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                if (featured)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Destacado',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.3,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54, fontSize: 12.8),
          ),
        ],
      ),
    );
  }

  Widget _emptySection(String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 54,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            Text(
              'Aún no hay $title',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cuando agreguemos contenido aquí, aparecerá en esta sección.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seeMoreCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color accent = const Color(0xFF0D47A1),
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                'Ver más',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.8,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _horizontalSection({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> items,
    required String label,
    required IconData icon,
    required VoidCallback? Function(Map<String, dynamic>) onTapBuilder,
    required VoidCallback onSeeMore,
    Color accent = const Color(0xFF0D47A1),
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    final previewItems = items.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title, subtitle),
        SizedBox(
          height: 270,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              ...previewItems.map((item) {
                final callback = onTapBuilder(item);
                return _contentCard(
                  item,
                  label: label,
                  icon: icon,
                  accent: accent,
                  onTap: callback ?? () {},
                );
              }),
              _seeMoreCard(
                title: title,
                icon: icon,
                accent: accent,
                onTap: onSeeMore,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _gridSection({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> items,
    required String label,
    required IconData icon,
    required VoidCallback? Function(Map<String, dynamic>) onTapBuilder,
    Color accent = const Color(0xFF0D47A1),
    ScrollController? controller,
    bool hasMore = false,
  }) {
    if (items.isEmpty) {
      return _emptySection(label.toLowerCase());
    }

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.62,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final callback = onTapBuilder(item);

            return _gridCard(
              item,
              label: label,
              icon: icon,
              accent: accent,
              onTap: callback ?? () {},
            );
          },
        ),
        if (hasMore) ...[
          const SizedBox(height: 18),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Cargando más contenido...',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _continueWatchingSection() {
    if (continueWatchingSeries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Continuar viendo', 'Sigue justo donde te quedaste'),
        SizedBox(
          height: 230,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: continueWatchingSeries.length,
            itemBuilder: (context, index) {
              final item = continueWatchingSeries[index];
              final seriesItem = Map<String, dynamic>.from(item['series']);
              final episode = Map<String, dynamic>.from(item['episode']);

              final title = seriesItem['title']?.toString() ?? 'Serie';
              final thumb = (seriesItem['cover_url']?.toString().trim().isNotEmpty ?? false)
                  ? seriesItem['cover_url'].toString()
                  : (seriesItem['thumbnail_url']?.toString() ?? '');

              return InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => _openSeries(seriesItem),
                child: Container(
                  width: 235,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      thumb.isNotEmpty
                          ? Image.network(
                        thumb,
                        width: double.infinity,
                        height: 132,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: double.infinity,
                          height: 132,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.tv, size: 44),
                        ),
                      )
                          : Container(
                        width: double.infinity,
                        height: 132,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.tv, size: 44),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Temporada ${episode['season_number']} · Episodio ${episode['episode_number']}',
                              style: const TextStyle(
                                color: Color(0xFF0D47A1),
                                fontWeight: FontWeight.w700,
                                fontSize: 12.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              episode['title']?.toString() ?? 'Continuar episodio',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _searchResultsView() {
    late String label;
    late IconData icon;
    late Color accent;
    late VoidCallback? Function(Map<String, dynamic>) onTapBuilder;

    switch (selectedTab) {
      case 'peliculas':
        label = 'Película';
        icon = Icons.movie;
        accent = const Color(0xFF0D47A1);
        onTapBuilder = (item) => () => _openMovie(item);
        break;

      case 'series':
        label = 'Serie';
        icon = Icons.tv;
        accent = const Color(0xFF1565C0);
        onTapBuilder = (item) => () => _openSeries(item);
        break;

      case 'predicas':
        label = 'Prédica';
        icon = Icons.record_voice_over_rounded;
        accent = const Color(0xFF2E7D32);
        onTapBuilder = (item) => () => _openMovie(item);
        break;

      case 'testimonios':
        label = 'Testimonio';
        icon = Icons.auto_stories_rounded;
        accent = const Color(0xFF6A1B9A);
        onTapBuilder = (item) => () => _openMovie(item);
        break;

      case 'todos':
      default:
        label = 'Contenido';
        icon = Icons.ondemand_video_rounded;
        accent = const Color(0xFF0D47A1);
        onTapBuilder = (item) {
          final type = item['content_type']?.toString() ?? '';
          if (type == 'series') {
            return () => _openSeries(item);
          }
          return () => _openMovie(item);
        };
        break;
    }

    return _gridSection(
      title: '',
      subtitle: '',
      items: currentItems,
      label: label,
      icon: icon,
      accent: accent,
      onTapBuilder: onTapBuilder,
      controller: _resultsScrollController,
      hasMore: _hasMoreResults || _isLoadingMore,
    );
  }

  Widget _defaultBody() {
    final homeMovies = featuredMovies.isNotEmpty ? featuredMovies : suggestedMovies;
    final homeSeries = featuredSeries.isNotEmpty ? featuredSeries : suggestedSeries;
    final homePreachings =
    featuredPreachings.isNotEmpty ? featuredPreachings : suggestedPreachings;
    final homeTestimonies =
    featuredTestimonies.isNotEmpty ? featuredTestimonies : suggestedTestimonies;

    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      children: [
        _continueWatchingSection(),
        _horizontalSection(
          title: 'Películas',
          subtitle: 'Las más recomendadas para abrir ahora',
          items: homeMovies,
          label: 'Película',
          icon: Icons.movie,
          onTapBuilder: (item) => () => _openMovie(item),
          onSeeMore: () => _changeTab('peliculas'),
        ),
        _horizontalSection(
          title: 'Series',
          subtitle: 'Temporadas, episodios y reproducción continua',
          items: homeSeries,
          label: 'Serie',
          icon: Icons.tv,
          onTapBuilder: (item) => () => _openSeries(item),
          onSeeMore: () => _changeTab('series'),
        ),
        _horizontalSection(
          title: 'Prédicas',
          subtitle: 'Mensajes para fortalecer tu fe',
          items: homePreachings,
          label: 'Prédica',
          icon: Icons.record_voice_over_rounded,
          accent: const Color(0xFF2E7D32),
          onTapBuilder: (item) => () => _openMovie(item),
          onSeeMore: () => _changeTab('predicas'),
        ),
        _horizontalSection(
          title: 'Testimonios',
          subtitle: 'Historias reales que inspiran',
          items: homeTestimonies,
          label: 'Testimonio',
          icon: Icons.auto_stories_rounded,
          accent: const Color(0xFF6A1B9A),
          onTapBuilder: (item) => () => _openMovie(item),
          onSeeMore: () => _changeTab('testimonios'),
        ),
        if (homeMovies.isEmpty &&
            homeSeries.isEmpty &&
            homePreachings.isEmpty &&
            homeTestimonies.isEmpty)
          _emptySection('contenido'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final showingSearch = searchController.text.trim().isNotEmpty;
    final showingPagedTab = selectedTab != 'todos';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF7F9FC),
      body: Column(
        children: [
          _miniHeader(),
          _buildSearchBox(),
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _chip('todos', 'Todo'),
                _chip('peliculas', 'Películas'),
                _chip('series', 'Series'),
                _chip('predicas', 'Prédicas'),
                _chip('testimonios', 'Testimonios'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : hasError
                ? NetworkErrorView(
              message: errorMessage,
              onRetry: _loadMedia,
            )
                : showingSearch || showingPagedTab
                ? _searchResultsView()
                : _defaultBody(),
          ),
        ],
      ),
    );
  }
}