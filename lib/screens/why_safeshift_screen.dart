import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../models/move_request.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_cta.dart';
import '../widgets/section_header.dart';
import '../providers/app_state.dart';

class WhySafeShiftScreen extends StatelessWidget {
  final MoveRequest request;

  const WhySafeShiftScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final finalPrice = context.watch<AppState>().finalPrice;

    return Scaffold(
      appBar: AppBar(
        title: const Text("The SafeShift AI Difference"),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gorgeous Header Card
            FadeInDown(
              child: const SectionHeader(
                title: "SafeShift AI vs Traditional Apps",
                subtitle: "A first-of-its-kind agentic moving orchestration prototype for Pakistan's informal movers and packers economy.",
              ),
            ),
            const SizedBox(height: 20),

            // Comparison Table Card
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                borderColor: const Color(0xFF81C784).withOpacity(0.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "DIRECT PLATFORM COMPARISON",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFB5A1),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildComparisonRow(
                      feature: "Inventory Audit",
                      traditional: "Plain text, prone to missing items & driver rejection.",
                      safeshift: "Multi-Image structured manifest with size/weight estimates.",
                    ),
                    const Divider(color: Color(0x1ACFC6B0), height: 24),
                    _buildComparisonRow(
                      feature: "Price Protection",
                      traditional: "Surcharges and extra demands upon driver arrival.",
                      safeshift: "Rs. ${finalPrice.toStringAsFixed(0)} confirmed quote range.",
                    ),
                    const Divider(color: Color(0x1ACFC6B0), height: 24),
                    _buildComparisonRow(
                      feature: "Disputes & Damage",
                      traditional: "No support. Customer must negotiate pre-existing scratches.",
                      safeshift: "Dispute recommendation holds and multi-evidence human review required.",
                    ),
                    const Divider(color: Color(0x1ACFC6B0), height: 24),
                    _buildComparisonRow(
                      feature: "Driver Performance",
                      traditional: "Generic aggregate 5-star ratings (easily manipulated).",
                      safeshift: "Granular feedback synced to punctuality & transparency metrics.",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Highlights Grid
            const Text(
              "Four Pillars of SafeShift Trust",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE4E1EA),
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
              children: [
                _buildTrustPillarCard(
                  icon: Icons.shield_outlined,
                  color: const Color(0xFF81C784),
                  title: "Simulated Protection Hold",
                  description: "Fare held in simulated lock. Disbursed only when delivery matches the manifest.",
                  imagePath: 'assets/images/pillars/protection_hold.png',
                ),
                _buildTrustPillarCard(
                  icon: Icons.photo_library_outlined,
                  color: const Color(0xFFFFB5A1),
                  title: "AI Manifests",
                  description: "Detects item quantity, weight class, fragility, and required crew.",
                  imagePath: 'assets/images/pillars/ai_manifests.png',
                ),
                _buildTrustPillarCard(
                  icon: Icons.gavel_outlined,
                  color: const Color(0xFFFF8B8B),
                  title: "Dispute Recommendation",
                  description: "AI-assisted evidence summary for pre/post move claim review.",
                  imagePath: 'assets/images/pillars/dispute.png',
                ),
                _buildTrustPillarCard(
                  icon: Icons.autorenew_outlined,
                  color: Colors.amberAccent,
                  title: "Auto Recovery",
                  description: "Instantly prompts updates for bad input / missing information.",
                  imagePath: 'assets/images/pillars/auto_recovery.png',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Demo disclaimer
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.2)),
                ),
                child: const Text(
                  "ℹ️ Simulated protection hold, human review required, and dispute recommendation are fully simulated workflows designed for MVP demonstration purposes.",
                  style: TextStyle(fontSize: 10, color: Colors.amberAccent, fontStyle: FontStyle.italic, height: 1.3),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Finish CTA
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: PrimaryCTA(
                label: "Done & Return Home",
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow({
    required String feature,
    required String traditional,
    required String safeshift,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          feature,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                traditional,
                style: const TextStyle(color: Color(0xFF908F9D), fontSize: 11, height: 1.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF81C784), size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                safeshift,
                style: const TextStyle(color: Color(0xFF81C784), fontSize: 11, height: 1.3, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustPillarCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required String imagePath,
  }) {
    return FadeInUp(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background illustration
            Positioned.fill(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF1F1F25),
                ),
              ),
            ),
            // Dark gradient overlay for text readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF131319).withOpacity(0.4),
                      const Color(0xFF131319).withOpacity(0.95),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Subtle border
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.25), width: 1),
                ),
              ),
            ),
            // Icon badge top-left
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF131319).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
            ),
            // Title & description bottom
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFFBBBBC5),
                      fontSize: 9,
                      height: 1.3,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
