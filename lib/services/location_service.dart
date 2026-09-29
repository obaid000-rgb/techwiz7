import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;


enum LocationStatus {
  /// Permission granted and a position was obtained.
  granted,

  notRequested,

  denied,


  deniedForever,

  serviceDisabled,

 
  positionUnavailable,
}

class LocationResult {
  final LocationStatus status;
  final Position? position;
  const LocationResult(this.status, [this.position]);
}

class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  static const Duration _positionTimeout = Duration(seconds: 15);
  static const Duration _geocodeTimeout = Duration(seconds: 8);


  bool _knownDeniedForever = false;

  void _log(String msg) {
    if (kDebugMode) debugPrint('[Location] $msg');
  }

  /// Resolves the Fan's location into exactly one [LocationStatus].
  /// With [requestIfNeeded] false the OS popup is never shown: an unasked
  /// permission comes back as [LocationStatus.notRequested].
  Future<LocationResult> locate({bool requestIfNeeded = true}) async {

    if (!await Geolocator.isLocationServiceEnabled()) {
      _log('state=serviceDisabled (device location is off)');
      return const LocationResult(LocationStatus.serviceDisabled);
    }

    // 2. App permission.
    var permission = await Geolocator.checkPermission();
    _log('checkPermission -> $permission');
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _knownDeniedForever = false; // e.g. re-enabled from app settings
    } else if (permission == LocationPermission.deniedForever ||
        (_knownDeniedForever && permission == LocationPermission.denied)) {
      _log('state=deniedForever (OS popup will not appear)');
      return const LocationResult(LocationStatus.deniedForever);
    } else {
      // permission == denied: either never asked, or refused once.
      if (!requestIfNeeded) {
        _log('state=notRequested (silent check, no popup shown)');
        return const LocationResult(LocationStatus.notRequested);
      }
      try {
        permission = await Geolocator.requestPermission();
      } catch (e) {
        _log('requestPermission threw: $e');
        permission = LocationPermission.denied;
      }
      _log('requestPermission -> $permission');
      if (permission == LocationPermission.deniedForever) {
        _knownDeniedForever = true;
        _log('state=deniedForever (OS popup will not appear)');
        return const LocationResult(LocationStatus.deniedForever);
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        _log('state=denied (popup can be shown again)');
        return const LocationResult(LocationStatus.denied);
      }
    }

    // 3. Actual position — time-limited so the UI can never spin forever.
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: _positionTimeout,
        ),
      );
      _log('state=granted (${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)})');
      return LocationResult(LocationStatus.granted, pos);
    } catch (e) {
      _log('getCurrentPosition failed: $e');
      if (!kIsWeb) {
        try {
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) {
            _log('state=granted (using last known position)');
            return LocationResult(LocationStatus.granted, last);
          }
        } catch (_) {}
      }
      _log('state=positionUnavailable');
      return const LocationResult(LocationStatus.positionUnavailable);
    }
  }

  /// Returns the Fan's current position, or null on any failure. Kept for
  /// callers that only need coordinates (admin map picker).
  Future<Position?> getCurrentPosition({bool requestIfNeeded = true}) async =>
      (await locate(requestIfNeeded: requestIfNeeded)).position;


  Future<bool> openAppSettings() => Geolocator.openAppSettings();


  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();


  Future<String?> reverseGeocodeCity(double lat, double lon) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&zoom=10&accept-language=en',
    );
    try {
      final res = await http.get(
        uri,
        headers: {'User-Agent': 'FandomVerseApp/1.0 (com.example.fandom_verse)'},
      ).timeout(_geocodeTimeout);
      if (res.statusCode != 200) {
        _log('geocode failed: HTTP ${res.statusCode}');
        return null;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;
      final city = (address?['city'] ??
          address?['town'] ??
          address?['village'] ??
          address?['county']) as String?;
      _log(city == null || city.isEmpty ? 'geocode empty: no city in response' : 'geocode -> $city');
      return (city == null || city.isEmpty) ? null : city;
    } catch (e) {
      _log('geocode failed: $e');
      return null;
    }
  }


  Future<({String? city, String? address})> reverseGeocodeAddress(double lat, double lon) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&zoom=18&accept-language=en',
    );
    try {
      final res = await http.get(
        uri,
        headers: {'User-Agent': 'FandomVerseApp/1.0 (com.example.fandom_verse)'},
      ).timeout(_geocodeTimeout);
      if (res.statusCode != 200) {
        _log('address geocode failed: HTTP ${res.statusCode}');
        return (city: null, address: null);
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final parts = data['address'] as Map<String, dynamic>?;
      final city = (parts?['city'] ?? parts?['town'] ?? parts?['village'] ?? parts?['county'])
          as String?;
      final address = data['display_name'] as String?;
      return (
        city: (city == null || city.isEmpty) ? null : city,
        address: (address == null || address.isEmpty) ? null : address,
      );
    } catch (e) {
      _log('address geocode failed: $e');
      return (city: null, address: null);
    }
  }
}
