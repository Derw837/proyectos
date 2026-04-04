import 'package:flutter/material.dart';
import 'package:red_cristiana/features/prayer/data/prayer_service.dart';

class CreatePrayerRequestSheet extends StatefulWidget {
  final Future<void> Function() onCreated;

  const CreatePrayerRequestSheet({
    super.key,
    required this.onCreated,
  });

  @override
  State<CreatePrayerRequestSheet> createState() =>
      _CreatePrayerRequestSheetState();
}

class _CreatePrayerRequestSheetState extends State<CreatePrayerRequestSheet> {
  bool isForMe = true;
  bool isSaving = false;
  String selectedCategory = 'salud';
  final targetNameController = TextEditingController();

  final categories = const [
    {'value': 'salud', 'label': 'Salud'},
    {'value': 'matrimonio', 'label': 'Matrimonio'},
    {'value': 'familia', 'label': 'Familia'},
    {'value': 'hijos', 'label': 'Hijos'},
    {'value': 'trabajo', 'label': 'Trabajo'},
    {'value': 'finanzas', 'label': 'Finanzas'},
    {'value': 'proteccion', 'label': 'Protección'},
    {'value': 'estudios', 'label': 'Estudios'},
    {'value': 'direccion', 'label': 'Dirección de Dios'},
    {'value': 'paz', 'label': 'Paz'},
    {'value': 'sanidad_emocional', 'label': 'Sanidad emocional'},
    {'value': 'fortaleza_espiritual', 'label': 'Fortaleza espiritual'},
    {'value': 'liberacion', 'label': 'Liberación'},
  ];

  @override
  void dispose() {
    targetNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = targetNameController.text.trim();

    if (!isForMe) {
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escribe el nombre y apellido')),
        );
        return;
      }

      if (name.split(' ').length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingresa nombre y apellido completo'),
          ),
        );
        return;
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      await PrayerService.createPrayerRequest(
        isForMe: isForMe,
        targetName: targetNameController.text.trim(),
        category: selectedCategory,
      );

      await widget.onCreated();

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu petición fue publicada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creando petición: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pedir oración',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Para mí'),
                    icon: Icon(Icons.person),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Para otra persona'),
                    icon: Icon(Icons.people),
                  ),
                ],
                selected: {isForMe},
                onSelectionChanged: (value) {
                  setState(() {
                    isForMe = value.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                items: categories
                    .map(
                      (e) => DropdownMenuItem<String>(
                    value: e['value']!,
                    child: Text(e['label']!),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedCategory = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              if (!isForMe) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: targetNameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre y apellido',
                    hintText: 'Ej: Juan Pérez',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _submit,
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Publicar petición'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}