import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:red_cristiana/features/churches/data/church_media_service.dart';
import 'package:red_cristiana/features/churches/data/church_service.dart';

class ChurchProfileManageScreen extends StatefulWidget {
  const ChurchProfileManageScreen({super.key});

  @override
  State<ChurchProfileManageScreen> createState() =>
      _ChurchProfileManageScreenState();
}

class _ChurchProfileManageScreenState
    extends State<ChurchProfileManageScreen> {
  final _formKey = GlobalKey<FormState>();

  final churchNameController = TextEditingController();
  final pastorNameController = TextEditingController();
  final countryController = TextEditingController();
  final cityController = TextEditingController();
  final sectorController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final whatsappController = TextEditingController();
  final descriptionController = TextEditingController();
  final doctrinalBaseController = TextEditingController();

  final donationAccountNameController = TextEditingController();
  final donationBankNameController = TextEditingController();
  final donationAccountNumberController = TextEditingController();
  final donationAccountTypeController = TextEditingController();
  final donationInstructionsController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  String? churchId;

  String logoUrl = '';
  String coverUrl = '';

  XFile? selectedLogoFile;
  XFile? selectedCoverFile;

  Uint8List? selectedLogoBytes;
  Uint8List? selectedCoverBytes;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadChurch();
  }

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
    doctrinalBaseController.dispose();
    donationAccountNameController.dispose();
    donationBankNameController.dispose();
    donationAccountNumberController.dispose();
    donationAccountTypeController.dispose();
    donationInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadChurch() async {
    try {
      final church = await ChurchService.getMyChurch();

      if (!mounted) return;

      if (church == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      churchId = church['id']?.toString();

      churchNameController.text = church['church_name']?.toString() ?? '';
      pastorNameController.text = church['pastor_name']?.toString() ?? '';
      countryController.text = church['country']?.toString() ?? '';
      cityController.text = church['city']?.toString() ?? '';
      sectorController.text = church['sector']?.toString() ?? '';
      addressController.text = church['address']?.toString() ?? '';
      phoneController.text = church['phone']?.toString() ?? '';
      whatsappController.text = church['whatsapp']?.toString() ?? '';
      descriptionController.text = church['description']?.toString() ?? '';
      doctrinalBaseController.text = church['doctrinal_base']?.toString() ?? '';

      donationAccountNameController.text =
          church['donation_account_name']?.toString() ?? '';
      donationBankNameController.text =
          church['donation_bank_name']?.toString() ?? '';
      donationAccountNumberController.text =
          church['donation_account_number']?.toString() ?? '';
      donationAccountTypeController.text =
          church['donation_account_type']?.toString() ?? '';
      donationInstructionsController.text =
          church['donation_instructions']?.toString() ?? '';

      logoUrl = church['logo_url']?.toString() ?? '';
      coverUrl = church['cover_url']?.toString() ?? '';

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando la iglesia: $e')),
      );
    }
  }

  Future<void> _pickLogo() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      selectedLogoFile = picked;
      selectedLogoBytes = bytes;
    });
  }

  Future<void> _pickCover() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      selectedCoverFile = picked;
      selectedCoverBytes = bytes;
    });
  }

  Future<void> _saveChurch() async {
    if (!_formKey.currentState!.validate()) return;
    if (churchId == null || churchId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró la iglesia a editar.')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      String? newLogoUrl;
      String? newCoverUrl;

      if (selectedLogoFile != null && selectedLogoBytes != null) {
        newLogoUrl = await ChurchMediaService.uploadChurchImage(
          filePath: selectedLogoFile!.path,
          bytes: selectedLogoBytes!,
          churchId: churchId!,
          folder: 'logos',
        );
      }

      if (selectedCoverFile != null && selectedCoverBytes != null) {
        newCoverUrl = await ChurchMediaService.uploadChurchImage(
          filePath: selectedCoverFile!.path,
          bytes: selectedCoverBytes!,
          churchId: churchId!,
          folder: 'covers',
        );
      }

      await ChurchService.updateMyChurch(
        churchId: churchId!,
        churchName: churchNameController.text.trim(),
        pastorName: pastorNameController.text.trim(),
        country: countryController.text.trim(),
        city: cityController.text.trim(),
        sector: sectorController.text.trim(),
        address: addressController.text.trim(),
        phone: phoneController.text.trim(),
        whatsapp: whatsappController.text.trim(),
        description: descriptionController.text.trim(),
        doctrinalBase: doctrinalBaseController.text.trim(),
        donationAccountName: donationAccountNameController.text.trim(),
        donationBankName: donationBankNameController.text.trim(),
        donationAccountNumber: donationAccountNumberController.text.trim(),
        donationAccountType: donationAccountTypeController.text.trim(),
        donationInstructions: donationInstructionsController.text.trim(),
      );

      await ChurchMediaService.updateChurchImages(
        churchId: churchId!,
        logoUrl: newLogoUrl,
        coverUrl: newCoverUrl,
      );

      if (newLogoUrl != null) logoUrl = newLogoUrl;
      if (newCoverUrl != null) coverUrl = newCoverUrl;

      if (!mounted) return;

      setState(() {
        selectedLogoFile = null;
        selectedCoverFile = null;
        selectedLogoBytes = null;
        selectedCoverBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos de la iglesia actualizados.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando cambios: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa $label';
    }
    return null;
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

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0D1B2A),
        ),
      ),
    );
  }

  Widget _imageBox({
    required String title,
    required VoidCallback onTap,
    Uint8List? memoryBytes,
    XFile? pickedFile,
    String? networkUrl,
    double height = 150,
  }) {
    Widget child;

    if (memoryBytes != null) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.memory(
          memoryBytes,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
        ),
      );
    } else if (!kIsWeb && pickedFile != null) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.file(
          File(pickedFile.path),
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
        ),
      );
    } else if (networkUrl != null && networkUrl.isNotEmpty) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          networkUrl,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emptyImagePlaceholder(title, height),
        ),
      );
    } else {
      child = _emptyImagePlaceholder(title, height);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: child,
        ),
      ],
    );
  }

  Widget _emptyImagePlaceholder(String title, double height) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined, size: 34),
            const SizedBox(height: 10),
            Text('Seleccionar $title'),
          ],
        ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Mi iglesia'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Imágenes'),
                _imageBox(
                  title: 'Portada',
                  onTap: _pickCover,
                  pickedFile: selectedCoverFile,
                  memoryBytes: selectedCoverBytes,
                  networkUrl: coverUrl,
                  height: 170,
                ),
                const SizedBox(height: 16),
                _imageBox(
                  title: 'Logo',
                  onTap: _pickLogo,
                  pickedFile: selectedLogoFile,
                  memoryBytes: selectedLogoBytes,
                  networkUrl: logoUrl,
                  height: 130,
                ),
                const SizedBox(height: 24),

                _sectionTitle('Información principal'),
                TextFormField(
                  controller: churchNameController,
                  validator: (value) =>
                      _required(value, 'el nombre de la iglesia'),
                  decoration: _decoration('Nombre de la iglesia', Icons.church),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: pastorNameController,
                  decoration:
                  _decoration('Nombre del pastor', Icons.person_outline),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration:
                  _decoration('Descripción', Icons.description_outlined),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: doctrinalBaseController,
                  maxLines: 4,
                  decoration: _decoration(
                    'Base doctrinal / información adicional',
                    Icons.menu_book_outlined,
                  ),
                ),
                const SizedBox(height: 24),

                _sectionTitle('Ubicación y contacto'),
                TextFormField(
                  controller: countryController,
                  validator: (value) => _required(value, 'el país'),
                  decoration: _decoration('País', Icons.public),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: cityController,
                  validator: (value) => _required(value, 'la ciudad'),
                  decoration: _decoration('Ciudad', Icons.location_city),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: sectorController,
                  decoration: _decoration('Sector', Icons.map_outlined),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  validator: (value) => _required(value, 'la dirección'),
                  decoration:
                  _decoration('Dirección', Icons.location_on_outlined),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: _decoration('Teléfono', Icons.phone_outlined),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: whatsappController,
                  decoration: _decoration('WhatsApp', Icons.message_outlined),
                ),
                const SizedBox(height: 24),

                _sectionTitle('Datos para ofrendas / donaciones'),
                TextFormField(
                  controller: donationAccountNameController,
                  decoration:
                  _decoration('Titular de la cuenta', Icons.badge_outlined),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: donationBankNameController,
                  decoration: _decoration(
                    'Banco',
                    Icons.account_balance_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: donationAccountNumberController,
                  decoration: _decoration('Número de cuenta', Icons.numbers),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: donationAccountTypeController,
                  decoration: _decoration(
                    'Tipo de cuenta',
                    Icons.credit_card_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: donationInstructionsController,
                  maxLines: 4,
                  decoration: _decoration(
                    'Instrucciones para donar',
                    Icons.info_outline,
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
                    onPressed: isSaving ? null : _saveChurch,
                    child: isSaving
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Guardar cambios',
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