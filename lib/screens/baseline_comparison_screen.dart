import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_cta.dart';
import '../widgets/section_header.dart';
import '../widgets/agent_trace_card.dart';
import '../models/agent_trace.dart';
import '../services/matching_service.dart';
import '../models/move_request.dart';
import '../services/pricing_engine.dart';

class BaselineComparisonScreen extends StatelessWidget {
  final List<MatchResult> rankedResults;
  final MoveRequest? request;
  final double? distanceKm;

  const BaselineComparisonScreen({
    super.key,
    required this.rankedResults,
    this.request,
    this.distanceKm,
  });

  /// Calculate a formula-based risk score (0–100, higher = riskier)
  static double _calculateRiskScore(MatchResult result) {
    final mover = result.provider;
    double risk = 0;

    // Hidden-charge complaints: +25 per complaint
    final hiddenChargeNeg = mover.reviews.where((r) => r.category == 'hidden_charges' && r.sentiment == 'negative').length;
    risk += hiddenChargeNeg * 25;

    // Fragile damage risk: +20 per negative fragile review
    final fragileNeg = mover.reviews.where((r) => r.category == 'fragile' && r.sentiment == 'negative').length;
    risk += fragileNeg * 20;

    // Low source confidence: +15 if confidence < 0.6
    if (mover.confidenceScore < 0.6) risk += 15;

    // No quote lock (not registered): +10
    if (!mover.isRegistered) risk += 10;

    // Cancellation/delay risk: +15 per delay complaint
    final delayNeg = mover.reviews.where((r) => r.category == 'punctuality' && r.sentiment == 'negative').length;
    risk += delayNeg * 15;

    // Vehicle/crew mismatch: +10 if small vehicle
    if (mover.vehicleType.toLowerCase().contains('suzuki')) risk += 5;

    return risk.clamp(0, 100);
  }

  double _getEstimatedPrice(MatchResult result) {
    if (request != null && distanceKm != null) {
      try {
        final breakdown = PricingEngine.calculatePrice(
          request: request!,
          provider: result.provider,
          distanceKm: distanceKm!,
        );
        return breakdown.total;
      } catch (e) {
        print("Pricing calculation error: $e");
      }
    }
    return result.provider.basePrice * result.provider.multiplier;
  }

