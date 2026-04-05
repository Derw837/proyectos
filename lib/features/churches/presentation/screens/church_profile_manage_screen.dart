import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:red_cristiana/features/auth/presentation/screens/login_screen.dart';
import 'package:red_cristiana/features/churches/data/church_media_service.dart';
import 'package:red_cristiana/features/churches/data/church_service.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/church_header_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  bool editMainInfo = false;
  bool editLocationInfo = false;
  bool editDonationInfo = false;

  List<TextEditingController> get _allControllers => [
    churchNameController,
    pastorNameController,
    countryController,
    cityController,
    sectorController,
    addressController,
    phoneController,
    whatsappController,
    descriptionController,
    doctrinalBaseController,
    donationAccountNameController,
    donationBankNameController,
    donationAccountNumberController,
    donationAccountTypeController,
    donationInstructionsController,
  ];

  @override
  void initState() {
    super.initState();
    for (final controller in _allControllers) {
      controller.addListener(_refreshUI);
    }
    _loadChurch();
  }

  @override
  void dispose() {
    for (final controller in _allControllers) {
      controller.removeListener(_refreshUI);
    }

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

  void _refreshUI() {
    if (!mounted) return;
    setState(() {});
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

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
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
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFF5F6B7A),
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF0D47A1),
        size: 22,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFD),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.grey.withValues(alpha: 0.18),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF0D47A1),
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.3,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.grey.withValues(alpha: 0.18),
        ),
      ),
    );
  }

  Widget _infoPreviewRow({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: const Color(0xFF0D47A1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isEditing,
    required VoidCallback onToggle,
    required List<Widget> fields,
    required List<Widget> previewItems,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isEditing
              ? const Color(0xFF0D47A1).withValues(alpha: 0.18)
              : Colors.grey.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF0D47A1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1B2A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onToggle,
                icon: Icon(
                  isEditing
                      ? Icons.visibility_off_outlined
                      : Icons.edit_outlined,
                ),
                label: Text(isEditing ? 'Ocultar' : 'Editar'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0D47A1),
                ),
              ),
            ],
          ),
          if (!isEditing) ...[
            const SizedBox(height: 8),
            ...previewItems,
          ],
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: fields,
              ),
            ),
            crossFadeState: isEditing
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
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
      return const ChurchHeaderShell(
        child: Scaffold(
          backgroundColor: Color(0xFFF7F9FC),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final displayChurchName = churchNameController.text.trim().isEmpty
        ? 'Mi iglesia'
        : churchNameController.text.trim();

    final displayLocation = [
      if (cityController.text.trim().isNotEmpty) cityController.text.trim(),
      if (countryController.text.trim().isNotEmpty)
        countryController.text.trim(),
    ].join(', ');

    final mainSubtitle = churchNameController.text.trim().isEmpty
        ? 'Completa los datos básicos de tu iglesia'
        : churchNameController.text.trim();

    final locationSubtitle = displayLocation.isEmpty
        ? 'Agrega ubicación, dirección y medios de contacto'
        : displayLocation;

    final donationSubtitle = donationBankNameController.text.trim().isEmpty
        ? 'Configura los datos para recibir apoyo y ofrendas'
        : donationBankNameController.text.trim();

    return ChurchHeaderShell(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            InkWell(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                              onTap: _pickCover,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                                child: selectedCoverBytes != null
                                    ? Image.memory(
                                  selectedCoverBytes!,
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                )
                                    : coverUrl.isNotEmpty
                                    ? Image.network(
                                  coverUrl,
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _emptyImagePlaceholder(
                                        'Portada',
                                        150,
                                      ),
                                )
                                    : _emptyImagePlaceholder(
                                  'Portada',
                                  150,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: -42,
                              child: Row(
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: _pickLogo,
                                    child: Container(
                                      width: 84,
                                      height: 84,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x16000000),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: selectedLogoBytes != null
                                          ? Image.memory(
                                        selectedLogoBytes!,
                                        fit: BoxFit.cover,
                                      )
                                          : logoUrl.isNotEmpty
                                          ? Image.network(
                                        logoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                        const Icon(
                                          Icons.church,
                                          size: 34,
                                          color: Color(0xFF0D47A1),
                                        ),
                                      )
                                          : const Icon(
                                        Icons.church,
                                        size: 34,
                                        color: Color(0xFF0D47A1),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 44),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayChurchName,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              height: 1.2,
                                            ),
                                          ),
                                          if (displayLocation.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              displayLocation,
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 56),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickLogo,
                                  icon:
                                  const Icon(Icons.photo_camera_outlined),
                                  label: const Text('Cambiar logo'),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickCover,
                                  icon: const Icon(Icons.image_outlined),
                                  label: const Text('Cambiar portada'),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  _editableSectionCard(
                    title: 'Información principal',
                    subtitle: mainSubtitle,
                    icon: Icons.church,
                    isEditing: editMainInfo,
                    onToggle: () {
                      setState(() {
                        editMainInfo = !editMainInfo;
                      });
                    },
                    previewItems: [
                      _infoPreviewRow(
                        icon: Icons.church_outlined,
                        text: churchNameController.text.trim().isEmpty
                            ? 'Nombre de la iglesia no agregado'
                            : churchNameController.text.trim(),
                      ),
                      _infoPreviewRow(
                        icon: Icons.person_outline,
                        text: pastorNameController.text.trim().isEmpty
                            ? 'Pastor no agregado'
                            : pastorNameController.text.trim(),
                      ),
                      _infoPreviewRow(
                        icon: Icons.description_outlined,
                        text: descriptionController.text.trim().isEmpty
                            ? 'No hay descripción agregada'
                            : descriptionController.text.trim(),
                      ),
                    ],
                    fields: [
                      TextFormField(
                        controller: churchNameController,
                        validator: (value) =>
                            _required(value, 'el nombre de la iglesia'),
                        decoration:
                        _decoration('Nombre de la iglesia', Icons.church),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: pastorNameController,
                        decoration: _decoration(
                          'Nombre del pastor',
                          Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: _decoration(
                          'Descripción',
                          Icons.description_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: doctrinalBaseController,
                        maxLines: 4,
                        decoration: _decoration(
                          'Base doctrinal / información adicional',
                          Icons.menu_book_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _editableSectionCard(
                    title: 'Ubicación y contacto',
                    subtitle: locationSubtitle,
                    icon: Icons.location_on_outlined,
                    isEditing: editLocationInfo,
                    onToggle: () {
                      setState(() {
                        editLocationInfo = !editLocationInfo;
                      });
                    },
                    previewItems: [
                      _infoPreviewRow(
                        icon: Icons.public,
                        text: countryController.text.trim().isEmpty
                            ? 'País no agregado'
                            : countryController.text.trim(),
                      ),
                      _infoPreviewRow(
                        icon: Icons.location_city,
                        text: cityController.text.trim().isEmpty
                            ? 'Ciudad no agregada'
                            : cityController.text.trim(),
                      ),
                      _infoPreviewRow(
                        icon: Icons.location_on_outlined,
                        text: addressController.text.trim().isEmpty
                            ? 'Dirección no agregada'
                            : addressController.text.trim(),
                      ),
                      _infoPreviewRow(
                        icon: Icons.phone_outlined,
                        text: phoneController.text.trim().isEmpty
                            ? 'Teléfono no agregado'
                            : phoneController.text.trim(),
                      ),
                      _infoPreviewRow(
                        icon: Icons.message_outlined,
                        text: whatsappController.text.trim().isEmpty
                            ? 'WhatsApp no agregado'
                            : whatsappController.text.trim(),
                      ),
                    ],
                    fields: [
                      TextFormField(
                        controller: countryController,
                        validator: (value) => _required(value, 'el país'),
                        decoration: _decoration('País', Icons.public),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: cityController,
                        validator: (value) => _required(value, 'la ciudad'),
                        decoration:
                        _decoration('Ciudad', Icons.location_city),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: sectorController,
                        decoration: _decoration('Sector', Icons.map_outlined),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: addressController,
                        validator: (value) => _required(value, 'la dirección'),
                        decoration: _decoration(
                          'Dirección',
                          Icons.location_on_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: phoneController,
                        decoration:
                        _decoration('Teléfono', Icons.phone_outlined),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: whatsappController,
                        decoration:
                        _decoration('WhatsApp', Icons.message_outlined),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _editableSectionCard(
                    title: 'Donaciones y ofrendas',
                    subtitle: donationSubtitle,
                    icon: Icons.favorite_outline,
                    isEditing: editDonationInfo,
                    onToggle: () {
                      setState(() {
                        editDonationInfo = !editDonationInfo;
                      });
                    },
                    previewItems: [
                      _infoPreviewRow(
                        icon: Icons.account_balance_outlined,
                        text: donationBankNameController.text.trim().isEmpty
                            ? 'Banco no agregado'
                            : donationBankNameController.text.trim(),
                      ),
                      _infoPreviewRow(
                        icon: Icons.badge_outlined,
                        text:
                        donationAccountNameController.text.trim().isEmpty
                            ? 'Titular no agregado'
                            : donationAccountNameController.text.trim(),
                      ),
                      _infoPreviewRow(
                        icon: Icons.numbers,
                        text:
                        donationAccountNumberController.text.trim().isEmpty
                            ? 'Número de cuenta no agregado'
                            : donationAccountNumberController.text.trim(),
                      ),
                      _infoPreviewRow(
                        icon: Icons.info_outline,
                        text: donationInstructionsController.text.trim().isEmpty
                            ? 'No hay instrucciones para donar'
                            : donationInstructionsController.text.trim(),
                      ),
                    ],
                    fields: [
                      TextFormField(
                        controller: donationAccountNameController,
                        decoration: _decoration(
                          'Titular de la cuenta',
                          Icons.badge_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: donationBankNameController,
                        decoration: _decoration(
                          'Banco',
                          Icons.account_balance_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: donationAccountNumberController,
                        decoration: _decoration(
                          'Número de cuenta',
                          Icons.numbers,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: donationAccountTypeController,
                        decoration: _decoration(
                          'Tipo de cuenta',
                          Icons.credit_card_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: donationInstructionsController,
                        maxLines: 4,
                        decoration: _decoration(
                          'Instrucciones para donar',
                          Icons.info_outline,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        elevation: 0,
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
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
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