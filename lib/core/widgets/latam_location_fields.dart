import 'package:flutter/material.dart';
import 'package:red_cristiana/core/location/latin_america_location_service.dart';

class LatamLocationFields extends StatefulWidget {
  final TextEditingController countryController;
  final TextEditingController cityController;
  final TextEditingController sectorController;
  final TextEditingController? addressController;
  final InputDecoration Function(String label, IconData icon) decorationBuilder;
  final String? Function(String? value, String fieldName) requiredValidator;
  final String defaultCountry;

  const LatamLocationFields({
    super.key,
    required this.countryController,
    required this.cityController,
    required this.sectorController,
    required this.decorationBuilder,
    required this.requiredValidator,
    this.addressController,
    this.defaultCountry = 'Ecuador',
  });

  @override
  State<LatamLocationFields> createState() => _LatamLocationFieldsState();
}

class _LatamLocationFieldsState extends State<LatamLocationFields> {
  final service = LatinAmericaLocationService.instance;

  bool _loading = true;
  List<String> _countries = [];
  List<String> _states = [];
  List<String> _cities = [];

  String _selectedCountry = '';
  String _selectedState = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
  try {
    await service.load();

    _countries = service.getCountries();

    final initialCountry = widget.countryController.text.trim().isNotEmpty
        ? widget.countryController.text.trim()
        : widget.defaultCountry;

    if (_countries.contains(initialCountry)) {
      _selectedCountry = initialCountry;
      widget.countryController.text = initialCountry;
      _states = service.getStates(initialCountry);
    } else if (_countries.isNotEmpty) {
      _selectedCountry = _countries.first;
      widget.countryController.text = _countries.first;
      _states = service.getStates(_countries.first);
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error cargando ubicaciones: $e'),
      ),
    );
  } finally {
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }
}

  Future<void> _pickCountry() async {
    final result = await _showSelector(
      title: 'Selecciona el país',
      items: _countries,
    );

    if (result == null || result == _selectedCountry) return;

    setState(() {
      _selectedCountry = result;
      _selectedState = '';
      _states = service.getStates(result);
      _cities = [];

      widget.countryController.text = result;
      widget.cityController.clear();
      widget.sectorController.clear();
      widget.addressController?.clear();
    });
  }

  Future<void> _pickState() async {
    if (_selectedCountry.isEmpty) {
      _showInfo('Primero selecciona el país.');
      return;
    }

    if (_states.isEmpty) {
      _showInfo('No hay estados o provincias disponibles para este país.');
      return;
    }

    final result = await _showSelector(
      title: 'Selecciona el estado o provincia',
      items: _states,
    );

    if (result == null || result == _selectedState) return;

    setState(() {
      _selectedState = result;
      _cities = service.getCities(
        country: _selectedCountry,
        state: _selectedState,
      );

      widget.cityController.clear();
      widget.sectorController.clear();
      widget.addressController?.clear();
    });
  }

  Future<void> _pickCity() async {
    if (_selectedCountry.isEmpty) {
      _showInfo('Primero selecciona el país.');
      return;
    }

    if (_selectedState.isEmpty) {
      _showInfo('Primero selecciona el estado o provincia.');
      return;
    }

    if (_cities.isEmpty) {
      _showInfo('No hay ciudades disponibles para esa selección.');
      return;
    }

    final result = await _showSelector(
      title: 'Selecciona la ciudad',
      items: _cities,
    );

    if (result == null) return;

    setState(() {
      widget.cityController.text = result;
      widget.sectorController.clear();
      widget.addressController?.clear();
    });
  }

  Future<String?> _showSelector({
    required String title,
    required List<String> items,
  }) async {
    final searchController = TextEditingController();
    List<String> filtered = List<String>.from(items);

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateFilter(String value) {
              final query = _normalize(value);
              setModalState(() {
                filtered = items.where((item) {
                  return _normalize(item).contains(query);
                }).toList();
              });
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.72,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        onChanged: updateFilter,
                        decoration: const InputDecoration(
                          hintText: 'Buscar...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: filtered.isEmpty
                                  ? const Center(
                                child: Text('No se encontraron resultados.'),
                              )
                                  : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return ListTile(
                                    title: Text(item),
                                    onTap: () => Navigator.pop(context, item),
                                  );
                                },
                              ),
                            ),

                            // 👇 NUEVO BOTÓN
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.add),
                              title: const Text('No encuentro mi ciudad'),
                              onTap: () async {
                                final customCity = await _showCustomCityDialog();
                                if (customCity != null) {
                                  Navigator.pop(context, customCity);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showInfo(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
  }

  Widget _selectorField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required String? Function(String?) validator,
    String? hintText,
  }) {
    return InkWell(
      onTap: _loading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: IgnorePointer(
        child: TextFormField(
          controller: controller,
          validator: validator,
          decoration: widget.decorationBuilder(label, icon).copyWith(
            hintText: hintText,
            suffixIcon: _loading
                ? const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : const Icon(Icons.arrow_drop_down),
          ),
        ),
      ),
    );
  }

  String _formatCity(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return '';

    final words = cleaned.toLowerCase().split(' ');
    return words
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _selectorField(
          controller: widget.countryController,
          label: 'País',
          icon: Icons.public,
          onTap: _pickCountry,
          validator: (value) => widget.requiredValidator(value, 'el país'),
          hintText: 'Selecciona un país',
        ),
        const SizedBox(height: 16),
        _selectorField(
          controller: TextEditingController(text: _selectedState),
          label: 'Estado / Provincia',
          icon: Icons.map,
          onTap: _pickState,
          validator: (_) {
            if ((_selectedState).trim().isEmpty) {
              return 'Selecciona el estado o provincia';
            }
            return null;
          },
          hintText: 'Selecciona un estado o provincia',
        ),
        const SizedBox(height: 16),
        _selectorField(
          controller: widget.cityController,
          label: 'Ciudad',
          icon: Icons.location_city,
          onTap: _pickCity,
          validator: (value) => widget.requiredValidator(value, 'la ciudad'),
          hintText: 'Selecciona una ciudad',
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: widget.sectorController,
          decoration: widget.decorationBuilder('Sector', Icons.map_outlined),
        ),
        if (widget.addressController != null) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.addressController,
            validator: (value) =>
                widget.requiredValidator(value, 'la dirección exacta'),
            maxLines: 2,
            decoration: widget.decorationBuilder(
              'Dirección exacta',
              Icons.location_on_outlined,
            ),
          ),
        ],
      ],
    );
  }
  Future<String?> _showCustomCityDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Escribe tu ciudad'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Ej: La Concordia',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.length < 3) return;

                Navigator.pop(context, _formatCity(value));
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

}