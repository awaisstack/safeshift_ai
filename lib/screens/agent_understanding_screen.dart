import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../models/move_request.dart';
import '../models/agent_trace.dart';
import '../widgets/primary_cta.dart';
import '../widgets/section_header.dart';
import '../widgets/animated_tag.dart';
import '../widgets/agent_trace_card.dart';
import '../widgets/glass_card.dart';
import 'inventory_risk_screen.dart';
import '../providers/app_state.dart';

class AgentUnderstandingScreen extends StatelessWidget {
  final MoveRequest request;

  const AgentUnderstandingScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final distance = appState.calculatedDistance;
    final firstImage = appState.uploadedImages.isNotEmpty ? appState.uploadedImages.first : null;

    String imageLabel = "Continuing without valid image evidence";
    Color labelColor = const Color(0xFFCFC6B0);
    IconData labelIcon = Icons.camera_alt;

    if (appState.continueWithoutImageEvidence) {
      imageLabel = "Continuing without valid image evidence";
      labelColor = const Color(0xFFFFB5A1);
      labelIcon = Icons.warning_amber_outlined;
    } else if (firstImage != null) {
      final status = firstImage.scanStatus;
      if (status == 'valid_inventory' || status == 'partially_useful') {
        imageLabel = "Inventory image analyzed";
        labelColor = const Color(0xFF81C784); // Mughal Emerald
        labelIcon = Icons.check_circle_outline;
      } else if (status == 'irrelevant_sensitive' || status == 'failed' || status == 'irrelevant' || status == 'sensitive') {
        imageLabel = "Image rejected as inventory evidence";
        labelColor = const Color(0xFFFFB5A1); // Terracotta
        labelIcon = Icons.error_outline;
      } else {
        imageLabel = "Continuing without valid image evidence";
        labelColor = const Color(0xFFFFB5A1);
        labelIcon = Icons.warning_amber_outlined;
      }
    }

    final requestTrace = AgentTrace(
      stepName: "Request Understanding Agent",
      observation: "Raw prompt: '${request.rawInput}'",
      inference: "Identified service type: '${request.serviceType}', budget preference: '${request.budgetPreference}'",
      decision: "Standardized inventory items list: [${request.inventory.join(', ')}].",
      toolCall: "RequestParserService.parseRequest(input)",
      toolResult: "{service_type: ${request.serviceType}, budget: ${request.budgetPreference}, inventory: ${request.inventory}}",
      action: "Extracted time preferences & constraints. Confidence: ${(request.confidenceScore ?? 0.9) * 100}%.",
      outcome: "Dispatched variables to Risk and Route Agents.",
    );

    final isGoogle = appState.routeSource == 'google';
    final routeTrace = AgentTrace(
      stepName: "Route & Distance Agent",
      observation: "User selected pickup '${appState.pickupLocation}' and drop-off '${appState.dropoffLocation}'.",
      inference: "Route distance is needed for quote calculation, mover matching, and scheduling confidence.",
      decision: "SafeShift uses OpenStreetMap tiles for map display. When Google API keys are configured, Google Routes API can provide live driving distance/ETA. If Google APIs fail, the app falls back to saved coordinates and Haversine × 1.3.",
      toolCall: isGoogle ? "Google Routes API" : "HaversineDistanceTool",
      toolResult: "Distance: ${distance.toStringAsFixed(1)} km, duration: ${appState.routeDurationMins} mins, route source: ${appState.routeSource}, confidence: High",
      action: "Pass route distance to PricingEngine and MatchingService.",
      outcome: "Quote and mover ranking update based on selected route.",
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Moving Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: const SectionHeader(
                title: "Extracted Details",
                subtitle: "Please verify the details below.",
              ),
            ),
            const SizedBox(height: 16),
            if (appState.selectedImageBytes != null) ...[
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                duration: const Duration(milliseconds: 600),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: MemoryImage(appState.selectedImageBytes!),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(
                        color: (firstImage?.scanStatus == 'irrelevant_sensitive' || firstImage?.scanStatus == 'failed')
                            ? const Color(0xFFFFB5A1)
                            : const Color(0x33CFC6B0),
                        width: 1.5,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.bottomLeft,
                      child: Row(
                        children: [
                          Icon(labelIcon, color: labelColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            imageLabel,
                            style: TextStyle(
                              color: labelColor,
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 600),
              child: GlassCard(
                child: Column(
                  children: [
                    _buildDetailRow("Service Type", request.serviceType ?? "Unknown", Icons.category_outlined),
                    const Divider(color: Color(0x1ACFC6B0), height: 24),
                    if (request.moveType != null) ...[
                      _buildDetailRow("Move Category", request.moveType!, Icons.assignment_outlined),
                      const Divider(color: Color(0x1ACFC6B0), height: 24),
                    ],
                    _buildDetailRow("Pickup", request.pickupLocation ?? "Unknown", Icons.location_on_outlined),
                    const Divider(color: Color(0x1ACFC6B0), height: 24),
                    _buildDetailRow("Drop-off", request.dropoffLocation ?? "Unknown", Icons.flag_outlined),
                    const Divider(color: Color(0x1ACFC6B0), height: 24),
                    _buildDetailRow("Distance", "${distance.toStringAsFixed(1)} km (approx driving)", Icons.straighten_outlined),
                    const Divider(color: Color(0x1ACFC6B0), height: 24),
                    _buildDetailRow("Time", request.preferredTime ?? "Flexible", Icons.access_time_outlined),
                    const Divider(color: Color(0x1ACFC6B0), height: 24),
                    _buildDetailRow("Budget", request.budgetPreference ?? "Standard", Icons.account_balance_wallet_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (request.moveType != null)
                  AnimatedTag(
                    label: "Move Type: ${request.moveType}",
                    color: const Color(0xFFCFC6B0),
                    icon: Icons.local_shipping_outlined,
                    index: 0,
                  ),
                if (request.riskLevel != null)
                  AnimatedTag(
                    label: "Risk: ${request.riskLevel}",
                    color: const Color(0xFFFFB5A1),
                    icon: Icons.warning_amber_rounded,
                    index: 1,
                  ),
                if (request.complexity != null)
                  AnimatedTag(
                    label: "Complexity: ${request.complexity}",
                    color: const Color(0xFF2E7D32),
                    icon: Icons.analytics_outlined,
                    index: 2,
                  ),
              ],
            ),
            
            if (context.watch<AppState>().isAgentTraceModeEnabled) ...[
              const SizedBox(height: 40),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 600),
                child: const SectionHeader(title: "Agent Trace Preview"),
              ),
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                duration: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    AgentTraceCard(trace: requestTrace),
                    const SizedBox(height: 12),
                    AgentTraceCard(trace: routeTrace),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 40),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              duration: const Duration(milliseconds: 600),
              child: PrimaryCTA(
                label: "Confirm & Analyze Inventory",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InventoryRiskScreen(request: request)),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF908F9D)),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF908F9D)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFFE4E1EA)),
          ),
        ),
      ],
    );
  }
}
