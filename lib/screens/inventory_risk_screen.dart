import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../models/move_request.dart';
import '../models/inventory_item.dart';
import '../services/inventory_complexity_service.dart';
import '../widgets/primary_cta.dart';
import '../widgets/section_header.dart';
import '../widgets/animated_tag.dart';
import '../widgets/glass_card.dart';
import '../providers/app_state.dart';
import '../models/agent_trace.dart';
import '../widgets/agent_trace_card.dart';
import 'scheduling_screen.dart';

class InventoryRiskScreen extends StatefulWidget {
  final MoveRequest request;

  const InventoryRiskScreen({super.key, required this.request});

  @override
  State<InventoryRiskScreen> createState() => _InventoryRiskScreenState();
}

class _InventoryRiskScreenState extends State<InventoryRiskScreen> {
  @override
  void initState() {
    super.initState();
    final service = InventoryComplexityService();
    service.analyzeRequest(widget.request);
  }

  @override
  Widget build(BuildContext context) {
    final isTraceMode = context.watch<AppState>().isAgentTraceModeEnabled;
    final bool isUnverified = widget.request.inventorySource == 'none';

    return Scaffold(
      appBar: AppBar(title: const Text("Inventory & Risk")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isUnverified) ...[
              FadeInDown(
                duration: const Duration(milliseconds: 450),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    borderColor: const Color(0xFFFFB5A1).withOpacity(0.4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB5A1), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "INSUFFICIENT INVENTORY EVIDENCE",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFB5A1), fontSize: 12, letterSpacing: 0.8),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "No verified room photo was analyzed. Shifting estimation is operating in Low-Confidence Mode. The final quote may change based on actual crew findings.",
                                style: TextStyle(color: Color(0xFFE4E1EA), fontSize: 12, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: const SectionHeader(
                title: "Item Breakdown",
                subtitle: "Categorized inventory from your request.",
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 600),
              child: _buildInventoryCategory(
                "Fragile Items", 
                widget.request.inventoryItems.where((e) => e.fragile).toList(), 
                const Color(0xFFFFB5A1), 
                Icons.wine_bar
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 600),
              child: _buildInventoryCategory(
                "Heavy Appliances", 
                widget.request.inventoryItems.where((e) => e.heavy && !e.fragile).toList(), 
                const Color(0xFFCFC6B0), 
                Icons.kitchen
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(milliseconds: 600),
              child: _buildInventoryCategory(
                "Other Items", 
                widget.request.inventoryItems.where((e) => !e.fragile && !e.heavy).toList(), 
                const Color(0xFF2E7D32), 
                Icons.inventory_2_outlined
              ),
            ),
            
            const SizedBox(height: 40),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              duration: const Duration(milliseconds: 600),
              child: const SectionHeader(title: "Risk & Resource Analysis"),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              duration: const Duration(milliseconds: 600),
              child: GlassCard(
                child: Column(
                  children: [
                    _buildAnalysisRow(
                      "Access Risk", 
                      isUnverified 
                      ? "Insufficient inventory data" 
                      : (widget.request.constraints.isNotEmpty ? "High (No Lift)" : "Low"), 
                      isHighRisk: isUnverified || widget.request.constraints.isNotEmpty
                    ),
                    const Divider(color: Color(0x1ACFC6B0), height: 24),
                    _buildAnalysisRow("Required Crew", "${widget.request.requiredCrew} Movers", isHighRisk: false),
                    const Divider(color: Color(0x1ACFC6B0), height: 24),
                    _buildAnalysisRow("Required Vehicle", widget.request.requiredVehicle ?? "Unknown", isHighRisk: false),
                    const Divider(color: Color(0x1ACFC6B0), height: 24),
                    _buildAnalysisRow("Estimated Time", widget.request.estimatedDuration ?? "Unknown", isHighRisk: false),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            if (isTraceMode) ...[
              FadeInUp(
                delay: const Duration(milliseconds: 550),
                duration: const Duration(milliseconds: 600),
                child: AgentTraceCard(
                  trace: AgentTrace(
                    stepName: "Risk Scoring Agent",
                    observation: "Inventory source: ${widget.request.inventorySource}. Items: ${widget.request.inventoryItems.map((e) => e.name).join(', ')}",
                    inference: isUnverified 
                    ? "Visual evidence missing. Risk calculations based on manual input only." 
                    : "Visual evidence present. Performing automated inventory safety analysis.",
                    decision: isUnverified 
                    ? "Bypassing automated image scan. Reduce score confidence." 
                    : "Classify constraints: stairs/no lift. Required crew: ${widget.request.requiredCrew}",
                    toolCall: "RiskScoringTool(inventory: ${widget.request.inventoryItems.map((e) => e.name).toList()}, constraints: ${widget.request.constraints})",
                    toolResult: "{risk_level: ${widget.request.riskLevel}, required_crew: ${widget.request.requiredCrew}, duration: ${widget.request.estimatedDuration}}",
                    action: "Determined Risk Level: ${widget.request.riskLevel}",
                    outcome: "Displayed crew resource allocation.",
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            FadeInUp(
              delay: const Duration(milliseconds: 600),
              duration: const Duration(milliseconds: 600),
              child: PrimaryCTA(
                label: "Analyze Shifting Schedule",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SchedulingScreen(request: widget.request)),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCategory(String title, List<InventoryItem> items, Color color, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((e) {
            final List<String> services = [];
            if (e.needsDisassembly) services.add("Disassembly");
            if (e.needsWrapping) services.add("Wrapping");
            final servicesStr = services.isNotEmpty ? " (${services.join('/')})" : "";
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                "${e.name} x${e.quantity}$servicesStr", 
                style: TextStyle(fontSize: 12, color: color.withOpacity(0.9)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnalysisRow(String label, String value, {required bool isHighRisk}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF908F9D), fontWeight: FontWeight.w500)),
        isHighRisk 
            ? AnimatedTag(label: value, color: const Color(0xFFFFB5A1), icon: Icons.warning_amber_rounded)
            : Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE4E1EA))),
      ],
    );
  }
}
