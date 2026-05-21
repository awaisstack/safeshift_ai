import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../data/movers_data.dart';
import '../models/inventory_item.dart';
import '../services/google_maps_service.dart';

class UploadedImage {
  final String id;
  final Uint8List bytes;
  final String mimeType;
  final String fileName;
  String scanStatus; // 'pending' | 'analyzing' | 'valid_inventory' | 'partially_useful' | 'irrelevant_sensitive' | 'failed'
  String? relevance;
  double confidence;
  String validationMessage;
  List<InventoryItem> extractedItems;

  UploadedImage({
    required this.id,
    required this.bytes,
    required this.mimeType,
    required this.fileName,
    this.scanStatus = 'pending',
    this.relevance,
    this.confidence = 0.0,
    this.validationMessage = '',
    this.extractedItems = const [],
  });
}

class AppState extends ChangeNotifier {
  bool _isAgentTraceModeEnabled = false;
  final List<UploadedImage> _uploadedImages = [];

  AppState() {
    recalculateRoute();
  }

  // Image Relevance Validation Fields
  String? _imageRelevance;
  double _imageInventoryConfidence = 1.0;
  String _imageValidationMessage = "";
  bool _hasValidInventoryEvidence = false;
  String _inventorySource = "none";
  bool _continueWithoutImageEvidence = false;

  // New location and maps state
  String _pickupLocation = "Bahria Phase 7";
  String _dropoffLocation = "G-13 Islamabad";
  double _calculatedDistance = 28.6; // default Bahria 7 to G-13

  // Google Maps Safe Enhanced Mode Additions
  LatLng? _customPickupLatLng;
  LatLng? _customDropoffLatLng;
  List<LatLng> _routePoints = [];
  String _routeSource = 'approximate'; // 'google', 'osm_fallback', or 'approximate'
  String _routeLabel = 'Approximate distance'; // "Google Maps live route", "OpenStreetMap fallback", "Approximate distance"
  String _pickupLocationSource = 'manual'; // 'gps', 'places', 'manual'
  String _dropoffLocationSource = 'manual'; // 'places', 'manual'
  int _routeDurationMins = 43;

  // Selected Booking Details
  MoverProvider? _selectedMover;
  double _finalPrice = 0.0;

  // Recovery simulation states
  bool _isRecoveryActive = false;
  MoverProvider? _originalFailedMover;
  List<MoverProvider> _backupMoversList = [];
  String _recoveryReason = "";
  MoverProvider? _selectedBackupMover;
  bool _recoverySettled = false;

  // Getters
  bool get isAgentTraceModeEnabled => _isAgentTraceModeEnabled;
  List<UploadedImage> get uploadedImages => _uploadedImages;

  // Legacy fallback getters for backward compatibility
  Uint8List? get selectedImageBytes => _uploadedImages.isNotEmpty ? _uploadedImages.first.bytes : null;
  String? get selectedImageMimeType => _uploadedImages.isNotEmpty ? _uploadedImages.first.mimeType : null;
  String? get imageScanResult {
    if (_uploadedImages.isEmpty) return null;
    final allNames = _uploadedImages
        .expand((img) => img.extractedItems.map((it) => it.name))
        .toList();
    return allNames.isEmpty ? null : allNames.join(', ');
  }

  String? get imageRelevance => _imageRelevance;
  double get imageInventoryConfidence => _imageInventoryConfidence;
  String get imageValidationMessage => _imageValidationMessage;
  bool get hasValidInventoryEvidence => _hasValidInventoryEvidence;
  String get inventorySource => _inventorySource;
  bool get continueWithoutImageEvidence => _continueWithoutImageEvidence;

  String get pickupLocation => _pickupLocation;
  String get dropoffLocation => _dropoffLocation;
  double get calculatedDistance => _calculatedDistance;

  LatLng? get customPickupLatLng => _customPickupLatLng;
  LatLng? get customDropoffLatLng => _customDropoffLatLng;
  List<LatLng> get routePoints => _routePoints;
  String get routeSource => _routeSource;
  String get routeLabel => _routeLabel;
  String get pickupLocationSource => _pickupLocationSource;
  String get dropoffLocationSource => _dropoffLocationSource;
  int get routeDurationMins => _routeDurationMins;

  LatLng get pickupLatLng => _customPickupLatLng ?? getCoordinatesForLocation(_pickupLocation);
  LatLng get dropoffLatLng => _customDropoffLatLng ?? getCoordinatesForLocation(_dropoffLocation);

  MoverProvider? get selectedMover => _selectedMover;
  double get finalPrice => _finalPrice;

  bool get isRecoveryActive => _isRecoveryActive;
  MoverProvider? get originalFailedMover => _originalFailedMover;
  List<MoverProvider> get backupMoversList => _backupMoversList;
  String get recoveryReason => _recoveryReason;
  MoverProvider? get selectedBackupMover => _selectedBackupMover;
  bool get recoverySettled => _recoverySettled;

