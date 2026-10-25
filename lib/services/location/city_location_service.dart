import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class CitySuggestion {
  final String city;
  final String region;
  final String country;
  final double latitude;
  final double longitude;

  const CitySuggestion({
    required this.city,
    required this.region,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  String get label {
    final parts = <String>[city];
    if (region.isNotEmpty && region.toLowerCase() != city.toLowerCase()) {
      parts.add(region);
    }
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }
}

class CityLocationService {
  Future<CitySuggestion?> currentCity() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isEmpty) return null;
    final place = placemarks.first;
    final city = (place.locality ?? place.subAdministrativeArea ?? '').trim();
    if (city.isEmpty) return null;

    return CitySuggestion(
      city: city,
      region: (place.administrativeArea ?? '').trim(),
      country: (place.country ?? '').trim(),
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<List<CitySuggestion>> searchCities(String query) async {
    final text = query.trim();
    if (text.length < 2) return const [];

    try {
      final locations = await locationFromAddress(text);
      final results = <CitySuggestion>[];
      final seen = <String>{};

      for (final location in locations.take(6)) {
        final placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        if (placemarks.isEmpty) continue;
        final place = placemarks.first;
        final city = (place.locality ?? place.subAdministrativeArea ?? '').trim();
        if (city.isEmpty) continue;
        final region = (place.administrativeArea ?? '').trim();
        final country = (place.country ?? '').trim();
        final key = '$city|$region|$country'.toLowerCase();
        if (!seen.add(key)) continue;

        results.add(
          CitySuggestion(
            city: city,
            region: region,
            country: country,
            latitude: location.latitude,
            longitude: location.longitude,
          ),
        );
      }
      return results;
    } catch (_) {
      return const [];
    }
  }
}
