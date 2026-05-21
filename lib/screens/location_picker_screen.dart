import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/app_state.dart';
import '../services/google_maps_service.dart';
import '../widgets/glass_card.dart';

class LocationPickerScreen extends StatefulWidget {
  final bool isPickup;

  const LocationPickerScreen({super.key, required this.isPickup});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GoogleMapsService _mapsService = GoogleMapsService();
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _predictions = [];
  bool _isSearching = false;
  bool _isLocating = false;
  bool _isReverseGeocoding = false;
  Timer? _debounceTimer;

  LatLng _currentCenter = const LatLng(33.6844, 73.0479); // default to Islamabad
  String _selectedAddress = "Select point on map";

  final List<String> _fallbackLocations = [
    "DHA Phase 1",
    "PWD",
    "Bahria Phase 7",
    "Bahria Phase 8",
    "G-13 Islamabad",
    "F-10 Islamabad",
    "I-8 Islamabad",
    "Blue Area Islamabad",
    "Saddar Rawalpindi",
    "Committee Chowk",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      setState(() {
        _currentCenter = widget.isPickup ? appState.pickupLatLng : appState.dropoffLatLng;
        _selectedAddress = widget.isPickup ? appState.pickupLocation : appState.dropoffLocation;
      });
      _mapController.move(_currentCenter, 15.0);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _onSearchChanged(String val) async {
    _debounceTimer?.cancel();
    if (val.trim().isEmpty) {
      setState(() {
        _predictions = [];
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _isSearching = true;
      });

      final results = await _mapsService.searchPlaces(val);

      if (mounted) {
        setState(() {
          _predictions = results;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });

    final loc = await _mapsService.getCurrentLocation();

    if (!mounted) return;

    setState(() {
      _isLocating = false;
    });

    if (loc != null) {
      setState(() {
        _currentCenter = loc;
        _isReverseGeocoding = true;
      });
      _mapController.move(loc, 15.5);

      final address = await _mapsService.reverseGeocode(loc);
      if (mounted) {
        setState(() {
          _selectedAddress = address;
          _isReverseGeocoding = false;
        });
      }
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1F1F25),
          title: const Text(
            "Location Unavailable",
            style: TextStyle(fontFamily: 'Outfit', color: Color(0xFFFFB5A1), fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "GPS location service is disabled, permissions are denied, or the request timed out. Please drag the map manually or select a predefined zone.",
            style: TextStyle(fontFamily: 'Outfit', color: Color(0xFFE4E1EA)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK", style: TextStyle(color: Color(0xFFFFB5A1))),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _selectPlace(Map<String, dynamic> prediction) async {
    final placeId = prediction['placeId'] as String;
    final description = prediction['description'] as String;

    setState(() {
      _isSearching = true;
    });

    final details = await _mapsService.getPlaceDetails(placeId);

    if (!mounted) return;

    setState(() {
      _isSearching = false;
      _predictions = [];
      _searchController.clear();
    });

    if (details != null && details['latLng'] != null) {
      final LatLng latLng = details['latLng'] as LatLng;
      setState(() {
        _currentCenter = latLng;
        _selectedAddress = description;
      });
      _mapController.move(latLng, 15.5);
      _searchFocusNode.unfocus();
    }
  }

  void _selectPredefined(String name) {
    final appState = Provider.of<AppState>(context, listen: false);
    final latLng = appState.getCoordinatesForLocation(name);

    setState(() {
      _currentCenter = latLng;
      _selectedAddress = name;
    });
    _mapController.move(latLng, 15.5);
    _searchFocusNode.unfocus();
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      setState(() {
        _currentCenter = camera.center;
      });

      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 800), () async {
        if (!mounted) return;
        setState(() {
          _isReverseGeocoding = true;
        });

        final address = await _mapsService.reverseGeocode(_currentCenter);

        if (mounted) {
          setState(() {
            _selectedAddress = address;
            _isReverseGeocoding = false;
          });
        }
      });
    }
  }

  void _confirmLocation() {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // We clean up address string if it contains coordinates to look professional
    String addressName = _selectedAddress;
    String source = 'places';
    if (addressName.contains("GPS")) {
      source = 'gps';
    } else if (addressName.startsWith("33.") || addressName.startsWith("34.")) {
      source = 'manual';
      addressName = widget.isPickup ? "Selected Pickup Coordinates" : "Selected Drop-off Coordinates";
    }

    if (widget.isPickup) {
      appState.setCustomPickup(addressName, _currentCenter, source: source);
    } else {
      appState.setCustomDropoff(addressName, _currentCenter, source: source);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isPickup ? "Pickup Location" : "Drop-off Location";
    final themeColor = widget.isPickup ? const Color(0xFF81C784) : const Color(0xFFFFB5A1);

    return Scaffold(
      backgroundColor: const Color(0xFF131319),
      body: Stack(
        children: [
          // 1. Full Screen Interactive Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15.0,
              maxZoom: 18.0,
              minZoom: 10.0,
              onPositionChanged: _onMapPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png",
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.safeshift.ai',
              ),
            ],
          ),

          // 2. Fixed Center Pin Overlay (Like Uber/Careem)
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 40), // Offset slightly to align pin point to center
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: themeColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        widget.isPickup ? "Pickup Here" : "Drop Here",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeColor.withOpacity(0.2),
                        ),
                      ),
                      Icon(
                        Icons.location_on,
                        size: 40,
                        color: themeColor,
                      ),
                    ],
                  ),
                  // Drop shadow/indicator
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Search Bar & Back Button (Top)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Glassy Back Button
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF131319).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x33CFC6B0)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFE4E1EA), size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Glassy Search Input
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF131319).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x33CFC6B0)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFFE4E1EA), fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Search location in Islamabad/RWP...",
                            hintStyle: const TextStyle(color: Color(0xFF908F9D), fontSize: 13),
                            prefixIcon: Icon(Icons.search, color: themeColor),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Color(0xFF908F9D), size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Search Results / Autocomplete Popup List
                if (_predictions.isNotEmpty || _isSearching)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131319).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x4DCFC6B0)),
                    ),
                    child: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB5A1)),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(8),
                            itemCount: _predictions.length,
                            separatorBuilder: (_, __) => const Divider(color: Color(0x1ACFC6B0), height: 1),
                            itemBuilder: (context, index) {
                              final pred = _predictions[index];
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.location_on_outlined, color: themeColor, size: 18),
                                title: Text(
                                  pred['description'],
                                  style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFFE4E1EA), fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _selectPlace(pred),
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),

          // 4. Floating GPS Fetch Button
          Positioned(
            bottom: 270,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'gps_fab',
              mini: true,
              backgroundColor: const Color(0xFF131319).withOpacity(0.85),
              foregroundColor: themeColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: themeColor.withOpacity(0.3)),
              ),
              onPressed: _isLocating ? null : _useCurrentLocation,
              child: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF81C784)),
                      ),
                    )
                  : const Icon(Icons.my_location, size: 18),
            ),
          ),

          // 5. Bottom Panel (Information & Confirmation)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: BoxDecoration(
                color: const Color(0xFF131319).withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: const Border(top: BorderSide(color: Color(0x33CFC6B0))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (_isReverseGeocoding)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF908F9D)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Location Address Field
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x26CFC6B0)),
                    ),
                    child: Text(
                      _selectedAddress,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Color(0xFFE4E1EA),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Horizontal list of Predefined shortcut buttons (Quick Zones)
                  const Text(
                    "QUICK ZONES",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF908F9D),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _fallbackLocations.length,
                      itemBuilder: (context, index) {
                        final name = _fallbackLocations[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            elevation: 0,
                            pressElevation: 0,
                            backgroundColor: const Color(0xFF1F1F25),
                            side: const BorderSide(color: Color(0x26CFC6B0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            label: Text(
                              name,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                color: Color(0xFFE4E1EA),
                              ),
                            ),
                            onPressed: () => _selectPredefined(name),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // Confirm Location Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Confirm ${widget.isPickup ? 'Pickup' : 'Drop-off'}",
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
