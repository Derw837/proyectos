import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:red_cristiana/core/utils/app_error_helper.dart';
import 'package:red_cristiana/features/churches/data/church_dashboard_service.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/church_header_shell.dart';

class ChurchMembersScreen extends StatefulWidget {
  const ChurchMembersScreen({super.key});

  @override
  State<ChurchMembersScreen> createState() => _ChurchMembersScreenState();
}

class _ChurchMembersScreenState extends State<ChurchMembersScreen> {
  static const Color _primary = Color(0xFF0D47A1);
  static const Color _primaryLight = Color(0xFF1565C0);
  static const Color _surface = Color(0xFFF4F7FB);
  static const Color _card = Colors.white;
  static const Color _textDark = Color(0xFF152033);
  static const Color _textSoft = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE6EDF6);

  bool isLoading = true;
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> filteredMembers = [];
  final TextEditingController searchController = TextEditingController();

  int currentPage = 1;
  int itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final data = await ChurchDashboardService.getMyMembers();

      if (!mounted) return;

      setState(() {
        members = data;
        filteredMembers = data;
        currentPage = 1;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(await AppErrorHelper.friendlyMessage(e, fallback: 'No se pudieron cargar los miembros en este momento.'))),
      );
    }
  }

  void _filterMembers() {
    final query = searchController.text.trim().toLowerCase();

    setState(() {
      filteredMembers = members.where((member) {
        final profile = member['profile'] as Map<String, dynamic>?;
        final fullName = profile?['full_name']?.toString().toLowerCase() ?? '';
        final country = profile?['country']?.toString().toLowerCase() ?? '';
        final city = profile?['city']?.toString().toLowerCase() ?? '';
        final sector = profile?['sector']?.toString().toLowerCase() ?? '';

        return fullName.contains(query) ||
            country.contains(query) ||
            city.contains(query) ||
            sector.contains(query);
      }).toList();

      currentPage = 1;
    });
  }

  String _memberName(Map<String, dynamic>? profile) {
    final fullName = profile?['full_name']?.toString().trim() ?? '';
    if (fullName.isNotEmpty) return fullName;
    return 'Miembro sin nombre';
  }

  String _locationText(Map<String, dynamic>? profile) {
    final city = profile?['city']?.toString().trim() ?? '';
    final country = profile?['country']?.toString().trim() ?? '';

    final parts = [
      if (city.isNotEmpty) city,
      if (country.isNotEmpty) country,
    ];

    return parts.join(', ');
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'M';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  int get _totalPages {
    if (filteredMembers.isEmpty) return 1;
    return (filteredMembers.length / itemsPerPage).ceil();
  }

  List<Map<String, dynamic>> get _paginatedMembers {
    final start = (currentPage - 1) * itemsPerPage;
    final end = math.min(start + itemsPerPage, filteredMembers.length);

    if (start >= filteredMembers.length) return [];
    return filteredMembers.sublist(start, end);
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
    final total = members.length;
    final filtered = filteredMembers.length;

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
            'Miembros',
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
                icon: Icons.groups_outlined,
                text: '$total total',
              ),
              _heroChip(
                icon: Icons.search_outlined,
                text: '$filtered visibles',
              ),
              _heroChip(
                icon: Icons.verified_user_outlined,
                text: 'Comunidad activa',
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

  Widget _searchBox() {
    return Container(
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
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Buscar miembro, ciudad, país o sector...',
          hintStyle: const TextStyle(
            color: _textSoft,
            fontSize: 13.5,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: _primary,
          ),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
            onPressed: () {
              searchController.clear();
              _filterMembers();
            },
            icon: const Icon(Icons.close),
          )
              : null,
          filled: true,
          fillColor: _card,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: _primary, width: 1.3),
          ),
        ),
      ),
    );
  }

  Widget _compactPaginationBar() {
    final pageOptions = <int>[10, 20, 50];

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: currentPage > 1
                ? () {
              setState(() {
                currentPage--;
              });
            }
                : null,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: currentPage > 1 ? const Color(0xFFEAF2FF) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: currentPage > 1 ? _primary : Colors.black26,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$currentPage / $_totalPages',
              style: const TextStyle(
                color: _primary,
                fontSize: 12.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: currentPage < _totalPages
                ? () {
              setState(() {
                currentPage++;
              });
            }
                : null,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: currentPage < _totalPages ? _primary : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: currentPage < _totalPages ? Colors.white : Colors.black26,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: itemsPerPage,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: _textSoft,
                ),
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 12.2,
                  fontWeight: FontWeight.w700,
                ),
                items: pageOptions.map((value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    itemsPerPage = value;
                    currentPage = 1;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 11.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color: _textSoft,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _textSoft,
              fontSize: 13.1,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _memberCard(Map<String, dynamic> member) {
    final profile = member['profile'] as Map<String, dynamic>?;
    final membership = member['membership'] as Map<String, dynamic>?;

    final fullName = _memberName(profile);
    final initials = _getInitials(fullName);
    final location = _locationText(profile);
    final sector = profile?['sector']?.toString().trim() ?? '';
    final createdAt = membership?['created_at']?.toString() ?? '';

    final hasProfileData = profile != null;
    final joinedDate =
    createdAt.isNotEmpty ? createdAt.split('T').first : 'No disponible';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEAF2FF), Color(0xFFDDEBFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: _primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _infoChip(
                      icon: Icons.verified_user_outlined,
                      text: 'Miembro',
                      bgColor: const Color(0xFFE8F5E9),
                      textColor: const Color(0xFF2E7D32),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                if (location.isNotEmpty)
                  _detailRow(
                    icon: Icons.location_on_outlined,
                    text: location,
                  ),
                if (sector.isNotEmpty) ...[
                  if (location.isNotEmpty) const SizedBox(height: 5),
                  _detailRow(
                    icon: Icons.map_outlined,
                    text: 'Sector: $sector',
                  ),
                ],
                if (location.isEmpty && sector.isEmpty)
                  _detailRow(
                    icon: Icons.info_outline,
                    text: 'Este miembro todavía no tiene ubicación agregada.',
                  ),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _infoChip(
                      icon: Icons.calendar_today_outlined,
                      text: 'Se unió: $joinedDate',
                      bgColor: const Color(0xFFEAF2FF),
                      textColor: _primary,
                    ),
                    if (!hasProfileData)
                      _infoChip(
                        icon: Icons.warning_amber_rounded,
                        text: 'Perfil incompleto',
                        bgColor: const Color(0xFFFFF3E0),
                        textColor: Colors.deepOrange,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyMembersState() {
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
                Icons.groups_outlined,
                size: 40,
                color: _primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Todavía no tienes miembros registrados',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando personas se unan a tu iglesia, aparecerán aquí para que puedas visualizarlas y buscarlas fácilmente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSoft,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptySearchState() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5FB),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.search_off_outlined,
              size: 34,
              color: _primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No encontramos miembros con esa búsqueda',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Prueba buscando por nombre, ciudad, país o sector.',
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
      onRefresh: _loadMembers,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _heroCard(),
          const SizedBox(height: 18),
          _sectionTitle(
            'Buscar miembros',
            'Filtra rápidamente por nombre o ubicación.',
          ),
          _searchBox(),
          if (filteredMembers.isNotEmpty) _compactPaginationBar(),
          if (filteredMembers.isEmpty)
            _emptySearchState()
          else
            ..._paginatedMembers.map(_memberCard),
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
            : members.isEmpty
            ? _emptyMembersState()
            : _content(),
      ),
    );
  }
}