import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/data/church_service.dart';
import 'package:red_cristiana/features/churches/data/models/church_model.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChurchesScreen extends StatefulWidget {
  const ChurchesScreen({super.key});

  @override
  State<ChurchesScreen> createState() => _ChurchesScreenState();
}

class _ChurchesScreenState extends State<ChurchesScreen> {
  final searchController = TextEditingController();

  bool isLoading = true;
  bool nearMeOnly = false;

  List<ChurchModel> allChurches = [];
  List<ChurchModel> filteredChurches = [];

  List<String> countries = [];
  List<String> cities = [];
  List<String> sectors = [];

  String selectedCountry = '';
  String selectedCity = '';
  String selectedSector = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final churchesResponse = await ChurchService.getApprovedChurches();
      final countriesResponse = await ChurchService.getAvailableCountries();
      final citiesResponse = await ChurchService.getAvailableCities();
      final sectorsResponse = await ChurchService.getAvailableSectors();

      final churches = churchesResponse
          .map((item) => ChurchModel.fromMap(item))
          .toList();

      if (!mounted) return;

      setState(() {
        allChurches = churches;
        filteredChurches = churches;
        countries = countriesResponse;
        cities = citiesResponse;
        sectors = sectorsResponse;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando iglesias: $e')),
      );
    }
  }

  Future<void> _showNearMe() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('country, city')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) return;

    final myCountry = profile['country']?.toString() ?? '';
    final myCity = profile['city']?.toString() ?? '';

    final results = allChurches.where((church) {
      return church.country == myCountry && church.city == myCity;
    }).toList();

    setState(() {
      nearMeOnly = true;
      selectedCountry = myCountry;
      selectedCity = myCity;
      filteredChurches = results;
    });
  }

  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();

    final results = allChurches.where((church) {
      final matchesQuery = query.isEmpty ||
          church.churchName.toLowerCase().contains(query) ||
          church.city.toLowerCase().contains(query) ||
          church.country.toLowerCase().contains(query) ||
          church.sector.toLowerCase().contains(query) ||
          church.pastorName.toLowerCase().contains(query);

      final matchesCountry =
          selectedCountry.isEmpty || church.country == selectedCountry;

      final matchesCity = selectedCity.isEmpty || church.city == selectedCity;

      final matchesSector =
          selectedSector.isEmpty || church.sector == selectedSector;

      return matchesQuery && matchesCountry && matchesCity && matchesSector;
    }).toList();

    setState(() {
      filteredChurches = results;
    });
  }

  void _clearFilters() {
    searchController.clear();
    setState(() {
      nearMeOnly = false;
      selectedCountry = '';
      selectedCity = '';
      selectedSector = '';
      filteredChurches = allChurches;
    });
  }

  Future<void> _openSearchSheet() async {
    final tempSearchController =
    TextEditingController(text: searchController.text);

    String tempCountry = selectedCountry;
    String tempCity = selectedCity;
    String tempSector = selectedSector;

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
                            'Buscar iglesias',
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
                        hintText: 'Nombre, pastor, ciudad...',
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
                    const SizedBox(height: 12),
                    dropdownFilter(
                      label: 'Sector',
                      value: tempSector,
                      items: sectors,
                      icon: Icons.map_outlined,
                      onChanged: (value) {
                        setSheetState(() {
                          tempSector = value ?? '';
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
                                tempSector = '';
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
                                selectedSector = tempSector;
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
          Icon(Icons.church, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Iglesias cristianas',
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

  Widget _searchChip() {
    final hasFilters = searchController.text.trim().isNotEmpty ||
        selectedCountry.isNotEmpty ||
        selectedCity.isNotEmpty ||
        selectedSector.isNotEmpty;

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

  Widget _nearMeChip() {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ActionChip(
        onPressed: _showNearMe,
        avatar: const Icon(Icons.near_me, size: 18),
        label: Text(nearMeOnly ? 'Cerca de ti activo' : 'Cerca de ti'),
      ),
    );
  }

  Widget _clearChip() {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ActionChip(
        onPressed: _clearFilters,
        avatar: const Icon(Icons.clear_all, size: 18),
        label: const Text('Limpiar'),
      ),
    );
  }

  Widget _churchCard(ChurchModel church) {
    final location = [
      if (church.city.isNotEmpty) church.city,
      if (church.country.isNotEmpty) church.country,
    ].join(', ');

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChurchDetailScreen(church: church),
          ),
        );
      },
      child: Container(
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
          children: [
            if (church.coverUrl != null && church.coverUrl!.isNotEmpty)
              Image.network(
                church.coverUrl!,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: double.infinity,
                  height: 140,
                  color: const Color(0xFFEAF4FF),
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Color(0xFF0D47A1),
                    size: 40,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 95,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0D47A1),
                      Color(0xFF1565C0),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.church,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4FF),
                      borderRadius: BorderRadius.circular(18),
                      image: church.logoUrl != null && church.logoUrl!.isNotEmpty
                          ? DecorationImage(
                        image: NetworkImage(church.logoUrl!),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: (church.logoUrl == null || church.logoUrl!.isEmpty)
                        ? const Icon(
                      Icons.church,
                      color: Color(0xFF0D47A1),
                      size: 32,
                    )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          church.churchName,
                          style: const TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        if (church.pastorName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Pastor: ${church.pastorName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF0D47A1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                        if (church.sector.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF4FF),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  church.sector,
                                  style: const TextStyle(
                                    color: Color(0xFF0D47A1),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (church.description.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            church.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _miniHeader(),
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _searchChip(),
                _nearMeChip(),
                _clearChip(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredChurches.isEmpty
                ? const Center(
              child: Text(
                'No se encontraron iglesias con esos filtros.',
                textAlign: TextAlign.center,
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: filteredChurches.length,
                itemBuilder: (context, index) {
                  return _churchCard(filteredChurches[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}