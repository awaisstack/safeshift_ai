import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GoogleMapsService {
  static final GoogleMapsService _instance = GoogleMapsService._internal();
  factory GoogleMapsService() => _instance;
  GoogleMapsService._internal();

  String get _mapsKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  String get _placesKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? _mapsKey;
  String get _routesKey => dotenv.env['GOOGLE_ROUTES_API_KEY'] ?? _mapsKey;

  bool get isGoogleMapsEnabled => _mapsKey.isNotEmpty && _mapsKey.startsWith('AIza');
  bool get isPlacesEnabled => _placesKey.isNotEmpty && _placesKey.startsWith('AIza');
  bool get isRoutesEnabled => _routesKey.isNotEmpty && _routesKey.startsWith('AIza');

  /// Gets the current location from GPS using Geolocator
  Future<LatLng?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print("GoogleMapsService.getCurrentLocation error: $e");
      return null;
    }
  }

  /// Autocomplete Search using Places API (New)
  Future<List<Map<String, dynamic>>> autocomplete(String input) async {
    if (input.trim().isEmpty || !isPlacesEnabled) return [];

    try {
      final url = Uri.parse('https://places.googleapis.com/v1/places:autocomplete');
      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _placesKey,
      };

      // Focus results around Islamabad / Rawalpindi (Latitude: 33.6844, Longitude: 73.0479)
      final body = jsonEncode({
        'input': input,
        'locationBias': {
          'circle': {
            'center': {
              'latitude': 33.6844,
              'longitude': 73.0479,
            },
            'radius': 30000.0, // 30km radius bias
          }
        }
      });

      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final suggestions = data['suggestions'] as List?;
        if (suggestions != null) {
          return suggestions.map((s) {
            final placePrediction = s['placePrediction'];
            return {
              'placeId': placePrediction['place'] as String,
              'description': placePrediction['text']['text'] as String,
            };
          }).toList();
        }
      } else {
        print("Places API (New) Autocomplete returned status: ${response.statusCode}, body: ${response.body}");
      }
    } catch (e) {
      print("GoogleMapsService.autocomplete error: $e");
    }
    return [];
  }

  /// Get Place Coordinates and Address Details using Places API (New)
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (placeId.startsWith('osm_')) {
      try {
        final parts = placeId.split('_');
        final lat = double.parse(parts[2]);
        final lng = double.parse(parts[3]);
        return {
          'latLng': LatLng(lat, lng),
          'name': 'OSM Selected Location',
          'address': '',
        };
      } catch (e) {
        print("GoogleMapsService: error parsing OSM details: $e");
      }
    }

    if (!isPlacesEnabled) return null;

    try {
      // Place ID in Places API (New) is in the format "places/ChIJ..."
      final name = placeId.startsWith('places/') ? placeId : 'places/$placeId';
      final url = Uri.parse('https://places.googleapis.com/v1/$name');
      final headers = {
        'X-Goog-Api-Key': _placesKey,
        'X-Goog-FieldMask': 'id,displayName,formattedAddress,location',
      };

      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final location = data['location'];
        if (location != null) {
          final lat = location['latitude'] as double;
          final lng = location['longitude'] as double;
          final displayNameObj = data['displayName'];
          final nameStr = displayNameObj != null ? displayNameObj['text'] as String : data['formattedAddress'] as String? ?? "Custom Location";
          return {
            'latLng': LatLng(lat, lng),
            'name': nameStr,
            'address': data['formattedAddress'] as String? ?? '',
          };
        }
      } else {
        print("Places API (New) Details returned status: ${response.statusCode}, body: ${response.body}");
      }
    } catch (e) {
      print("GoogleMapsService.getPlaceDetails error: $e");
    }
    return null;
  }

  /// Unified search that tries Google first, then falls back to OpenStreetMap Nominatim and Photon
  Future<List<Map<String, dynamic>>> searchPlaces(String input) async {
    print("GoogleMapsService: searchPlaces called with input: '$input'");
    if (input.trim().isEmpty) return [];

    // 1. Try Google Places first
    if (isPlacesEnabled) {
      print("GoogleMapsService: Google Places is enabled. Calling autocomplete...");
      final googleResults = await autocomplete(input);
      if (googleResults.isNotEmpty) {
        print("GoogleMapsService: Google Places returned ${googleResults.length} results.");
        return googleResults;
      }
      print("GoogleMapsService: Google Places returned 0 results or failed. Falling back to OSM/Photon...");
    } else {
      print("GoogleMapsService: Google Places NOT enabled. Falling back to OSM/Photon...");
    }

    // 2. Fall back to OpenStreetMap Nominatim (using a standard browser User-Agent to avoid 403 blocks)
    try {
      final query = Uri.encodeComponent("$input, pakistan");
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=6&addressdetails=1');
      print("GoogleMapsService: Querying OSM Nominatim URL: $url");
      
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      });
      print("GoogleMapsService: OSM Nominatim status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          print("GoogleMapsService: OSM Nominatim returned ${data.length} results.");
          return data.map<Map<String, dynamic>>((item) {
            final displayName = item['display_name'] as String;
            final lat = item['lat'];
            final lon = item['lon'];
            final placeId = item['place_id'].toString();
            
            return {
              'placeId': 'osm_${placeId}_${lat}_${lon}',
              'description': displayName,
            };
          }).toList();
        }
      } else {
        print("GoogleMapsService: OSM Nominatim failed with status ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      print("GoogleMapsService: OSM Nominatim search error: $e");
    }

    // 3. Fall back to Photon (Komoot) API as a secondary failsafe
    try {
      String photonQuery = input;
      if (!photonQuery.toLowerCase().contains("pakistan") && !photonQuery.toLowerCase().contains("pk")) {
        photonQuery = "$photonQuery pakistan";
      }
      final query = Uri.encodeComponent(photonQuery);
      final url = Uri.parse('https://photon.komoot.io/api/?q=$query&limit=6&lat=33.6844&lon=73.0479');
      print("GoogleMapsService: Querying Photon URL: $url");

      final response = await http.get(url);
      print("GoogleMapsService: Photon status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List features = data['features'] as List? ?? [];
        if (features.isNotEmpty) {
          print("GoogleMapsService: Photon returned ${features.length} results.");
          return features.map<Map<String, dynamic>>((f) {
            final props = f['properties'] as Map<String, dynamic>;
            final geom = f['geometry'] as Map<String, dynamic>;
            final coords = geom['coordinates'] as List;
            
            final name = props['name'] as String? ?? "";
            final street = props['street'] as String? ?? "";
            final city = props['city'] as String? ?? props['town'] as String? ?? "";
            final state = props['state'] as String? ?? "";
            final country = props['country'] as String? ?? "";
            
            final parts = [name, street, city, state, country]
                .where((s) => s.isNotEmpty)
                .toList();
            final description = parts.join(", ");
            
            final lat = coords[1];
            final lon = coords[0];
            final placeId = props['osm_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

            return {
              'placeId': 'osm_${placeId}_${lat}_${lon}',
              'description': description,
            };
          }).toList();
        }
      }
    } catch (e) {
      print("GoogleMapsService: Photon search error: $e");
    }

    return [];
  }

  /// Reverse geocode LatLng to address string using Nominatim & Photon fallbacks
  Future<String> reverseGeocode(LatLng coord) async {
    // 1. Try OSM Nominatim first
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${coord.latitude}&lon=${coord.longitude}&format=json');
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'] as String? ?? "${coord.latitude.toStringAsFixed(4)}, ${coord.longitude.toStringAsFixed(4)}";
      }
    } catch (e) {
      print("OSM Nominatim reverse geocode error: $e");
    }

    // 2. Try Photon reverse geocoding fallback
    try {
      final url = Uri.parse('https://photon.komoot.io/reverse?lat=${coord.latitude}&lon=${coord.longitude}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List features = data['features'] as List? ?? [];
        if (features.isNotEmpty) {
          final props = features[0]['properties'] as Map<String, dynamic>;
          final name = props['name'] as String? ?? "";
          final street = props['street'] as String? ?? "";
          final city = props['city'] as String? ?? props['town'] as String? ?? "";
          final state = props['state'] as String? ?? "";
          
          final parts = [name, street, city, state]
              .where((s) => s.isNotEmpty)
              .toList();
          if (parts.isNotEmpty) {
            return parts.join(", ");
          }
        }
      }
    } catch (e) {
      print("Photon reverse geocode error: $e");
    }

    return "${coord.latitude.toStringAsFixed(4)}, ${coord.longitude.toStringAsFixed(4)}";
  }

  /// Compute Driving Route using Routes API (New)
  Future<Map<String, dynamic>?> computeRoute(LatLng origin, LatLng dest) async {
    if (!isRoutesEnabled) return null;

    try {
      final url = Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes');
      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _routesKey,
        'X-Goog-FieldMask': 'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline',
      };

      final body = jsonEncode({
        'origin': {
          'location': {
            'latLng': {
              'latitude': origin.latitude,
              'longitude': origin.longitude,
            }
          }
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': dest.latitude,
              'longitude': dest.longitude,
            }
          }
        },
        'travelMode': 'DRIVE',
        'routingPreference': 'TRAFFIC_AWARE',
      });

      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes.first;
          final distanceMeters = route['distanceMeters'] as int? ?? 0;
          final durationStr = route['duration'] as String? ?? '0s'; // e.g. "1200s"
          final encodedPolyline = route['polyline']?.containsKey('encodedPolyline') == true
              ? route['polyline']['encodedPolyline'] as String
              : '';

          final distanceKm = distanceMeters / 1000.0;
          final durationSecs = int.tryParse(durationStr.replaceAll('s', '')) ?? 0;
          final durationMins = (durationSecs / 60.0).round();

          List<LatLng> points = [];
          if (encodedPolyline.isNotEmpty) {
            points = decodePolyline(encodedPolyline);
          } else {
            points = [origin, dest];
          }

          return {
            'distanceKm': distanceKm,
            'durationMins': durationMins,
            'durationStr': '$durationMins mins',
            'polylinePoints': points,
            'success': true,
          };
        }
      } else {
        print("Routes API returned status: ${response.statusCode}, body: ${response.body}");
      }
    } catch (e) {
      print("GoogleMapsService.computeRoute error: $e");
    }
    return null;
  }

  /// Self-contained compact decoder for Google's Polyline Format
  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
