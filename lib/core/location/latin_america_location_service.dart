import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class LatinAmericaLocationService {
  LatinAmericaLocationService._();

  static final LatinAmericaLocationService instance =
      LatinAmericaLocationService._();

  List<dynamic> _raw = [];
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;

    final jsonString = await rootBundle.loadString(
      'assets/data/locations.json',
    );

    final decoded = json.decode(jsonString);

    if (decoded is! List) {
      throw Exception(
        'El archivo locations.json no tiene formato de lista JSON.',
      );
    }

    _raw = decoded;
    _loaded = true;
  }

  List<String> getCountries() {
    final countries = _raw
        .map((e) => (e['name'] ?? '').toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    countries.sort(_sortEs);
    return countries;
  }

  List<String> getStates(String country) {
    final countryMap = _findCountry(country);
    if (countryMap == null) return [];

    final states = ((countryMap['states'] ?? []) as List)
        .map((e) => (e['name'] ?? '').toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    states.sort(_sortEs);
    return states;
  }

  List<String> getCities({
    required String country,
    required String state,
  }) {
    final stateMap = _findState(country: country, state: state);
    if (stateMap == null) return [];

    final cities = ((stateMap['cities'] ?? []) as List)
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .where(_isUsefulCity)
        .toSet()
        .toList();

    cities.sort(_sortEs);
    return cities;
  }

  Map<String, dynamic>? _findCountry(String country) {
    for (final item in _raw) {
      final map = Map<String, dynamic>.from(item as Map);
      if (_normalize((map['name'] ?? '').toString()) == _normalize(country)) {
        return map;
      }
    }
    return null;
  }

  Map<String, dynamic>? _findState({
    required String country,
    required String state,
  }) {
    final countryMap = _findCountry(country);
    if (countryMap == null) return null;

    final states = (countryMap['states'] ?? []) as List;

    for (final item in states) {
      final map = Map<String, dynamic>.from(item as Map);
      final name = (map['name'] ?? '').toString();
      if (_normalize(name) == _normalize(state)) {
        return map;
      }
    }
    return null;
  }

  bool _isUsefulCity(String value) {
    final v = _normalize(value);

    if (v.isEmpty) return false;

    const blockedStarts = [
      'departamento de ',
      'department of ',
      'departamento ',
      'province of ',
      'provincia de ',
      'distrito de ',
      'district of ',
      'municipio de ',
    ];

    for (final prefix in blockedStarts) {
      if (v.startsWith(prefix)) return false;
    }

    return true;
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

  int _sortEs(String a, String b) => _normalize(a).compareTo(_normalize(b));
}