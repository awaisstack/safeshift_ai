import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final List<GenerativeModel> _models = [];
  int _currentModelIndex = 0;

  bool get isMockMode => _models.isEmpty;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty && apiKey != 'YOUR_GEMINI_API_KEY_HERE') {
      // Initialize multiple models for automatic failover / fallback
      _models.add(GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      ));
      _models.add(GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      ));
      _models.add(GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
      ));
    }
  }

  String _modelName(int index) {
    switch (index) {
      case 0:
        return 'gemini-2.5-flash';
      case 1:
        return 'gemini-1.5-flash';
      case 2:
        return 'gemini-2.0-flash';
      default:
        return 'unknown';
    }
  }

  Future<String?> generateText(String prompt) async {
    if (isMockMode) {
      print("Using mock Gemini response");
      return null;
    }
    
    for (int i = 0; i < _models.length; i++) {
      final modelIndex = (i + _currentModelIndex) % _models.length;
      final modelInstance = _models[modelIndex];
      final name = _modelName(modelIndex);
      
      try {
        print("Attempting generateText with model: $name");
        final response = await modelInstance.generateContent([Content.text(prompt)]);
        _currentModelIndex = modelIndex; // save successful model index
        return response.text;
      } catch (e) {
        print("Gemini API Error with $name: $e");
      }
    }
    return null;
  }

  Future<String?> generateContentWithImage(String prompt, Uint8List imageBytes, String mimeType) async {
    if (isMockMode) {
      print("Using mock Gemini Vision response");
      return null;
    }
    
    final imagePart = DataPart(mimeType, imageBytes);
    for (int i = 0; i < _models.length; i++) {
      final modelIndex = (i + _currentModelIndex) % _models.length;
      final modelInstance = _models[modelIndex];
      final name = _modelName(modelIndex);
      
      try {
        print("Attempting generateContentWithImage with model: $name");
        final response = await modelInstance.generateContent([
          Content.multi([TextPart(prompt), imagePart])
        ]);
        _currentModelIndex = modelIndex;
        return response.text;
      } catch (e) {
        print("Gemini Vision API Error with $name: $e");
      }
    }
    return null;
  }

  Future<String?> validateImageRelevance(Uint8List imageBytes, String mimeType, String fileName) async {
    final lowerName = fileName.toLowerCase();
    if (isMockMode) {
      // Simulate validation failure for selfies, irrelevant images, or general success
      if (lowerName.contains("selfie") || lowerName.contains("person") || lowerName.contains("face") || lowerName.contains("avatar") || lowerName.contains("profile")) {
        return """{
          "image_relevance": "unsafe_or_sensitive_image",
          "image_summary": "Selfie or face image detected.",
          "confidence": 0.1,
          "items": [],
          "missing_context_questions": [],
          "should_block_auto_inventory": true,
          "user_message": "This image appears to contain a person/selfie and does not help estimate moving inventory. For privacy, SafeShift does not use personal photos for move planning. Please upload room/furniture/items instead."
        }""";
      } else if (lowerName.contains("food") || lowerName.contains("scenery") || lowerName.contains("cat") || lowerName.contains("dog") || lowerName.contains("document") || lowerName.contains("screenshot") || lowerName.contains("logo")) {
        return """{
          "image_relevance": "irrelevant_image",
          "image_summary": "Non-inventory scenery or random object.",
          "confidence": 0.0,
          "items": [],
          "missing_context_questions": [],
          "should_block_auto_inventory": true,
          "user_message": "No moving inventory detected. Please upload a room, furniture, appliance, or carton photo — or enter items manually."
        }""";
      } else if (lowerName.contains("partial") || lowerName.contains("clutter") || lowerName.contains("dark")) {
        return """{
          "image_relevance": "partially_useful_image",
          "image_summary": "Dimly lit study area view.",
          "confidence": 0.6,
          "items": [
            {
              "name": "Study Desk",
              "quantity": 1,
              "category": "furniture",
              "confidence": 0.85,
              "weight_class": "medium",
              "estimated_weight_range": "15-30 kg",
              "volume_class": "medium",
              "handling_difficulty": "moderate",
              "fragile": false,
              "heavy": false,
              "bulky": false,
              "needs_disassembly": true,
              "needs_wrapping": true,
              "needs_two_person_lift": false,
              "packing_material": "shrink wrap",
              "risk_flags": ["scratch_risk"],
              "notes": "Wooden desk.",
              "source": "image"
            },
            {
              "name": "Office Chair",
              "quantity": 1,
              "category": "furniture",
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
              "notes": "Rolling chair.",
              "source": "image"
            }
          ],
          "missing_context_questions": ["Is there an accompanying bookshelf not pictured?"],
          "should_block_auto_inventory": false,
          "user_message": "Some move-related items were detected, but confidence is limited. Please confirm or edit the item list."
        }""";
      } else {
        // Valid inventory image
        return """{
          "image_relevance": "valid_inventory_image",
          "image_summary": "Complete living/bed room set items.",
          "confidence": 0.94,
          "items": [
            {
              "name": "Double Bed",
              "quantity": 1,
              "category": "furniture",
              "confidence": 0.96,
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
              "risk_flags": ["disassembly_risk", "stairs_risk"],
              "notes": "Requires disassembly before carrying.",
              "source": "image"
            },
            {
              "name": "glass dining table",
              "quantity": 1,
              "category": "furniture",
              "confidence": 0.92,
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
              "risk_flags": ["glass_surface", "scratch_risk", "stairs_risk"],
              "notes": "Glass item requires careful handling and protection.",
              "source": "image"
            },
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
              "risk_flags": ["appliance", "stairs_risk", "scratch_risk"],
              "notes": "Clean coils, secure doors before moving.",
              "source": "image"
            },
            {
              "name": "Washing Machine",
              "quantity": 1,
              "category": "appliance",
              "confidence": 0.91,
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
              "risk_flags": ["appliance", "scratch_risk"],
              "notes": "Drain remaining water.",
              "source": "image"
            },
            {
              "name": "Moving Cartons",
              "quantity": 6,
              "category": "carton",
              "confidence": 0.93,
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
              "notes": "Standard packed moving boxes.",
              "source": "image"
            }
          ],
          "missing_context_questions": [],
          "should_block_auto_inventory": false,
          "user_message": "Room items detected successfully."
        }""";
      }
    }

    final prompt = """
Analyze the uploaded image for its relevance to estimating inventory for a house/office move.
Determine if it contains items that need to be moved (furniture, appliances, boxes, cartons, household goods, office chairs, desks, etc.).

Return a JSON object matching this schema exactly:
{
  "image_relevance": "valid_inventory_image | partially_useful_image | irrelevant_image | unsafe_or_sensitive_image",
  "image_summary": "brief summary of image context",
  "confidence": 0.0,
  "items": [
    {
      "name": "item name",
      "quantity": 1,
      "category": "furniture | appliance | carton | other",
      "confidence": 0.9,
      "weight_class": "light | medium | heavy",
      "estimated_weight_range": "e.g. 10-20 kg",
      "volume_class": "compact | medium | bulky | very_bulky",
      "handling_difficulty": "easy | moderate | difficult",
      "fragile": false,
      "heavy": false,
      "bulky": false,
      "needs_disassembly": false,
      "needs_wrapping": false,
      "needs_two_person_lift": false,
      "packing_material": "bubble wrap | shrink wrap | blanket wrap | none",
      "risk_flags": ["scratch_risk", "glass_surface", "disassembly_risk"],
      "notes": "special handling notes"
    }
  ],
  "missing_context_questions": ["questions about items that might be hidden or needed"],
  "should_block_auto_inventory": true | false,
  "user_message": "friendly message explaining the classification and next steps"
}

Rules:
1. "image_relevance" must be:
   - "valid_inventory_image": if a room photo, furniture, appliances, boxes/cartons, or visible household/office items relevant to moving are present.
   - "partially_useful_image": if some moving-relevant objects are visible but unclear, low light, cluttered, or partial room view.
   - "irrelevant_image": if it's a selfie/face/person-only image, food, outdoor scenery, document/screenshot, or random image with no move inventory.
   - "unsafe_or_sensitive_image": if ID cards, documents, private personal images, children/family photos, medical, or private content.
2. If "image_relevance" is "irrelevant_image" or "unsafe_or_sensitive_image", or if a person/selfie is detected:
   - Set "should_block_auto_inventory" to true.
   - Return empty "items" array.
   - If a person/selfie is detected, set "user_message" to: "This image appears to contain a person/selfie and does not help estimate moving inventory. For privacy, SafeShift does not use personal photos for move planning. Please upload room/furniture/items instead."
   - DO NOT identify or describe the person's face or body.
3. If "image_relevance" is "partially_useful_image":
   - "user_message" should say: "Some move-related items were detected, but confidence is limited. Please confirm or edit the item list."
4. If "image_relevance" is "valid_inventory_image":
   - List the extracted items with reasonable confidence.
   - "user_message" can show the summary of detected items.
5. If "image_relevance" is "irrelevant_image" (not containing a face, e.g. food/scenery):
   - Set "user_message" to: "No moving inventory detected. Please upload a room, furniture, appliance, or carton photo — or enter items manually."

Ensure you ONLY return the raw JSON object, without markdown code block formatting (no ```json).
""";

    final imagePart = DataPart(mimeType, imageBytes);
    for (int i = 0; i < _models.length; i++) {
      final modelIndex = (i + _currentModelIndex) % _models.length;
      final modelInstance = _models[modelIndex];
      final name = _modelName(modelIndex);
      
      try {
        print("Attempting validateImageRelevance with model: $name");
        final response = await modelInstance.generateContent([
          Content.multi([TextPart(prompt), imagePart])
        ]);
        _currentModelIndex = modelIndex;
        return response.text;
      } catch (e) {
        print("Gemini Vision API Error during image validation with $name: $e");
      }
    }
    return null;
  }
}

