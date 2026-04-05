import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/data/church_prayer_requests_service.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/church_header_shell.dart';

class ChurchPrayerRequestsScreen extends StatefulWidget {
  const ChurchPrayerRequestsScreen({super.key});

  @override
  State<ChurchPrayerRequestsScreen> createState() =>
      _ChurchPrayerRequestsScreenState();
}

class _ChurchPrayerRequestsScreenState
    extends State<ChurchPrayerRequestsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> requests = [];
  List<Map<String, dynamic>> filtered = [];

  String selectedCategory = 'all';
  String selectedPeriod = 'today';

  final categories = const [
    {'value': 'all', 'label': 'Todas'},
    {'value': 'salud', 'label': 'Salud'},
    {'value': 'familia', 'label': 'Familia'},
    {'value': 'hijos', 'label': 'Hijos'},
    {'value': 'trabajo', 'label': 'Trabajo'},
    {'value': 'estudios', 'label': 'Estudios'},
    {'value': 'finanzas', 'label': 'Finanzas'},
    {'value': 'proteccion', 'label': 'Protección'},
    {'value': 'matrimonio', 'label': 'Matrimonio'},
    {'value': 'direccion', 'label': 'Dirección de Dios'},
    {'value': 'paz', 'label': 'Paz'},
    {'value': 'sanidad_emocional', 'label': 'Sanidad emocional'},
    {'value': 'fortaleza_espiritual', 'label': 'Fortaleza espiritual'},
    {'value': 'liberacion', 'label': 'Liberación'},
  ];

  final periods = const [
    {'value': 'today', 'label': 'Hoy'},
    {'value': 'week', 'label': 'Esta semana'},
    {'value': 'month', 'label': 'Este mes'},
    {'value': 'past_months', 'label': 'Meses anteriores'},
    {'value': 'year', 'label': 'Este año'},
    {'value': 'all', 'label': 'Todo'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data =
      await ChurchPrayerRequestsService.getPrayerRequestsForMyChurch();

      if (!mounted) return;

      setState(() {
        requests = data;
        isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando peticiones: $e')),
      );
    }
  }

  bool _matchesPeriod(DateTime date) {
    final now = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);

    switch (selectedPeriod) {
      case 'today':
        return dateOnly == today;
      case 'week':
        final difference = today.difference(dateOnly).inDays;
        return difference >= 0 && difference < 7;
      case 'month':
        return date.year == now.year && date.month == now.month;
      case 'past_months':
        return date.year == now.year && date.month != now.month;
      case 'year':
        return date.year == now.year;
      case 'all':
      default:
        return true;
    }
  }

  void _applyFilters() {
    final results = requests.where((r) {
      final category = r['category']?.toString() ?? '';
      final createdAt = r['created_at']?.toString() ?? '';
      final createdDate =
          DateTime.tryParse(createdAt) ?? DateTime(2000);

      final matchesCategory =
          selectedCategory == 'all' || category == selectedCategory;

      final matchesPeriod = _matchesPeriod(createdDate);

      return matchesCategory && matchesPeriod;
    }).toList();

    setState(() {
      filtered = results;
    });
  }

  Widget _filterBox({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
          value: item['value'],
          child: Text(item['label'] ?? ''),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _statusChip(bool isMember) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isMember ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isMember ? 'Miembro' : 'No miembro',
        style: TextStyle(
          color: isMember ? const Color(0xFF2E7D32) : Colors.deepOrange,
          fontWeight: FontWeight.bold,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _chip(String text, IconData icon, {Color? color}) {
    final chipColor = color ?? const Color(0xFFEAF4FF);
    final textColor = color == null ? const Color(0xFF0D47A1) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSupport(Map<String, dynamic> item) async {
    final prayerId = item['prayer_request_id']?.toString() ?? '';
    if (prayerId.isEmpty) return;

    await ChurchPrayerRequestsService.toggleChurchPrayerSupport(prayerId);
    await _load();
  }

  Widget _requestCard(Map<String, dynamic> r) {
    final category =
    ChurchPrayerRequestsService.categoryLabel(r['category'] ?? '');
    final isForMe = r['is_for_me'] == true;
    final fullName = (r['full_name'] ?? '').toString().trim();
    final author = (r['prayer_author_name'] ?? 'Usuario').toString();
    final count = r['requested_count'] ?? 1;
    final isMember = r['is_member_of_my_church'] == true;
    final supported = r['supported_by_my_church'] == true;
    final createdAt = (r['created_at'] ?? '').toString();
    final createdDate = createdAt.isNotEmpty
        ? createdAt.split('T').first
        : 'Sin fecha';

    final description = isForMe
        ? '$author pide oración por su $category.'
        : '$author pide oración por $fullName por $category.';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _statusChip(isMember),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(category, Icons.category_outlined),
              _chip('$count solicitudes', Icons.people_outline),
              _chip(createdDate, Icons.calendar_today_outlined),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => _toggleSupport(r),
              icon: Icon(
                supported ? Icons.check_circle : Icons.volunteer_activism,
              ),
              label: Text(
                supported
                    ? 'La iglesia está orando'
                    : 'Marcar que la iglesia ora',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                supported ? Colors.green : const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.volunteer_activism_outlined,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              filtered.length == 1
                  ? 'Hay 1 petición en esta vista'
                  : 'Hay ${filtered.length} peticiones en esta vista',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChurchHeaderShell(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text('Peticiones de oración'),
          backgroundColor: const Color(0xFFF7F9FC),
          centerTitle: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            children: [
              _filterBox(
                label: 'Filtrar por tiempo',
                value: selectedPeriod,
                items: periods,
                icon: Icons.date_range_outlined,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedPeriod = value;
                  });
                  _applyFilters();
                },
              ),
              const SizedBox(height: 12),
              _filterBox(
                label: 'Filtrar por categoría',
                value: selectedCategory,
                items: categories,
                icon: Icons.filter_list,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedCategory = value;
                  });
                  _applyFilters();
                },
              ),
              const SizedBox(height: 12),
              _topSummary(),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'No hay peticiones con esos filtros.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...filtered.map(_requestCard),
            ],
          ),
        ),
      ),
    );
  }
}