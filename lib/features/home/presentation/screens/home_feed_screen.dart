import 'dart:async';
import 'package:flutter/material.dart';
import 'package:red_cristiana/features/prayer/data/prayer_service.dart';
import 'package:red_cristiana/features/prayer/presentation/widgets/create_prayer_request_sheet.dart';
import 'package:red_cristiana/core/notifications/app_refresh_bus.dart';
import 'package:red_cristiana/features/churches/data/models/church_model.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_detail_screen.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/post_images_widget.dart';
import 'package:red_cristiana/features/home/data/home_feed_service.dart';
import 'package:red_cristiana/core/widgets/network_error_view.dart';
import 'package:red_cristiana/features/media/presentation/screens/app_video_player_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  final String? initialChurchId;
  final String? initialChurchName;
  final String initialTab;
  final bool allowResetToGeneral;

  const HomeFeedScreen({
    super.key,
    this.initialChurchId,
    this.initialChurchName,
    this.initialTab = 'all',
    this.allowResetToGeneral = true,
  });

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  bool isLoadingMore = false;
  bool hasMore = true;

  static const int pageSize = 10;
  int currentOffset = 0;

  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> filteredItems = [];

  StreamSubscription<String>? _refreshSubscription;
  Timer? _silentRefreshTimer;

  List<Map<String, dynamic>> pendingNewItems = [];
  bool isCheckingNewFeedItems = false;

  String selectedTab = 'all';
  String selectedChurchId = '';
  String selectedCountry = '';
  String selectedCity = '';

  List<String> countries = [];
  List<String> cities = [];

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab;
    selectedChurchId = widget.initialChurchId ?? '';

    _loadFeed();
    searchController.addListener(_applyFilters);
    scrollController.addListener(_onScroll);

    _refreshSubscription = AppRefreshBus.stream.listen((event) async {
      if (event == 'feed_refresh' || event == 'general_refresh') {
        await _checkForNewFeedItems();
      }
    });

    _startSilentFeedRefresh();
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    _silentRefreshTimer?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!scrollController.hasClients || isLoadingMore || !hasMore) return;

    final threshold = scrollController.position.maxScrollExtent - 250;
    if (scrollController.position.pixels >= threshold) {
      _loadMoreFeed();
    }
  }

  void _startSilentFeedRefresh() {
    _silentRefreshTimer?.cancel();
    _silentRefreshTimer = Timer.periodic(
      const Duration(seconds: 35),
          (_) => _checkForNewFeedItems(),
    );
  }

  Future<void> _checkForNewFeedItems() async {
    if (isLoading ||
        isLoadingMore ||
        isCheckingNewFeedItems ||
        !mounted ||
        allItems.isEmpty) {
      return;
    }

    try {
      isCheckingNewFeedItems = true;

      final response = await HomeFeedService.getGeneralFeedPage(
        offset: 0,
        limit: pageSize,
      );

      final latestItems =
      List<Map<String, dynamic>>.from(response['items'] ?? []);

      if (latestItems.isEmpty) {
        isCheckingNewFeedItems = false;
        return;
      }

      final existingKeys =
      allItems.map((item) => '${item['type']}_${item['id']}').toSet();

      final newItems = latestItems.where((item) {
        final key = '${item['type']}_${item['id']}';
        return !existingKeys.contains(key);
      }).toList();

      if (!mounted) {
        isCheckingNewFeedItems = false;
        return;
      }

      if (newItems.isNotEmpty) {
        final pendingKeys =
        pendingNewItems.map((item) => '${item['type']}_${item['id']}').toSet();

        final uniqueNewItems = newItems.where((item) {
          final key = '${item['type']}_${item['id']}';
          return !pendingKeys.contains(key);
        }).toList();

        if (uniqueNewItems.isNotEmpty) {
          setState(() {
            pendingNewItems = [...uniqueNewItems, ...pendingNewItems];
          });
        }
      }
    } catch (_) {
      // refresco silencioso
    } finally {
      isCheckingNewFeedItems = false;
    }
  }

  void _insertPendingItemsIntoFeed() {
    if (pendingNewItems.isEmpty) return;

    final merged = [...pendingNewItems, ...allItems];
    final unique = <String, Map<String, dynamic>>{};

    for (final item in merged) {
      final key = '${item['type']}_${item['id']}';
      unique[key] = item;
    }

    final uniqueItems = unique.values.toList();

    uniqueItems.sort((a, b) {
      final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
          DateTime(2000);
      final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
          DateTime(2000);
      return bDate.compareTo(aDate);
    });

    final countrySet = <String>{};
    final citySet = <String>{};

    for (final item in uniqueItems) {
      final church = item['church'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(item['church'])
          : <String, dynamic>{};

      final country = church['country']?.toString().trim() ?? '';
      final city = church['city']?.toString().trim() ?? '';

      if (country.isNotEmpty) countrySet.add(country);
      if (city.isNotEmpty) citySet.add(city);
    }

    setState(() {
      allItems = uniqueItems;
      countries = countrySet.toList()..sort();
      cities = citySet.toList()..sort();
      currentOffset = allItems.length;
      pendingNewItems = [];
    });

    _applyFilters();

    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadFeed({bool refresh = true}) async {
    try {
      if (refresh) {
        setState(() {
          isLoading = true;
          hasError = false;
          errorMessage = '';
          currentOffset = 0;
          hasMore = true;
        });
      }

      final response = await HomeFeedService.getGeneralFeedPage(
        offset: 0,
        limit: pageSize,
      );

      final data = List<Map<String, dynamic>>.from(response['items'] ?? []);
      final pageHasMore = response['has_more'] == true;

      final countrySet = <String>{};
      final citySet = <String>{};

      for (final item in data) {
        final church = item['church'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(item['church'])
            : <String, dynamic>{};

        final country = church['country']?.toString().trim() ?? '';
        final city = church['city']?.toString().trim() ?? '';

        if (country.isNotEmpty) countrySet.add(country);
        if (city.isNotEmpty) citySet.add(city);
      }

      if (!mounted) return;

      setState(() {
        allItems = data;
        countries = countrySet.toList()..sort();
        cities = citySet.toList()..sort();
        isLoading = false;
        hasError = false;
        hasMore = pageHasMore;
        currentOffset = data.length;
        pendingNewItems = [];
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage =
        'Creo que no tienes internet. Verifica tu conexión y vuelve a intentarlo.';
      });
    }
  }

  Future<void> _loadMoreFeed() async {
    if (isLoadingMore || !hasMore) return;

    try {
      setState(() {
        isLoadingMore = true;
      });

      final response = await HomeFeedService.getGeneralFeedPage(
        offset: currentOffset,
        limit: pageSize,
      );

      final newItems = List<Map<String, dynamic>>.from(response['items'] ?? []);
      final pageHasMore = response['has_more'] == true;

      if (!mounted) return;

      if (newItems.isEmpty) {
        setState(() {
          isLoadingMore = false;
          hasMore = false;
        });
        return;
      }

      final merged = [...allItems, ...newItems];
      final unique = <String, Map<String, dynamic>>{};

      for (final item in merged) {
        final key = '${item['type']}_${item['id']}';
        unique[key] = item;
      }

      final uniqueItems = unique.values.toList();

      uniqueItems.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime(2000);
        final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime(2000);
        return bDate.compareTo(aDate);
      });

      final countrySet = <String>{};
      final citySet = <String>{};

      for (final item in uniqueItems) {
        final church = item['church'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(item['church'])
            : <String, dynamic>{};

        final country = church['country']?.toString().trim() ?? '';
        final city = church['city']?.toString().trim() ?? '';

        if (country.isNotEmpty) countrySet.add(country);
        if (city.isNotEmpty) citySet.add(city);
      }

      setState(() {
        allItems = uniqueItems;
        countries = countrySet.toList()..sort();
        cities = citySet.toList()..sort();
        currentOffset = allItems.length;
        hasMore = pageHasMore;
        isLoadingMore = false;
      });

      _applyFilters();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();

    final results = allItems.where((item) {
      final church = item['church'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(item['church'])
          : <String, dynamic>{};

      final churchName = church['church_name']?.toString().toLowerCase() ?? '';
      final country = church['country']?.toString() ?? '';
      final city = church['city']?.toString() ?? '';
      final title = item['title']?.toString().toLowerCase() ?? '';
      final content = item['content']?.toString().toLowerCase() ?? '';
      final type = item['type']?.toString() ?? '';
      final isMyChurch = item['is_my_church'] == true;
      final churchId = item['church_id']?.toString() ?? '';

      final matchesText = query.isEmpty ||
          churchName.contains(query) ||
          title.contains(query) ||
          content.contains(query) ||
          country.toLowerCase().contains(query) ||
          city.toLowerCase().contains(query);

      final matchesCountry =
          selectedCountry.isEmpty || country == selectedCountry;

      final matchesCity = selectedCity.isEmpty || city == selectedCity;

      final matchesChurch =
          selectedChurchId.isEmpty || churchId == selectedChurchId;

      bool matchesTab = true;

      if (selectedTab == 'my_church') {
        matchesTab = isMyChurch;
      } else if (selectedTab == 'posts') {
        matchesTab = type == 'post';
      } else if (selectedTab == 'videos') {
        matchesTab = type == 'video';
      } else if (selectedTab == 'prayers') {
        matchesTab = type == 'prayer';
      }

      return matchesText &&
          matchesCountry &&
          matchesCity &&
          matchesChurch &&
          matchesTab;
    }).toList();

    setState(() {
      filteredItems = results;
    });
  }

  void _replaceItemLocally(Map<String, dynamic> updatedItem) {
    final type = updatedItem['type']?.toString() ?? '';
    final id = updatedItem['id']?.toString() ?? '';

    final index = allItems.indexWhere(
          (item) =>
      item['type']?.toString() == type && item['id']?.toString() == id,
    );

    if (index == -1) return;

    setState(() {
      allItems[index] = updatedItem;
    });

    _applyFilters();
  }

  void _removeItemLocally(String type, String id) {
    setState(() {
      allItems.removeWhere(
            (item) =>
        item['type']?.toString() == type && item['id']?.toString() == id,
      );
    });

    _applyFilters();
  }

  void _resetToGeneralFeed() {
    searchController.clear();

    setState(() {
      selectedTab = 'all';
      selectedCountry = '';
      selectedCity = '';
      selectedChurchId = '';
    });

    _applyFilters();
  }

  void _clearFilters() {
    searchController.clear();

    setState(() {
      selectedTab = 'all';
      selectedCountry = '';
      selectedCity = '';
      selectedChurchId = '';
    });

    _applyFilters();
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                initialValue: value.isEmpty ? null : value,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon, size: 18),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
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
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF0D47A1)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Buscar en el feed',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: tempSearchController,
                      decoration: InputDecoration(
                        hintText: 'Iglesia, contenido, país...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              tempSearchController.clear();
                              setSheetState(() {
                                tempCountry = '';
                                tempCity = '';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Limpiar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Aplicar'),
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
    final index = allItems.indexWhere(
          (item) => item['type'] == 'post' && item['id'].toString() == postId,
    );
    if (index == -1) return;

    final current = Map<String, dynamic>.from(allItems[index]);
    final likedByMe = current['liked_by_me'] == true;
    final likesCount = (current['likes_count'] ?? 0) as int;

    final updated = Map<String, dynamic>.from(current)
      ..['liked_by_me'] = !likedByMe
      ..['likes_count'] = likedByMe ? likesCount - 1 : likesCount + 1;

    _replaceItemLocally(updated);

    try {
      await HomeFeedService.togglePostLike(postId);
    } catch (e) {
      _replaceItemLocally(current);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en Me gusta: $e')),
      );
    }
  }

  Future<void> _toggleVideoLike(String videoId) async {
    final index = allItems.indexWhere(
          (item) => item['type'] == 'video' && item['id'].toString() == videoId,
    );
    if (index == -1) return;

    final current = Map<String, dynamic>.from(allItems[index]);
    final likedByMe = current['liked_by_me'] == true;
    final likesCount = (current['likes_count'] ?? 0) as int;

    final updated = Map<String, dynamic>.from(current)
      ..['liked_by_me'] = !likedByMe
      ..['likes_count'] = likedByMe ? likesCount - 1 : likesCount + 1;

    _replaceItemLocally(updated);

    try {
      await HomeFeedService.toggleVideoLike(videoId);
    } catch (e) {
      _replaceItemLocally(current);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en Me gusta: $e')),
      );
    }
  }

  Future<void> _togglePrayerUserSupport(String prayerRequestId) async {
    final index = allItems.indexWhere(
          (item) =>
      item['type'] == 'prayer' &&
          item['id'].toString() == prayerRequestId,
    );
    if (index == -1) return;

    final current = Map<String, dynamic>.from(allItems[index]);
    final supportedByMe = current['supported_by_me'] == true;
    final count = (current['user_support_count'] ?? 0) as int;

    final updated = Map<String, dynamic>.from(current)
      ..['supported_by_me'] = !supportedByMe
      ..['user_support_count'] = supportedByMe ? count - 1 : count + 1;

    _replaceItemLocally(updated);

    try {
      await HomeFeedService.togglePrayerUserSupport(prayerRequestId);
    } catch (e) {
      _replaceItemLocally(current);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al apoyar en oración: $e')),
      );
    }
  }

  Future<void> _togglePrayerChurchSupport(String prayerRequestId) async {
    final index = allItems.indexWhere(
          (item) =>
      item['type'] == 'prayer' &&
          item['id'].toString() == prayerRequestId,
    );
    if (index == -1) return;

    final current = Map<String, dynamic>.from(allItems[index]);
    final supportedByMyChurch = current['supported_by_my_church'] == true;
    final count = (current['church_support_count'] ?? 0) as int;

    final updated = Map<String, dynamic>.from(current)
      ..['supported_by_my_church'] = !supportedByMyChurch
      ..['church_support_count'] =
      supportedByMyChurch ? count - 1 : count + 1;

    _replaceItemLocally(updated);

    try {
      await HomeFeedService.togglePrayerChurchSupport(prayerRequestId);
    } catch (e) {
      _replaceItemLocally(current);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al apoyar con la iglesia: $e')),
      );
    }
  }

  Future<void> _requestMyChurchPrayer(String prayerRequestId) async {
    final index = allItems.indexWhere(
          (item) =>
      item['type'] == 'prayer' &&
          item['id'].toString() == prayerRequestId,
    );
    if (index == -1) return;

    final current = Map<String, dynamic>.from(allItems[index]);
    final requestedMyChurch = current['requested_my_church'] == true;
    final count = (current['my_church_request_count'] ?? 0) as int;

    final updated = Map<String, dynamic>.from(current)
      ..['requested_my_church'] = !requestedMyChurch
      ..['my_church_request_count'] =
      requestedMyChurch ? count - 1 : count + 1;

    _replaceItemLocally(updated);

    try {
      await HomeFeedService.requestMyChurchPrayer(prayerRequestId);
    } catch (e) {
      _replaceItemLocally(current);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al pedir a tu iglesia que ore: $e')),
      );
    }
  }

  Future<void> _deletePrayerRequest(String prayerRequestId) async {
    final index = allItems.indexWhere(
          (item) =>
      item['type'] == 'prayer' &&
          item['id'].toString() == prayerRequestId,
    );
    if (index == -1) return;

    final current = Map<String, dynamic>.from(allItems[index]);

    _removeItemLocally('prayer', prayerRequestId);

    try {
      await HomeFeedService.deletePrayerRequest(prayerRequestId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Petición eliminada')),
      );
    } catch (e) {
      setState(() {
        allItems.insert(index, current);
      });
      _applyFilters();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar petición: $e')),
      );
    }
  }

  void _openCreatePrayerRequest() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CreatePrayerRequestSheet(
        onCreated: () async {
          await _loadFeed();
          _applyFilters();
        },
      ),
    );
  }

  Widget _tinyFilterChip(String value, String label, IconData icon) {
    final isSelected = selectedTab == value;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          setState(() {
            selectedTab = value;
          });
          _applyFilters();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0D47A1)
                  : const Color(0xFFD9E2F2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : const Color(0xFF48607A),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF48607A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchChip() {
    final hasFilters = searchController.text.trim().isNotEmpty ||
        selectedCountry.isNotEmpty ||
        selectedCity.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: _openSearchSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: hasFilters ? const Color(0xFFEAF4FF) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: hasFilters
                  ? const Color(0xFF0D47A1)
                  : const Color(0xFFD9E2F2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasFilters ? Icons.tune_rounded : Icons.search_rounded,
                size: 14,
                color: hasFilters
                    ? const Color(0xFF0D47A1)
                    : const Color(0xFF48607A),
              ),
              const SizedBox(width: 5),
              Text(
                hasFilters ? 'Filtro' : 'Buscar',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: hasFilters
                      ? const Color(0xFF0D47A1)
                      : const Color(0xFF48607A),
                ),
              ),
            ],
          ),
        ),
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
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFEAF4FF),
              backgroundImage:
              logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
              child: logoUrl.isEmpty
                  ? const Icon(
                Icons.church,
                color: Color(0xFF0D47A1),
                size: 18,
              )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    churchName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (location.isNotEmpty)
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      if (createdAt.isNotEmpty)
                        Text(
                          createdAt.split('T').first,
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.black45,
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge({
    required String text,
    required Color bg,
    required Color fg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _postCard(Map<String, dynamic> item) {
    final church = Map<String, dynamic>.from(item['church'] ?? {});
    final title = item['title']?.toString() ?? '';
    final content = item['content']?.toString() ?? '';
    final createdAt = item['created_at']?.toString() ?? '';
    final likesCount = item['likes_count'] ?? 0;
    final likedByMe = item['liked_by_me'] == true;

    final images = List<Map<String, dynamic>>.from(item['images'] ?? []);
    final urls = images
        .map((e) => e['image_url']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    return _compactCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _churchHeader(church, createdAt),
          if (urls.isNotEmpty) PostImagesWidget(imageUrls: urls),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _typeBadge(
                  text: 'Publicación',
                  bg: const Color(0xFFEAF4FF),
                  fg: const Color(0xFF0D47A1),
                  icon: Icons.article_outlined,
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  ExpandableText(
                    text: content,
                    trimLines: 4,
                  ),
                ],
                const SizedBox(height: 8),
                _socialRow(
                  active: likedByMe,
                  activeIcon: Icons.favorite,
                  inactiveIcon: Icons.favorite_border,
                  activeColor: Colors.red,
                  label: '$likesCount',
                  onTap: () => _togglePostLike(item['id'].toString()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoCard(Map<String, dynamic> item) {
    final church = Map<String, dynamic>.from(item['church'] ?? {});
    final title = item['title']?.toString() ?? '';
    final description = item['content']?.toString() ?? '';
    final thumbnailUrl = item['thumbnail_url']?.toString() ?? '';
    final createdAt = item['created_at']?.toString() ?? '';
    final likesCount = item['likes_count'] ?? 0;
    final likedByMe = item['liked_by_me'] == true;

    return _compactCard(
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
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: Image.network(
                    thumbnailUrl,
                    width: double.infinity,
                    height: 205,
                    fit: BoxFit.cover,
                  ),
                )
                    : Container(
                  width: double.infinity,
                  height: 205,
                  color: Colors.grey.shade300,
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _typeBadge(
                  text: 'Video',
                  bg: const Color(0xFFFFF3E0),
                  fg: Colors.deepOrange,
                  icon: Icons.ondemand_video_outlined,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  ExpandableText(
                    text: description,
                    trimLines: 3,
                  ),
                ],
                const SizedBox(height: 8),
                _socialRow(
                  active: likedByMe,
                  activeIcon: Icons.favorite,
                  inactiveIcon: Icons.favorite_border,
                  activeColor: Colors.red,
                  label: '$likesCount',
                  onTap: () => _toggleVideoLike(item['id'].toString()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _prayerCard(Map<String, dynamic> item) {
    final userName = item['user_name']?.toString() ?? 'Un usuario';
    final category = item['category']?.toString() ?? 'otro';
    final isForMe = item['is_for_me'] == true;
    final targetName = item['target_name']?.toString().trim() ?? '';
    final userSupportCount = item['user_support_count'] ?? 0;
    final churchSupportCount = item['church_support_count'] ?? 0;
    final supportedByMe = item['supported_by_me'] == true;
    final supportedByMyChurch = item['supported_by_my_church'] == true;
    final createdByMe = item['created_by_me'] == true;
    final isChurchAccount = item['is_church_account'] == true;
    final requestedMyChurch = item['requested_my_church'] == true;
    final myChurchRequestCount = item['my_church_request_count'] ?? 0;
    final myChurchId = item['my_church_id']?.toString() ?? '';
    final canRequestMyChurch = myChurchId.isNotEmpty && !isChurchAccount;

    final prayerText = isForMe
        ? '$userName pide oración por su ${PrayerService.categoryLabel(category)}.'
        : '$userName pide oración por $targetName por ${PrayerService.categoryLabel(category)}.';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Petición de oración',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                    ),
                  ),
                ),
                if (createdByMe)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePrayerRequest(item['id'].toString());
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar petición'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              prayerText,
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '🙏 $userSupportCount personas orando',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '⛪ $churchSupportCount iglesias unidas',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (myChurchRequestCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$myChurchRequestCount miembro${myChurchRequestCount == 1 ? '' : 's'} pidió${myChurchRequestCount == 1 ? '' : 'eron'} a su iglesia orar',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (isChurchAccount)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _togglePrayerChurchSupport(item['id'].toString()),
                  icon: const Icon(Icons.church),
                  label: Text(
                    supportedByMyChurch ? 'Iglesia orando' : 'Iglesia ora',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: supportedByMyChurch
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _togglePrayerUserSupport(item['id'].toString()),
                      icon: Icon(
                        supportedByMe
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: supportedByMe ? Colors.red : null,
                      ),
                      label: Text(
                        supportedByMe ? 'Estoy orando' : 'Orar',
                        style: const TextStyle(
                          fontSize: 11,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  if (canRequestMyChurch) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _requestMyChurchPrayer(item['id'].toString()),
                        icon: const Icon(Icons.groups_2_outlined),
                        label: Text(
                          requestedMyChurch
                              ? 'Solicitud enviada'
                              : 'Pedir a mi iglesia',
                          style: const TextStyle(
                            fontSize: 11,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: requestedMyChurch
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _tinyActionButton({
    required IconData icon,
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: active ? color.withOpacity(0.10) : const Color(0xFFF5F7FB),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: active ? color : Colors.black54,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.4,
                    fontWeight: FontWeight.w700,
                    color: active ? color : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialRow({
    required bool active,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required Color activeColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Row(
              children: [
                Icon(
                  active ? activeIcon : inactiveIcon,
                  size: 20,
                  color: active ? activeColor : Colors.black54,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _compactCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F2F6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _feedItem(Map<String, dynamic> item) {
    final type = item['type']?.toString() ?? '';

    if (type == 'post') return _postCard(item);
    if (type == 'video') return _videoCard(item);
    if (type == 'prayer') return _prayerCard(item);

    return const SizedBox.shrink();
  }

  Widget _buildTopInfo() {
    return Column(
      children: [
        if (widget.initialChurchId != null && widget.initialChurchId!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.church,
                    color: Color(0xFF0D47A1),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mostrando contenido de ${widget.initialChurchName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  if (widget.allowResetToGeneral)
                    TextButton(
                      onPressed: _resetToGeneralFeed,
                      child: const Text('Ver todo'),
                    ),
                ],
              ),
            ),
          ),
        if (pendingNewItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _insertPendingItemsIntoFeed,
              child: Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fiber_new_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        pendingNewItems.length == 1
                            ? 'Hay 1 publicación nueva'
                            : 'Hay ${pendingNewItems.length} publicaciones nuevas',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.2,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 34,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        children: [
          _tinyFilterChip('all', 'Todo', Icons.apps_rounded),
          _tinyFilterChip('my_church', 'Mi iglesia', Icons.favorite_outline),
          _tinyFilterChip('posts', 'Posts', Icons.article_outlined),
          _tinyFilterChip('videos', 'Videos', Icons.play_circle_outline),
          _tinyFilterChip('prayers', 'Oración', Icons.volunteer_activism_outlined),
          _searchChip(),
          if (searchController.text.trim().isNotEmpty ||
              selectedCountry.isNotEmpty ||
              selectedCity.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _clearFilters,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F0),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFFD5CF)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Limpiar',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return NetworkErrorView(
        message: errorMessage,
        onRetry: _loadFeed,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'feed_prayer_fab',
        onPressed: _openCreatePrayerRequest,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.volunteer_activism_rounded, size: 20),
        label: const Text(
          'Pedir oración',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTopInfo(),
          const SizedBox(height: 2),
          _buildFilters(),
          const SizedBox(height: 6),
          Expanded(
            child: filteredItems.isEmpty
                ? RefreshIndicator(
              onRefresh: () => _loadFeed(),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 90),
                children: const [
                  SizedBox(height: 140),
                  Center(
                    child: Text(
                      'No hay resultados para esos filtros.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () => _loadFeed(),
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 90),
                itemCount: filteredItems.length + (isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= filteredItems.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  return _feedItem(filteredItems[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpandableText extends StatefulWidget {
  final String text;
  final int trimLines;

  const ExpandableText({
    super.key,
    required this.text,
    this.trimLines = 4,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool expanded = false;
  bool canExpand = false;

  @override
  Widget build(BuildContext context) {
    final style = const TextStyle(
      color: Colors.black87,
      fontSize: 13.4,
      height: 1.42,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(text: widget.text, style: style);

        final textPainter = TextPainter(
          text: textSpan,
          maxLines: widget.trimLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        canExpand = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: expanded ? null : widget.trimLines,
              overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (canExpand)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      expanded = !expanded;
                    });
                  },
                  child: Text(
                    expanded ? 'Ver menos' : 'Ver más',
                    style: const TextStyle(
                      color: Color(0xFF0D47A1),
                      fontSize: 12.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}