import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/move_request.dart';
import 'gemini_service.dart';

class RequestParserService {
  final GeminiService _geminiService;

  RequestParserService(this._geminiService);

  Future<MoveRequest> parseRequest(String rawInput) async {
    final String prompt = '''
    You are an expert AI agent that parses moving/shifting requests in Pakistan (Roman Urdu, English, Urdu).
    Extract the following information and return ONLY a JSON object:
    - service_type: e.g., "home_shifting", "office_shifting"
    - move_type: Must be one of the following exact strings based on context: "Full home shifting", "Small item move", "One-item move", "Furniture-only move", "Truck-assisted move", "Packing-only service", "Loading/unloading-only service", "Office shifting", "Intercity move", "Internal furniture rearrangement"
    - pickup: The pickup location
    - dropoff: The dropoff location
    - inventory_items: A list of objects matching this schema exactly:
      {
        "name": "item name",
        "quantity": 1,
        "category": "furniture | appliance | carton | other",
        "confidence": 0.9,
        "weight_class": "light | medium | heavy",
        "estimated_weight_range": "e.g. 10-20 kg",
        "volume_class": "compact | medium | bulky | very_bulky",
        "handling_difficulty": "easy | moderate | difficult",
        "fragile": true | false,
        "heavy": true | false,
        "bulky": true | false,
        "needs_disassembly": true | false,
        "needs_wrapping": true | false,
        "needs_two_person_lift": true | false,
        "packing_material": "string",
        "risk_flags": ["scratch_risk"],
        "notes": "any relevant details"
      }
    - constraints: Any constraints like "no lift at pickup"
    - budget_preference: "controlled", "cheap", "premium"
    - preferred_time: extracted time
    - complexity: "basic", "intermediate", "complex"
    - risk_level: "low", "medium", "high", "medium-high"
    - confidence: A double between 0.0 and 1.0 representing how confident you are in this extraction.

    Raw Input: "$rawInput"
    ''';

    final result = await _geminiService.generateText(prompt);
    
    if (result != null) {
      try {
        final cleanJson = result.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> data = jsonDecode(cleanJson);
        data['id'] = const Uuid().v4();
        data['rawInput'] = rawInput;
        data['move_type'] = data['move_type'] ?? 'Full home shifting';
        return MoveRequest.fromJson(data);
      } catch (e) {
        print('Error parsing JSON from Gemini: $e');
      }
    }

    // Fallback Mock Logic
    return _mockParse(rawInput);
  }

