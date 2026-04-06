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
  static const Color _primary = Color(0xFF0D47A1);
  static const Color _primaryLight = Color(0xFF1565C0);
  static const Color _surface = Color(0xFFF4F7FB);
  static const Color _card = Colors.white;
  static const Color _textDark = Color(0xFF152033);
  static const Color _textSoft = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE6EDF6);

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

  String _safeText(String value, String fallback) {
    return value.trim().isEmpty ? fallback : value.trim();
  }

  String _getInitials(String text) {
    final parts = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'IG';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
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
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _primary,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.2,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border),
      ),
    );
  }

  Widget _infoPreviewRow({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 15,
              color: _primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: _textDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isEditing,
    required VoidCallback onToggle,
    required List<Widget> fields,
    required List<Widget> previewItems,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isEditing ? _primary.withValues(alpha: 0.18) : _border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: _primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _textSoft,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onToggle,
                icon: Icon(
                  isEditing
                      ? Icons.visibility_off_outlined
                      : Icons.edit_outlined,
                  size: 18,
                ),
                label: Text(isEditing ? 'Ocultar' : 'Editar'),
                style: TextButton.styleFrom(
                  foregroundColor: _primary,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          if (!isEditing) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: previewItems,
              ),
            ),
          ],
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(children: fields),
            ),
            crossFadeState: isEditing
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _buildImage({
    Uint8List? memoryBytes,
    XFile? pickedFile,
    String? networkUrl,
    IconData fallbackIcon = Icons.image_outlined,
  }) {
    if (memoryBytes != null) {
      return Image.memory(
        memoryBytes,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    if (!kIsWeb && pickedFile != null) {
      return Image.file(
        File(pickedFile.path),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    if (networkUrl != null && networkUrl.isNotEmpty) {
      return Image.network(
        networkUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _emptyImageContent(fallbackIcon);
        },
      );
    }

    return _emptyImageContent(fallbackIcon);
  }

  Widget _emptyImageContent(IconData icon) {
    return Container(
      color: const Color(0xFFF3F6FB),
      child: Center(
        child: Icon(
          icon,
          size: 34,
          color: const Color(0xFF89A0C4),
        ),
      ),
    );
  }

  Widget _imageActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  Widget _headerCard() {
    final displayChurchName = churchNameController.text.trim().isEmpty
        ? 'Mi iglesia'
        : churchNameController.text.trim();

    final displayLocation = [
      if (cityController.text.trim().isNotEmpty) cityController.text.trim(),
      if (countryController.text.trim().isNotEmpty) countryController.text.trim(),
    ].join(', ');

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 168,
                  child: InkWell(
                    onTap: _pickCover,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImage(
                          memoryBytes: selectedCoverBytes,
                          pickedFile: selectedCoverFile,
                          networkUrl: coverUrl,
                          fallbackIcon: Icons.landscape_outlined,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.05),
                                Colors.black.withValues(alpha: 0.38),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Cambiar portada',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: -38,
                child: InkWell(
                  onTap: _pickLogo,
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 86,
                    height: 86,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x16000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: selectedLogoBytes == null &&
                          selectedLogoFile == null &&
                          logoUrl.isEmpty
                          ? Container(
                        color: const Color(0xFFEAF2FF),
                        child: Center(
                          child: Text(
                            _getInitials(displayChurchName),
                            style: const TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      )
                          : _buildImage(
                        memoryBytes: selectedLogoBytes,
                        pickedFile: selectedLogoFile,
                        networkUrl: logoUrl,
                        fallbackIcon: Icons.church_outlined,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayChurchName,
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7EE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            size: 15,
                            color: Color(0xFF2E7D32),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Perfil activo',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (displayLocation.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    displayLocation,
                    style: const TextStyle(
                      color: _textSoft,
                      fontSize: 13.5,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primary, _primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Perfil institucional',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Administra nombre, ubicación, contacto, descripción y datos de donación desde un solo lugar.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.8,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _summaryChip(
                            icon: Icons.edit_outlined,
                            text: 'Editable',
                          ),
                          _summaryChip(
                            icon: Icons.photo_camera_outlined,
                            text: 'Logo y portada',
                          ),
                          _summaryChip(
                            icon: Icons.favorite_outline,
                            text: 'Donaciones',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _imageActionButton(
                      text: 'Cambiar logo',
                      icon: Icons.photo_camera_outlined,
                      onTap: _pickLogo,
                    ),
                    const SizedBox(width: 10),
                    _imageActionButton(
                      text: 'Cambiar portada',
                      icon: Icons.image_outlined,
                      onTap: _pickCover,
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

  Widget _buildStickyActions() {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _saveChurch,
                icon: isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.1,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  isSaving ? 'Guardando...' : 'Guardar cambios',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Cerrar sesión',
                  style: TextStyle(fontWeight: FontWeight.w800),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const ChurchHeaderShell(
        child: Scaffold(
          backgroundColor: _surface,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final mainSubtitle = churchNameController.text.trim().isEmpty
        ? 'Completa los datos principales de tu iglesia.'
        : _safeText(
      pastorNameController.text,
      'Actualiza la información general de tu iglesia.',
    );

    final locationText = [
      if (cityController.text.trim().isNotEmpty) cityController.text.trim(),
      if (countryController.text.trim().isNotEmpty) countryController.text.trim(),
    ].join(', ');

    final locationSubtitle = locationText.isEmpty
        ? 'Ubicación, dirección y medios de contacto.'
        : locationText;

    final donationSubtitle = donationBankNameController.text.trim().isEmpty
        ? 'Configura cómo recibir apoyo y ofrendas.'
        : donationBankNameController.text.trim();

    return ChurchHeaderShell(
      child: Scaffold(
        backgroundColor: _surface,
        bottomNavigationBar: _buildStickyActions(),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerCard(),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Información principal',
                    subtitle: mainSubtitle,
                    icon: Icons.church_outlined,
                    isEditing: editMainInfo,
                    onToggle: () {
                      setState(() {
                        editMainInfo = !editMainInfo;
                      });
                    },
                    previewItems: [
                      _infoPreviewRow(
                        icon: Icons.church_outlined,
                        text: _safeText(
                          churchNameController.text,
                          'Nombre de la iglesia no agregado.',
                        ),
                      ),
                      _infoPreviewRow(
                        icon: Icons.person_outline,
                        text: _safeText(
                          pastorNameController.text,
                          'Pastor no agregado.',
                        ),
                      ),
                      _infoPreviewRow(
                        icon: Icons.description_outlined,
                        text: _safeText(
                          descriptionController.text,
                          'No hay descripción agregada.',
                        ),
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: pastorNameController,
                        decoration: _decoration(
                          'Nombre del pastor',
                          Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: _decoration(
                          'Descripción',
                          Icons.description_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                  _sectionCard(
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
                        text: _safeText(
                          countryController.text,
                          'País no agregado.',
                        ),
                      ),
                      _infoPreviewRow(
                        icon: Icons.location_city,
                        text: _safeText(
                          cityController.text,
                          'Ciudad no agregada.',
                        ),
                      ),
                      _infoPreviewRow(
                        icon: Icons.map_outlined,
                        text: _safeText(
                          sectorController.text,
                          'Sector no agregado.',
                        ),
                      ),
                      _infoPreviewRow(
                        icon: Icons.location_on_outlined,
                        text: _safeText(
                          addressController.text,
                          'Dirección no agregada.',
                        ),
                      ),
                      _infoPreviewRow(
                        icon: Icons.phone_outlined,
                        text: _safeText(
                          phoneController.text,
                          'Teléfono no agregado.',
                        ),
                      ),
                      _infoPreviewRow(
                        icon: Icons.message_outlined,
                        text: _safeText(
                          whatsappController.text,
                          'WhatsApp no agregado.',
                        ),
                      ),
                    ],
                    fields: [
                      TextFormField(
                        controller: countryController,
                        validator: (value) => _required(value, 'el país'),
                        decoration: _decoration('País', Icons.public),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cityController,
                        validator: (value) => _required(value, 'la ciudad'),
                        decoration:
                        _decoration('Ciudad', Icons.location_city),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: sectorController,
                        decoration: _decoration('Sector', Icons.map_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addressController,
                        validator: (value) => _required(value, 'la dirección'),
                        decoration: _decoration(
                          'Dirección',
                          Icons.location_on_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration:
                        _decoration('Teléfono', Icons.phone_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: whatsappController,
                        decoration:
                        _decoration('WhatsApp', Icons.message_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
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
                        text: _safeText(
                          donationBankNameController.text,
                          'Banco no agregado.',
                        ),
                      ),
                      _infoPreviewRow(
                        icon: Icons.badge_outlined,
                        text: _safeText(
                          donationAccountNameController.text,
                          'Titular no agregado.',
                        ),
                      ),
                      _infoPreviewRow(
                        icon: Icons.numbers,
                        text: _safeText(
                          donationAccountNumberController.text,
                          'Número de cuenta no agregado.',
                        ),
                      ),
                      _infoPreviewRow(
                        icon: Icons.credit_card_outlined,
                        text: _safeText(
                          donationAccountTypeController.text,
                          'Tipo de cuenta no agregado.',
                        ),
                      ),
                      _infoPreviewRow(
                        icon: Icons.info_outline,
                        text: _safeText(
                          donationInstructionsController.text,
                          'No hay instrucciones para donar.',
                        ),
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: donationBankNameController,
                        decoration: _decoration(
                          'Banco',
                          Icons.account_balance_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: donationAccountNumberController,
                        decoration: _decoration(
                          'Número de cuenta',
                          Icons.numbers,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: donationAccountTypeController,
                        decoration: _decoration(
                          'Tipo de cuenta',
                          Icons.credit_card_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}