import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../models/move_request.dart';
import '../services/gemini_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_cta.dart';
import '../widgets/section_header.dart';
import '../widgets/agent_trace_card.dart';
import '../models/agent_trace.dart';
import '../providers/app_state.dart';
import 'dispute_screen.dart';
import 'why_safeshift_screen.dart';

class FeedbackScreen extends StatefulWidget {
  final MoveRequest request;

  const FeedbackScreen({super.key, required this.request});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _punctualityRating = 5;
  int _fragileHandlingRating = 5;
  int _transparencyRating = 5;
  final TextEditingController _commentController = TextEditingController(
    text: "Mover waqt par nahi pohancha, lekin fragile items ko theek handle kiya aur hidden charges nahi lagaye.",
  );
  bool _isSubmitting = false;
  bool _submitted = false;

  String _geminiSummary = "";
  int _repDelta = 0;
  AgentTrace? _trace;

  Future<void> _submitFeedback() async {
    setState(() {
      _isSubmitting = true;
    });

    final comment = _commentController.text.trim().isNotEmpty 
        ? _commentController.text 
        : "No comments provided.";

    final prompt = '''
    You are an automated provider reputation agent for a moving platform in Pakistan.
    A user gave the following rating updates for a driver move:
    - Punctuality Rating: $_punctualityRating/5
    - Fragile Items Handling: $_fragileHandlingRating/5
    - Price & Cost Transparency (No Hidden Charges): $_transparencyRating/5
    
    Customer wrote this feedback comment: "$comment".
    
    Analyze these multi-dimensional scores and sentiment.
    Return ONLY a JSON block with:
    - "summary": a one-sentence summary of the review in Roman Urdu (e.g. "Mover ne safely deliver kiya aur koi extra charges nahi liye.")
    - "delta": an integer between -30 and +30 representing the reputation score adjustment. If transparency is < 4, apply high negative penalty for hidden charges.
    - "rationale": technical reasoning for why this reputation adjustment was chosen.
    ''';

    final gemini = GeminiService();
    final response = await gemini.generateText(prompt);

    if (response != null) {
      try {
        final cleaned = response.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> data = jsonDecode(cleaned);

        setState(() {
          _geminiSummary = data["summary"] ?? "Feedback received.";
          _repDelta = data["delta"] ?? 0;
          _trace = AgentTrace(
            stepName: "Reputation Sync",
            observation: "Ratings - Punc: $_punctualityRating, Fragile: $_fragileHandlingRating, Trans: $_transparencyRating. Comment: $comment",
            inference: data["rationale"] ?? "Analyzing driver performance.",
            decision: "Adjusting provider aggregate score by $_repDelta points.",
            action: "Reputation DB Updated",
            outcome: "Updated aggregate rating and flagged key feedback patterns.",
          );
          _isSubmitting = false;
          _submitted = true;
        });
        return;
      } catch (e) {
        // Parse error fallback
      }
    }

    // Fallback Mock Logic
    await Future.delayed(const Duration(seconds: 1));
    final avgRating = (_punctualityRating + _fragileHandlingRating + _transparencyRating) / 3.0;
    setState(() {
      _geminiSummary = avgRating >= 4 ? "Bohat accha experience raha, shifting theek time pe aur locked cost pe hui." : "Khidmat se user mukammal mutmain nahi hai.";
      _repDelta = avgRating >= 4 ? 12 : -18;
      // Penalty for transparency issue
      if (_transparencyRating < 4) {
        _repDelta -= 10;
        _geminiSummary += " Hidden charge discrepancy detected.";
      }
      _trace = AgentTrace(
        stepName: "Reputation Sync (Offline)",
        observation: "Average Rating: ${avgRating.toStringAsFixed(1)} Stars (Punc: $_punctualityRating, Fragile: $_fragileHandlingRating, Trans: $_transparencyRating)",
        inference: "Feedback processed with multidimensional ratings. Low transparency penalizes provider score heavily.",
        decision: "Applying base-tier reputational rules.",
        action: "Local DB Updated",
        outcome: "Score delta: $_repDelta",
      );
      _isSubmitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTraceMode = context.watch<AppState>().isAgentTraceModeEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Share Feedback"),
        automaticallyImplyLeading: !_submitted,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: _submitted ? _buildSuccessState(isTraceMode) : _buildFormState(),
      ),
    );
  }

