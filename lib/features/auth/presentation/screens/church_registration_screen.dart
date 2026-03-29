import 'package:flutter/material.dart';
import 'package:red_cristiana/features/home/presentation/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChurchRegistrationScreen extends StatefulWidget {
  final String userId;
  final String userEmail;

  const ChurchRegistrationScreen({
    super.key,
    required this.userId,
    required this.userEmail,
  });

  @override
  State<ChurchRegistrationScreen> createState() =>
      _ChurchRegistrationScreenState();
}

class _ChurchRegistrationScreenState extends State<ChurchRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final churchNameController = TextEditingController();
  final pastorNameController = TextEditingController();
  final countryController = TextEditingController(text: 'Ecuador');
  final cityController = TextEditingController();
  final sectorController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final whatsappController = TextEditingController();
  final descriptionController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    churchNameController.dispose();
    pastorNameController.dispose();
    countryController.dispose();
    cityController.dispose();
    sectorController.dispose();
    addressController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa $fieldName';
    }
    return null;
  }

  Future<void> _saveChurch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      await Supabase.instance.client.from('churches').insert({
        'user_id': widget.userId,
        'church_name': churchNameController.text.trim(),
        'pastor_name': pastorNameController.text.trim(),
        'country': countryController.text.trim(),
        'city': cityController.text.trim(),
        'sector': sectorController.text.trim(),
        'address': addressController.text.trim(),
        'phone': phoneController.text.trim(),
        'whatsapp': whatsappController.text.trim(),
        'email': widget.userEmail,
        'description': descriptionController.text.trim(),
        'status': 'pending',
      });

      await Supabase.instance.client.from('profiles').update({
        'country': countryController.text.trim(),
        'city': cityController.text.trim(),
        'sector': sectorController.text.trim(),
        'approval_status': 'pending',
      }).eq('id', widget.userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Iglesia registrada correctamente. Queda pendiente de aprobación.',
          ),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar iglesia: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar iglesia'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Completa los datos de la iglesia',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tu solicitud quedará pendiente hasta que sea revisada por el administrador.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: churchNameController,
                  validator: (value) =>
                      _requiredValidator(value, 'el nombre de la iglesia'),
                  decoration: _decoration('Nombre de la iglesia', Icons.church),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: pastorNameController,
                  validator: (value) =>
                      _requiredValidator(value, 'el nombre del pastor'),
                  decoration: _decoration('Nombre del pastor', Icons.person),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: countryController,
                  validator: (value) =>
                      _requiredValidator(value, 'el país'),
                  decoration: _decoration('País', Icons.public),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: cityController,
                  validator: (value) =>
                      _requiredValidator(value, 'la ciudad'),
                  decoration: _decoration('Ciudad', Icons.location_city),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: sectorController,
                  decoration: _decoration('Sector', Icons.map_outlined),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: addressController,
                  validator: (value) =>
                      _requiredValidator(value, 'la dirección'),
                  decoration: _decoration('Dirección', Icons.location_on_outlined),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: phoneController,
                  decoration: _decoration('Teléfono', Icons.phone_outlined),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: whatsappController,
                  decoration: _decoration('WhatsApp', Icons.message_outlined),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: _decoration(
                    'Descripción breve',
                    Icons.description_outlined,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: isLoading ? null : _saveChurch,
                    child: isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Guardar solicitud',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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