import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/data/church_dashboard_service.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/church_header_shell.dart';

class ChurchMembersScreen extends StatefulWidget {
  const ChurchMembersScreen({super.key});

  @override
  State<ChurchMembersScreen> createState() => _ChurchMembersScreenState();
}

class _ChurchMembersScreenState extends State<ChurchMembersScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> filteredMembers = [];
  final TextEditingController searchController = TextEditingController();

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
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando miembros: $e')),
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

  Widget _infoChip({
    required IconData icon,
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberCard(Map<String, dynamic> member) {
    final profile = member['profile'] as Map<String, dynamic>?;
    final membership = member['membership'] as Map<String, dynamic>?;

    final fullName = _memberName(profile);
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFF0D47A1),
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
                const SizedBox(height: 8),
                if (location.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (sector.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 15,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Sector: $sector',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _infoChip(
                      icon: Icons.calendar_today_outlined,
                      text: 'Se unió: $joinedDate',
                      bgColor: const Color(0xFFEAF4FF),
                      textColor: const Color(0xFF0D47A1),
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

  Widget _topSummary() {
    final total = filteredMembers.length;

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
              Icons.groups_outlined,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              total == 1
                  ? 'Tienes 1 miembro registrado'
                  : 'Tienes $total miembros registrados',
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

  Widget _searchBox() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Buscar miembro, ciudad o sector...',
        prefixIcon: const Icon(Icons.search),
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
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1.3),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChurchHeaderShell(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text('Miembros de mi iglesia'),
          centerTitle: true,
          backgroundColor: const Color(0xFFF7F9FC),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : members.isEmpty
            ? const Center(
          child: Text('Todavía no tienes miembros registrados.'),
        )
            : RefreshIndicator(
          onRefresh: _loadMembers,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            children: [
              _searchBox(),
              const SizedBox(height: 12),
              _topSummary(),
              const SizedBox(height: 14),
              if (filteredMembers.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'No encontramos miembros con esa búsqueda.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...filteredMembers.map(_memberCard),
            ],
          ),
        ),
      ),
    );
  }
}