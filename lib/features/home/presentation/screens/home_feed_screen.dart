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

  bool isLoadingMore = false;
  bool hasMore = true;

  static const int pageSize = 10;
  int currentOffset = 0;

  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> filteredItems = [];

  final searchController = TextEditingController();

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

    final threshold = scrollController.position.maxScrollExtent - 300;
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

      final existingKeys = allItems
          .map((item) => '${item['type']}_${item['id']}')
          .toSet();

      final newItems = latestItems.where((item) {
        final key = '${item['type']}_${item['id']}';
        return !existingKeys.contains(key);
      }).toList();

      if (!mounted) {
        isCheckingNewFeedItems = false;
        return;
      }

      if (newItems.isNotEmpty) {
        final pendingKeys = pendingNewItems
            .map((item) => '${item['type']}_${item['id']}')
            .toSet();

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
      // silencioso a propósito
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
      final aDate =
          DateTime.tryParse(a['created_at']?.toString() ?? '') ??
              DateTime(2000);
      final bDate =
          DateTime.tryParse(b['created_at']?.toString() ?? '') ??
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
        duration: const Duration(milliseconds: 350),
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
        final aDate =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ??
                DateTime(2000);
        final bDate =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ??
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
      item['type']?.toString() == type &&
          item['id']?.toString() == id,
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
        item['type']?.toString() == type &&
            item['id']?.toString() == id,
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
                initialValue: value.isEmpty ? null : value,
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
                      fontSize: 12.5,
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
                      fontSize: 12.5,
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
                        fontSize: 12,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
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
                              ? 'Pedida a mi iglesia'
                              : 'Pedir a mi iglesia',
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

  Widget _feedItem(Map<String, dynamic> item) {
    final type = item['type']?.toString() ?? 'post';

    if (type == 'video') {
      return _videoCard(item);
    }

    if (type == 'prayer') {
      return _prayerCard(item);
    }

    return _postCard(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? NetworkErrorView(
        message: errorMessage,
        onRetry: () => _loadFeed(),
      )
          : Column(
        children: [
          if (selectedChurchId.isNotEmpty &&
              widget.initialChurchName != null &&
              widget.initialChurchName!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.church,
                      color: Color(0xFF0D47A1),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Mostrando contenido de ${widget.initialChurchName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openCreatePrayerRequest,
                icon: const Icon(Icons.volunteer_activism),
                label: const Text('Pedir oración'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          if (pendingNewItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _insertPendingItemsIntoFeed,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D47A1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.fiber_new,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          pendingNewItems.length == 1
                              ? 'Hay 1 publicación nueva'
                              : 'Hay ${pendingNewItems.length} publicaciones nuevas',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
              onRefresh: () => _loadFeed(),
              child: ListView.builder(
                controller: scrollController,
                padding:
                const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount:
                filteredItems.length + (isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= filteredItems.length) {
                    return const Padding(
                      padding:
                      EdgeInsets.symmetric(vertical: 18),
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