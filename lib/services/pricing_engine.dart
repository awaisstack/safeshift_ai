import '../models/move_request.dart';
import '../data/movers_data.dart';

class PricingBreakdown {
  final double baseFee;
  final double distanceFee;
  final double vehicleAddon;
  final double laborFee;
  final double stairsFee;
  final double fragileFee;
  final double heavyFee;
  final double disassemblyFee;
  final double wrappingFee;
  final double unverifiedBuffer;
  final double weekendMarkup;
  final double providerMarkup;
  final double total;

  PricingBreakdown({
    required this.baseFee,
    required this.distanceFee,
    required this.vehicleAddon,
    required this.laborFee,
    required this.stairsFee,
    required this.fragileFee,
    required this.heavyFee,
    required this.disassemblyFee,
    required this.wrappingFee,
    required this.unverifiedBuffer,
    required this.weekendMarkup,
    required this.providerMarkup,
    required this.total,
  });

  Map<String, double> toMap() => {
        'Base Transport': baseFee,
        'Distance Fee': distanceFee,
        'Vehicle Class': vehicleAddon,
        'Labor / Crew': laborFee,
        'Stairs Surcharge': stairsFee,
        'Fragile Surcharge': fragileFee,
        'Heavy Surcharge': heavyFee,
        'Disassembly Service': disassemblyFee,
        'Wrapping Service': wrappingFee,
        'Unverified Buffer': unverifiedBuffer,
        'Weekend/Urgency': weekendMarkup,
        'Provider Premium': providerMarkup,
        'Total': total,
      };
}

class PricingEngine {
  static PricingBreakdown calculatePrice({
    required MoveRequest request,
    required MoverProvider provider,
    required double distanceKm,
  }) {
    // 1. Base Fee (From Provider or default, adjusted by moveType)
    double moveTypeMultiplier = 1.0;
    if (request.moveType == 'Intercity move') {
      moveTypeMultiplier = 1.6;
    } else if (request.moveType == 'Office shifting') {
      moveTypeMultiplier = 1.3;
    } else if (request.moveType == 'One-item move') {
      moveTypeMultiplier = 0.8;
    } else if (request.moveType == 'Internal furniture rearrangement') {
      moveTypeMultiplier = 0.5;
    }
    final baseFee = provider.basePrice * moveTypeMultiplier;

    // 2. Distance Fee (PKR 150 per Km for Suzuki, PKR 200/Km for Shahzor, PKR 280/Km for Mazda)
    double ratePerKm = 150;
    double vehicleAddon = 0;
    
    if (provider.vehicleType.toLowerCase().contains("shahzor")) {
      ratePerKm = 200;
      vehicleAddon = 1500; // base size upgrade
    } else if (provider.vehicleType.toLowerCase().contains("mazda") || 
               provider.vehicleType.toLowerCase().contains("medium truck")) {
      ratePerKm = 280;
      vehicleAddon = 3500;
    }
    final distanceFee = distanceKm * ratePerKm;

    // 3. Labor Fee: PKR 1,500 per helper
    int helpers = request.requiredCrew ?? 2;
    final laborFee = helpers * 1500.0;

    // 4. Stairs/No-lift Fee: PKR 2,000 flat surcharge if no lift
    double stairsFee = 0;
    final hasStairConstraint = request.constraints.any((c) => c.toLowerCase().contains("no lift") || c.toLowerCase().contains("stairs"));
    if (hasStairConstraint) {
      stairsFee = 2000.0; // Flat stairs surcharge for loading/unloading floors
    }

    // 5. Fragile Surcharge: PKR 800 per fragile item (for bubble wrap & safe padding)
    final fragileCount = request.inventoryItems.where((item) => item.fragile).fold(0, (sum, item) => sum + item.quantity);
    final fragileFee = fragileCount * 800.0;

    // 6. Heavy Item Surcharge: PKR 1,200 per heavy item (requires multi-loader safety straps)
    final heavyCount = request.inventoryItems.where((item) => item.heavy).fold(0, (sum, item) => sum + item.quantity);
    final heavyFee = heavyCount * 1200.0;

    // Disassembly Surcharge: PKR 1,000 per disassembled item
    final disassemblyCount = request.inventoryItems.where((item) => item.needsDisassembly).fold(0, (sum, item) => sum + item.quantity);
    final disassemblyFee = disassemblyCount * 1000.0;

    // Wrapping Surcharge: PKR 500 per wrapped item
    final wrappingCount = request.inventoryItems.where((item) => item.needsWrapping).fold(0, (sum, item) => sum + item.quantity);
    final wrappingFee = wrappingCount * 500.0;

    // Low confidence / unverified buffer penalty fee: PKR 2,000 if manual/none, PKR 1,000 if low confidence scan (<0.75)
    double unverifiedBuffer = 0.0;
    if (request.inventorySource == 'none' || request.continueWithoutImageEvidence) {
      unverifiedBuffer = 2000.0;
    } else if (request.imageInventoryConfidence != null && request.imageInventoryConfidence! < 0.75) {
      unverifiedBuffer = 1000.0;
    }

    // 7. Weekend / Urgency markup: +PKR 1,500 if shifting weekend
    double weekendMarkup = 0;
    final isWeekend = request.preferredTime?.toLowerCase().contains("saturday") == true ||
        request.preferredTime?.toLowerCase().contains("sunday") == true;
    if (isWeekend) {
      weekendMarkup = 1500.0;
    }

    // 8. Raw subtotal
    final subtotal = baseFee + distanceFee + vehicleAddon + laborFee + stairsFee + fragileFee + heavyFee + disassemblyFee + wrappingFee + unverifiedBuffer + weekendMarkup;

    // 9. Provider Multiplier Markup (Brand reputation adjustment)
    final double totalWithMultiplier = subtotal * provider.multiplier;
    final providerMarkup = totalWithMultiplier - subtotal;

    // Calculate and set quote confidence
    if (request.inventorySource == 'image' || request.inventorySource == 'mixed') {
      if (request.hasValidInventoryEvidence) {
        request.quoteConfidence = 'High';
        request.quoteConfidenceReason = 'Verified via photo scans of room/items';
      } else {
        request.quoteConfidence = 'Low';
        request.quoteConfidenceReason = 'Unverified image evidence submitted';
      }
    } else if (request.inventorySource == 'text') {
      request.quoteConfidence = 'Medium';
      request.quoteConfidenceReason = 'Inventory extracted from prompt text only (no photo)';
    } else {
      request.quoteConfidence = 'Low';
      request.quoteConfidenceReason = 'No inventory manifest provided';
    }

    return PricingBreakdown(
      baseFee: baseFee,
      distanceFee: distanceFee,
      vehicleAddon: vehicleAddon,
      laborFee: laborFee,
      stairsFee: stairsFee,
      fragileFee: fragileFee,
      heavyFee: heavyFee,
      disassemblyFee: disassemblyFee,
      wrappingFee: wrappingFee,
      unverifiedBuffer: unverifiedBuffer,
      weekendMarkup: weekendMarkup,
      providerMarkup: providerMarkup,
      total: totalWithMultiplier,
    );
  }
}