  void toggleAgentTraceMode() {
    _isAgentTraceModeEnabled = !_isAgentTraceModeEnabled;
    notifyListeners();
  }

  // Multi-image management methods
  void addUploadedImage(UploadedImage img) {
    _uploadedImages.add(img);
    _recalculateValidationState();
    notifyListeners();
  }

  void removeUploadedImage(String id) {
    _uploadedImages.removeWhere((img) => img.id == id);
    _recalculateValidationState();
    notifyListeners();
  }

  void clearUploadedImages() {
    _uploadedImages.clear();
    resetImageValidation();
    notifyListeners();
  }

  void updateUploadedImage(String id, {
    String? scanStatus,
    String? relevance,
    double? confidence,
    String? validationMessage,
    List<InventoryItem>? extractedItems,
  }) {
    final index = _uploadedImages.indexWhere((img) => img.id == id);
    if (index != -1) {
      final img = _uploadedImages[index];
      _uploadedImages[index] = UploadedImage(
        id: img.id,
        bytes: img.bytes,
        mimeType: img.mimeType,
        fileName: img.fileName,
        scanStatus: scanStatus ?? img.scanStatus,
        relevance: relevance ?? img.relevance,
        confidence: confidence ?? img.confidence,
        validationMessage: validationMessage ?? img.validationMessage,
        extractedItems: extractedItems ?? img.extractedItems,
      );
      _recalculateValidationState();
      notifyListeners();
    }
  }

  void _recalculateValidationState() {
    if (_uploadedImages.isEmpty) {
      _imageRelevance = null;
      _imageInventoryConfidence = 1.0;
      _imageValidationMessage = "";
      _hasValidInventoryEvidence = false;
      _inventorySource = "none";
      return;
    }

    // Check if any is valid
    final hasValid = _uploadedImages.any((img) => 
      img.scanStatus == 'valid_inventory' || img.scanStatus == 'partially_useful');

    _hasValidInventoryEvidence = hasValid;

    // relevance is highest level of validation found
    if (_uploadedImages.any((img) => img.relevance == 'unsafe_or_sensitive_image')) {
      _imageRelevance = 'unsafe_or_sensitive_image';
    } else if (_uploadedImages.any((img) => img.relevance == 'irrelevant_image')) {
      _imageRelevance = 'irrelevant_image';
    } else if (_uploadedImages.any((img) => img.relevance == 'partially_useful_image')) {
      _imageRelevance = 'partially_useful_image';
    } else {
      _imageRelevance = 'valid_inventory_image';
    }

    // Average confidence of scans
    final scannedImages = _uploadedImages.where((img) => img.scanStatus != 'pending' && img.scanStatus != 'analyzing').toList();
    if (scannedImages.isNotEmpty) {
      _imageInventoryConfidence = scannedImages.map((e) => e.confidence).reduce((a, b) => a + b) / scannedImages.length;
    } else {
      _imageInventoryConfidence = 1.0;
    }

    // Set combined user validation message
    final messages = _uploadedImages
        .where((img) => img.validationMessage.isNotEmpty)
        .map((img) => "${img.fileName}: ${img.validationMessage}")
        .toList();
    _imageValidationMessage = messages.isNotEmpty ? messages.join("\n") : "";

    // inventory source definition
    if (_hasValidInventoryEvidence) {
      _inventorySource = _uploadedImages.any((img) => img.scanStatus == 'partially_useful') ? 'mixed' : 'image';
    } else {
      _inventorySource = 'none';
    }
  }

  // Legacy support setters/methods (redirected or reset)
  void setImage(Uint8List? bytes, String? mimeType) {
    if (bytes == null) {
      clearUploadedImages();
    } else {
      // Clear and add as singular for legacy actions
      _uploadedImages.clear();
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      addUploadedImage(UploadedImage(
        id: id,
        bytes: bytes,
        mimeType: mimeType ?? 'image/jpeg',
        fileName: 'upload.jpg',
      ));
    }
  }

