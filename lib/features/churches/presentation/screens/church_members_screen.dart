import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/data/church_dashboard_service.dart';

class ChurchMembersScreen extends StatefulWidget {
  const ChurchMembersScreen({super.key});

  @override
  State<ChurchMembersScreen> createState() => _ChurchMembersScreenState();
}

class _ChurchMembersScreenState extends State<ChurchMembersScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final data = await ChurchDashboardService.getMyMembers();

      if (!mounted) return;
      setState(() {
        members = data;
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

  Widget _memberCard(Map<String, dynamic> member) {
    final profile = member['profile'] as Map<String, dynamic>?;
    final membership = member['membership'] as Map<String, dynamic>?;

    final fullName = profile?['full_name']?.toString() ?? 'Usuario';
    final country = profile?['country']?.toString() ?? '';
    final city = profile?['city']?.toString() ?? '';
    final sector = profile?['sector']?.toString() ?? '';
    final createdAt = membership?['created_at']?.toString() ?? '';

    final location = [
      if (city.isNotEmpty) city,
      if (country.isNotEmpty) country,
    ].join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFEAF4FF),
            child: Icon(Icons.person, color: Color(0xFF0D47A1)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
                if (sector.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Sector: $sector',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
                if (createdAt.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Se unió: ${createdAt.split('T').first}',
                    style: const TextStyle(
                      color: Color(0xFF0D47A1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: members.length,
          itemBuilder: (context, index) =>
              _memberCard(members[index]),
        ),
      ),
    );
  }
}