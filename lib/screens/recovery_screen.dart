import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_cta.dart';
import '../widgets/agent_trace_card.dart';
import '../models/agent_trace.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  bool _isSearching = true;

  @override
  void initState() {
    super.initState();
    _startSearchTimer();
  }

  void _startSearchTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final failedMover = appState.originalFailedMover;
    final backups = appState.backupMoversList;

    final recoveryTrace = AgentTrace(
      stepName: "Recovery & Scheduling Agent",
      observation: "Mover '${failedMover?.name ?? 'Assigned Mover'}' flagged: delayed by 45 minutes due to fuel queue in Rawalpindi.",
      inference: "Customer constraints requires arrival by 10:30 AM. Original schedule violated.",
      decision: "Triggered dynamic recovery protocol. Searched local provider dataset for active backups in service zone.",
      toolCall: "RecoveryPlanner.findActiveBackups(zone: 'Islamabad', originalMoverId: '${failedMover?.id}')",
      toolResult: "{backups_found: ${backups.length}, compensation_applied: true}",
      action: "Identified 2 available backups. Calculated updated pricing with a Rs. 500 delay compensation rebate applied.",
      outcome: "Offered user immediate switch to backup, wait, or reschedule options.",
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Shifting Recovery"),
        automaticallyImplyLeading: false,
      ),
      body: _isSearching
          ? _buildSearchingState(failedMover?.name)
          : _buildRecoveryPanel(context, appState, failedMover, backups, recoveryTrace),
    );
  }

  Widget _buildSearchingState(String? failedName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFFFB5A1)),
            const SizedBox(height: 32),
            Text(
              "⚠️ Shifting Conflict Identified!",
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF8B8B)),
            ),
            const SizedBox(height: 12),
            Text(
              "Mover '$failedName' is delayed. SafeShift AI Recovery Agent is scanning nearby backup providers...",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF908F9D), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveryPanel(
    BuildContext context,
    AppState appState,
    dynamic failedMover,
    List<dynamic> backups,
    AgentTrace recoveryTrace,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Driver Delay: ${failedMover?.name ?? 'Assigned Mover'}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Reason: ${appState.recoveryReason}",
                          style: const TextStyle(fontSize: 12, color: Color(0xFFE4E1EA)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "AI Recovery Options",
            style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE4E1EA)),
          ),
          const SizedBox(height: 12),
          // Option 1: Switch to Backup (Recommended)
          if (backups.isNotEmpty) ...[
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF81C784), width: 1.5),
                ),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "RECOMMENDED BACKUP",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF81C784)),
                            ),
                          ),
                          Text(
                            "Rs. ${backups[0].basePrice - 500} (Rs. 500 Rebate)",
                            style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF81C784)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        backups[0].name,
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE4E1EA)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Vehicle: ${backups[0].vehicleType} • ETA: 20 mins",
                        style: const TextStyle(fontSize: 13, color: Color(0xFF908F9D)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "✅ Insured for fragile furniture. Review evidence matches original criteria perfectly.",
                        style: TextStyle(fontSize: 11, color: Color(0xFFE4E1EA)),
                      ),
                      const SizedBox(height: 16),
                      PrimaryCTA(
                        label: "Switch to Backup Now",
                        onPressed: () {
                          appState.selectBackupMover(backups[0]);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Switched booking to backup. Compensation rebate applied!")),
                          );
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Option 2: Wait
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Wait for original driver",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFE4E1EA)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Accept 45-minute delay. New ETA: ${failedMover != null ? '10:45 AM' : 'Flexible'}",
                          style: const TextStyle(fontSize: 12, color: Color(0xFF908F9D)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      appState.clearRecovery();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Accepted driver delay. Waiting...")),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text("Wait", style: TextStyle(color: Color(0xFFFFB5A1))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Option 3: Reschedule
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Reschedule shifting date",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFE4E1EA)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Select another day next week.",
                          style: TextStyle(fontSize: 12, color: Color(0xFF908F9D)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      appState.clearRecovery();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Rescheduling requested.")),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text("Reschedule", style: TextStyle(color: Color(0xFFFFB5A1))),
                  ),
                ],
              ),
            ),
          ),
          
          if (appState.isAgentTraceModeEnabled) ...[
            const SizedBox(height: 40),
            const Text(
              "Agent Trace Output",
              style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE4E1EA)),
            ),
            const SizedBox(height: 12),
            AgentTraceCard(trace: recoveryTrace),
          ],
        ],
      ),
    );
  }
}
