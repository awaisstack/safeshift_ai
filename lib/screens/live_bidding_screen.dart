import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/move_request.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_cta.dart';
import '../widgets/section_header.dart';
import '../widgets/agent_trace_card.dart';
import '../widgets/interactive_map_widget.dart';
import '../models/agent_trace.dart';
import '../data/movers_data.dart';
import '../services/pricing_engine.dart';
import '../services/matching_service.dart';
import '../providers/app_state.dart';
import 'mover_chat_screen.dart';
import 'baseline_comparison_screen.dart';
import 'recovery_screen.dart';

class LiveBiddingScreen extends StatefulWidget {
  final MoveRequest request;

  const LiveBiddingScreen({super.key, required this.request});

  @override
  State<LiveBiddingScreen> createState() => _LiveBiddingScreenState();
}

class _LiveBiddingScreenState extends State<LiveBiddingScreen> {
  bool _isLoading = true;
  final Map<String, bool> _analystExpanded = {};
  List<MatchResult> _rankedResults = [];

  @override
  void initState() {
    super.initState();
    _startSearchTimer();
  }

  void _startSearchTimer() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        final distance = appState.calculatedDistance;
        _rankedResults = MatchingService.rankProviders(
          providers: localMoversDatabase,
          request: widget.request,
          distanceKm: distance,
        );
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTraceMode = appState.isAgentTraceModeEnabled;
    final distance = appState.calculatedDistance;

    final pickup = widget.request.pickupLocation ?? appState.pickupLocation;
    final dropoff = widget.request.dropoffLocation ?? appState.dropoffLocation;

    // Traces
    final discoveryTrace = AgentTrace(
      stepName: "Provider Discovery Agent",
      observation: "User needs a mover in Rawalpindi/Islamabad.",
      inference: "Search/filter provider candidates by city coverage, route, inventory capability, public source confidence, and contactability.",
      decision: "Use curated public-source providers for MVP. Mark unverified contact channels clearly.",
      action: "Create shortlist with provider source links, contact status, and evidence confidence.",
      outcome: "Compiled ${localMoversDatabase.length} movers for Review Evidence evaluation.",
    );