  Widget _buildSubRatingRow(String label, int currentRating, ValueChanged<int> onRatingChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFCFC6B0))),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return IconButton(
                padding: const EdgeInsets.only(right: 8.0),
                constraints: const BoxConstraints(),
                icon: Icon(
                  starIndex <= currentRating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: const Color(0xFFFFB5A1),
                  size: 32,
                ),
                onPressed: () => onRatingChanged(starIndex),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFormState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          duration: const Duration(milliseconds: 600),
          child: const SectionHeader(
            title: "How was your move?",
            subtitle: "Your feedback helps maintain high standards in the local community.",
          ),
        ),
        const SizedBox(height: 16),
        
        // Mover Protection Alert
        FadeInUp(
          delay: const Duration(milliseconds: 50),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.amberAccent, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Mover Protection Alert: Please rate only what was under the mover's control (e.g. traffic delays, third-party checkpoint holdups, or pre-existing scratches are excluded).",
                    style: TextStyle(color: Colors.amberAccent, fontSize: 11, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        FadeInUp(
          delay: const Duration(milliseconds: 100),
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Rate Your Experience", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                const Divider(color: Color(0x1ACFC6B0), height: 1),
                const SizedBox(height: 12),
                
                _buildSubRatingRow(
                  "Punctuality & Arrival Time",
                  _punctualityRating,
                  (val) => setState(() => _punctualityRating = val),
                ),
                const SizedBox(height: 8),
                _buildSubRatingRow(
                  "Fragile Items Handling & Safety",
                  _fragileHandlingRating,
                  (val) => setState(() => _fragileHandlingRating = val),
                ),
                const SizedBox(height: 8),
                _buildSubRatingRow(
                  "Price Transparency (No Hidden Charges Request)",
                  _transparencyRating,
                  (val) => setState(() => _transparencyRating = val),
                ),
                
                const SizedBox(height: 24),
                const Text("Detailed Review & Comments", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFCFC6B0))),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "E.g. Shifting late hui, par bed safety se fix kiya... (Urdu/English mixed)",
                    hintStyle: const TextStyle(color: Color(0x66CFC6B0), fontSize: 13),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0x33CFC6B0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFB5A1)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        if (_isSubmitting)
          const Center(child: CircularProgressIndicator(color: Color(0xFFFFB5A1)))
        else
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: PrimaryCTA(
              label: "Submit Review",
              onPressed: _submitFeedback,
            ),
          ),
      ],
    );
  }

  Widget _buildSuccessState(bool isTraceMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ZoomIn(
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 70),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            "Review Submitted!",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFE4E1EA)),
          ),
        ),
        const SizedBox(height: 16),
        // Structured Feedback Summary Card
        FadeInUp(
          delay: const Duration(milliseconds: 100),
          duration: const Duration(milliseconds: 500),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "STRUCTURED FEEDBACK SUMMARY",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF908F9D), letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),
                _buildFeedbackRow("Punctuality & Arrival", _punctualityRating),
                const SizedBox(height: 8),
                _buildFeedbackRow("Fragile Items Handling", _fragileHandlingRating),
                const SizedBox(height: 8),
                _buildFeedbackRow("Price Transparency (No Hidden Charges)", _transparencyRating),
                const Divider(color: Color(0x1ACFC6B0), height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Overall Average", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFCFC6B0))),
                    Text(
                      "${((_punctualityRating + _fragileHandlingRating + _transparencyRating) / 3.0).toStringAsFixed(1)} / 5",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFFB5A1)),
                    ),
                  ],
                ),
                if (_commentController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Color(0x1ACFC6B0), height: 1),
                  const SizedBox(height: 8),
                  Text(
                    "Comment: \"${_commentController.text.trim()}\"",
                    style: const TextStyle(fontSize: 11, color: Color(0xFFCFC6B0), fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // AI Sentiment Summary
        FadeInUp(
          delay: const Duration(milliseconds: 200),
          duration: const Duration(milliseconds: 500),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderColor: const Color(0xFFFFB5A1).withOpacity(0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI REPUTATION ANALYSIS",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF908F9D), letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  _geminiSummary,
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Color(0xFFCFC6B0), height: 1.4),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _repDelta >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: _repDelta >= 0 ? const Color(0xFF81C784) : Colors.redAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Reputation Δ: ${_repDelta >= 0 ? '+' : ''}$_repDelta points",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _repDelta >= 0 ? const Color(0xFF81C784) : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        if (isTraceMode && _trace != null) ...[
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: const SectionHeader(title: "Agent Trace: Reputation Sync"),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: AgentTraceCard(trace: _trace!),
          ),
          const SizedBox(height: 32),
        ],
        FadeInUp(
          delay: const Duration(milliseconds: 200),
          child: PrimaryCTA(
            label: "Finish & View SafeShift Advantage",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WhySafeShiftScreen(request: widget.request),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        FadeInUp(
          delay: const Duration(milliseconds: 300),
          child: Center(
            child: TextButton.icon(
              icon: const Icon(Icons.report_problem_outlined, color: Color(0xFFFFB5A1)),
              label: const Text(
                "Report Damage or Missing Items",
                style: TextStyle(color: Color(0xFFFFB5A1), fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DisputeScreen(request: widget.request),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackRow(String label, int rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFCFC6B0))),
        ),
        Row(
          children: List.generate(5, (i) => Icon(
            i < rating ? Icons.star_rounded : Icons.star_border_rounded,
            color: const Color(0xFFFFB5A1),
            size: 18,
          )),
        ),
      ],
    );
  }
}
