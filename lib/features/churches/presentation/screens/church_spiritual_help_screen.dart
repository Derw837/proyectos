import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/data/church_dashboard_service.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/church_header_shell.dart';

class ChurchSpiritualHelpScreen extends StatefulWidget {
  const ChurchSpiritualHelpScreen({super.key});

  @override
  State<ChurchSpiritualHelpScreen> createState() =>
      _ChurchSpiritualHelpScreenState();
}

class _ChurchSpiritualHelpScreenState extends State<ChurchSpiritualHelpScreen> {
  final labelController = TextEditingController();
  final urlController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  String? churchId;

  @override
  void initState() {
    super.initState();
    _loadChurch();
  }

  @override
  void dispose() {
    labelController.dispose();
    urlController.dispose();
    super.dispose();
  }

  Future<void> _loadChurch() async {
    try {
      final church = await ChurchDashboardService.getMyChurch();

      if (!mounted) return;

      if (church != null) {
        churchId = church['id']?.toString();
        labelController.text =
            church['spiritual_help_label']?.toString() ?? '';
        urlController.text =
            church['spiritual_help_url']?.toString() ?? '';
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando apoyo espiritual: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (churchId == null || churchId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró la iglesia')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await ChurchDashboardService.updateSpiritualHelp(
        churchId: churchId!,
        label: labelController.text.trim(),
        url: urlController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apoyo espiritual actualizado correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isSaving = false;
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
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChurchHeaderShell(
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
        title: const Text('Apoyo espiritual'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              TextField(
                controller: labelController,
                decoration: _decoration(
                  'Texto del botón',
                  Icons.text_fields,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: _decoration(
                  'Enlace o WhatsApp',
                  Icons.link,
                ),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ejemplos: "Solicitar oración", "Hablar con consejería", o un enlace directo de WhatsApp, Meet, Zoom, formulario, etc.',
                  style: TextStyle(
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
        ),
    );
  }
}