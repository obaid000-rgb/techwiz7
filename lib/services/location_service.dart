import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  /// Returns the Fan's current position, or null if location services are
  /// off or permission isn't already granted — callers fall back to the
  /// existing city-matching behavior rather than prompting a custom flow.
  Future<Position?> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
    } catch (_) {
      return null;
    }
  }

  /// Reverse-geocodes coordinates to a city name via OSM's free Nominatim
  /// API — no existing geocoding package was found in the project, and the
  /// native `geocoding` plugin is mobile-only (no Flutter Web support),
  /// so this uses a plain HTTP call to stay consistent with the rest of
  /// this task's no-API-key, cross-platform OSM approach.
  Future<String?> reverseGeocodeCity(double lat, double lon) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&zoom=10',
    );
    try {
      final res = await http.get(
        uri,
        headers: {'User-Agent': 'FandomVerseApp/1.0 (com.example.fandom_verse)'},
      );
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;
      return address?['city'] ??
          address?['town'] ??
          address?['village'] ??
          address?['county'] as String?;
    } catch (_) {
      return null;
    }
  }
}
