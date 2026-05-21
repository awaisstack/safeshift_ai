import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../models/move_request.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_cta.dart';
import '../widgets/section_header.dart';
import '../widgets/agent_trace_card.dart';
import '../models/agent_trace.dart';
import '../providers/app_state.dart';
import 'feedback_screen.dart';
import 'dispute_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final MoveRequest request;

  const BookingConfirmationScreen({super.key, required this.request});

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  bool _isLoading = true;
  bool _isBriefExpanded = false;
  bool _isChecklistExpanded = true;

  @override
  void initState() {
    super.initState();
    _simulateBooking();
  }

  Future<void> _simulateBooking() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: Color(0xFFFFB5A1)),
              SizedBox(height: 16),
              Text("Simulating Booking Actions...", style: TextStyle(color: Color(0xFFE4E1EA))),
            ],
          ),
        ),
      );
    }

    final trace = AgentTrace(
      stepName: "Booking Simulation (Slot Confirmed)",
      observation: "User approved quote.",
      inference: "Need to lock time slot and notify provider.",
      decision: "Assigning booking ID and generating QR checkpoint.",
      action: "Created Booking & Confirmed Slot",
      outcome: "WhatsApp notification drafted. Provider confirmed. Booking slot locked.",
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Prototype Booking"), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ZoomIn(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 80),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Prototype Booking Created",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE4E1EA)),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "This is a simulated booking workflow for the MVP. No real mover has been contacted and no payment has been processed.",
                      style: TextStyle(color: Color(0xFF908F9D), fontSize: 12, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Quote Lock and Booking Simulation Details Card
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(milliseconds: 600),
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                borderColor: const Color(0xFF81C784).withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "PROTOTYPE QUOTE LOCK",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF908F9D), fontSize: 11),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.lock_outline, color: Color(0xFF81C784), size: 12),
                              SizedBox(width: 4),
                              Text(
                                "SIMULATED HOLD",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF81C784)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Simulated Protection Hold: Rs. ${context.watch<AppState>().finalPrice.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFB5A1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "SafeShift MVP simulates quote-lock and protection workflows. No real funds are held or transferred. Quote is protected in demo workflow only.",
                      style: TextStyle(color: Color(0xFF908F9D), fontSize: 12, height: 1.4),
                    ),
                    if (widget.request.inventorySource == 'none') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.withOpacity(0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 14),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "⚠️ quote may change because inventory was not verified",
                                style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(color: Color(0x1ACFC6B0), height: 32),
                    const Text(
                      "SIMULATED BOOKING BREAKDOWN",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF908F9D), fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    _buildPayoutRow(
                      "Mover Simulated Share (70%)",
                      "Rs. ${(context.watch<AppState>().finalPrice * 0.70).toStringAsFixed(0)}",
                      "Simulated completion allocation on delivery verification",
                    ),
                    const SizedBox(height: 10),
                    _buildPayoutRow(
                      "Platform Fee (15%)",
                      "Rs. ${(context.watch<AppState>().finalPrice * 0.15).toStringAsFixed(0)}",
                      "Simulated platform fee",
                    ),
                    const SizedBox(height: 10),
                    _buildPayoutRow(
                      "Insurance Reserve (15%)",
                      "Rs. ${(context.watch<AppState>().finalPrice * 0.15).toStringAsFixed(0)}",
                      "Simulated protection reserve hold",
                    ),
                  ],
                ),
              ),
            ),
            
            // Collapsible Hidden-Charge Protection Checklist
            FadeInUp(
              delay: const Duration(milliseconds: 350),
              duration: const Duration(milliseconds: 600),
              child: _buildHiddenChargeChecklist(),
            ),
            
            // Collapsible Job Brief Card
            FadeInUp(
              delay: const Duration(milliseconds: 380),
              duration: const Duration(milliseconds: 600),
              child: _buildJobBriefSection(),
            ),
            const SizedBox(height: 40),
            if (context.watch<AppState>().isAgentTraceModeEnabled) ...[
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 600),
                child: const SectionHeader(title: "Agent Trace: Booking Action"),
              ),
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                duration: const Duration(milliseconds: 600),
                child: AgentTraceCard(trace: trace),
              ),
              const SizedBox(height: 40),
            ],
            FadeInUp(
              delay: const Duration(milliseconds: 550),
              duration: const Duration(milliseconds: 600),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.report_problem_outlined, color: Color(0xFFFF8B8B), size: 18),
                label: const Text(
                  "Report Damage / Missing Item",
                  style: TextStyle(color: Color(0xFFFF8B8B), fontFamily: 'Outfit', fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.4)),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DisputeScreen(request: widget.request)),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              duration: const Duration(milliseconds: 600),
              child: PrimaryCTA(
                label: "Proceed to Feedback & Rating",
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => FeedbackScreen(request: widget.request)),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHiddenChargeChecklist() {
    final finalPrice = context.watch<AppState>().finalPrice;
    return Card(
      margin: const EdgeInsets.only(top: 16),
      color: const Color(0xFF1F1F25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFF81C784).withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.security, color: Color(0xFF81C784)),
            title: const Text(
              "Hidden-Charge Protection Guarantee",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF81C784),
              ),
            ),
            subtitle: const Text("100% Locked price coverage details", style: TextStyle(fontSize: 11, color: Color(0xFF908F9D))),
            trailing: Icon(
              _isChecklistExpanded ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFFCFC6B0),
            ),
            onTap: () {
              setState(() {
                _isChecklistExpanded = !_isChecklistExpanded;
              });
            },
          ),
          if (_isChecklistExpanded) ...[
            const Divider(color: Color(0x1ACFC6B0), height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildGuaranteeItem(
                    title: "Prototype Locked Rates",
                    description: "Your booking uses a simulated protection hold. The driver cannot request the Rs. ${finalPrice.toStringAsFixed(0)} simulated completion until you verify successful delivery.",
                  ),
                  const SizedBox(height: 10),
                  _buildGuaranteeItem(
                    title: "Zero Route/Toll Surcharges",
                    description: "All fuel expenses, distance allowances, and toll rates between locations are pre-calculated and locked.",
                  ),
                  const SizedBox(height: 10),
                  _buildGuaranteeItem(
                    title: "Pre-Declared Crew Allowance",
                    description: "Mover loading, unloading, and labor fees are fully bundled based on the manifest. No unexpected loading fee is required.",
                  ),
                  const SizedBox(height: 10),
                  _buildGuaranteeItem(
                    title: "Stairs & Wrapping Covered",
                    description: "Stairways and item wrapping constraints declared in your manifest are entirely paid for. No hidden surcharge will be accepted.",
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuaranteeItem({required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.verified, color: Color(0xFF81C784), size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(color: Color(0xFF908F9D), fontSize: 11, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJobBriefSection() {
    final pickup = widget.request.pickupLocation ?? 'Not specified';
    final dropoff = widget.request.dropoffLocation ?? 'Not specified';
    final moveType = widget.request.moveType ?? 'Standard Shifting';
    final constraints = widget.request.constraints.isNotEmpty 
        ? widget.request.constraints.join(', ') 
        : 'None';
    
    final itemsStr = widget.request.inventoryItems.isNotEmpty
        ? widget.request.inventoryItems.map((e) => "${e.name} (x${e.quantity})").join(', ')
        : (widget.request.inventory.isNotEmpty ? widget.request.inventory.join(', ') : 'Complete items');

    return Card(
      margin: const EdgeInsets.only(top: 12),
      color: const Color(0xFF1F1F25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x1ACFC6B0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.assignment, color: Color(0xFFFFB5A1)),
            title: const Text(
              "Mover-Facing Job Brief",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFB5A1),
              ),
            ),
            subtitle: const Text("Exact details shared with the provider", style: TextStyle(fontSize: 11, color: Color(0xFF908F9D))),
            trailing: Icon(
              _isBriefExpanded ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFFCFC6B0),
            ),
            onTap: () {
              setState(() {
                _isBriefExpanded = !_isBriefExpanded;
              });
            },
          ),
          if (_isBriefExpanded) ...[
            const Divider(color: Color(0x1ACFC6B0), height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBriefRow("Move Type", moveType),
                  const SizedBox(height: 6),
                  _buildBriefRow("Pickup Location", pickup),
                  const SizedBox(height: 6),
                  _buildBriefRow("Drop-off Location", dropoff),
                  const SizedBox(height: 6),
                  _buildBriefRow("Stairs Constraints", constraints),
                  const SizedBox(height: 6),
                  _buildBriefRow("Inventory Manifest", itemsStr),
                  const SizedBox(height: 6),
                  _buildBriefRow("Locked Price", "Rs. ${context.read<AppState>().finalPrice.toStringAsFixed(0)} (Locked)"),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBriefRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFCFC6B0)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutRow(String label, String amount, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFE4E1EA), fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF908F9D), fontSize: 11),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Color(0xFFE4E1EA), fontSize: 15),
        ),
      ],
    );
  }
}
