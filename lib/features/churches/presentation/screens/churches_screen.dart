import 'package:flutter/material.dart';
import 'package:red_cristiana/core/utils/app_error_helper.dart';
import 'package:red_cristiana/core/widgets/network_error_view.dart';
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
  static const Color _primary = Color(0xFF0D47A1);
  static const Color _primaryLight = Color(0xFF1565C0);
  static const Color _surface = Color(0xFFF4F7FB);
  static const Color _card = Colors.white;
  static const Color _textDark = Color(0xFF152033);
  static const Color _textSoft = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE6EDF6);

  final searchController = TextEditingController();

  bool isLoading = true;
  bool nearMeOnly = false;
  bool hasError = false;
  String errorMessage = '';

  List<ChurchModel> allChurches = [];
  List<ChurchModel> filteredChurches = [];

  List<String> countries = [];
  List<String> cities = [];
  List<String> sectors = [];

  String selectedCountry = '';
  String selectedCity = '';
  String selectedSector = '';
  String profileCountry = '';
  String profileCity = '';
  String profileSector = '';

  bool showingCityFallback = false;
  bool showingCountryFallback = false;
  bool showingSectorSuggestion = false;

  int cityMatchesCount = 0;
  int countryMatchesCount = 0;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
  _recalculateChurches();
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
      .replaceAll(RegExp(r'\s+'), ' ');
}

bool _matchesLoose(String source, String target) {
  final a = _normalizeText(source);
  final b = _normalizeText(target);

  if (a.isEmpty || b.isEmpty) return false;

  return a == b || a.contains(b) || b.contains(a);
}

