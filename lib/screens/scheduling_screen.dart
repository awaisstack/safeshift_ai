import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../models/move_request.dart';
import '../services/gemini_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_cta.dart';
import '../widgets/section_header.dart';
import '../widgets/animated_tag.dart';
import '../widgets/agent_trace_card.dart';
import '../models/agent_trace.dart';
import '../providers/app_state.dart';
import 'live_bidding_screen.dart';

class SchedulingScreen extends StatefulWidget {
  final MoveRequest request;

  const SchedulingScreen({super.key, required this.request});

  @override
  State<SchedulingScreen> createState() => _SchedulingScreenState();
}

class _SchedulingScreenState extends State<SchedulingScreen> {
  bool _isLoading = true;
  String _status = "Checking";
  String _analysisText = "";
  AgentTrace? _trace;

  @override
  void initState() {
    super.initState();
    _analyzeSchedule();
  }

  Future<void> _analyzeSchedule() async {
    final timeStr = widget.request.preferredTime ?? "Not specified";
    final constraintsStr = widget.request.constraints.join(", ");

    final prompt = '''
    You are an expert logistics coordinator in Pakistan.
    Analyze the preferred shifting time: "$timeStr" with constraints: "$constraintsStr".
    Identify any potential issues typical to Pakistan (e.g. Friday prayers jam, weekend peak price, morning heat, city container blockage/protests, night security entry rules in gated communities like Bahria/DHA).
    
    Return ONLY a JSON block with:
    - "status": either "Clear", "Alert", or "Conflict"
    - "analysis": a 1-2 sentence friendly warning or validation in mixed Roman Urdu & English.
    - "suggested_time": a better time slot if status is not "Clear" (otherwise same preferred time).
    - "reasoning": technical inference for the agent trace card.
    ''';

    final gemini = GeminiService();
    final response = await gemini.generateText(prompt);

    if (response != null) {
      try {
        final cleaned = response.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> data = jsonDecode(cleaned);

        setState(() {
          _status = data["status"] ?? "Clear";
          _analysisText = data["analysis"] ?? "Time slot looks good for shifting.";
          if (data["suggested_time"] != null && data["suggested_time"] != timeStr) {
            widget.request.preferredTime = data["suggested_time"];
          }
          _trace = AgentTrace(
            stepName: "Temporal Orchestration",
            observation: "Preferred time: $timeStr. Constraints: $constraintsStr",
            inference: data["reasoning"] ?? "Analyzing peak load and local traffic rules.",
            decision: "Preferred moving window selected and passed to Provider Matching and Pricing Agents.",
            toolCall: "TemporalRuleEngine.checkTrafficAndVolume(${widget.request.preferredTime})",
            toolResult: "{status: $_status, reasoning: ${data["reasoning"] ?? ""}}",
            action: "Schedule Checked",
            outcome: "Status: $_status",
          );
          _isLoading = false;
        });
        return;
      } catch (e) {
        // Parse error fallback
      }
    }

    // Fallback Mock Logic
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      final isWeekend = timeStr.toLowerCase().contains("saturday") || timeStr.toLowerCase().contains("sunday");
      _status = isWeekend ? "Alert" : "Clear";
      _analysisText = isWeekend
          ? "Saturday morning is a peak slot for Bahria Phase 7. Road blockages or higher provider rates may apply. Consider shifting at 2:00 PM instead."
          : "Selected slot looks clean. Traffic flow is normal.";
      
      _trace = AgentTrace(
        stepName: "Temporal Orchestration (Offline)",
        observation: "Preferred time: $timeStr",
        inference: isWeekend ? "Peak weekend demand spotted." : "Low load weekday.",
        decision: "Preferred moving window selected and passed to Provider Matching and Pricing Agents.",
        toolCall: "TemporalRuleEngine.checkOfflineTraffic(${widget.request.preferredTime})",
        toolResult: "{status: $_status, suggestion: '2:00 PM if weekend'}",
        action: "Local rules applied",
        outcome: "Verified status: $_status",
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTraceMode = context.watch<AppState>().isAgentTraceModeEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Schedule Analysis"),
        actions: [
          Row(
            children: [
              const Text("Agent Trace Mode", style: TextStyle(fontSize: 12)),
              Switch(
                value: isTraceMode,
                onChanged: (val) {
                  context.read<AppState>().toggleAgentTraceMode();
                },
                activeColor: const Color(0xFFFFB5A1),
              ),
            ],
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFFB5A1)),
                  SizedBox(height: 16),
                  Text("Analyzing Local Schedule Conflicts...", style: TextStyle(color: Color(0xFFE4E1EA))),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: const SectionHeader(
                      title: "Smart Scheduling",
                      subtitle: "SafeShift checks local traffic, area constraints, and peak rules.",
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Shifting Window", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              AnimatedTag(
                                label: _status,
                                color: _status == "Clear"
                                    ? const Color(0xFF2E7D32)
                                    : _status == "Alert"
                                        ? const Color(0xFFFFB5A1)
                                        : const Color(0xFFFF8B8B),
                                icon: _status == "Clear" ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Color(0xFFFFB5A1), size: 20),
                              const SizedBox(width: 12),
                              Text(
                                widget.request.preferredTime ?? "Not Specified",
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFE4E1EA)),
                              ),
                            ],
                          ),
                          const Divider(color: Color(0x1ACFC6B0), height: 32),
                          Text(
                            _analysisText,
                            style: const TextStyle(color: Color(0xFFCFC6B0), height: 1.4, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (isTraceMode && _trace != null) ...[
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: const SectionHeader(title: "Agent Trace: Scheduling Decisions"),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: AgentTraceCard(trace: _trace!),
                    ),
                    const SizedBox(height: 32),
                  ],
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PrimaryCTA(
                          label: _status == "Clear" ? "Use This Time & Find Movers" : "Set Preferred Time & Find Movers",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LiveBiddingScreen(request: widget.request),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "This time is used to calculate mover availability and pricing. Your booking is not confirmed until you select a mover.",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              color: Color(0xFF908F9D),
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
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
