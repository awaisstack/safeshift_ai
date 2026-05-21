import '../models/move_request.dart';

class InventoryComplexityService {
  void analyzeRequest(MoveRequest request) {
    int totalItems = request.inventoryItems.fold(0, (sum, item) => sum + item.quantity);
    int heavyItemsCount = request.inventoryItems.where((item) => item.heavy).fold(0, (sum, item) => sum + item.quantity);
    int needsTwoPersonLiftCount = request.inventoryItems.where((item) => item.needsTwoPersonLift).length;
    int needsDisassemblyCount = request.inventoryItems.where((item) => item.needsDisassembly).length;

    int baseCrew = 2;
    if (totalItems > 12) baseCrew++;
    if (heavyItemsCount > 0) baseCrew++;
    if (needsTwoPersonLiftCount > 0) baseCrew = baseCrew < 3 ? 3 : baseCrew; // At least 3 if heavy lifts
    if (request.constraints.contains("no lift at pickup") || request.constraints.contains("no lift at dropoff")) {
      baseCrew++;
    }

    request.requiredCrew = baseCrew.clamp(2, 6);

    // Vehicle estimation based on volume categories
    int bulkyCount = request.inventoryItems.where((item) => item.volumeClass == 'bulky' || item.volumeClass == 'very_bulky').fold(0, (sum, item) => sum + item.quantity);

    if (bulkyCount > 3 || totalItems > 15) {
      request.requiredVehicle = "Medium Truck";
    } else if (bulkyCount > 0 || heavyItemsCount > 0 || totalItems > 5) {
      request.requiredVehicle = "Shahzor";
    } else {
      request.requiredVehicle = "Suzuki";
    }

    // Duration estimation
    if (request.requiredVehicle == "Medium Truck") {
      request.estimatedDuration = needsDisassemblyCount > 1 ? "5-7 hours" : "4-6 hours";
    } else if (request.requiredVehicle == "Shahzor") {
      request.estimatedDuration = "3-5 hours";
    } else {
      request.estimatedDuration = "2-3 hours";
    }
  }
}

