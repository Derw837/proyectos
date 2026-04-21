import 'package:flutter/material.dart';
import 'package:red_cristiana/core/utils/app_error_helper.dart';
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
  static const Color _primary = Color(0xFF0D47A1);
  static const Color _primaryLight = Color(0xFF1565C0);
  static const Color _surface = Color(0xFFF4F7FB);
  static const Color _card = Colors.white;
  static const Color _textDark = Color(0xFF152033);
  static const Color _textSoft = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE6EDF6);

  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final messageController = TextEditingController();

  bool isSending = false;
  String churchName = 'Mi iglesia';

  @override
  void initState() {
    super.initState();
    titleController.addListener(_refresh);
    messageController.addListener(_refresh);
    _loadChurch();
  }

  @override
  void dispose() {
    titleController.removeListener(_refresh);
    messageController.removeListener(_refresh);
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
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
        SnackBar(content: Text(await AppErrorHelper.friendlyMessage(e, fallback: 'No se pudo enviar la notificación en este momento.'))),
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
      labelStyle: const TextStyle(
        color: _textSoft,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(
        icon,
        color: _primary,
        size: 21,
      ),
      filled: true,
      fillColor: const Color(0xFFF9FBFE),
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
        borderSide: const BorderSide(color: _primary, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _border),
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
    final hasTitle = titleController.text.trim().isNotEmpty;
    final hasMessage = messageController.text.trim().isNotEmpty;

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
          Text(
            churchName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Notificar miembros',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroChip(
                icon: Icons.title_outlined,
                text: hasTitle ? 'Título listo' : 'Falta título',
              ),
              _heroChip(
                icon: Icons.message_outlined,
                text: hasMessage ? 'Mensaje listo' : 'Falta mensaje',
              ),
              _heroChip(
                icon: Icons.send_outlined,
                text: 'Aviso pastoral',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final titleLength = titleController.text.trim().length;
    final messageLength = messageController.text.trim().length;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.campaign_outlined,
              color: _primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen del aviso',
                  style: TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Título: $titleLength caracteres • Mensaje: $messageLength caracteres',
                  style: const TextStyle(
                    color: _textSoft,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipsCard() {
    return Container(
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: _primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Consejos para el aviso',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '• Usa un título corto y claro.\n'
                '• Escribe el mensaje de forma directa.\n'
                '• Si es una convocatoria, menciona día, hora y lugar.\n'
                '• Evita mensajes demasiado largos.',
            style: TextStyle(
              color: _textSoft,
              fontSize: 12.8,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stickyButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: const Border(
          top: BorderSide(color: _border),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
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
                : const Icon(Icons.send_rounded),
            label: Text(
              isSending ? 'Enviando...' : 'Enviar a mis miembros',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFB8C7E0),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChurchHeaderShell(
      child: Scaffold(
        backgroundColor: _surface,
        bottomNavigationBar: _stickyButton(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heroCard(),
                  const SizedBox(height: 18),
                  _sectionTitle(
                    'Redactar aviso',
                    'Envía un mensaje claro y directo a los miembros de tu iglesia.',
                  ),
                  TextFormField(
                    controller: titleController,
                    validator: (value) => _required(value, 'un título'),
                    textInputAction: TextInputAction.next,
                    decoration: _decoration(
                      'Título',
                      Icons.title_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: messageController,
                    validator: (value) => _required(value, 'un mensaje'),
                    maxLines: 6,
                    decoration: _decoration(
                      'Mensaje',
                      Icons.campaign_outlined,
                    ).copyWith(
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${messageController.text.trim().length} caracteres',
                      style: const TextStyle(
                        color: _textSoft,
                        fontSize: 12.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _summaryCard(),
                  const SizedBox(height: 12),
                  _tipsCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}