  void setImageScanResult(String? result) {
    // Legacy support: update first image's extractedItems with a placeholder parsed list
    if (_uploadedImages.isNotEmpty && result != null) {
      final items = result.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).map((name) {
        return InventoryItem(
          name: name,
          quantity: 1,
          category: 'other',
          source: 'image',
        );
      }).toList();
      updateUploadedImage(_uploadedImages.first.id, extractedItems: items);
    }
  }

  void clearImage() {
    clearUploadedImages();
  }

  void updateImageValidation({
    String? relevance,
    double? confidence,
    String? message,
    bool? hasValidEvidence,
    String? source,
    bool? continueWithoutImage,
  }) {
    if (relevance != null) _imageRelevance = relevance;
    if (confidence != null) _imageInventoryConfidence = confidence;
    if (message != null) _imageValidationMessage = message;
    if (hasValidEvidence != null) _hasValidInventoryEvidence = hasValidEvidence;
    if (source != null) _inventorySource = source;
    if (continueWithoutImage != null) _continueWithoutImageEvidence = continueWithoutImage;
    notifyListeners();
  }

  void resetImageValidation() {
    _imageRelevance = null;
    _imageInventoryConfidence = 1.0;
    _imageValidationMessage = "";
    _hasValidInventoryEvidence = false;
    _inventorySource = "none";
    _continueWithoutImageEvidence = false;
    notifyListeners();
  }

  LatLng getCoordinatesForLocation(String name) {
    final Map<String, List<double>> coords = {
      "Bahria Phase 7": [33.5235, 73.0805],
      "Bahria Phase 8": [33.5042, 73.0763],
      "DHA Phase 1": [33.5358, 73.1190],
      "Saddar Rawalpindi": [33.5984, 73.0551],
      "Committee Chowk": [33.6062, 73.0688],
      "PWD": [33.5670, 73.1360],
      "G-13 Islamabad": [33.6441, 72.9691],
      "F-10 Islamabad": [33.6934, 73.0118],
      "I-8 Islamabad": [33.6702, 73.0754],
      "Blue Area Islamabad": [33.7126, 73.0617],
    };
    final pCoords = coords[name] ?? [33.5235, 73.0805];
    return LatLng(pCoords[0], pCoords[1]);
  }

  void updateLocations(String pickup, String dropoff) {
    _pickupLocation = pickup;
    _dropoffLocation = dropoff;
    _customPickupLatLng = null;
    _customDropoffLatLng = null;
    _pickupLocationSource = 'manual';
    _dropoffLocationSource = 'manual';
    recalculateRoute();
  }

  void setCustomPickup(String name, LatLng latLng, {String source = 'places'}) {
    _pickupLocation = name;
    _customPickupLatLng = latLng;
    _pickupLocationSource = source;
    recalculateRoute();
  }

  void setCustomDropoff(String name, LatLng latLng, {String source = 'places'}) {
    _dropoffLocation = name;
    _customDropoffLatLng = latLng;
    _dropoffLocationSource = source;
    recalculateRoute();
  }

  Future<void> recalculateRoute() async {
    final pickupLatLng = _customPickupLatLng ?? getCoordinatesForLocation(_pickupLocation);
    final dropoffLatLng = _customDropoffLatLng ?? getCoordinatesForLocation(_dropoffLocation);

    final service = GoogleMapsService();
    if (service.isRoutesEnabled) {
      final routeData = await service.computeRoute(pickupLatLng, dropoffLatLng);
      if (routeData != null && routeData['success'] == true) {
        _calculatedDistance = routeData['distanceKm'] as double;
        _routeDurationMins = routeData['durationMins'] as int;
        _routePoints = routeData['polylinePoints'] as List<LatLng>;
        _routeSource = 'google';
        _routeLabel = 'Google Routes live distance';
        notifyListeners();
        return;
      }
    }

    // Fallback: Haversine distance * 1.3
    const double r = 6371; // Earth radius in km
    final double dLat = (dropoffLatLng.latitude - pickupLatLng.latitude) * pi / 180;
    final double dLon = (dropoffLatLng.longitude - pickupLatLng.longitude) * pi / 180;
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(pickupLatLng.latitude * pi / 180) * cos(dropoffLatLng.latitude * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double rawDistance = r * c;
    _calculatedDistance = rawDistance * 1.3;
    _routeDurationMins = (_calculatedDistance / 40.0 * 60.0).round(); // Assume 40 km/h average speed in city
    _routePoints = [pickupLatLng, dropoffLatLng];
    
    if (service.isGoogleMapsEnabled || service.isRoutesEnabled) {
      _routeSource = 'osm_fallback';
      _routeLabel = 'OpenStreetMap fallback';
    } else {
      _routeSource = 'approximate';
      _routeLabel = 'Approximate distance';
    }
    notifyListeners();
  }

  void selectMover(MoverProvider provider, double price) {
    _selectedMover = provider;
    _finalPrice = price;
    notifyListeners();
  }

  // Recovery simulation triggers
  void triggerRecoverySimulation(MoverProvider failedMover, String reason, List<MoverProvider> backups) {
    _isRecoveryActive = true;
    _originalFailedMover = failedMover;
    _recoveryReason = reason;
    _backupMoversList = backups;
    _selectedBackupMover = null;
    _recoverySettled = false;
    notifyListeners();
  }

  void selectBackupMover(MoverProvider backup) {
    _selectedBackupMover = backup;
    _selectedMover = backup; // Switch booking over
    _recoverySettled = true;
    _isRecoveryActive = false;
    notifyListeners();
  }

  void clearRecovery() {
    _isRecoveryActive = false;
    _originalFailedMover = null;
    _backupMoversList = [];
    _recoveryReason = "";
    _selectedBackupMover = null;
    _recoverySettled = false;
    notifyListeners();
  }
}
