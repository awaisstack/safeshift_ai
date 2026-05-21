import 'package:flutter/material.dart';
import '../models/agent_trace.dart';
import 'glass_card.dart';

class AgentTraceCard extends StatelessWidget {
  final AgentTrace trace;

  const AgentTraceCard({super.key, required this.trace});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.memory, color: Color(0xFFCFC6B0), size: 20),
              const SizedBox(width: 8),
              Text(
                trace.stepName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFCFC6B0)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0x1ACFC6B0)),
          ),
          _buildRow("Observation", trace.observation),
          const SizedBox(height: 12),
          _buildRow("Inference", trace.inference),
          const SizedBox(height: 12),
          _buildRow("Decision", trace.decision),
          if (trace.toolCall != null) ...[
            const SizedBox(height: 12),
            _buildRow("Tool Call", trace.toolCall!, color: const Color(0xFFE0E0E0)),
          ],
          if (trace.toolResult != null) ...[
            const SizedBox(height: 12),
            _buildRow("Tool Result", trace.toolResult!, color: const Color(0xFFC8E6C9)),
          ],
          const SizedBox(height: 12),
          _buildRow("Action", trace.action, isHighlight: true, color: const Color(0xFFFFB5A1)),
          if (trace.fallback != null) ...[
            const SizedBox(height: 12),
            _buildRow("Fallback", trace.fallback!, color: const Color(0xFFFFB4AB)),
          ],
          const SizedBox(height: 12),
          _buildRow("Outcome", trace.outcome, color: const Color(0xFF2E7D32)),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF908F9D), letterSpacing: 0.8),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            color: color ?? const Color(0xFFE4E1EA),
          ),
        ),
      ],
    );
  }
}
