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
  static const Color _primary = Color(0xFF0D47A1);
  static const Color _primaryLight = Color(0xFF1565C0);
  static const Color _surface = Color(0xFFF4F7FB);
  static const Color _card = Colors.white;
  static const Color _textDark = Color(0xFF152033);
  static const Color _textSoft = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE6EDF6);

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
      final createdDate = DateTime.tryParse(createdAt) ?? DateTime(2000);

      final matchesCategory =
          selectedCategory == 'all' || category == selectedCategory;
      final matchesPeriod = _matchesPeriod(createdDate);

      return matchesCategory && matchesPeriod;
    }).toList();

    setState(() {
      filtered = results;
    });
  }

  Future<void> _toggleSupport(Map<String, dynamic> item) async {
    final prayerId = item['prayer_request_id']?.toString() ?? '';
    if (prayerId.isEmpty) return;

    await ChurchPrayerRequestsService.toggleChurchPrayerSupport(prayerId);
    await _load();
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: _textSoft,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220D47A1),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Peticiones de oración',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroChip(
                icon: Icons.volunteer_activism_outlined,
                text: '${requests.length} total',
              ),
              _heroChip(
                icon: Icons.filter_alt_outlined,
                text: '${filtered.length} visibles',
              ),
              _heroChip(
                icon: Icons.favorite_outline,
                text: 'Apoyo pastoral',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
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
        labelStyle: const TextStyle(
          color: _textSoft,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: _primary),
        filled: true,
        fillColor: _card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _primary, width: 1.2),
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

  Widget _summaryCard() {
    final categoryText = categories.firstWhere(
          (c) => c['value'] == selectedCategory,
      orElse: () => {'value': 'all', 'label': 'Todas'},
    )['label'];

    final periodText = periods.firstWhere(
          (p) => p['value'] == selectedPeriod,
      orElse: () => {'value': 'all', 'label': 'Todo'},
    )['label'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
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
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.insights_outlined,
              color: _primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filtered.length == 1
                      ? '1 petición en esta vista'
                      : '${filtered.length} peticiones en esta vista',
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Filtro: $periodText • $categoryText',
                  style: const TextStyle(
                    color: _textSoft,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(bool isMember) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMember ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isMember ? 'Miembro' : 'No miembro',
        style: TextStyle(
          color: isMember ? const Color(0xFF2E7D32) : Colors.deepOrange,
          fontWeight: FontWeight.w800,
          fontSize: 11.8,
        ),
      ),
    );
  }

  Widget _chip(
      String text,
      IconData icon, {
        Color? bgColor,
        Color? textColor,
      }) {
    final resolvedBg = bgColor ?? const Color(0xFFEAF2FF);
    final resolvedText = textColor ?? _primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: resolvedText),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: resolvedText,
              fontWeight: FontWeight.w700,
              fontSize: 11.8,
            ),
          ),
        ],
      ),
    );
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
    final createdDate =
    createdAt.isNotEmpty ? createdAt.split('T').first : 'Sin fecha';

    final description = isForMe
        ? '$author pide oración por su $category.'
        : '$author pide oración por $fullName por $category.';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  description,
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.6,
                    height: 1.3,
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
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 47,
            child: ElevatedButton.icon(
              onPressed: () => _toggleSupport(r),
              icon: Icon(
                supported ? Icons.check_circle_outline : Icons.favorite_outline,
              ),
              label: Text(
                supported
                    ? 'La iglesia está orando'
                    : 'Marcar que la iglesia ora',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.8,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                supported ? const Color(0xFF2E7D32) : _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.volunteer_activism_outlined,
              size: 34,
              color: _primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No hay peticiones con esos filtros',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textDark,
              fontSize: 16.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Prueba otro período o una categoría distinta para ver más resultados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSoft,
              fontSize: 13.2,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _heroCard(),
          const SizedBox(height: 18),
          _sectionTitle(
            'Filtros',
            'Selecciona el período y la categoría que deseas revisar.',
          ),
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
          _summaryCard(),
          const SizedBox(height: 20),
          _sectionTitle(
            'Listado de peticiones',
            'Visualiza y marca cuáles están siendo atendidas por la iglesia.',
          ),
          if (filtered.isEmpty)
            _emptyState()
          else
            ...filtered.map(_requestCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChurchHeaderShell(
      child: Scaffold(
        backgroundColor: _surface,
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _content(),
      ),
    );
  }
}