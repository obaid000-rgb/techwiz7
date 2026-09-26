import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Every distinct outcome of trying to locate the Fan. These are kept
/// separate on purpose — each one has a different cause and a different fix,
/// and lumping them together is what made location failures look "silent".
enum LocationStatus {
  /// Permission granted and a position was obtained.
  granted,

  /// Permission hasn't been asked for yet (silent check only, no prompt shown).
  notRequested,

  /// The Fan refused the OS popup. The popup can still be shown again.
  denied,

  /// Permanently refused: the OS will NOT show the popup again — the only fix
  /// is the app's system settings page. (On Android, checkPermission() never
  /// reports this; only requestPermission() does, and it returns instantly
  /// without any popup — which is why "tapping allow did nothing".)
  deniedForever,

  /// Device location (GPS) is switched off at the OS level. This is not an
  /// app-permission problem; the fix is the device's location settings.
  serviceDisabled,

  /// Permission is fine but no position came back (no GPS fix / timeout).
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

  /// Android never reports deniedForever from checkPermission(), so once a
  /// request has returned it we remember it for the rest of the session.
  bool _knownDeniedForever = false;

  void _log(String msg) {
    if (kDebugMode) debugPrint('[Location] $msg');
  }

  /// Resolves the Fan's location into exactly one [LocationStatus].
  /// With [requestIfNeeded] false the OS popup is never shown: an unasked
  /// permission comes back as [LocationStatus.notRequested].
  Future<LocationResult> locate({bool requestIfNeeded = true}) async {
    // 1. Device-level GPS switch — checked before permission because it's a
    //    different problem with a different fix.
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

  /// Opens this app's page in system settings (fix for deniedForever).
  /// Not available on web — callers hide the button there.
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Opens the device's location settings (fix for serviceDisabled).
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Reverse-geocodes coordinates to a city name via OSM's free Nominatim
  /// API — no existing geocoding package was found in the project, and the
  /// native `geocoding` plugin is mobile-only (no Flutter Web support),
  /// so this uses a plain HTTP call to stay consistent with the rest of
  /// this task's no-API-key, cross-platform OSM approach.
  /// Returns null when no city could be determined (network error, timeout,
  /// or a location with no city/town/village) — a distinct case from any
  /// permission failure.
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
}