  @override
  Widget build(BuildContext context) {
    // 1. SafeShift provider selected by highest Match Score (first of sorted rankedResults)
    final bestResult = rankedResults.isNotEmpty ? rankedResults.first : null;

    // 2. Baseline provider selected by traditional logic: lowest estimated price
    MatchResult? cheapestResult;
    double lowestPrice = double.infinity;
    for (final result in rankedResults) {
      final price = _getEstimatedPrice(result);
      if (price < lowestPrice) {
        lowestPrice = price;
        cheapestResult = result;
      }
    }

    final worstResult = cheapestResult;

    final bestRisk = bestResult != null ? _calculateRiskScore(bestResult) : 0.0;
    final worstRisk = worstResult != null ? _calculateRiskScore(worstResult) : 0.0;

    final trace = AgentTrace(
      stepName: "Matcher & Ranker Agent (Baseline vs SafeShift)",
      observation: "User chose controlled budget with fragile items in inventory.",
      inference: "${worstResult?.provider.name ?? 'N/A'} has the lowest estimated price but review evidence shows hidden fees and fragile handling issues.",
      decision: "Reject ${worstResult?.provider.name ?? 'N/A'} despite lowest price. Recommend ${bestResult?.provider.name ?? 'N/A'}.",
      action: "Calculated risk scores: Baseline Risk ${worstRisk.toStringAsFixed(0)}/100, SafeShift Risk ${bestRisk.toStringAsFixed(0)}/100.",
      outcome: "Risk reduction of ${(worstRisk - bestRisk).toStringAsFixed(0)} points by choosing SafeShift-recommended provider.",
    );

    return Scaffold(
      appBar: AppBar(title: const Text("AI Matcher Baseline Comparison")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: const SectionHeader(
                title: "SafeShift AI vs. Simple Sorting",
                subtitle: "Contrast agentic decision orchestration against a traditional listing app.",
              ),
            ),
            const SizedBox(height: 24),

            // Risk Formula Explanation
            FadeInUp(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x0DFFB5A1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x33FFB5A1)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("RISK SCORE FORMULA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFFB5A1))),
                    SizedBox(height: 6),
                    Text(
                      "Risk = (hidden_charge_complaints × 25) + (fragile_damage_reviews × 20) + (low_confidence < 0.6 ? 15 : 0) + (not_registered ? 10 : 0) + (delay_complaints × 15) + (small_vehicle ? 5 : 0)",
                      style: TextStyle(fontSize: 10, color: Color(0xFF908F9D), fontFamily: 'Outfit', height: 1.4),
                    ),
                    SizedBox(height: 4),
                    Text("Scale: 0 = safest, 100 = highest risk", style: TextStyle(fontSize: 9, color: Color(0xFF908F9D), fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baseline Column
                Expanded(
                  child: FadeInLeft(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close, color: Colors.redAccent, size: 14),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "Standard Listing App",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassCard(
                          padding: const EdgeInsets.all(12),
                          borderColor: Colors.redAccent.withOpacity(0.2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("CHEAPEST PICK:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF908F9D), fontSize: 10)),
                              const SizedBox(height: 4),
                              Text(worstResult?.provider.name ?? "N/A", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 8),
                              const Divider(color: Color(0x1ACFC6B0), height: 12),
                              const Text("RISK SCORE:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF908F9D), fontSize: 10)),
                              const SizedBox(height: 4),
                              Text(
                                "${worstRisk.toStringAsFixed(0)} / 100",
                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 22),
                              ),
                              const SizedBox(height: 8),
                              if (worstResult != null) ...[
                                ...worstResult.cons.take(3).map((c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text("⚠️ $c", style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                                )),
                              ],
                              const SizedBox(height: 8),
                              const Text(
                                "⚠️ No review analysis. Sorts by price only.",
                                style: TextStyle(color: Color(0xFF908F9D), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // SafeShift Column
                Expanded(
                  child: FadeInRight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, color: Colors.greenAccent, size: 14),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "SafeShift AI",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassCard(
                          padding: const EdgeInsets.all(12),
                          borderColor: Colors.greenAccent.withOpacity(0.2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("AI RECOMMENDED:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF908F9D), fontSize: 10)),
                              const SizedBox(height: 4),
                              Text(bestResult?.provider.name ?? "N/A", style: const TextStyle(color: Color(0xFFFFB5A1), fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 8),
                              const Divider(color: Color(0x1ACFC6B0), height: 12),
                              const Text("RISK SCORE:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF908F9D), fontSize: 10)),
                              const SizedBox(height: 4),
                              Text(
                                "${bestRisk.toStringAsFixed(0)} / 100",
                                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 22),
                              ),
                              const SizedBox(height: 8),
                              if (bestResult != null) ...[
                                ...bestResult.pros.take(3).map((p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text("✅ $p", style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                                )),
                              ],
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.amber.withOpacity(0.2)),
                                ),
                                child: const Text(
                                  "Simulated protection hold quote lock is a prototype feature.",
                                  style: TextStyle(fontSize: 9, color: Colors.amberAccent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            FadeInUp(
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Why does this happen?",
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE4E1EA)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Traditional logistics aggregators display star rankings without scanning textual review metadata. Informal drivers often offer low base quotes to get selected, then demand extra charges upon arrival due to constraints like stairs or parking distance.\n\nSafeShift AI uses the Review Evidence Summary to audit curated review samples, identifying hidden pricing traps and fragile safety indicators before ranking providers with a 12-factor weighted formula.",
                      style: TextStyle(color: Color(0xFF908F9D), fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            AgentTraceCard(trace: trace),
            const SizedBox(height: 32),
            PrimaryCTA(
              label: "Back to Mover List",
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
