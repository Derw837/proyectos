import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/data/models/church_model.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_detail_screen.dart';
import 'package:red_cristiana/features/events/data/church_events_service.dart';
import 'package:red_cristiana/features/events/presentation/screens/event_detail_screen.dart';
import 'package:red_cristiana/core/widgets/network_error_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventsScreen extends StatefulWidget {
  final String? initialChurchId;
  final String? initialChurchName;
  final bool allowResetToGeneral;

  const EventsScreen({
    super.key,
    this.initialChurchId,
    this.initialChurchName,
    this.allowResetToGeneral = true,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool isLoading = true;
  bool nearMeOnly = false;
  bool hasError = false;
  String errorMessage = '';

  List<Map<String, dynamic>> allEvents = [];
  List<Map<String, dynamic>> filteredEvents = [];

  List<String> countries = [];
  List<String> cities = [];

  final searchController = TextEditingController();

  String selectedCountry = '';
  String selectedCity = '';
  String selectedChurchId = '';

  @override
  void initState() {
    super.initState();
    selectedChurchId = widget.initialChurchId ?? '';
    _loadEvents();
    searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
        errorMessage = '';
      });

      final data = await ChurchEventsService.getPublishedEvents();
      final countriesData =
      await ChurchEventsService.getAvailableEventCountries();
      final citiesData = await ChurchEventsService.getAvailableEventCities();

      if (!mounted) return;
      setState(() {
        allEvents = data;
        countries = countriesData;
        cities = citiesData;
        isLoading = false;
        hasError = false;
      });

      _applyCurrentFilters();
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

  Future<void> _toggleNearMe() async {
    if (nearMeOnly) {
      setState(() {
        nearMeOnly = false;
        selectedCountry = '';
        selectedCity = '';
        _applyFilters();
      });
      return;
    }

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

    setState(() {
      nearMeOnly = true;
      selectedCountry = myCountry;
      selectedCity = myCity;
      searchController.clear();
    });

    _applyFilters();
  }

  void _applyCurrentFilters() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();

    final results = allEvents.where((event) {
      final title = event['title']?.toString().toLowerCase() ?? '';
      final description = event['description']?.toString().toLowerCase() ?? '';
      final city = event['city']?.toString() ?? '';
      final country = event['country']?.toString() ?? '';
      final churchId = event['church_id']?.toString() ?? '';

      String churchName = '';
      final churchData = event['churches'];
      if (churchData is Map<String, dynamic>) {
        churchName = churchData['church_name']?.toString().toLowerCase() ?? '';
      }

      final matchesQuery = query.isEmpty ||
          title.contains(query) ||
          description.contains(query) ||
          churchName.contains(query) ||
          city.toLowerCase().contains(query) ||
          country.toLowerCase().contains(query);

      final matchesCountry =
          selectedCountry.isEmpty || country == selectedCountry;

      final matchesCity = selectedCity.isEmpty || city == selectedCity;

      final matchesChurch =
          selectedChurchId.isEmpty || churchId == selectedChurchId;

      return matchesQuery && matchesCountry && matchesCity && matchesChurch;
    }).toList();

    setState(() {
      filteredEvents = results;
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
                        const Icon(Icons.search, color: Colors.deepOrange),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Buscar eventos',
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
                        hintText: 'Evento, iglesia, ciudad...',
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
                        setSheetState(() => tempCountry = value ?? '');
                      },
                    ),
                    const SizedBox(height: 12),
                    dropdownFilter(
                      label: 'Ciudad',
                      value: tempCity,
                      items: cities,
                      icon: Icons.location_city,
                      onChanged: (value) {
                        setSheetState(() => tempCity = value ?? '');
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
                              backgroundColor: Colors.deepOrange,
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

  void _resetToGeneralEvents() {
    searchController.clear();

    setState(() {
      nearMeOnly = false;
      selectedCountry = '';
      selectedCity = '';
      selectedChurchId = '';
    });

    _applyFilters();
  }

  void _clearFilters() {
    searchController.clear();
    setState(() {
      nearMeOnly = false;
      selectedCountry = '';
      selectedCity = '';
      selectedChurchId = '';
    });
    _applyFilters();
  }

  Widget _eventCard(Map<String, dynamic> event) {
    final title = event['title']?.toString() ?? '';
    final description = event['description']?.toString() ?? '';
    final date = event['event_date']?.toString() ?? '';
    final city = event['city']?.toString() ?? '';
    final start = event['start_time']?.toString() ?? '';
    final end = event['end_time']?.toString() ?? '';
    final imageUrl = event['image_url']?.toString() ?? '';

    String churchName = '';
    ChurchModel? church;
    final churchData = event['churches'];

    if (churchData is Map<String, dynamic>) {
      churchName = churchData['church_name']?.toString() ?? '';
      church = ChurchModel.fromMap(churchData);
    }

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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(event: event),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              )
            else
              Container(
                width: double.infinity,
                height: 110,
                color: const Color(0xFFFFF3E0),
                child: const Icon(
                  Icons.event,
                  color: Colors.deepOrange,
                  size: 48,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Evento',
                          style: TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      if (date.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            date,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      height: 1.3,
                    ),
                  ),
                  if (churchName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      churchName,
                      style: const TextStyle(
                        color: Color(0xFF0D47A1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (city.isNotEmpty || start.isNotEmpty || end.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      [
                        if (city.isNotEmpty) city,
                        if (start.isNotEmpty || end.isNotEmpty)
                          '$start${end.isNotEmpty ? ' - $end' : ''}',
                      ].join(' • '),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(height: 1.45),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (church != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ChurchDetailScreen(church: church!),
                                ),
                              );
                            },
                            icon: const Icon(Icons.church_outlined),
                            label: const Text('Iglesia'),
                          ),
                        ),
                      if (church != null) const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailScreen(event: event),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Ver'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF7043),
            Color(0xFFF4511E),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.event_available, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Eventos cristianos',
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

  Widget _nearMeChip() {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ActionChip(
        onPressed: _toggleNearMe,
        avatar: Icon(
          nearMeOnly ? Icons.list_alt : Icons.near_me,
          size: 18,
          color: nearMeOnly ? Colors.white : null,
        ),
        label: Text(
          nearMeOnly ? 'Ver todos los eventos' : 'Cerca de ti',
          style: TextStyle(
            color: nearMeOnly ? Colors.white : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: nearMeOnly ? Colors.deepOrange : null,
      ),
    );
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
        onRetry: _loadEvents,
      )
          : Column(
        children: [
          _miniHeader(),
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
                    const Icon(Icons.event, color: Color(0xFF0D47A1)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Mostrando eventos de ${widget.initialChurchName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    if (widget.allowResetToGeneral)
                      TextButton(
                        onPressed: _resetToGeneralEvents,
                        child: const Text('Ver todos'),
                      ),
                  ],
                ),
              ),
            ),
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _searchChip(),
                _nearMeChip(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredEvents.isEmpty
                ? const Center(
              child: Text(
                'No hay eventos disponibles.',
                textAlign: TextAlign.center,
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadEvents,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) =>
                    _eventCard(filteredEvents[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}