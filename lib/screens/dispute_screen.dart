import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/move_request.dart';
import '../services/gemini_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_cta.dart';
import '../widgets/section_header.dart';
import '../widgets/agent_trace_card.dart';
import '../models/agent_trace.dart';
import '../providers/app_state.dart';

class DisputeScreen extends StatefulWidget {
  final MoveRequest request;

  const DisputeScreen({super.key, required this.request});

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  XFile? _imageFile;
  bool _useMockImage = false;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _submitted = false;

  String _suggestedResolution = "";
  int _recommendedCompensation = 0;
  int _prototypeRebate = 0;
  AgentTrace? _trace;

  @override
  void initState() {
    super.initState();
    // Default to the first fragile item if available
    if (widget.request.fragileItems.isNotEmpty) {
      _itemController.text = widget.request.fragileItems.first;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = image;
          _useMockImage = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick image: $e")),
      );
    }
  }

  void _useDemoMockPhoto() {
    setState(() {
      _useMockImage = true;
      _imageFile = null;
    });
  }

  Future<void> _submitDispute() async {
    final item = _itemController.text.trim();
    final description = _descriptionController.text.trim();

    if (item.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in the item name and description.")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final prompt = '''
    You are an expert prototype dispute resolution agent for a home shifting app in Pakistan.
    A user is reporting damage/loss for the item: "$item".
    User Description: "$description".
    This item was in the original move request and was marked as fragile.
    The mover accepted moving terms.
    
    CRITICAL PROTOTYPE CONSTRAINTS:
    - This is a non-binding prototype compensation recommendation only.
    - Human review is strictly required before any action.
    - No real payment is processed.
    - No real escrow or insurance claim is involved.
    - Absolutely do NOT refer to "liability insurance coverage", "fair refund/payout", or "escrow rebate".
    
    Analyze the claim (and damage photo if available).
    Suggest a non-binding prototype compensation recommendation in PKR (usually 2,000 to 15,000 PKR depending on typical Pakistani repairs for furniture or glass tables).
    Also suggest a prototype protection rebate (PKR) representing a simulated discount/rebate applied to the locked quote.
    
    Return ONLY a JSON block with:
    - "resolution": a concise, empathetic 1-2 sentence solution in mixed Roman Urdu and English (clearly stating that this is a simulated non-binding prototype compensation recommendation subject to human review, with no real payment processed and no real escrow/insurance claim).
    - "payout": the prototype recommended compensation amount integer in PKR (e.g. 5000).
    - "escrow_rebate": the prototype protection rebate integer in PKR (e.g. 1500).
    - "severity": "Low", "Medium", "High"
    - "reasoning": technical inference for the agent trace card explaining how the prototype compensation recommendation and protection rebate were calculated under prototype constraints.
    ''';

    final gemini = GeminiService();
    String? response;

    if (_imageFile != null) {
      try {
        final bytes = await _imageFile!.readAsBytes();
        response = await gemini.generateContentWithImage(prompt, bytes, "image/jpeg");
      } catch (e) {
        print("Error reading image: $e");
      }
    }

    response ??= await gemini.generateText(prompt);

    if (response != null) {
      try {
        final cleaned = response.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> data = jsonDecode(cleaned);

        setState(() {
          _suggestedResolution = data["resolution"] ?? "Refund will be processed.";
          _recommendedCompensation = data["payout"] ?? 0;
          _prototypeRebate = data["escrow_rebate"] ?? 1500;
          _trace = AgentTrace(
            stepName: "Agentic Dispute Auditor Action",
            observation: "Dispute reported on item: $item. Damage details: $description. Mock Photo: $_useMockImage, Has Real Photo: ${_imageFile != null}",
            inference: data["reasoning"] ?? "Assessing structural integrity damage and repair rates.",
            decision: "Recommended compensation of $_recommendedCompensation PKR. Prototype protection rebate of $_prototypeRebate PKR suggested.",
            toolCall: "ReviewEvidenceTool.verifyClaim(itemId: '$item', evidenceType: 'photo_and_text')",
            toolResult: "{valid: true, estimated_damage_cost: $_recommendedCompensation, rebate: $_prototypeRebate}",
            action: "Prototype dispute recommendation generated.",
            outcome: "Human review required. No real payment processed. Protection/compensation simulation only.",
          );
          _isSubmitting = false;
          _submitted = true;
        });
        return;
      } catch (e) {
        // Parse error fallback
      }
    }

    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _suggestedResolution = "Fragile item claim processed. SafeShift AI recommends Rs. 5,000 compensation to cover repairs, along with a Rs. 1,500 prototype protection rebate. Subject to human operator verification.";
      _recommendedCompensation = 5000;
      _prototypeRebate = 1500;
      _trace = AgentTrace(
        stepName: "Agentic Dispute Auditor Action",
        observation: "Dispute reported on item: $item",
        inference: "Claim processed using standard flat rates.",
        decision: "Recommended standard compensation of $_recommendedCompensation PKR. Prototype protection rebate of $_prototypeRebate PKR suggested.",
        toolCall: "ReviewEvidenceTool.verifyClaim(itemId: '$item', evidenceType: 'text_only')",
        toolResult: "{valid: true, estimated_damage_cost: $_recommendedCompensation, rebate: $_prototypeRebate}",
        action: "Prototype compensation recommendation generated.",
        outcome: "Human review required. No real payment processed.",
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
        title: const Text("File Damage Claim"),
        automaticallyImplyLeading: !_submitted,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: _submitted ? _buildSuccessState(isTraceMode) : _buildFormState(),
      ),
    );
  }

  Widget _buildStatusItem(String name, String status, Color color, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: const TextStyle(fontSize: 13, color: Color(0xFFCFC6B0))),
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildFormState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          duration: const Duration(milliseconds: 600),
          child: const SectionHeader(
            title: "Report Damage",
            subtitle: "SafeShift Agent reviews claims and generates compensation recommendations.",
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x1ACFC6B0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFFFB5A1), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Notice: Dispute recommendations and rebates are AI-generated recommendations. Final approval requires human operator audit and verification under prototype constraints.",
                  style: TextStyle(fontSize: 11, color: Color(0xFFCFC6B0), height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Item Delivery Status Checklist
        FadeInUp(
          delay: const Duration(milliseconds: 50),
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1ACFC6B0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: Color(0xFFFFB5A1), size: 16),
                    SizedBox(width: 8),
                    Text(
                      "Delivery Checklist Status",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE4E1EA)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatusItem("Fridge (Appliance)", "Checked - Safe", Colors.greenAccent, Icons.check_circle_outline),
                const Divider(color: Color(0x0DCFC6B0), height: 16),
                _buildStatusItem("Dining Table (Wood)", "Checked - Safe", Colors.greenAccent, Icons.check_circle_outline),
                const Divider(color: Color(0x0DCFC6B0), height: 16),
                _buildStatusItem("Glass Lamp (Fragile)", "Damaged (Scratched corner)", Colors.redAccent, Icons.error_outline),
              ],
            ),
          ),
        ),
        FadeInUp(
          delay: const Duration(milliseconds: 100),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Damaged Item Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _itemController,
                  decoration: InputDecoration(
                    hintText: "E.g. Glass Dining Table",
                    hintStyle: const TextStyle(color: Color(0x66CFC6B0)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("What happened?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Describe the damage (e.g. glass corner chip or crack)",
                    hintStyle: const TextStyle(color: Color(0x66CFC6B0)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Evidence Upload", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    TextButton(
                      onPressed: _useDemoMockPhoto,
                      child: const Text("Load Demo Mock Photo", style: TextStyle(color: Color(0xFFFFB5A1), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _useMockImage 
                              ? Colors.redAccent.withOpacity(0.5) 
                              : const Color(0x33CFC6B0), 
                          width: 1.5
                        ),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: kIsWeb
                                  ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                                  : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                            )
                          : _useMockImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        color: Colors.black45,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                      CustomPaint(
                                        painter: ScratchCrackPainter(),
                                        size: const Size(double.infinity, 140),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            "MOCK EVIDENCE",
                                            style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, color: Color(0xFFFFB5A1), size: 36),
                                    SizedBox(height: 8),
                                    Text("Choose Image from Gallery", style: TextStyle(fontSize: 12, color: Color(0x88CFC6B0))),
                                  ],
                                ),
                    ),
                  ),
                ),
                if (_useMockImage || _imageFile != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    "⚠️ Synthetic/mock damage evidence for demonstration purposes.",
                    style: TextStyle(color: Color(0xFFFFB5A1), fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
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
              label: "Submit Claim to AI Agent",
              onPressed: _submitDispute,
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
              child: const Icon(Icons.gavel_outlined, color: Color(0xFF2E7D32), size: 70),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            "AI Dispute Recommendation Generated",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFE4E1EA)),
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "AI Claim Assessment:",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF908F9D)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "LIKELY VALID CLAIM",
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF81C784)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "Recommended Compensation:",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFB5A1)),
              ),
              const SizedBox(height: 6),
              Text(
                "Rs. $_recommendedCompensation PKR",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE4E1EA)),
              ),
              const SizedBox(height: 12),
              const Text(
                "Prototype Protection Rebate:",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFB5A1)),
              ),
              const SizedBox(height: 6),
              Text(
                "Rs. $_prototypeRebate PKR",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE4E1EA)),
              ),
              const Divider(color: Color(0x1ACFC6B0), height: 24),
              Text(
                _suggestedResolution,
                style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFFCFC6B0)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 14),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Prototype Notice: Dispute resolution is simulated. Compensation recommendation requires human review and verified evidence before approval.",
                        style: TextStyle(fontSize: 10, color: Colors.amberAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        if (isTraceMode && _trace != null) ...[
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: const SectionHeader(title: "Agent Trace: Dispute Decision"),
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
            label: "Finish & Return Home",
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ),
      ],
    );
  }
}

class ScratchCrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent.withOpacity(0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.3, size.height * 0.4)
      ..lineTo(size.width * 0.5, size.height * 0.6)
      ..lineTo(size.width * 0.45, size.height * 0.65)
      ..lineTo(size.width * 0.7, size.height * 0.85);

    final crack2 = Path()
      ..moveTo(size.width * 0.5, size.height * 0.6)
      ..lineTo(size.width * 0.65, size.height * 0.5)
      ..lineTo(size.width * 0.75, size.height * 0.55);

    canvas.drawPath(path, paint);
    canvas.drawPath(crack2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
