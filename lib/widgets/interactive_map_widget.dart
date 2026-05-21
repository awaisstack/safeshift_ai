import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/glass_card.dart';

// Predefined Coordinates for Rawalpindi / Islamabad
final Map<String, LatLng> rawalpindiIslamabadCoordinates = {
  "Bahria Phase 7": const LatLng(33.5235, 73.0805),
  "Bahria Phase 8": const LatLng(33.5042, 73.0763),
  "DHA Phase 1": const LatLng(33.5358, 73.1190),
  "Saddar Rawalpindi": const LatLng(33.5984, 73.0551),
  "Committee Chowk": const LatLng(33.6062, 73.0688),
  "PWD": const LatLng(33.5670, 73.1360),
  "G-13 Islamabad": const LatLng(33.6441, 72.9691),
  "F-10 Islamabad": const LatLng(33.6934, 73.0118),
  "I-8 Islamabad": const LatLng(33.6702, 73.0754),
  "Blue Area Islamabad": const LatLng(33.7126, 73.0617),
};

double calculateHaversineDistance(LatLng p1, LatLng p2) {
  const double r = 6371; // Earth radius in km
  final double dLat = _toRadians(p2.latitude - p1.latitude);
  final double dLon = _toRadians(p2.longitude - p1.longitude);
  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(p1.latitude)) * cos(_toRadians(p2.latitude)) *
      sin(dLon / 2) * sin(dLon / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}

double _toRadians(double degree) {
  return degree * pi / 180;
}

class InteractiveMapWidget extends StatelessWidget {
  final String pickupName;
  final String dropoffName;
  final double height;

  const InteractiveMapWidget({
    super.key,
    required this.pickupName,
    required this.dropoffName,
    this.height = 250,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final pickupLatLng = appState.pickupLatLng;
    final dropoffLatLng = appState.dropoffLatLng;

    // Calculate center LatLng to focus map
    final centerLat = (pickupLatLng.latitude + dropoffLatLng.latitude) / 2;
    final centerLng = (pickupLatLng.longitude + dropoffLatLng.longitude) / 2;
    final centerLatLng = LatLng(centerLat, centerLng);

    final List<LatLng> polyPoints = appState.routePoints.isNotEmpty 
        ? appState.routePoints 
        : [pickupLatLng, dropoffLatLng];

    final routeSource = appState.routeSource;
    final routeLabel = appState.routeLabel;
    final roadDistance = appState.calculatedDistance;
    final durationMins = appState.routeDurationMins;

    // Determine colors/icons based on route source for hackathon badge honesty
    Color badgeBgColor;
    Color badgeTextColor;
    if (routeSource == 'google') {
      badgeBgColor = const Color(0xFF2E7D32).withAlpha(40);
      badgeTextColor = const Color(0xFF81C784);
    } else if (routeSource == 'osm_fallback') {
      badgeBgColor = const Color(0xFFE65100).withAlpha(40);
      badgeTextColor = const Color(0xFFFFB74D);
    } else {
      badgeBgColor = const Color(0xFF131319).withAlpha(40);
      badgeTextColor = const Color(0xFF908F9D);
    }

    return Column(
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x33CFC6B0), width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: centerLatLng,
                  initialZoom: 11.5,
                  minZoom: 8,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: "com.safeshift.ai",
                    // Apply a beautiful dark tint using native tiles color filtration
                    tileBuilder: (context, tileWidget, tile) {
                      return ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          -0.2, -0.2, -0.2, 0.0, 255.0, // Red invert & dim
                          -0.2, -0.2, -0.2, 0.0, 255.0, // Green invert & dim
                          -0.2, -0.2, -0.2, 0.0, 255.0, // Blue invert & dim
                          0.0, 0.0, 0.0, 1.0, 0.0,
                        ]),
                        child: tileWidget,
                      );
                    },
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: polyPoints,
                        strokeWidth: 4.0,
                        color: const Color(0xFFFFB5A1),
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: pickupLatLng,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFF81C784),
                          size: 36,
                        ),
                      ),
                      Marker(
                        point: dropoffLatLng,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFFF8B8B),
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Live Route / Fallback Badges responsive top container
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeTextColor.withAlpha(50)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            routeSource == 'google' 
                                ? Icons.offline_pin_outlined 
                                : routeSource == 'osm_fallback'
                                    ? Icons.warning_amber_rounded
                                    : Icons.help_outline_rounded,
                            color: badgeTextColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            routeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.bold,
                              color: badgeTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131319).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x33CFC6B0)),
                      ),
                      child: Text(
                        routeSource == 'google' ? "OSM Map + Google Route" : "OpenStreetMap tiles",
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'Outfit',
                          color: const Color(0xFFCFC6B0).withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Route: ${appState.pickupLocation} → ${appState.dropoffLocation}",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE4E1EA),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              routeSource == 'google'
                                  ? "Live route ETA: ~$durationMins mins driving"
                                  : "MVP approximate distance via real coordinates.",
                              style: const TextStyle(fontSize: 9, color: Color(0xFF908F9D)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFB5A1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${roadDistance.toStringAsFixed(1)} km",
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFFFFB5A1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