void _recalculateChurches() {
  final query = searchController.text.trim().toLowerCase();

  final base = allChurches.where((church) {
    final matchesQuery = query.isEmpty ||
        church.churchName.toLowerCase().contains(query) ||
        church.city.toLowerCase().contains(query) ||
        church.country.toLowerCase().contains(query) ||
        church.sector.toLowerCase().contains(query) ||
        church.pastorName.toLowerCase().contains(query);

    final matchesCountry =
        selectedCountry.isEmpty || _matchesLoose(church.country, selectedCountry);

    final matchesCity =
        selectedCity.isEmpty || _matchesLoose(church.city, selectedCity);

    return matchesQuery && matchesCountry && matchesCity;
  }).toList();

  final cityBase = base;
  final countryBase = allChurches.where((church) {
    final matchesQuery = query.isEmpty ||
        church.churchName.toLowerCase().contains(query) ||
        church.city.toLowerCase().contains(query) ||
        church.country.toLowerCase().contains(query) ||
        church.sector.toLowerCase().contains(query) ||
        church.pastorName.toLowerCase().contains(query);

    final matchesCountry =
        selectedCountry.isEmpty || _matchesLoose(church.country, selectedCountry);

    return matchesQuery && matchesCountry;
  }).toList();

  List<ChurchModel> result = [];
  bool cityFallback = false;
  bool countryFallback = false;
  bool sectorSuggestion = false;

  int cityCount = cityBase.length;
  int countryCount = countryBase.length;

  if (selectedSector.trim().isNotEmpty) {
    final sectorResults = cityBase.where((church) {
      return _matchesLoose(church.sector, selectedSector);
    }).toList();

    if (sectorResults.isNotEmpty) {
      result = sectorResults;

      if (selectedCity.trim().isNotEmpty &&
          cityBase.length > sectorResults.length &&
          sectorResults.length <= 2) {
        sectorSuggestion = true;
      }
    } else {
      if (selectedCity.trim().isNotEmpty && cityBase.isNotEmpty) {
        result = cityBase;
        cityFallback = true;
      } else if (selectedCountry.trim().isNotEmpty && countryBase.isNotEmpty) {
        result = countryBase;
        countryFallback = true;
      } else {
        result = [];
      }
    }
  } else {
    result = cityBase;
  }

  if (!mounted) return;

  setState(() {
    filteredChurches = result;
    showingCityFallback = cityFallback;
    showingCountryFallback = countryFallback;
    showingSectorSuggestion = sectorSuggestion;
    cityMatchesCount = cityCount;
    countryMatchesCount = countryCount;
  });
}

  List<ChurchModel> _getFilteredChurches() {
  return filteredChurches;
}

  List<String> _uniqueSorted(List<String> items) {
    final map = <String, String>{};

    for (final item in items) {
      final trimmed = item.trim();
      if (trimmed.isEmpty) continue;

      final key = _normalizeText(trimmed);
      map.putIfAbsent(key, () => trimmed);
    }

    final result = map.values.toList();
    result.sort((a, b) => _normalizeText(a).compareTo(_normalizeText(b)));
    return result;
  }

  List<String> _availableCitiesForCountry(String country) {
    final source = country.trim().isEmpty
        ? allChurches
        : allChurches.where((church) {
      return _normalizeText(church.country) == _normalizeText(country);
    }).toList();

    return _uniqueSorted(
      source.map((church) => church.city).where((e) => e.trim().isNotEmpty).toList(),
    );
  }

  List<String> _availableSectors({
    required String country,
    required String city,
  }) {
    final source = allChurches.where((church) {
      final countryMatch = country.trim().isEmpty
          ? true
          : _normalizeText(church.country) == _normalizeText(country);

      final cityMatch = city.trim().isEmpty
          ? true
          : _normalizeText(church.city) == _normalizeText(city);

      return countryMatch && cityMatch;
    }).toList();

    return _uniqueSorted(
      source.map((church) => church.sector).where((e) => e.trim().isNotEmpty).toList(),
    );
  }

  Future<void> _loadData() async {
  try {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
    });

    final user = Supabase.instance.client.auth.currentUser;

    final churchesResponse = await ChurchService.getApprovedChurches();
    final countriesResponse = await ChurchService.getAvailableCountries();
    final citiesResponse = await ChurchService.getAvailableCities();
    final sectorsResponse = await ChurchService.getAvailableSectors();

    Map<String, dynamic>? profile;
    if (user != null) {
      profile = await Supabase.instance.client
          .from('profiles')
          .select('country, city, sector')
          .eq('id', user.id)
          .maybeSingle();
    }

    final churches = churchesResponse
        .map((item) => ChurchModel.fromMap(item))
        .toList();

    if (!mounted) return;

    allChurches = churches;
    countries = countriesResponse;
    cities = citiesResponse;
    sectors = sectorsResponse;

    profileCountry = profile?['country']?.toString() ?? '';
    profileCity = profile?['city']?.toString() ?? '';
    profileSector = profile?['sector']?.toString() ?? '';

    setState(() {
      isLoading = false;
      hasError = false;
    });

    _recalculateChurches();
  } catch (e) {
    if (!mounted) return;

    final message = await AppErrorHelper.friendlyMessage(
      e,
      fallback: 'No se pudieron cargar las iglesias en este momento.',
    );

    setState(() {
      isLoading = false;
      hasError = true;
      errorMessage = message;
    });
  }
}

  Future<void> _toggleNearMe() async {
    if (nearMeOnly) {
      if (!mounted) return;
      setState(() {
        nearMeOnly = false;
        selectedCountry = '';
        selectedCity = '';
        selectedSector = '';
      });

      _recalculateChurches();
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('country, city, sector')
        .eq('id', user.id)
        .maybeSingle();

    if (!mounted || profile == null) return;

    final myCountry = profile['country']?.toString() ?? '';
    final myCity = profile['city']?.toString() ?? '';
    final mySector = profile['sector']?.toString() ?? '';

    setState(() {
      nearMeOnly = true;
      selectedCountry = myCountry;
      selectedCity = myCity;
      selectedSector = mySector;
      searchController.clear();
    });

    _recalculateChurches();
  }

  void _clearFilters() {
    searchController.clear();

    if (!mounted) return;
    setState(() {
      nearMeOnly = false;
      selectedCountry = '';
      selectedCity = '';
      selectedSector = '';
    });

    _recalculateChurches();
  }

  Future<void> _openSearchSheet() async {
    final result = await showModalBottomSheet<_SearchSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final tempSearchController =
        TextEditingController(text: searchController.text);

        String tempCountry = selectedCountry;
        String tempCity = selectedCity;
        String tempSector = selectedSector;

        final modalCities = _availableCitiesForCountry(tempCountry);

        final modalSectors = _availableSectors(
          country: tempCountry,
          city: tempCity,
        );

        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget dropdownFilter({
              required String label,
              required String value,
              required List<String> items,
              required ValueChanged<String?> onChanged,
              required IconData icon,
            }) {
              final safeItems = _uniqueSorted(items);
              final safeValue =
              value.isEmpty || !safeItems.contains(value) ? null : value;

              return DropdownButtonFormField<String>(
                value: safeValue,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(
                    color: _textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: Icon(icon, color: _primary),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: _primary, width: 1.2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: _border),
                  ),
                ),
                items: safeItems
                    .map(
                      (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                    .toList(),
                onChanged: onChanged,
              );
            }

            return Container(
              decoration: const BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCAD5E5),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primary, _primaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Buscar iglesias',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Busca por nombre, pastor o ubicación y aplica filtros para encontrar iglesias más rápido.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13.2,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: tempSearchController,
                          decoration: InputDecoration(
                            hintText: 'Nombre, pastor, ciudad...',
                            hintStyle: const TextStyle(
                              color: _textSoft,
                            ),
                            prefixIcon:
                            const Icon(Icons.search, color: _primary),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: _border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: _primary,
                                width: 1.2,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: _border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        dropdownFilter(
                          label: 'País',
                          value: tempCountry,
                          items: _uniqueSorted(countries),
                          icon: Icons.public,
                          onChanged: (value) {
                            setSheetState(() {
                              tempCountry = value ?? '';
                              tempCity = '';
                              tempSector = '';
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        dropdownFilter(
                          label: 'Ciudad',
                          value: tempCity,
                          items: modalCities,
                          icon: Icons.location_city,
                          onChanged: (value) {
                            setSheetState(() {
                              tempCity = value ?? '';
                              tempSector = '';
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        dropdownFilter(
                          label: 'Sector',
                          value: tempSector,
                          items: modalSectors,
                          icon: Icons.map_outlined,
                          onChanged: (value) {
                            setSheetState(() {
                              tempSector = value ?? '';
                            });
                          },
                        ),
                        const SizedBox(height: 18),
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
                                label: const Text(
                                  'Limpiar',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _primary,
                                  side: const BorderSide(color: _border),
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
                                  Navigator.of(sheetContext).pop(
                                    _SearchSheetResult(
                                      search: tempSearchController.text.trim(),
                                      country: tempCountry,
                                      city: tempCity,
                                      sector: tempSector,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check),
                                label: const Text(
                                  'Aplicar',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
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
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      nearMeOnly = false;
      selectedCountry = result.country;
      selectedCity = result.city;
      selectedSector = result.sector;
      searchController.text = result.search;
    });

    _recalculateChurches();
  }

  Widget _heroCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2962FF),
            Color(0xFF0D47A1),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.church, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Iglesias',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${allChurches.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBar() {
    final hasManualFilters = searchController.text.trim().isNotEmpty ||
        (!nearMeOnly &&
            (selectedCountry.isNotEmpty ||
                selectedCity.isNotEmpty ||
                selectedSector.isNotEmpty));

    final hasAnythingActive = nearMeOnly ||
        searchController.text.trim().isNotEmpty ||
        selectedCountry.isNotEmpty ||
        selectedCity.isNotEmpty ||
        selectedSector.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _openSearchSheet,
              icon: Icon(
                hasManualFilters ? Icons.tune : Icons.search,
                color: _primary,
              ),
              label: Text(
                hasManualFilters ? 'Editar búsqueda' : 'Buscar',
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: _border),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _toggleNearMe,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: nearMeOnly ? _primary : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: nearMeOnly ? _primary : _border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    nearMeOnly ? Icons.list_alt : Icons.near_me_outlined,
                    size: 18,
                    color: nearMeOnly ? Colors.white : _primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    nearMeOnly ? 'Todas' : 'Cerca',
                    style: TextStyle(
                      color: nearMeOnly ? Colors.white : _primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasAnythingActive) ...[
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _clearFilters,
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.clear_all,
                      size: 18,
                      color: _primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Limpiar',
                      style: TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

    Widget _suggestionCard() {
      if (!showingCityFallback &&
          !showingCountryFallback &&
          !showingSectorSuggestion) {
        return const SizedBox.shrink();
      }

      String title = '';
      String subtitle = '';
      String primaryLabel = '';
      VoidCallback? primaryAction;
      String? secondaryLabel;
      VoidCallback? secondaryAction;

      if (showingSectorSuggestion) {
        final extra = cityMatchesCount - filteredChurches.length;
        title = 'Encontramos iglesias en tu sector';
        subtitle = extra > 0
            ? 'Además, en tu ciudad hay $extra iglesias más. ¿Quieres verlas?'
            : 'También puedes ver todas las iglesias de tu ciudad.';
        primaryLabel = 'Ver iglesias de mi ciudad';
        primaryAction = () {
          setState(() {
            selectedSector = '';
          });
          _recalculateChurches();
        };

        if (selectedCountry.trim().isNotEmpty) {
          secondaryLabel = 'Ver todas las de mi país';
          secondaryAction = () {
            setState(() {
              selectedCity = '';
              selectedSector = '';
            });
            _recalculateChurches();
          };
        }
      } else if (showingCityFallback) {
        title = 'No encontramos iglesias en tu sector';
        subtitle =
        'Pero sí encontramos $cityMatchesCount iglesias en tu ciudad.';
        primaryLabel = 'Ver solo las de mi ciudad';
        primaryAction = () {
          setState(() {
            selectedSector = '';
          });
          _recalculateChurches();
        };

        if (selectedCountry.trim().isNotEmpty) {
          secondaryLabel = 'Ver todas las de mi país';
          secondaryAction = () {
            setState(() {
              selectedCity = '';
              selectedSector = '';
            });
            _recalculateChurches();
          };
        }
      } else if (showingCountryFallback) {
        title = 'No encontramos iglesias en tu sector o ciudad';
        subtitle =
        'Pero sí encontramos $countryMatchesCount iglesias en tu país.';
        primaryLabel = 'Ver iglesias de mi país';
        primaryAction = () {
          setState(() {
            selectedCity = '';
            selectedSector = '';
          });
          _recalculateChurches();
        };
      }

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: _primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sugerencia',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: _textDark,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: _textSoft,
                fontSize: 13.2,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: primaryAction,
                  icon: const Icon(Icons.location_city),
                  label: Text(primaryLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                if (secondaryLabel != null && secondaryAction != null)
                  OutlinedButton.icon(
                    onPressed: secondaryAction,
                    icon: const Icon(Icons.public),
                    label: Text(secondaryLabel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
              ],
            ),
          ],
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
          color: _card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
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
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _coverPlaceholder(),
              )
            else
              _coverPlaceholder(),
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
                      color: _primary,
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
                            color: _textDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        if (church.pastorName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Pastor: ${church.pastorName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.2,
                            ),
                          ),
                        ],
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: _textSoft,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _textSoft,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (church.sector.isNotEmpty) ...[
                          const SizedBox(height: 8),
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
                                    color: _primary,
                                    fontSize: 12.2,
                                    fontWeight: FontWeight.w800,
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
                              color: _textSoft,
                              fontSize: 13.2,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F8FC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _border),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_forward_outlined,
                                size: 18,
                                color: _primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Ver iglesia',
                                style: TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primaryLight],
        ),
      ),
      child: const Icon(
        Icons.church,
        color: Colors.white,
        size: 42,
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.search_off_outlined,
                size: 40,
                color: _primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No se encontraron iglesias',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Prueba otra búsqueda o cambia los filtros para ver más resultados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSoft,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.restart_alt),
              label: const Text(
                'Limpiar filtros',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

    Widget _content() {
      return Column(
        children: [
          _heroCard(),
          _actionBar(),
          _suggestionCard(),
          Expanded(
            child: filteredChurches.isEmpty
                ? _emptyState()
                : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: filteredChurches.length,
                itemBuilder: (context, index) {
                  return _churchCard(filteredChurches[index]);
                },
              ),
            ),
          ),
        ],
      );
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? NetworkErrorView(
        message: errorMessage,
        onRetry: _loadData,
      )
          : _content(),
    );
  }
}

class _SearchSheetResult {
  final String search;
  final String country;
  final String city;
  final String sector;

  const _SearchSheetResult({
    required this.search,
    required this.country,
    required this.city,
    required this.sector,
  });
}