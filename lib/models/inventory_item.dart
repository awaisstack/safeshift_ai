class InventoryItem {
  final String name;
  int quantity;
  final String category; // 'furniture' | 'appliance' | 'carton' | 'other'
  final double confidence;
  final String weightClass; // 'light' | 'medium' | 'heavy'
  final String estimatedWeightRange;
  final String volumeClass; // 'compact' | 'medium' | 'bulky' | 'very_bulky'
  final String handlingDifficulty; // 'easy' | 'moderate' | 'difficult'
  bool fragile;
  bool heavy;
  bool bulky;
  bool needsDisassembly;
  bool needsWrapping;
  bool needsTwoPersonLift;
  final String packingMaterial;
  final List<String> riskFlags;
  final String notes;
  final String source; // 'image' | 'text' | 'manual'

  InventoryItem({
    required this.name,
    this.quantity = 1,
    required this.category,
    this.confidence = 1.0,
    this.weightClass = 'medium',
    this.estimatedWeightRange = '',
    this.volumeClass = 'medium',
    this.handlingDifficulty = 'moderate',
    this.fragile = false,
    this.heavy = false,
    this.bulky = false,
    this.needsDisassembly = false,
    this.needsWrapping = false,
    this.needsTwoPersonLift = false,
    this.packingMaterial = 'none',
    this.riskFlags = const [],
    this.notes = '',
    this.source = 'manual',
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      category: json['category'] ?? 'other',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      weightClass: json['weight_class'] ?? 'medium',
      estimatedWeightRange: json['estimated_weight_range'] ?? '',
      volumeClass: json['volume_class'] ?? 'medium',
      handlingDifficulty: json['handling_difficulty'] ?? 'moderate',
      fragile: json['fragile'] ?? false,
      heavy: json['heavy'] ?? false,
      bulky: json['bulky'] ?? false,
      needsDisassembly: json['needs_disassembly'] ?? false,
      needsWrapping: json['needs_wrapping'] ?? false,
      needsTwoPersonLift: json['needs_two_person_lift'] ?? false,
      packingMaterial: json['packing_material'] ?? 'none',
      riskFlags: List<String>.from(json['risk_flags'] ?? []),
      notes: json['notes'] ?? '',
      source: json['source'] ?? 'manual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'category': category,
      'confidence': confidence,
      'weight_class': weightClass,
      'estimated_weight_range': estimatedWeightRange,
      'volume_class': volumeClass,
      'handling_difficulty': handlingDifficulty,
      'fragile': fragile,
      'heavy': heavy,
      'bulky': bulky,
      'needs_disassembly': needsDisassembly,
      'needs_wrapping': needsWrapping,
      'needs_two_person_lift': needsTwoPersonLift,
      'packing_material': packingMaterial,
      'risk_flags': riskFlags,
      'notes': notes,
      'source': source,
    };
  }

  InventoryItem copyWith({
    String? name,
    int? quantity,
    String? category,
    double? confidence,
    String? weightClass,
    String? estimatedWeightRange,
    String? volumeClass,
    String? handlingDifficulty,
    bool? fragile,
    bool? heavy,
    bool? bulky,
    bool? needsDisassembly,
    bool? needsWrapping,
    bool? needsTwoPersonLift,
    String? packingMaterial,
    List<String>? riskFlags,
    String? notes,
    String? source,
  }) {
    return InventoryItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      weightClass: weightClass ?? this.weightClass,
      estimatedWeightRange: estimatedWeightRange ?? this.estimatedWeightRange,
      volumeClass: volumeClass ?? this.volumeClass,
      handlingDifficulty: handlingDifficulty ?? this.handlingDifficulty,
      fragile: fragile ?? this.fragile,
      heavy: heavy ?? this.heavy,
      bulky: bulky ?? this.bulky,
      needsDisassembly: needsDisassembly ?? this.needsDisassembly,
      needsWrapping: needsWrapping ?? this.needsWrapping,
      needsTwoPersonLift: needsTwoPersonLift ?? this.needsTwoPersonLift,
      packingMaterial: packingMaterial ?? this.packingMaterial,
      riskFlags: riskFlags ?? this.riskFlags,
      notes: notes ?? this.notes,
      source: source ?? this.source,
    );
  }
}
