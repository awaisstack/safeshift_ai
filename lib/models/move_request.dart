import 'inventory_item.dart';

class MoveRequest {
  final String id;
  final String rawInput;
  String? serviceType;
  String? pickupLocation;
  String? dropoffLocation;
  List<String> inventory;
  List<String> fragileItems;
  List<String> heavyItems;
  List<String> constraints;
  String? budgetPreference;
  String? preferredTime;
  String? complexity;
  String? riskLevel;
  double? confidenceScore;
  int? requiredCrew;
  String? requiredVehicle;
  String? estimatedDuration;

  // Move-Type & Quote Confidence
  String? moveType;
  String? quoteConfidence; // 'High' | 'Medium' | 'Low'
  String? quoteConfidenceReason;

  // Validation Fields
  String? imageRelevance; // 'valid_inventory_image' | 'partially_useful_image' | 'irrelevant_image' | 'unsafe_or_sensitive_image'
  double? imageInventoryConfidence;
  String? imageValidationMessage;
  bool hasValidInventoryEvidence;
  String inventorySource; // 'manual' | 'image' | 'mixed' | 'none'
  bool continueWithoutImageEvidence;

  // New Structured Manifest
  List<InventoryItem> inventoryItems;

  MoveRequest({
    required this.id,
    required this.rawInput,
    this.serviceType,
    this.pickupLocation,
    this.dropoffLocation,
    this.inventory = const [],
    this.fragileItems = const [],
    this.heavyItems = const [],
    this.constraints = const [],
    this.budgetPreference,
    this.preferredTime,
    this.complexity,
    this.riskLevel,
    this.confidenceScore,
    this.requiredCrew,
    this.requiredVehicle,
    this.estimatedDuration,
    this.moveType,
    this.quoteConfidence,
    this.quoteConfidenceReason,
    this.imageRelevance,
    this.imageInventoryConfidence = 1.0,
    this.imageValidationMessage = '',
    this.hasValidInventoryEvidence = false,
    this.inventorySource = 'none',
    this.continueWithoutImageEvidence = false,
    this.inventoryItems = const [],
  }) {
    if (inventoryItems.isEmpty && inventory.isNotEmpty) {
      // Reconstruct inventoryItems from legacy lists for compatibility
      inventoryItems = inventory.map((name) {
        final lower = name.toLowerCase();
        final hasQtyMatch = RegExp(r'^(\d+)x?\s+(.+)$').firstMatch(lower);
        int qty = 1;
        String cleanName = name;
        if (hasQtyMatch != null) {
          qty = int.tryParse(hasQtyMatch.group(1) ?? '1') ?? 1;
          cleanName = hasQtyMatch.group(2) ?? name;
        }
        
        final isFragile = fragileItems.any((f) => cleanName.toLowerCase().contains(f.toLowerCase()) || f.toLowerCase().contains(cleanName.toLowerCase()));
        final isHeavy = heavyItems.any((h) => cleanName.toLowerCase().contains(h.toLowerCase()) || h.toLowerCase().contains(cleanName.toLowerCase()));
        
        return InventoryItem(
          name: cleanName,
          quantity: qty,
          category: isHeavy ? 'appliance' : 'furniture',
          fragile: isFragile,
          heavy: isHeavy,
          source: 'text',
        );
      }).toList();
    }
    syncLegacyFields();
  }

  void syncLegacyFields() {
    inventory = inventoryItems.map((item) => "${item.quantity}x ${item.name}").toList();
    fragileItems = inventoryItems.where((item) => item.fragile).map((item) => item.name).toList();
    heavyItems = inventoryItems.where((item) => item.heavy).map((item) => item.name).toList();
  }

  factory MoveRequest.fromJson(Map<String, dynamic> json) {
    final rawItems = json['inventory_items'] as List?;
    final parsedItems = rawItems != null
        ? rawItems.map((item) => InventoryItem.fromJson(item as Map<String, dynamic>)).toList()
        : <InventoryItem>[];

    return MoveRequest(
      id: json['id'] ?? '',
      rawInput: json['rawInput'] ?? '',
      serviceType: json['service_type'],
      pickupLocation: json['pickup'],
      dropoffLocation: json['dropoff'],
      inventory: List<String>.from(json['inventory'] ?? []),
      fragileItems: List<String>.from(json['fragile_items'] ?? []),
      heavyItems: List<String>.from(json['heavy_items'] ?? []),
      constraints: List<String>.from(json['constraints'] ?? []),
      budgetPreference: json['budget_preference'],
      preferredTime: json['preferred_time'],
      complexity: json['complexity'],
      riskLevel: json['risk_level'],
      confidenceScore: (json['confidence'] as num?)?.toDouble(),
      requiredCrew: json['required_crew'],
      requiredVehicle: json['required_vehicle'],
      estimatedDuration: json['estimated_duration'],
      moveType: json['move_type'],
      quoteConfidence: json['quote_confidence'],
      quoteConfidenceReason: json['quote_confidence_reason'],
      imageRelevance: json['image_relevance'],
      imageInventoryConfidence: (json['image_inventory_confidence'] as num?)?.toDouble() ?? 1.0,
      imageValidationMessage: json['image_validation_message'] ?? '',
      hasValidInventoryEvidence: json['has_valid_inventory_evidence'] ?? false,
      inventorySource: json['inventory_source'] ?? 'none',
      continueWithoutImageEvidence: json['continue_without_image_evidence'] ?? false,
      inventoryItems: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rawInput': rawInput,
      'service_type': serviceType,
      'pickup': pickupLocation,
      'dropoff': dropoffLocation,
      'inventory': inventory,
      'fragile_items': fragileItems,
      'heavy_items': heavyItems,
      'constraints': constraints,
      'budget_preference': budgetPreference,
      'preferred_time': preferredTime,
      'complexity': complexity,
      'risk_level': riskLevel,
      'confidence': confidenceScore,
      'required_crew': requiredCrew,
      'required_vehicle': requiredVehicle,
      'estimated_duration': estimatedDuration,
      'move_type': moveType,
      'quote_confidence': quoteConfidence,
      'quote_confidence_reason': quoteConfidenceReason,
      'image_relevance': imageRelevance,
      'image_inventory_confidence': imageInventoryConfidence,
      'image_validation_message': imageValidationMessage,
      'has_valid_inventory_evidence': hasValidInventoryEvidence,
      'inventory_source': inventorySource,
      'continue_without_image_evidence': continueWithoutImageEvidence,
      'inventory_items': inventoryItems.map((item) => item.toJson()).toList(),
    };
  }
}

