import 'dart:async';
import 'package:flutter/material.dart';
import 'package:red_cristiana/core/notifications/app_refresh_bus.dart';
import 'package:red_cristiana/features/churches/data/models/church_model.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_detail_screen.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/post_images_widget.dart';
import 'package:red_cristiana/features/home/data/home_feed_service.dart';
import 'package:red_cristiana/features/media/presentation/screens/app_video_player_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  bool isLoading = true;

  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> filteredItems = [];

  final searchController = TextEditingController();

  StreamSubscription<String>? _refreshSubscription;

  String selectedTab = 'all';
  String selectedCountry = '';
  String selectedCity = '';

  List<String> countries = [];
  List<String> cities = [];

  @override
  void initState() {
    super.initState();
    _loadFeed();
    searchController.addListener(_applyFilters);

    _refreshSubscription = AppRefreshBus.stream.listen((event) async {
      if (event == 'feed_refresh' || event == 'general_refresh') {
        await _loadFeed();
        _applyFilters();
      }
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    try {
      final data = await HomeFeedService.getGeneralFeed();

      final countrySet = <String>{};
      final citySet = <String>{};

      for (final item in data) {
        final church = Map<String, dynamic>.from(item['church']);
        final country = church['country']?.toString().trim() ?? '';
        final city = church['city']?.toString().trim() ?? '';

        if (country.isNotEmpty) {
          countrySet.add(country);
        }
        if (city.isNotEmpty) {
          citySet.add(city);
        }
      }

      if (!mounted) return;

      setState(() {
        allItems = data;
        filteredItems = data;
        countries = countrySet.toList()..sort();
        cities = citySet.toList()..sort();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando feed: $e')),
      );
    }
  }

  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();

    final results = allItems.where((item) {
      final church = Map<String, dynamic>.from(item['church']);
      final churchName = church['church_name']?.toString().toLowerCase() ?? '';
      final country = church['country']?.toString() ?? '';
      final city = church['city']?.toString() ?? '';
      final title = item['title']?.toString().toLowerCase() ?? '';
      final content = item['content']?.toString().toLowerCase() ?? '';
      final type = item['type']?.toString() ?? '';
      final isMyChurch = item['is_my_church'] == true;

      final matchesText = query.isEmpty ||
          churchName.contains(query) ||
          title.contains(query) ||
          content.contains(query) ||
          country.toLowerCase().contains(query) ||
          city.toLowerCase().contains(query);

      final matchesCountry =
          selectedCountry.isEmpty || country == selectedCountry;

      final matchesCity = selectedCity.isEmpty || city == selectedCity;

      bool matchesTab = true;

      if (selectedTab == 'my_church') {
        matchesTab = isMyChurch;
      } else if (selectedTab == 'posts') {
        matchesTab = type == 'post';
      } else if (selectedTab == 'videos') {
        matchesTab = type == 'video';
      }

      return matchesText && matchesCountry && matchesCity && matchesTab;
    }).toList();

    setState(() {
      filteredItems = results;
    });
  }

  void _clearFilters() {
    searchController.clear();

    setState(() {
      selectedTab = 'all';
      selectedCountry = '';
      selectedCity = '';
      filteredItems = allItems;
    });
  }

  Future<void> _openSearchSheet() async {
    final tempSearchController =
    TextEditingController(text: searchController.text);
    String tempCountry = selectedCountry;
    String tempCity = selectedCity;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F9FC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget dropdownFilter({
              required String label,
              required String value,
              required List<String> items,
              required ValueChanged<String?> onChanged,
              required IconData icon,
            }) {
              return DropdownButtonFormField<String>(
                value: value.isEmpty ? null : value,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: items
                    .map(
                      (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, overflow: TextOverflow.ellipsis),
                  ),
                )
                    .toList(),
                onChanged: onChanged,
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF0D47A1)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Buscar en el feed',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.keyboard_arrow_down),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tempSearchController,
                      decoration: InputDecoration(
                        hintText: 'Nombre de iglesia, contenido, país...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    dropdownFilter(
                      label: 'País',
                      value: tempCountry,
                      items: countries,
                      icon: Icons.public,
                      onChanged: (value) {
                        setSheetState(() {
                          tempCountry = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    dropdownFilter(
                      label: 'Ciudad',
                      value: tempCity,
                      items: cities,
                      icon: Icons.location_city,
                      onChanged: (value) {
                        setSheetState(() {
                          tempCity = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              tempSearchController.clear();
                              setSheetState(() {
                                tempCountry = '';
                                tempCity = '';
                              });
                            },
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Limpiar'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              searchController.text =
                                  tempSearchController.text.trim();

                              setState(() {
                                selectedCountry = tempCountry;
                                selectedCity = tempCity;
                              });

                              _applyFilters();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Aplicar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openChurch(Map<String, dynamic> churchMap) {
    final church = ChurchModel.fromMap(churchMap);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChurchDetailScreen(church: church),
      ),
    );
  }

  Future<void> _togglePostLike(String postId) async {
    try {
      await HomeFeedService.togglePostLike(postId);
      await _loadFeed();
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en Me gusta: $e')),
      );
    }
  }

  Future<void> _toggleVideoLike(String videoId) async {
    try {
      await HomeFeedService.toggleVideoLike(videoId);
      await _loadFeed();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en Me gusta: $e')),
      );
    }
  }

  Widget _filterChip(String value, String label, IconData icon) {
    final isSelected = selectedTab == value;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            selectedTab = value;
          });
          _applyFilters();
        },
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _searchChip() {
    final hasFilters = searchController.text.trim().isNotEmpty ||
        selectedCountry.isNotEmpty ||
        selectedCity.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ActionChip(
        onPressed: _openSearchSheet,
        avatar: Icon(
          hasFilters ? Icons.tune : Icons.search,
          size: 18,
        ),
        label: Text(hasFilters ? 'Buscar activo' : 'Buscar'),
      ),
    );
  }

  Widget _churchHeader(Map<String, dynamic> church, String createdAt) {
    final churchName = church['church_name']?.toString() ?? 'Iglesia';
    final logoUrl = church['logo_url']?.toString() ?? '';
    final country = church['country']?.toString() ?? '';
    final city = church['city']?.toString() ?? '';

    final location = [
      if (city.isNotEmpty) city,
      if (country.isNotEmpty) country,
    ].join(', ');

    return InkWell(
      onTap: () => _openChurch(church),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFEAF4FF),
              backgroundImage:
              logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
              child: logoUrl.isEmpty
                  ? const Icon(
                Icons.church,
                color: Color(0xFF0D47A1),
              )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    churchName,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (createdAt.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      createdAt.split('T').first,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _postCard(Map<String, dynamic> item) {
    final church = Map<String, dynamic>.from(item['church']);
    final title = item['title']?.toString() ?? '';
    final content = item['content']?.toString() ?? '';
    final createdAt = item['created_at']?.toString() ?? '';
    final likesCount = item['likes_count'] ?? 0;
    final likedByMe = item['liked_by_me'] ?? false;

    final images = List<Map<String, dynamic>>.from(item['images'] ?? []);
    final urls = images
        .map((e) => e['image_url']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _churchHeader(church, createdAt),
          if (urls.isNotEmpty) PostImagesWidget(imageUrls: urls),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Publicación',
                    style: TextStyle(
                      color: Color(0xFF0D47A1),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(
                      color: Colors.black87,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _togglePostLike(item['id'].toString()),
                      icon: Icon(
                        likedByMe ? Icons.favorite : Icons.favorite_border,
                        color: likedByMe ? Colors.red : Colors.black54,
                      ),
                    ),
                    Text('$likesCount Me gusta'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoCard(Map<String, dynamic> item) {
    final church = Map<String, dynamic>.from(item['church']);
    final title = item['title']?.toString() ?? '';
    final description = item['content']?.toString() ?? '';
    final thumbnailUrl = item['thumbnail_url']?.toString() ?? '';
    final createdAt = item['created_at']?.toString() ?? '';
    final likesCount = item['likes_count'] ?? 0;
    final likedByMe = item['liked_by_me'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _churchHeader(church, createdAt),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                  MaterialPageRoute(
                  builder: (_) => AppVideoPlayerScreen(
                  title: item['title']?.toString() ?? '',
                  description: item['content']?.toString() ?? '',
                  videoUrl: item['video_url']?.toString() ?? '',
                  ),
                ),
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                thumbnailUrl.isNotEmpty
                    ? Image.network(
                  thumbnailUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: double.infinity,
                  height: 220,
                  color: Colors.grey.shade300,
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Video',
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.black87,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _toggleVideoLike(item['id'].toString()),
                      icon: Icon(
                        likedByMe ? Icons.favorite : Icons.favorite_border,
                        color: likedByMe ? Colors.red : Colors.black54,
                      ),
                    ),
                    Text('$likesCount Me gusta'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedItem(Map<String, dynamic> item) {
    final type = item['type']?.toString() ?? 'post';

    if (type == 'video') {
      return _videoCard(item);
    }

    return _postCard(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('all', 'Todo', Icons.dashboard_outlined),
                _filterChip(
                  'my_church',
                  'Mi iglesia',
                  Icons.favorite_outline,
                ),
                _filterChip(
                  'posts',
                  'Publicaciones',
                  Icons.photo_library_outlined,
                ),
                _filterChip(
                  'videos',
                  'Videos',
                  Icons.ondemand_video_outlined,
                ),
                _searchChip(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
              child: Text(
                'No hay resultados para esos filtros.',
                textAlign: TextAlign.center,
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadFeed,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) =>
                    _feedItem(filteredItems[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}