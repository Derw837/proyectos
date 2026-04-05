import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/data/church_member_notifications_service.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/church_header_shell.dart';

class ChurchNotifyMembersScreen extends StatefulWidget {
  const ChurchNotifyMembersScreen({super.key});

  @override
  State<ChurchNotifyMembersScreen> createState() =>
      _ChurchNotifyMembersScreenState();
}

class _ChurchNotifyMembersScreenState
    extends State<ChurchNotifyMembersScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final messageController = TextEditingController();

  bool isSending = false;
  String churchName = 'Mi iglesia';

  @override
  void initState() {
    super.initState();
    _loadChurch();
  }

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> _loadChurch() async {
    try {
      final church = await ChurchMemberNotificationsService.getMyChurch();
      if (!mounted || church == null) return;

      setState(() {
        churchName = church['church_name']?.toString() ?? 'Mi iglesia';
      });
    } catch (_) {}
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa $label';
    }
    return null;
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSending = true;
    });

    try {
      final total =
      await ChurchMemberNotificationsService.sendNotificationToMyMembers(
        title: titleController.text.trim(),
        message: messageController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            total == 0
                ? 'Tu iglesia aún no tiene miembros registrados.'
                : 'Notificación enviada a $total miembro${total == 1 ? '' : 's'}.',
          ),
        ),
      );

      if (total > 0) {
        titleController.clear();
        messageController.clear();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error enviando notificación: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isSending = false;
      });
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChurchHeaderShell(
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
        title: const Text('Notificar miembros'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0D47A1),
                        Color(0xFF1565C0),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enviar aviso a tus miembros',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        churchName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: titleController,
                  validator: (value) => _required(value, 'un título'),
                  decoration: _decoration(
                    'Título',
                    Icons.title_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: messageController,
                  validator: (value) => _required(value, 'un mensaje'),
                  maxLines: 5,
                  decoration: _decoration(
                    'Mensaje',
                    Icons.campaign_outlined,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: isSending ? null : _send,
                    icon: isSending
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.send),
                    label: Text(
                      isSending ? 'Enviando...' : 'Enviar a mis miembros',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
        ),
    );
  }
}