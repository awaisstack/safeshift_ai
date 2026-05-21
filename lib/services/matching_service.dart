import '../data/movers_data.dart';
import '../models/move_request.dart';

/// Multi-factor matching and ranking service.
/// Calculates a numeric SafeShift Match Score (0–100) for each provider
/// using 12 weighted factors from review evidence, provenance, and request fit.
class MatchingService {
  /// Scored result for a single provider
  static MatchResult scoreProvider({
    required MoverProvider provider,
    required MoveRequest request,
    required double distanceKm,
  }) {
    final factors = <String, double>{};
    final pros = <String>[];
    final cons = <String>[];

    // 1. Source Confidence (0-10)
    final sourceScore = provider.confidenceScore * 10;
    factors['Source Confidence'] = sourceScore;
    if (provider.confidenceScore >= 0.9) {
      pros.add('High-confidence data source (${(provider.confidenceScore * 100).toStringAsFixed(0)}%)');
    } else if (provider.confidenceScore < 0.6) {
      cons.add('Low data source confidence (${(provider.confidenceScore * 100).toStringAsFixed(0)}%)');
    }

    // 2. Rating (0-10)
    final ratingScore = (provider.rating / 5.0) * 10;
    factors['Rating'] = ratingScore;
    if (provider.rating >= 4.5) {
      pros.add('Excellent rating: ${provider.rating}/5');
    } else if (provider.rating < 4.0) {
      cons.add('Below-average rating: ${provider.rating}/5');
    }

    // 3. Review Volume (0-10)
    final reviewScore = (provider.reviewCount >= 50) ? 10.0 : (provider.reviewCount / 50) * 10;
    factors['Review Volume'] = reviewScore;
    if (provider.reviewCount < 15) {
      cons.add('Very few reviews (${provider.reviewCount})');
    }

    // 4. Fragile Handling Evidence (0-10)
    final fragilePositive = provider.reviews.where((r) => r.category == 'fragile' && r.sentiment == 'positive').length;
    final fragileNegative = provider.reviews.where((r) => r.category == 'fragile' && r.sentiment == 'negative').length;
    final hasFragileItems = request.inventoryItems.any((item) => item.fragile);
    double fragileScore = 5.0; // neutral default
    if (hasFragileItems) {
      if (fragilePositive > 0 && fragileNegative == 0) {
        fragileScore = 10.0;
        pros.add('Positive fragile handling evidence ($fragilePositive reviews)');
      } else if (fragileNegative > 0) {
        fragileScore = 2.0;
        cons.add('Fragile damage complaints ($fragileNegative reviews)');
      }
    }
    factors['Fragile Handling'] = fragileScore;

    // 5. Hidden Charge Risk (0-10, higher = safer)
    final hiddenChargeNeg = provider.reviews.where((r) => r.category == 'hidden_charges' && r.sentiment == 'negative').length;
    final hiddenChargePos = provider.reviews.where((r) => r.category == 'hidden_charges' && r.sentiment == 'positive').length;
    double hiddenChargeScore = 7.0;
    if (hiddenChargeNeg > 0) {
      hiddenChargeScore = (hiddenChargeNeg >= 2) ? 0.0 : 3.0;
      cons.add('Hidden charge complaints ($hiddenChargeNeg reviews)');
    } else if (hiddenChargePos > 0) {
      hiddenChargeScore = 10.0;
      pros.add('No hidden charges reported');
    }
    factors['Hidden Charge Risk'] = hiddenChargeScore;

    // 6. Damage Complaint Risk (0-10, higher = safer)
    final damageNeg = provider.reviews.where((r) => r.category == 'fragile' && r.sentiment == 'negative').length;
    double damageScore = 8.0;
    if (damageNeg > 0) {
      damageScore = (damageNeg >= 2) ? 1.0 : 4.0;
      cons.add('Damage complaints in reviews ($damageNeg)');
    }
    factors['Damage Risk (lower=riskier)'] = damageScore;

    // 7. Punctuality Evidence (0-10)
    final punctualityNeg = provider.reviews.where((r) => r.category == 'punctuality' && r.sentiment == 'negative').length;
    final punctualityPos = provider.reviews.where((r) => r.category == 'punctuality' && r.sentiment == 'positive').length;
    double punctualityScore = 7.0;
    if (punctualityNeg > 0) {
      punctualityScore = 3.0;
      cons.add('Punctuality/delay issues ($punctualityNeg reviews)');
    } else if (punctualityPos > 0) {
      punctualityScore = 10.0;
      pros.add('Strong punctuality record');
    }
    factors['Punctuality'] = punctualityScore;

    // 8. Route/City Coverage & Service-Area Compatibility (0-10)
    final pickup = request.pickupLocation?.toLowerCase() ?? '';
    final dropoff = request.dropoffLocation?.toLowerCase() ?? '';
    final serviceCities = ['islamabad', 'rawalpindi', 'bahria', 'g-13', 'saddar', 'dha', 'f-10', 'i-8', 'f-8', 'f-11'];
    
    bool pickupOk = serviceCities.any((city) => pickup.contains(city));
    bool dropoffOk = serviceCities.any((city) => dropoff.contains(city));
    
    double coverageScore = 10.0;
    if (!pickupOk || !dropoffOk) {
      coverageScore = 4.0;
      cons.add('Limited service coverage outside primary Islamabad/Rawalpindi zones');
    } else {
      pros.add('Pickup & drop-off within active Rawalpindi/Islamabad coverage');
    }
    factors['Route Coverage'] = coverageScore;

    // 9. Price Fairness (0-10) — lower multiplier = fairer price
    double priceScore = 10.0 - ((provider.multiplier - 0.85) / (1.25 - 0.85)) * 10;
    priceScore = priceScore.clamp(0.0, 10.0);
    
    // Parse budget sensitivity from constraints AND budgetPreference
    final budgetTerms = ['budget', 'controlled', 'affordable', 'cheap', 'low cost', 'kam budget', 'zyada nahi'];
    bool isBudgetSensitive = false;
    if (request.budgetPreference != null) {
      final bp = request.budgetPreference!.toLowerCase();
      if (budgetTerms.any((term) => bp.contains(term))) {
        isBudgetSensitive = true;
      }
    }
    if (!isBudgetSensitive) {
      for (final c in request.constraints) {
        final cl = c.toLowerCase();
        if (budgetTerms.any((term) => cl.contains(term))) {
          isBudgetSensitive = true;
          break;
        }
      }
    }

    if (isBudgetSensitive && provider.multiplier > 1.15) {
      cons.add('Premium pricing may exceed budget preference');
      priceScore *= 0.7;
    }
    factors['Price Fairness'] = priceScore;

    // 10. Provider Markup (0-10)
    double multiplierScore = provider.multiplier <= 1.0 ? 10.0 : (10.0 - (provider.multiplier - 1.0) * 20).clamp(0.0, 10.0);
    factors['Provider Markup'] = multiplierScore;

    // 11. Vehicle/Crew & Long-Distance Fit (0-10)
    double vehicleFitScore = 7.0;
    final reqVehicle = request.requiredVehicle?.toLowerCase() ?? '';
    final provVehicle = provider.vehicleType.toLowerCase();

    if (reqVehicle.contains('medium truck') || reqVehicle.contains('mazda')) {
      if (provVehicle.contains('mazda') || provVehicle.contains('medium truck') || provVehicle.contains('truck')) {
        vehicleFitScore = 10.0;
        pros.add('Vehicle class matches required truck capacity');
      } else if (provVehicle.contains('shahzor')) {
        vehicleFitScore = 8.0;
        pros.add('Shahzor suitable for this load in city routes (may need careful stacking)');
      } else {
        vehicleFitScore = 2.0;
        cons.add('Small vehicle may not fit required truck capacity');
      }
    } else if (reqVehicle.contains('shahzor')) {
      if (provVehicle.contains('shahzor')) {
        vehicleFitScore = 10.0;
        pros.add('Perfect vehicle size match (Shahzor)');
      } else if (provVehicle.contains('mazda') || provVehicle.contains('medium truck')) {
        vehicleFitScore = 8.0;
        pros.add('Provider offers larger capacity vehicle');
      } else {
        vehicleFitScore = 4.0;
        cons.add('Suzuki may require multiple trips for this load');
      }
    } else { // suzuki requested or standard load
      if (provVehicle.contains('suzuki')) {
        vehicleFitScore = 10.0;
        pros.add('Suzuki matches small/standard shifting volume');
      } else {
        vehicleFitScore = 7.0; // Overkill but fits
      }
    }
    
    // Check distance compatibility in scoring
    if (distanceKm > 15.0 && provider.vehicleType.toLowerCase().contains('suzuki')) {
      vehicleFitScore = (vehicleFitScore - 3.0).clamp(0.0, 10.0);
      cons.add('Suzuki is less suitable for long distance (${distanceKm.toStringAsFixed(1)} km)');
    } else if (distanceKm > 15.0 && !provider.vehicleType.toLowerCase().contains('suzuki')) {
      pros.add('Sturdy vehicle suitable for long-distance transit');
    }
    factors['Vehicle/Crew Fit'] = vehicleFitScore;

    // 12. Budget Preference Alignment (0-10)
    double budgetAlignScore = 7.0;
    if (isBudgetSensitive) {
      if (provider.basePrice <= 4500) {
        budgetAlignScore = 10.0;
        pros.add('Budget-friendly base price');
      } else if (provider.basePrice >= 7000) {
        budgetAlignScore = 3.0;
        cons.add('High base price vs budget preference');
      }
    }
    factors['Budget Alignment'] = budgetAlignScore;

    // Weighted total (weights sum to 1.0)
    final requiredEquipment = <String>[];
    final missingEquipment = <String>[];

    final hasFragile = request.inventoryItems.any((item) => item.fragile) || request.fragileItems.isNotEmpty;
    final hasHeavy = request.inventoryItems.any((item) => item.heavy) || request.heavyItems.isNotEmpty;
    final hasStairs = request.constraints.any((c) => c.toLowerCase().contains('stairs') || c.toLowerCase().contains('no lift') || c.toLowerCase().contains('floor'));
    final needsDisassembly = request.inventoryItems.any((item) => item.needsDisassembly);

    if (hasFragile) {
      requiredEquipment.add('blankets');
      requiredEquipment.add('bubbleWrap');
    }
    if (hasHeavy) {
      requiredEquipment.add('straps');
      requiredEquipment.add('trolley');
    }
    if (hasStairs) {
      requiredEquipment.add('trolley');
      requiredEquipment.add('straps');
      requiredEquipment.add('crewCount>=3');
    }
    if (needsDisassembly) {
      requiredEquipment.add('disassemblyTools');
      requiredEquipment.add('tools');
    }

    if (requiredEquipment.isEmpty) {
      requiredEquipment.addAll(['cartons', 'tape', 'tools']);
    }

    int satisfiedCount = 0;
    final uniqueReqs = requiredEquipment.toSet().toList();
    for (final req in uniqueReqs) {
      bool ok = false;
      if (req == 'blankets' && provider.hasBlankets) ok = true;
      else if (req == 'bubbleWrap' && provider.hasBubbleWrap) ok = true;
      else if (req == 'cartons' && provider.hasCartons) ok = true;
      else if (req == 'tape' && provider.hasTape) ok = true;
      else if (req == 'trolley' && provider.hasTrolley) ok = true;
      else if (req == 'straps' && provider.hasStraps) ok = true;
      else if (req == 'tools' && provider.hasTools) ok = true;
      else if (req == 'disassemblyTools' && provider.hasDisassemblyTools) ok = true;
      else if (req == 'crewCount>=3' && provider.crewCount >= 3) ok = true;

      if (ok) {
        satisfiedCount++;
      } else {
        missingEquipment.add(req);
      }
    }

    final double equipmentFitScore = uniqueReqs.isEmpty ? 100.0 : (satisfiedCount / uniqueReqs.length) * 100.0;
    factors['Equipment Fit'] = equipmentFitScore / 10.0;

    if (equipmentFitScore >= 80.0) {
      pros.add('Excellent equipment fit: ${equipmentFitScore.toStringAsFixed(0)}%');
    } else if (equipmentFitScore < 50.0) {
      cons.add('Poor equipment fit: ${equipmentFitScore.toStringAsFixed(0)}%');
    }

    // Red Flag Audit
    final redFlags = <String>[];
    if (provider.basePrice < 3575.0) {
      redFlags.add('Suspiciously cheap quote (>35% below median)');
    }
    final hasHiddenNeg = provider.reviews.any((r) => r.category == 'hidden_charges' && r.sentiment == 'negative');
    if (hasHiddenNeg) {
      redFlags.add('Hidden-charge complaints detected');
    }
    if (provider.confidenceScore < 0.60) {
      redFlags.add('Low data source evidence confidence');
    }
    if (!provider.hasBlankets && !provider.hasTrolley && !provider.hasStraps && !provider.hasTools) {
      redFlags.add('No professional shifting equipment details');
    }

    const weights = {
      'Source Confidence': 0.08,
      'Rating': 0.10,
      'Review Volume': 0.05,
      'Fragile Handling': 0.10,
      'Hidden Charge Risk': 0.10,
      'Damage Risk (lower=riskier)': 0.08,
      'Punctuality': 0.08,
      'Route Coverage': 0.05,
      'Price Fairness': 0.08,
      'Provider Markup': 0.05,
      'Vehicle/Crew Fit': 0.08,
      'Budget Alignment': 0.05,
      'Equipment Fit': 0.10,
    };

    double totalScore = 0;
    for (final entry in weights.entries) {
      totalScore += (factors[entry.key] ?? 5.0) * entry.value;
    }
    // Scale to 0-100
    final matchScore = (totalScore * 10).clamp(0.0, 100.0);

    return MatchResult(
      provider: provider,
      matchScore: matchScore,
      factors: factors,
      pros: pros,
      cons: cons,
      status: 'CALCULATING', // Will be overridden in rankProviders
      equipmentFitScore: equipmentFitScore,
      missingEquipment: missingEquipment,
      redFlags: redFlags,
    );
  }