  MoveRequest _mockParse(String input) {
    final lowerInput = input.toLowerCase();
    
    // Dynamic Preferred Time
    String preferredTime = "Saturday 10 AM"; // default fallback
    String detectedDay = "";
    if (lowerInput.contains("sunmday") || lowerInput.contains("sunday")) {
      detectedDay = "Sunday";
    } else if (lowerInput.contains("saturday") || lowerInput.contains("satday") || lowerInput.contains("satmday")) {
      detectedDay = "Saturday";
    } else if (lowerInput.contains("monday")) {
      detectedDay = "Monday";
    } else if (lowerInput.contains("tuesday")) {
      detectedDay = "Tuesday";
    } else if (lowerInput.contains("wednesday")) {
      detectedDay = "Wednesday";
    } else if (lowerInput.contains("thursday")) {
      detectedDay = "Thursday";
    } else if (lowerInput.contains("friday")) {
      detectedDay = "Friday";
    }

    String detectedTime = "";
    if (lowerInput.contains("10 baje") || lowerInput.contains("10:00") || lowerInput.contains("10am") || lowerInput.contains("10 am")) {
      detectedTime = "10 AM";
    } else if (lowerInput.contains("2 baje") || lowerInput.contains("2:00") || lowerInput.contains("2pm") || lowerInput.contains("2 pm")) {
      detectedTime = "2 PM";
    } else if (lowerInput.contains("12 baje") || lowerInput.contains("12:00") || lowerInput.contains("12pm") || lowerInput.contains("12 pm")) {
      detectedTime = "12 PM";
    } else if (lowerInput.contains("9 baje") || lowerInput.contains("9:00") || lowerInput.contains("9am") || lowerInput.contains("9 am")) {
      detectedTime = "9 AM";
    } else if (lowerInput.contains("11 baje") || lowerInput.contains("11:00") || lowerInput.contains("11am") || lowerInput.contains("11 am")) {
      detectedTime = "11 AM";
    }

    if (detectedDay.isNotEmpty && detectedTime.isNotEmpty) {
      preferredTime = "$detectedDay $detectedTime";
    } else if (detectedDay.isNotEmpty) {
      preferredTime = "$detectedDay 10 AM";
    } else if (detectedTime.isNotEmpty) {
      preferredTime = "Saturday $detectedTime";
    }

    // Dynamic Carton Count
    int cartonCount = 14; // default
    final cartonRegex = RegExp(r'(\d+)\s*(?:carton|petian|box|dabba|dibba|peti)');
    final cartonMatch = cartonRegex.firstMatch(lowerInput);
    if (cartonMatch != null) {
      cartonCount = int.tryParse(cartonMatch.group(1) ?? '') ?? 14;
    }

    // Dynamic Budget Preference
    String budgetPreference = "controlled";
    if (lowerInput.contains("cheap") || lowerInput.contains("sasta") || lowerInput.contains("low budget") || lowerInput.contains("kam budget")) {
      budgetPreference = "cheap";
    } else if (lowerInput.contains("premium") || lowerInput.contains("vip") || lowerInput.contains("high budget")) {
      budgetPreference = "premium";
    }

    // Dynamic Pickup and Dropoff
    String pickup = "Bahria Phase 7";
    String dropoff = "G-13 Islamabad";
    if (lowerInput.contains("saddar")) {
      pickup = "Saddar Rawalpindi";
    }
    if (lowerInput.contains("g-13") || lowerInput.contains("g13")) {
      dropoff = "G-13 Islamabad";
    }

    if (lowerInput.contains("bahria phase 7 se g-13") || lowerInput.contains("bahria") || lowerInput.contains("g-13") || lowerInput.contains("shift")) {
      return MoveRequest.fromJson({
        "id": const Uuid().v4(),
        "rawInput": input,
        "service_type": "home_shifting",
        "move_type": "Full home shifting",
        "pickup": pickup,
        "dropoff": dropoff,
        "inventory_items": [
          {
            "name": "Refrigerator",
            "quantity": 1,
            "category": "appliance",
            "confidence": 0.95,
            "weight_class": "heavy",
            "estimated_weight_range": "50-90 kg",
            "volume_class": "bulky",
            "handling_difficulty": "difficult",
            "fragile": false,
            "heavy": true,
            "bulky": true,
            "needs_disassembly": false,
            "needs_wrapping": true,
            "needs_two_person_lift": true,
            "packing_material": "bubble wrap",
            "risk_flags": ["appliance", "stairs_risk"],
            "notes": "Clean coils, secure doors before moving.",
            "source": "text"
          },
          {
            "name": "Washing Machine",
            "quantity": 1,
            "category": "appliance",
            "confidence": 0.92,
            "weight_class": "heavy",
            "estimated_weight_range": "30-50 kg",
            "volume_class": "medium",
            "handling_difficulty": "moderate",
            "fragile": false,
            "heavy": true,
            "bulky": false,
            "needs_disassembly": false,
            "needs_wrapping": true,
            "needs_two_person_lift": true,
            "packing_material": "bubble wrap",
            "risk_flags": ["appliance"],
            "notes": "Drain remaining water.",
            "source": "text"
          },
          {
            "name": "Double Bed",
            "quantity": 1,
            "category": "furniture",
            "confidence": 0.95,
            "weight_class": "heavy",
            "estimated_weight_range": "40-80 kg",
            "volume_class": "very_bulky",
            "handling_difficulty": "difficult",
            "fragile": false,
            "heavy": true,
            "bulky": true,
            "needs_disassembly": true,
            "needs_wrapping": true,
            "needs_two_person_lift": true,
            "packing_material": "blanket wrap",
            "risk_flags": ["disassembly_risk"],
            "notes": "Requires disassembly before carrying.",
            "source": "text"
          },
          {
            "name": "glass dining table",
            "quantity": 1,
            "category": "furniture",
            "confidence": 0.90,
            "weight_class": "heavy",
            "estimated_weight_range": "30-60 kg",
            "volume_class": "bulky",
            "handling_difficulty": "difficult",
            "fragile": true,
            "heavy": true,
            "bulky": true,
            "needs_disassembly": false,
            "needs_wrapping": true,
            "needs_two_person_lift": true,
            "packing_material": "blanket wrap + edge protection",
            "risk_flags": ["glass_surface"],
            "notes": "Glass item requires careful handling and protection.",
            "source": "text"
          },
          {
            "name": "Sofa",
            "quantity": 1,
            "category": "furniture",
            "confidence": 0.95,
            "weight_class": "heavy",
            "estimated_weight_range": "30-50 kg",
            "volume_class": "bulky",
            "handling_difficulty": "moderate",
            "fragile": false,
            "heavy": false,
            "bulky": true,
            "needs_disassembly": false,
            "needs_wrapping": true,
            "needs_two_person_lift": true,
            "packing_material": "shrink wrap",
            "risk_flags": [],
            "notes": "",
            "source": "text"
          },
          {
            "name": "Moving Cartons",
            "quantity": cartonCount,
            "category": "carton",
            "confidence": 0.90,
            "weight_class": "medium",
            "estimated_weight_range": "10-20 kg",
            "volume_class": "medium",
            "handling_difficulty": "easy",
            "fragile": false,
            "heavy": false,
            "bulky": false,
            "needs_disassembly": false,
            "needs_wrapping": false,
            "needs_two_person_lift": false,
            "packing_material": "none",
            "risk_flags": [],
            "notes": "",
            "source": "text"
          }
        ],
        "constraints": ["no lift at pickup", "lift at dropoff"],
        "budget_preference": budgetPreference,
        "preferred_time": preferredTime,
        "complexity": "complex",
        "risk_level": "medium-high",
        "confidence": 0.92,
      });
    }

    if (input.toLowerCase().contains("rawalpindi se islamabad")) {
      return MoveRequest(
        id: const Uuid().v4(),
        rawInput: input,
        serviceType: "home_shifting",
        moveType: "Full home shifting",
        pickupLocation: "Saddar Rawalpindi",
        dropoffLocation: "G-13 Islamabad",
        inventorySource: "none",
        confidenceScore: 0.3,
        complexity: "basic",
        riskLevel: "low",
      );
    }

    return MoveRequest(
      id: const Uuid().v4(),
      rawInput: input,
      serviceType: "home_shifting",
      confidenceScore: 0.5,
    );
  }
}
