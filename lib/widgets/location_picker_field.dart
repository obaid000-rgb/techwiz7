import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// OSM map the admin taps to place (or re-tap to move) a pin for an event's
/// location, or jumps to their own GPS position via the locate button.
/// Reverse-geocodes the pin to a city name on every placement.
class LocationPickerField extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final void Function(double lat, double lng, String? city) onLocationPicked;

  const LocationPickerField({
    super.key,
    this.initialLat,
    this.initialLng,
    required this.onLocationPicked,
  });

  @override
  State<LocationPickerField> createState() => _LocationPickerFieldState();
}

class _LocationPickerFieldState extends State<LocationPickerField> {
  final MapController _mapController = MapController();
  LatLng? _pin;
  bool _resolvingCity = false;
  bool _locating = false;
  String? _locateError;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _pin = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  Future<void> _placePin(LatLng point) async {
    setState(() {
      _pin = point;
      _resolvingCity = true;
    });
    final city =
        await LocationService.instance.reverseGeocodeCity(point.latitude, point.longitude);
    if (!mounted) return;
    setState(() => _resolvingCity = false);
    widget.onLocationPicked(point.latitude, point.longitude, city);
  }

  Future<void> _onTap(TapPosition tapPos, LatLng point) => _placePin(point);

  Future<void> _useMyLocation() async {
    setState(() {
      _locating = true;
      _locateError = null;
    });
    final position = await LocationService.instance.getCurrentPosition();
    if (!mounted) return;
    setState(() => _locating = false);
    if (position == null) {
      setState(() => _locateError =
          'Could not get your location — check location permission and try again.');
      return;
    }
    final point = LatLng(position.latitude, position.longitude);
    _mapController.move(point, 14);
    await _placePin(point);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pin ?? const LatLng(20, 0),
                    initialZoom: _pin != null ? 13 : 2,
                    onTap: _onTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.fandom_verse',
                    ),
                    if (_pin != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: _pin!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_pin,
                              color: AppTheme.pink, size: 40),
                        ),
                      ]),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: AppTheme.card,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _locating ? null : _useMyLocation,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _locating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppTheme.cyan),
                              )
                            : const Icon(Icons.my_location, color: AppTheme.cyan, size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _resolvingCity
              ? 'Finding city name…'
              : _pin == null
                  ? 'Tap the map (or use the locate button) to drop a pin for this event\'s location.'
                  : 'Pinned at ${_pin!.latitude.toStringAsFixed(4)}, '
                      '${_pin!.longitude.toStringAsFixed(4)} — tap elsewhere to adjust.',
          style: AppTheme.inter(size: 11, color: Colors.grey),
        ),
        if (_locateError != null) ...[
          const SizedBox(height: 4),
          Text(_locateError!, style: AppTheme.inter(size: 11, color: Colors.redAccent)),
        ],
      ],
    );
  }
}