  /// Rank all providers for a given request, sorted by match score descending.
  static List<MatchResult> rankProviders({
    required List<MoverProvider> providers,
    required MoveRequest request,
    required double distanceKm,
  }) {
    final results = providers.map((p) => scoreProvider(
      provider: p,
      request: request,
      distanceKm: distanceKm,
    )).toList();
    
    // Sort descending
    results.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    // Dynamic status assignment with no hardcoded winner logic
    for (int i = 0; i < results.length; i++) {
      final res = results[i];
      final mover = res.provider;
      String status;
      
      if (i == 0) {
        status = 'Best Recommended';
      } else {
        // Evaluate other statuses deterministically
        final hasHiddenNeg = mover.reviews.any((r) => r.category == 'hidden_charges' && r.sentiment == 'negative');
        final hasFragileNeg = mover.reviews.any((r) => r.category == 'fragile' && r.sentiment == 'negative');
        final isSuzuki = mover.vehicleType.toLowerCase().contains('suzuki');
        
        if (hasHiddenNeg) {
          status = 'Higher hidden-charge risk';
        } else if (hasFragileNeg && request.fragileItems.isNotEmpty) {
          status = 'High review score but weak fragile evidence';
        } else if (isSuzuki && distanceKm > 15.0) {
          status = 'Limited coverage';
        } else if (mover.multiplier < 1.0 && mover.rating < 4.0) {
          status = 'Cheaper but risky';
        } else {
          status = 'Good backup';
        }
      }

      results[i] = MatchResult(
        provider: res.provider,
        matchScore: res.matchScore,
        factors: res.factors,
        pros: res.pros,
        cons: res.cons,
        status: status,
        equipmentFitScore: res.equipmentFitScore,
        missingEquipment: res.missingEquipment,
        redFlags: res.redFlags,
      );
    }

    return results;
  }
}

class MatchResult {
  final MoverProvider provider;
  final double matchScore;
  final Map<String, double> factors;
  final List<String> pros;
  final List<String> cons;
  final String status;
  final double equipmentFitScore;
  final List<String> missingEquipment;
  final List<String> redFlags;

  const MatchResult({
    required this.provider,
    required this.matchScore,
    required this.factors,
    required this.pros,
    required this.cons,
    required this.status,
    required this.equipmentFitScore,
    required this.missingEquipment,
    required this.redFlags,
  });
}