    final reviewTrace = AgentTrace(
      stepName: "Review Evidence Summary",
      observation: "Audited ${localMoversDatabase.fold<int>(0, (sum, m) => sum + m.reviews.length)} synthetic MVP review samples across ${localMoversDatabase.length} providers.",
      inference: "Counted hidden-charge complaints, fragile damage reports, and punctuality issues from curated review samples.",
      decision: "Assigned deterministic trust scores based on review category counts and source confidence.",
      action: "Computed match scores using 12-factor weighted formula. Top scorer: ${_rankedResults.isNotEmpty ? _rankedResults.first.provider.name : 'N/A'} (${_rankedResults.isNotEmpty ? _rankedResults.first.matchScore.toStringAsFixed(1) : 'N/A'}/100).",
      outcome: "Dispatched ranked results to UI. Reviews labeled as synthetic MVP samples.",
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Service Matching"),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows, color: Color(0xFFFFB5A1)),
            tooltip: "Compare AI vs Simple Sorting",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BaselineComparisonScreen(
                  rankedResults: _rankedResults,
                  request: widget.request,
                  distanceKm: distance,
                )),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState(pickup, dropoff)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map routing at the top
                  InteractiveMapWidget(
                    pickupName: pickup,
                    dropoffName: dropoff,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x1A81C784),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x3381C784)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, color: Color(0xFF81C784), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Price is based on ${widget.request.inventoryItems.fold<int>(0, (sum, i) => sum + i.quantity)} confirmed items. If more items are added later, the quote may change.",
                            style: const TextStyle(fontSize: 12, color: Color(0xFFE4E1EA), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Curated AI Recommendations",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE4E1EA),
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Ranked by 12-factor match scoring.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFCFC6B0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.warning_amber, size: 14, color: Color(0xFFFF8B8B)),
                        label: const Text("Simulate Delay", style: TextStyle(fontSize: 11, color: Color(0xFFFF8B8B))),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          final failedMover = localMoversDatabase.firstWhere((m) => m.id == "p1");
                          final backups = localMoversDatabase.where((m) => m.id == "p2" || m.id == "p3").toList();
                          appState.triggerRecoverySimulation(
                            failedMover, 
                            "Fuel queue delays at Saddar filling station.", 
                            backups
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RecoveryScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Render providers sorted by match score
                  ..._rankedResults.map((result) {
                    final breakdown = PricingEngine.calculatePrice(
                      request: widget.request,
                      provider: result.provider,
                      distanceKm: distance,
                    );
                    return _buildMoverCard(result, breakdown, isTraceMode, appState);
                  }),

                  if (isTraceMode) ...[
                    const SizedBox(height: 32),
                    const SectionHeader(title: "Matching System Traces"),
                    const SizedBox(height: 12),
                    AgentTraceCard(trace: discoveryTrace),
                    const SizedBox(height: 12),
                    AgentTraceCard(trace: reviewTrace),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState(String pickup, String dropoff) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFFFB5A1)),
          const SizedBox(height: 24),
          const Text(
            "Analyzing Local Movers...",
            style: TextStyle(fontFamily: 'Outfit', fontSize: 18, color: Color(0xFFCFC6B0)),
          ),
          const SizedBox(height: 8),
          Text(
            "Routing: $pickup se $dropoff",
            style: const TextStyle(color: Color(0xFF908F9D)),
          ),
        ],
      ),
    );
  }

  Widget _buildMoverCard(MatchResult result, PricingBreakdown price, bool isTraceMode, AppState appState) {
    final mover = result.provider;
    final isRecommended = result.status == 'Best Recommended';
    final isRisky = result.status.toLowerCase().contains('risk') || result.status.toLowerCase().contains('weak') || mover.sourceType == "Fictional/Mock";

    // Review evidence counts for honest display
    final hiddenChargeCount = mover.reviews.where((r) => r.category == 'hidden_charges' && r.sentiment == 'negative').length;
    final fragileNegCount = mover.reviews.where((r) => r.category == 'fragile' && r.sentiment == 'negative').length;
    final punctualityIssues = mover.reviews.where((r) => r.category == 'punctuality' && r.sentiment == 'negative').length;
    final totalReviews = mover.reviews.length;
    final negativeReviews = mover.reviews.where((r) => r.sentiment == 'negative').length;
    final trustScore = totalReviews > 0 ? ((totalReviews - negativeReviews) / totalReviews * 100).toStringAsFixed(0) : "100";

    // CTA Label mapping based on provider certification and risk level
    String ctaLabel = "Prepare Outreach Draft";
    if (mover.sourceType == "Fictional/Mock") {
      ctaLabel = "View Demo Outreach Only";
    } else if (mover.isRegistered) {
      ctaLabel = "Connect & Chat (Certified)";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRisky
              ? Colors.redAccent.withOpacity(0.4)
              : isRecommended
                  ? const Color(0xFFFFB5A1).withOpacity(0.4)
                  : const Color(0x1ACFC6B0),
          width: isRecommended ? 1.5 : 1,
        ),
      ),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Provider name, Price, Quote confidence in fully responsive column layout
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        mover.name,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE4E1EA),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Rs. ${price.total.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFB5A1),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "PKR quote (sim.)",
                          style: TextStyle(fontSize: 8, color: Color(0xFF81C784)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildConfidenceBadge(widget.request.quoteConfidence),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Trust Row: Match Score, Registered/Public/Mock status, Equipment Fit, Star Rating (using uniform Wrap badges)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildTrustBadge(
                  icon: isRisky ? Icons.warning_amber_rounded : Icons.verified_outlined,
                  text: "Match: ${result.matchScore.toStringAsFixed(0)}/100",
                  color: isRisky ? Colors.redAccent : isRecommended ? const Color(0xFF81C784) : const Color(0xFFFFB5A1),
                ),
                if (mover.sourceType == "Fictional/Mock")
                  _buildTrustBadge(icon: Icons.dangerous_outlined, text: "Mock Provider", color: Colors.redAccent)
                else if (mover.isRegistered)
                  _buildTrustBadge(icon: Icons.verified, text: "Certified Partner", color: const Color(0xFF81C784))
                else
                  _buildTrustBadge(icon: Icons.search, text: "Public Source", color: const Color(0xFFFFB5A1)),
                _buildTrustBadge(
                  icon: Icons.handyman_outlined,
                  text: "Equip Fit: ${result.equipmentFitScore.toStringAsFixed(0)}%",
                  color: result.equipmentFitScore >= 80 ? const Color(0xFF81C784) : const Color(0xFFFFB5A1),
                ),
                _buildTrustBadge(
                  icon: Icons.star_rounded,
                  text: "${mover.rating} (${mover.reviewCount})",
                  color: Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. Key Reason Row callout: single concise agentic sentence
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isRisky
                    ? Colors.red.withOpacity(0.08)
                    : isRecommended
                        ? const Color(0x0D81C784)
                        : const Color(0x0DFFB5A1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isRisky
                      ? Colors.redAccent.withOpacity(0.2)
                      : isRecommended
                          ? const Color(0x1A81C784)
                          : const Color(0x1AFFB5A1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isRisky ? Icons.warning_amber_rounded : Icons.info_outline,
                    color: isRisky ? Colors.redAccent : isRecommended ? const Color(0xFF81C784) : const Color(0xFFFFB5A1),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isRisky
                          ? "Not recommended: hidden-charge risk and weak equipment fit."
                      : isRecommended
                          ? "Selected because of high source confidence, stronger fragile-item evidence, and better equipment fit."
                          : "Suitable budget alternative. Verifiable OLX/public data coverage.",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isRisky ? const Color(0xFFFF8B8B) : isRecommended ? const Color(0xFF81C784) : const Color(0xFFCFC6B0),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. Risk / Trust Row: Top 2-3 chips wrapped cleanly to avoid RenderFlex overflows
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...result.pros.take(2).map((p) => _buildEvidenceChip(p, true)),
                ...result.cons.take(1).map((c) => _buildEvidenceChip(c, false)),
              ],
            ),
            const SizedBox(height: 12),

            const Divider(color: Color(0x1ACFC6B0), height: 10),

            // 5. Expandable Sections
            _buildExpandableSection(
              title: "Transparent Price Breakdown",
              icon: Icons.receipt_long_outlined,
              children: price.toMap().entries.map((entry) {
                if (entry.key == 'Total') return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF908F9D)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Rs. ${entry.value.toStringAsFixed(0)}",
                        style: const TextStyle(fontSize: 11, color: Color(0xFFE4E1EA), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            _buildExpandableSection(
              title: "Review Evidence Summary",
              icon: Icons.rate_review_outlined,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _buildEvidenceStat("Hidden Charges", hiddenChargeCount, hiddenChargeCount > 0 ? Colors.redAccent : const Color(0xFF81C784))),
                    Expanded(child: _buildEvidenceStat("Fragile Damage", fragileNegCount, fragileNegCount > 0 ? Colors.redAccent : const Color(0xFF81C784))),
                    Expanded(child: _buildEvidenceStat("Delay Issues", punctualityIssues, punctualityIssues > 0 ? Colors.amber : const Color(0xFF81C784))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Evidence Trust: $trustScore% ($totalReviews samples, $negativeReviews negative)",
                  style: const TextStyle(fontSize: 10, color: Color(0xFF908F9D)),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.amber.withOpacity(0.2)),
                  ),
                  child: const Text(
                    "⚠️ Synthetic MVP review samples — not real scraped reviews",
                    style: TextStyle(fontSize: 9, color: Colors.amberAccent, fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 8),
                ...mover.reviews.map((rev) {
                  final bool isNeg = rev.sentiment == "negative";
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isNeg ? "⚠️ " : "✅ ", style: const TextStyle(fontSize: 10)),
                        Expanded(
                          child: Text(
                            "\"${rev.text}\" — ${rev.author} (${rev.date})",
                            style: TextStyle(
                              fontSize: 10,
                              color: isNeg ? const Color(0xFFFF8B8B) : const Color(0xFF81C784),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),

            _buildExpandableSection(
              title: "Data Provenance",
              icon: Icons.source_outlined,
              children: [
                _buildProvenanceRow("Specialty", mover.speciality),
                _buildProvenanceRow("Vehicle Type", mover.vehicleType),
                _buildProvenanceRow("Source", "${mover.sourceType} (${mover.sourceUrl})"),
                _buildProvenanceRow("Last Updated", mover.lastUpdated),
                _buildProvenanceRow("SafeShift Certified", mover.isRegistered ? "YES (Certified Partner)" : "NO (Publicly Sourced Discovery)"),
                _buildProvenanceRow("Preferred Contact", mover.contactMethod),
                _buildProvenanceRow("Review Type", mover.reviewType),
                _buildProvenanceRow("Rating Provider", mover.ratingSource),
              ],
            ),

            if (result.redFlags.isNotEmpty)
              _buildExpandableSection(
                title: "Scam & Red Flags Detection (${result.redFlags.length})",
                icon: Icons.gavel_outlined,
                headerTextColor: Colors.redAccent,
                initiallyExpanded: true,
                children: result.redFlags.map((flag) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, size: 12, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          flag,
                          style: const TextStyle(fontSize: 10, color: Color(0xFFFF8B8B), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),

            _buildExpandableSection(
              title: "Agent Reasoning & Verdict",
              icon: Icons.psychology_outlined,
              initiallyExpanded: isTraceMode,
              children: [
                Text(
                  mover.agentVerdict,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFCFC6B0),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Scoring Confidence: ${(mover.confidenceScore * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(fontSize: 10, color: Color(0xFF908F9D)),
                ),
                if (isTraceMode) ...[
                  const Divider(color: Color(0x1ACFC6B0), height: 16),
                  AgentTraceCard(
                    trace: AgentTrace(
                      stepName: "Matcher & Ranker Agent",
                      observation: "Distance: ${appState.calculatedDistance.toStringAsFixed(1)} km. Base fee Rs. ${mover.basePrice}. Source confidence: ${(mover.confidenceScore * 100).toStringAsFixed(0)}%.",
                      inference: "12-factor scoring: hidden charges(${hiddenChargeCount}), fragile damage(${fragileNegCount}), delays(${punctualityIssues}). Trust: $trustScore%.",
                      decision: "${result.status} — Match Score ${result.matchScore.toStringAsFixed(1)}/100.",
                      action: "Calculated PKR quote: Rs. ${price.total.toStringAsFixed(0)}",
                      outcome: "Awaiting user selection.",
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Provider Warning Blocks based on certification
            if (mover.sourceType == "Fictional/Mock") ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.dangerous_outlined, color: Colors.redAccent, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "This is a high-risk mock provider. SafeShift recommends avoiding this loader.",
                        style: TextStyle(fontSize: 10, color: Colors.redAccent, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (!mover.isRegistered) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.25)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.amberAccent, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "This provider is not registered/verified. SafeShift can only prepare an outreach draft or run a demo simulation.",
                        style: TextStyle(fontSize: 10, color: Colors.amberAccent, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 6. Primary CTA
            SizedBox(
              width: double.infinity,
              child: PrimaryCTA(
                label: ctaLabel,
                onPressed: () {
                  appState.selectMover(mover, price.total);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MoverChatScreen(
                        request: widget.request,
                        mover: mover,
                        price: price.total.toStringAsFixed(0),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(String? confidence) {
    final conf = confidence ?? 'Low';
    Color color = Colors.redAccent;
    if (conf == 'High') {
      color = const Color(0xFF81C784);
    } else if (conf == 'Medium') {
      color = Colors.amberAccent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        "Quote Confidence: $conf",
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTrustBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      constraints: const BoxConstraints(maxWidth: 135),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvenanceRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• $label: ", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFCFC6B0))),
          Expanded(child: Text(val, style: const TextStyle(fontSize: 10, color: Color(0xFF908F9D)))),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
    Color? headerTextColor,
  }) {
    final themeColor = headerTextColor ?? const Color(0xFFFFB5A1);
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(icon, size: 14, color: themeColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        tilePadding: EdgeInsets.zero,
        iconColor: themeColor,
        collapsedIconColor: const Color(0xFF908F9D),
        initiallyExpanded: initiallyExpanded,
        childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
        children: children,
      ),
    );
  }

  Widget _buildEvidenceChip(String text, bool isPositive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      constraints: const BoxConstraints(maxWidth: 250),
      decoration: BoxDecoration(
        color: isPositive ? const Color(0x0D81C784) : const Color(0x0DFF8B8B),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isPositive ? const Color(0x3381C784) : const Color(0x33FF8B8B),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isPositive ? "✅ " : "⚠️ ", style: const TextStyle(fontSize: 9)),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 9,
                color: isPositive ? const Color(0xFF81C784) : const Color(0xFFFF8B8B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF908F9D))),
      ],
    );
  }
}
