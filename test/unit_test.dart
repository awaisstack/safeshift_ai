import 'package:flutter_test/flutter_test.dart';
import 'package:safeshift_ai/models/move_request.dart';
import 'package:safeshift_ai/services/inventory_complexity_service.dart';
import 'package:safeshift_ai/models/inventory_item.dart';
import 'package:safeshift_ai/data/movers_data.dart';
import 'package:safeshift_ai/services/matching_service.dart';

void main() {
  group('MoveRequest and InventoryComplexityService Tests', () {
    late InventoryComplexityService service;

    setUp(() {
      service = InventoryComplexityService();
    });

    test('Simple Move Request calculation', () {
      final request = MoveRequest(
        id: "test-1",
        rawInput: "shifting small studio",
        pickupLocation: "F-10 Islamabad",
        dropoffLocation: "G-11 Islamabad",
        inventory: ["box1", "box2", "chair"],
        fragileItems: [],
        heavyItems: [],
        constraints: [],
        budgetPreference: "budget friendly",
        preferredTime: "Friday 10 AM",
      );

      service.analyzeRequest(request);

      expect(request.requiredCrew, equals(2));
      expect(request.requiredVehicle, equals("Suzuki"));
      expect(request.estimatedDuration, equals("2-3 hours"));
    });

    test('Complex Move Request with heavy items and no lift constraint', () {
      final request = MoveRequest(
        id: "test-2",
        rawInput: "shifting full house with heavy double bed and ground floor to 3rd floor no lift",
        pickupLocation: "DHA Phase 2 Islamabad",
        dropoffLocation: "G-13 Islamabad",
        inventory: ["fridge", "double bed", "wardrobe", "dining table", "sofa", "boxes"],
        fragileItems: ["dining table"],
        heavyItems: ["fridge", "double bed", "wardrobe"],
        constraints: ["no lift at pickup"],
        budgetPreference: "standard",
        preferredTime: "Sunday morning",
      );

      service.analyzeRequest(request);

      // Base crew: 2. Heavy items: +1. No lift constraint: +1.
      expect(request.requiredCrew, equals(4));
      // Heavy items present -> Shahzor vehicle
      expect(request.requiredVehicle, equals("Shahzor"));
      expect(request.estimatedDuration, equals("3-5 hours"));
    });
  });

  group('MatchingService and Trust-First Features Tests', () {
    test('Equipment Fit and Red Flag Auditing for a standard provider', () {
      final request = MoveRequest(
        id: "test-trust-1",
        rawInput: "shifting home with fragile items",
        pickupLocation: "F-10 Islamabad",
        dropoffLocation: "G-11 Islamabad",
        inventory: ["dining table", "sofa", "boxes"],
        fragileItems: ["dining table"],
        heavyItems: [],
        constraints: [],
        budgetPreference: "standard",
        preferredTime: "Friday 10 AM",
      );

      // Populate mock InventoryItems
      request.inventoryItems = [
        InventoryItem(name: "dining table", quantity: 1, category: "furniture", fragile: true, heavy: false),
        InventoryItem(name: "sofa", quantity: 1, category: "furniture", fragile: false, heavy: false),
        InventoryItem(name: "boxes", quantity: 5, category: "carton", fragile: false, heavy: false),
      ];

      // Reliable Packers and Movers has blankets and bubble wrap, so they should have 100% equipment fit score for fragile items.
      final provider = localMoversDatabase.firstWhere((p) => p.id == "p1");
      final result = MatchingService.scoreProvider(
        provider: provider,
        request: request,
        distanceKm: 5.0,
      );

      expect(result.equipmentFitScore, equals(100.0));
      expect(result.missingEquipment, isEmpty);
      expect(result.redFlags, isEmpty); // Reliable packers is high trust, no red flags
    });

    test('Red Flag Auditing for a low trust cheap provider', () {
      final request = MoveRequest(
        id: "test-trust-2",
        rawInput: "shifting small room",
        pickupLocation: "F-10 Islamabad",
        dropoffLocation: "G-11 Islamabad",
        inventory: ["boxes"],
        fragileItems: [],
        heavyItems: [],
        constraints: [],
        budgetPreference: "cheap",
      );

      // Budget Loaderz has low confidence and cheap base price, so they should trigger red flags
      final provider = localMoversDatabase.firstWhere((p) => p.id == "p5"); // Budget Loaderz
      final result = MatchingService.scoreProvider(
        provider: provider,
        request: request,
        distanceKm: 5.0,
      );

      expect(result.redFlags, isNotEmpty);
      expect(result.redFlags.any((flag) => flag.contains('Suspiciously cheap') || flag.contains('Low data source')), isTrue);
    });
  });
}
