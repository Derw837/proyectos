import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:red_cristiana/features/churches/data/church_verification_service.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_pending_screen.dart';
import 'package:red_cristiana/core/widgets/latam_location_fields.dart';

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

  final ImagePicker _imagePicker = ImagePicker();

  bool isLoading = false;

  File? photo1File;
  File? photo2File;
  Uint8List? photo1Bytes;
  Uint8List? photo2Bytes;
  String? photo1Name;
  String? photo2Name;

  File? certificateFile;
  Uint8List? certificateBytes;
  String? certificateName;

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

  Future<void> _pickPhoto(int index) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );

    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        if (index == 1) {
          photo1Bytes = bytes;
          photo1Name = picked.name;
        } else {
          photo2Bytes = bytes;
          photo2Name = picked.name;
        }
      });
    } else {
      setState(() {
        if (index == 1) {
          photo1File = File(picked.path);
          photo1Name = picked.name;
        } else {
          photo2File = File(picked.path);
          photo2Name = picked.name;
        }
      });
    }
  }

  Future<void> _pickCertificate() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: kIsWeb,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    setState(() {
      certificateName = file.name;

      if (kIsWeb) {
        certificateBytes = file.bytes;
      } else {
        if (file.path != null) {
          certificateFile = File(file.path!);
        }
      }
    });
  }

  bool _hasPhoto1() => kIsWeb ? photo1Bytes != null : photo1File != null;
  bool _hasPhoto2() => kIsWeb ? photo2Bytes != null : photo2File != null;
  bool _hasCertificate() =>
      kIsWeb ? certificateBytes != null : certificateFile != null;

  Future<void> _saveChurch() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasCertificate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes subir el certificado o registro')),
      );
      return;
    }

    if (!_hasPhoto1()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes subir la foto 1 de la iglesia')),
      );
      return;
    }

    if (!_hasPhoto2()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes subir la foto 2 de la iglesia')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final certificateUrl = await ChurchVerificationService.uploadFile(
        userId: widget.userId,
        folder: 'certificate',
        fileName: certificateName ?? 'certificate.pdf',
        bytes: certificateBytes,
        file: certificateFile,
        contentType: _guessContentType(certificateName),
      );

      final photo1Url = await ChurchVerificationService.uploadFile(
        userId: widget.userId,
        folder: 'photos',
        fileName: photo1Name ?? 'photo1.jpg',
        bytes: photo1Bytes,
        file: photo1File,
        contentType: _guessContentType(photo1Name),
      );

      final photo2Url = await ChurchVerificationService.uploadFile(
        userId: widget.userId,
        folder: 'photos',
        fileName: photo2Name ?? 'photo2.jpg',
        bytes: photo2Bytes,
        file: photo2File,
        contentType: _guessContentType(photo2Name),
      );

      await ChurchVerificationService.saveChurchVerification(
        userId: widget.userId,
        userEmail: widget.userEmail,
        churchName: churchNameController.text.trim(),
        pastorName: pastorNameController.text.trim(),
        country: countryController.text.trim(),
        city: cityController.text.trim(),
        sector: sectorController.text.trim(),
        address: addressController.text.trim(),
        phone: phoneController.text.trim(),
        whatsapp: whatsappController.text.trim(),
        description: descriptionController.text.trim(),
        certificateUrl: certificateUrl,
        photo1Url: photo1Url,
        photo2Url: photo2Url,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solicitud enviada correctamente. Tu iglesia queda pendiente de aprobación.',
          ),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ChurchPendingScreen()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar la solicitud: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  String? _guessContentType(String? fileName) {
    final lower = (fileName ?? '').toLowerCase();

    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
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

  Widget _uploadCard({
    required String title,
    required String subtitle,
    required String? fileName,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEAF4FF),
                child: Icon(icon, color: const Color(0xFF0D47A1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (fileName != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                fileName,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.upload_file),
              label: Text(fileName == null ? 'Seleccionar archivo' : 'Cambiar'),
            ),
          ),
        ],
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
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Completa la verificación de tu iglesia',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Debes enviar los datos reales de la iglesia, dirección exacta, certificado o registro y dos fotos para que el administrador pueda revisar la solicitud.',
                        style: TextStyle(
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: churchNameController,
                        validator: (value) =>
                            _requiredValidator(value, 'el nombre de la iglesia'),
                        decoration:
                        _decoration('Nombre de la iglesia', Icons.church),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: pastorNameController,
                        validator: (value) =>
                            _requiredValidator(value, 'el nombre del pastor'),
                        decoration:
                        _decoration('Nombre del pastor', Icons.person),
                      ),
                      const SizedBox(height: 16),
                      LatamLocationFields(
                        countryController: countryController,
                        cityController: cityController,
                        sectorController: sectorController,
                        addressController: addressController,
                        requiredValidator: _requiredValidator,
                        decorationBuilder: _decoration,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneController,
                        decoration:
                        _decoration('Teléfono', Icons.phone_outlined),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: whatsappController,
                        decoration:
                        _decoration('WhatsApp', Icons.message_outlined),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: _decoration(
                          'Descripción breve',
                          Icons.description_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _uploadCard(
                  title: 'Certificado o registro',
                  subtitle:
                  'Sube el documento que demuestre que la iglesia está constituida. Puede ser PDF, JPG o PNG.',
                  fileName: certificateName,
                  icon: Icons.verified_outlined,
                  onTap: _pickCertificate,
                ),
                const SizedBox(height: 14),
                _uploadCard(
                  title: 'Foto 1 de la iglesia',
                  subtitle:
                  'Sube una foto clara de la fachada, entrada o parte visible de la iglesia.',
                  fileName: photo1Name,
                  icon: Icons.photo_camera_back_outlined,
                  onTap: () => _pickPhoto(1),
                ),
                const SizedBox(height: 14),
                _uploadCard(
                  title: 'Foto 2 de la iglesia',
                  subtitle:
                  'Sube una segunda foto para validar mejor la existencia del lugar.',
                  fileName: photo2Name,
                  icon: Icons.photo_library_outlined,
                  onTap: () => _pickPhoto(2),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _saveChurch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Enviar solicitud',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}