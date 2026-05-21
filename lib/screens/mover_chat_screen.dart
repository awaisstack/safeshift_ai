import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../models/move_request.dart';
import '../models/agent_trace.dart';
import '../services/gemini_service.dart';
import '../widgets/agent_trace_card.dart';
import '../widgets/primary_cta.dart';
import '../providers/app_state.dart';
import '../data/movers_data.dart';
import 'booking_confirmation_screen.dart';

class MoverChatScreen extends StatefulWidget {
  final MoveRequest request;
  final MoverProvider mover;
  final String price;

  const MoverChatScreen({
    super.key,
    required this.request,
    required this.mover,
    required this.price,
  });

  @override
  State<MoverChatScreen> createState() => _MoverChatScreenState();
}

class _MoverChatScreenState extends State<MoverChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  // For Unregistered / Public Movers Outreach Draft
  String _draftMessage = "";
  bool _isGeneratingDraft = false;

  // Job Brief and Checklist State
  bool _isBriefExpanded = true;
  bool _check1 = false;
  bool _check2 = false;
  bool _check3 = false;
  bool _check4 = false;

  bool get _isChecklistComplete => _check1 && _check2 && _check3 && _check4;

  @override
  void initState() {
    super.initState();
    if (widget.mover.isRegistered) {
      final pickup = widget.request.pickupLocation ?? 'Pickup Location';
      final dropoff = widget.request.dropoffLocation ?? 'Dropoff Location';
      _messages.add({
        "role": "mover",
        "content": "Assalam o Alaikum! Me ${widget.mover.name} se baat kar raha hu. Apki shifting request ($pickup se $dropoff) mil gayi hai. Final price Rs. ${widget.price} hai. Koi sawaal hai toh poochein."
      });
    } else {
      _initDraftMessage();
    }
  }

  void _initDraftMessage() async {
    final pickup = widget.request.pickupLocation ?? 'Pickup Location';
    final dropoff = widget.request.dropoffLocation ?? 'Dropoff Location';
    
    final String items;
    final String fragileStr;
    if (widget.request.inventoryItems.isNotEmpty) {
      items = widget.request.inventoryItems.map((e) {
        final List<String> services = [];
        if (e.needsDisassembly) services.add("Disassembly");
        if (e.needsWrapping) services.add("Wrapping");
        final servicesStr = services.isNotEmpty ? " (${services.join('/')})" : "";
        return "${e.name} x${e.quantity}$servicesStr";
      }).join(', ');
      
      final fragileList = widget.request.inventoryItems.where((e) => e.fragile).map((e) => e.name).toList();
      fragileStr = fragileList.isEmpty ? "None" : fragileList.join(', ');
    } else {
      items = widget.request.inventory.isEmpty
          ? "Complete household items"
          : widget.request.inventory.join(', ');
      fragileStr = widget.request.fragileItems.isEmpty
          ? "None"
          : widget.request.fragileItems.join(', ');
    }
    
    final constraintsStr = widget.request.constraints.isEmpty
        ? "None"
        : widget.request.constraints.join(', ');
    final preferredTime = widget.request.preferredTime ?? 'Flexible';

    final localTemplate = "Assalam o Alaikum! Mujhe shifting service chahiye.\n\n"
        "Shifting Details:\n"
        "• Pickup: $pickup\n"
        "• Drop-off: $dropoff\n"
        "• Items list: $items\n"
        "• Fragile items (need bubble wrap): $fragileStr\n"
        "• Special constraints: $constraintsStr\n"
        "• Preferred shifting window: $preferredTime\n\n"
        "SafeShift AI has estimated the route price as Rs. ${widget.price} based on public rates. Please confirm if your vehicle is available and confirm this quote range. Shukriya!";

    setState(() {
      _draftMessage = localTemplate;
    });

    final gemini = GeminiService();
    if (!gemini.isMockMode) {
      setState(() {
        _isGeneratingDraft = true;
      });
      final prompt = '''
      Write a highly polite and clear loader driver outreach message in Roman Urdu (with a brief English summary if needed) requesting shifting services from $pickup to $dropoff.
      The customer's inventory items are: $items.
      Fragile items are: $fragileStr.
      Floor/stair constraints: $constraintsStr.
      Shifting time: $preferredTime.
      Estimated price is Rs. ${widget.price}.
      Ask them to confirm if they accept this rate and are available. Keep it structured and easy to copy directly into WhatsApp or SMS.
      Do not include any placeholders, write it as a ready-to-send draft.
      ''';
      final dynamicResult = await gemini.generateText(prompt);
      if (dynamicResult != null && dynamicResult.trim().isNotEmpty) {
        if (mounted) {
          setState(() {
            _draftMessage = dynamicResult.trim();
            _isGeneratingDraft = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isGeneratingDraft = false;
          });
        }
      }
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    final geminiService = GeminiService();

    // Construct chat history context
    String chatHistory = "";
    for (var m in _messages) {
      final role = m['role'] == 'user' ? 'Customer' : 'Mover';
      final content = m['content'];
      chatHistory += "$role: $content\n";
    }

    final pickup = widget.request.pickupLocation ?? 'Pickup Location';
    final dropoff = widget.request.dropoffLocation ?? 'Dropoff Location';

    final prompt = '''
    You are a local loader/mover driver in Pakistan working for ${widget.mover.name}.
    You are chatting with a customer who wants to move from $pickup to $dropoff.
    The agreed price is Rs. ${widget.price}.
    
    Chat history:
    $chatHistory
    
    Respond to the customer's last message. 
    You MUST speak in Roman Urdu. Keep it natural, polite, and brief (like a WhatsApp message).
    If they ask for a discount, you can say the price is fixed because of distance/items, or offer a tiny 200 Rs discount.
    If they ask about fragile items, assure them you have blankets/cartons.
    Return ONLY your response message, no markdown, no quotes.
    ''';

    final response = await geminiService.generateText(prompt);

    setState(() {
      _isTyping = false;
      if (response != null) {
        _messages.add({"role": "mover", "content": response.trim()});
      } else {
        _messages.add({"role": "mover", "content": "Jee sir, hum time pe aajainge. Tension na lein."});
      }
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getJobBriefText() {
    final pickup = widget.request.pickupLocation ?? 'Not specified';
    final dropoff = widget.request.dropoffLocation ?? 'Not specified';
    final moveType = widget.request.moveType ?? 'Standard Shifting';
    
    final String items;
    if (widget.request.inventoryItems.isNotEmpty) {
      items = widget.request.inventoryItems.map((e) => "• ${e.name} (x${e.quantity})").join('\n');
    } else if (widget.request.inventory.isNotEmpty) {
      items = widget.request.inventory.map((e) => "• $e").join('\n');
    } else {
      items = "• Complete household items";
    }

    final constraints = widget.request.constraints.isNotEmpty 
        ? widget.request.constraints.join(', ') 
        : 'None';
    
    return "SAFESHIFT AI - MOVER JOB BRIEF\n"
        "=================================\n"
        "Move Type: $moveType\n"
        "Pickup: $pickup\n"
        "Drop-off: $dropoff\n"
        "Stair Constraints: $constraints\n"
        "---------------------------------\n"
        "Inventory Items:\n$items\n"
        "---------------------------------\n"
        "Required Vehicle: ${widget.request.requiredVehicle ?? 'Shahzor'}\n"
        "Required Crew: ${widget.request.requiredCrew ?? 3} Men\n"
        "Mover Vehicle: ${widget.mover.vehicleType} (${widget.mover.crewCount} crew)\n"
        "Locked Price: Rs. ${widget.price} (Simulated Protection Hold)\n"
        "=================================";
  }

  Widget _buildJobBriefAndChecklist() {
    final pickup = widget.request.pickupLocation ?? 'Not specified';
    final dropoff = widget.request.dropoffLocation ?? 'Not specified';
    final moveType = widget.request.moveType ?? 'Standard Shifting';
    final constraints = widget.request.constraints.isNotEmpty 
        ? widget.request.constraints.join(', ') 
        : 'None (Ground to Ground)';
    
    final itemsStr = widget.request.inventoryItems.isNotEmpty
        ? widget.request.inventoryItems.map((e) => "${e.name} (x${e.quantity})").join(', ')
        : (widget.request.inventory.isNotEmpty ? widget.request.inventory.join(', ') : 'Complete items');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1F1F25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x33CFC6B0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            dense: true,
            leading: const Icon(Icons.assignment_outlined, color: Color(0xFFFFB5A1)),
            title: const Text(
              "SafeShift Verified Job Brief & Driver Checklist",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFB5A1),
              ),
            ),
            subtitle: Text(
              _isBriefExpanded ? "Tap to collapse job details" : "Tap to expand and complete checklist to Book",
              style: const TextStyle(fontSize: 11, color: Color(0xFF908F9D)),
            ),
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
                  // Job Details Grid/Rows
                  _buildDetailRow("Move Type", moveType, icon: Icons.category_outlined),
                  const SizedBox(height: 6),
                  _buildDetailRow("Pickup ➔ Dropoff", "$pickup ➔ $dropoff", icon: Icons.route_outlined),
                  const SizedBox(height: 6),
                  _buildDetailRow("Stair Constraints", constraints, icon: Icons.filter_hdr_outlined),
                  const SizedBox(height: 6),
                  _buildDetailRow("Inventory Items", itemsStr, icon: Icons.list_alt_outlined),
                  const SizedBox(height: 6),
                  _buildDetailRow("Required Resources", "${widget.request.requiredCrew ?? 3} movers | ${widget.request.requiredVehicle ?? 'Shahzor'}", icon: Icons.people_outline),
                  const SizedBox(height: 6),
                  _buildDetailRow("Mover Capacity", "${widget.mover.crewCount} crew | ${widget.mover.vehicleType}", icon: Icons.local_shipping_outlined),
                  // Capacity Mismatch Warning
                  Builder(builder: (context) {
                    final reqV = (widget.request.requiredVehicle ?? 'suzuki').toLowerCase();
                    final movV = widget.mover.vehicleType.toLowerCase();
                    bool vehicleOk = true;
                    if (reqV.contains('medium') || reqV.contains('mazda')) {
                      vehicleOk = movV.contains('mazda') || movV.contains('medium') || movV.contains('truck') || movV.contains('shahzor');
                    } else if (reqV.contains('shahzor')) {
                      vehicleOk = movV.contains('shahzor') || movV.contains('mazda') || movV.contains('medium') || movV.contains('truck');
                    }
                    final crewOk = widget.mover.crewCount >= (widget.request.requiredCrew ?? 2);
                    if (vehicleOk && crewOk) return const SizedBox.shrink();
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Capacity mismatch — this mover provides ${widget.mover.crewCount} crew / ${widget.mover.vehicleType}, but the manifest requires ${widget.request.requiredCrew ?? 3} movers / ${widget.request.requiredVehicle ?? 'Shahzor'}. Not recommended for this load.",
                              style: const TextStyle(color: Color(0xFFFF8B8B), fontWeight: FontWeight.bold, fontSize: 11, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  
                  // Locked Price Protection Badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF81C784), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline, color: Color(0xFF81C784), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Locked Price Protection: Rs. ${widget.price} (No Hidden Charges)",
                            style: const TextStyle(
                              color: Color(0xFF81C784),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Copy Brief Button
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _getJobBriefText()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Job Brief copied to clipboard!"),
                          backgroundColor: Color(0xFF2E7D32),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFCFC6B0),
                      side: const BorderSide(color: Color(0x33CFC6B0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text("Copy Brief for Driver", style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(height: 16),
                  
                  const Divider(color: Color(0x1ACFC6B0), height: 1),
                  const SizedBox(height: 12),
                  
                  // Checklist Title
                  Row(
                    children: [
                      const Icon(Icons.fact_check_outlined, color: Color(0xFFFFB5A1), size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        "Mover Commitment Checklist",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE4E1EA),
                        ),
                      ),
                      const Spacer(),
                      if (_isChecklistComplete)
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF81C784), size: 16),
                            SizedBox(width: 4),
                            Text("VERIFIED", style: TextStyle(color: Color(0xFF81C784), fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        )
                      else
                        const Text("REQUIRED TO BOOK", style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Ensure you have verified these commitments with the driver in chat/phone before activating simulated protection hold:",
                    style: TextStyle(fontSize: 11, color: Color(0xFF908F9D)),
                  ),
                  const SizedBox(height: 10),
                  
                  // Checkboxes
                  _buildChecklistTile(
                    value: _check1,
                    onChanged: (val) => setState(() => _check1 = val ?? false),
                    title: "Driver accepts locked quote of Rs. ${widget.price} with absolutely NO hidden charges.",
                  ),
                  _buildChecklistTile(
                    value: _check2,
                    onChanged: (val) => setState(() => _check2 = val ?? false),
                    title: "Driver confirms vehicle capacity is correct and will not request extra vehicle.",
                  ),
                  _buildChecklistTile(
                    value: _check3,
                    onChanged: (val) => setState(() => _check3 = val ?? false),
                    title: "Driver confirms crew strength (${widget.mover.crewCount} men) and tools for assembly/loading.",
                  ),
                  _buildChecklistTile(
                    value: _check4,
                    onChanged: (val) => setState(() => _check4 = val ?? false),
                    title: "Driver has protective equipment (blankets/ropes/wrap) as required for fragile items.",
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFFCFC6B0)),
        const SizedBox(width: 8),
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

  Widget _buildChecklistTile({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String title,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: const Color(0xFF2E7D32),
      checkColor: Colors.white,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: Color(0xFFE4E1EA)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTraceMode = context.watch<AppState>().isAgentTraceModeEnabled;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.mover.isRegistered ? "SafeShift Partner Chat" : "AI Outreach Assistant",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.mover.name,
              style: TextStyle(
                fontSize: 11,
                color: widget.mover.isRegistered ? const Color(0xFF81C784) : const Color(0xFFFFB5A1),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isChecklistComplete
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BookingConfirmationScreen(request: widget.request)),
                    );
                  }
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please complete the Driver Checklist first to enable Booking."),
                        backgroundColor: Color(0xFFD32F2F),
                      ),
                    );
                  },
            child: Text(
              "BOOK NOW",
              style: TextStyle(
                color: _isChecklistComplete ? const Color(0xFFFFB5A1) : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
      body: widget.mover.isRegistered ? _buildChatLayout(isTraceMode) : _buildOutreachLayout(isTraceMode),
    );
  }

  // --- Registered Partner In-App Chat Simulation ---
  Widget _buildChatLayout(bool isTraceMode) {
    return Column(
      children: [
        // Honesty Banner
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.15),
            border: const Border(bottom: BorderSide(color: Colors.amber, width: 0.5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.amber),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Demo Simulation: Provider responses are generated dynamically for MVP demonstration.",
                  style: TextStyle(fontSize: 11, color: Color(0xFFE4E1EA), height: 1.2),
                ),
              ),
            ],
          ),
        ),
        if (isTraceMode)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AgentTraceCard(
              trace: AgentTrace(
                stepName: "Mover Negotiation Persona",
                observation: "User initiated chat with certified mover '${widget.mover.name}'.",
                inference: "Using Gemini API to simulate provider dialog persona in Roman Urdu.",
                decision: "Generate Urdu replies honoring base constraints & locked quote.",
                action: "Active Chat Session.",
                outcome: "Awaiting Book Now action.",
              ),
            ),
          ),
        // Collapsible Job Brief & Checklist
        _buildJobBriefAndChecklist(),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isUser = msg["role"] == "user";
              return FadeInUp(
                duration: const Duration(milliseconds: 300),
                child: Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF2E7D32) : const Color(0x1ACFC6B0),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg["content"]!,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        if (!isUser) ...[
                          const SizedBox(height: 4),
                          const Text(
                            "Simulated provider response for demo",
                            style: TextStyle(fontSize: 8, color: Colors.amberAccent, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_isTyping)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("typing...", style: TextStyle(color: Color(0xFF908F9D), fontStyle: FontStyle.italic)),
            ),
          ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F25),
        border: Border(top: BorderSide(color: Color(0x1ACFC6B0))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: const TextStyle(color: Color(0xFF908F9D)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0x1ACFC6B0),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(color: Colors.white),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFFFFB5A1),
              child: IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF131319)),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Unregistered Public Movers Outreach Drafting Flow ---
  Widget _buildOutreachLayout(bool isTraceMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clear Registration Status & Contact Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x1AFFB5A1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x33FFB5A1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFFFB5A1), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "Publicly Discovered Mover",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFB5A1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "This provider is not registered on the SafeShift platform. SafeShift AI drafts a negotiation message with your exact inventory, constraints, and locked price to facilitate external contact via WhatsApp or phone call.",
                  style: TextStyle(color: Color(0xFFCFC6B0), fontSize: 12, height: 1.3),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0x33FFB5A1)),
                const SizedBox(height: 8),
                Text("• Provider: ${widget.mover.name}", style: const TextStyle(color: Color(0xFFE4E1EA), fontSize: 12, fontWeight: FontWeight.bold)),
                Text("• Source Type: ${widget.mover.sourceType}", style: const TextStyle(color: Color(0xFFCFC6B0), fontSize: 12)),
                Text("• Source URL: ${widget.mover.sourceUrl}", style: const TextStyle(color: Color(0xFFCFC6B0), fontSize: 12)),
                Text("• Public Phone Available: ${widget.mover.hasPhone ? 'Yes' : 'No'}", style: const TextStyle(color: Color(0xFFCFC6B0), fontSize: 12)),
                Text("• Website Available: ${widget.mover.hasWebsite ? 'Yes' : 'No'}", style: const TextStyle(color: Color(0xFFCFC6B0), fontSize: 12)),
                Text("• WhatsApp Available: ${widget.mover.hasWhatsApp.toUpperCase()}", style: const TextStyle(color: Color(0xFFCFC6B0), fontSize: 12)),
                Text("• Registered on SafeShift: NO", style: const TextStyle(color: Color(0xFFCFC6B0), fontSize: 12)),
                Text("• Contact Method: ${widget.mover.contactMethod}", style: const TextStyle(color: Color(0xFFCFC6B0), fontSize: 12)),
                Text("• Data Confidence Score: ${(widget.mover.confidenceScore * 100).toStringAsFixed(0)}%", style: const TextStyle(color: Color(0xFFFFB5A1), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Collapsible Job Brief & Checklist
          _buildJobBriefAndChecklist(),
          const SizedBox(height: 24),

          // Message Drafting Box
          const Text(
            "SafeShift Outreach Draft (Roman Urdu):",
            style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE4E1EA)),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1ACFC6B0)),
            ),
            child: _isGeneratingDraft
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Color(0xFFFFB5A1)),
                          SizedBox(height: 12),
                          Text(
                            "AI Outreach Assistant drafting message...",
                            style: TextStyle(fontSize: 12, color: Color(0xFF908F9D), fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        _draftMessage,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0x1ACFC6B0)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0x1AFFB5A1),
                              foregroundColor: const Color(0xFFFFB5A1),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.copy, size: 14),
                            label: const Text("Copy Draft", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _draftMessage));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Outreach draft message copied to clipboard!"),
                                  backgroundColor: Color(0xFF2E7D32),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),

          // Prototype Reply
          const Text(
            "Prototype Provider Response (For Demo Only):",
            style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE4E1EA)),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Driver: \"Haan bhai, Suzuki pickup ready hai. Milte hain. Locked quote confirm hai.\"",
                  style: TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 6),
                Text(
                  "⚠️ Simulated provider response shown for demo only.",
                  style: TextStyle(fontSize: 9, color: Colors.amberAccent, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          const Text(
            "Outreach Actions (Direct contact):",
            style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE4E1EA)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.mover.hasPhone)
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x1ACFC6B0)),
                    ),
                    child: TextButton.icon(
                      icon: const Icon(Icons.phone, color: Colors.greenAccent),
                      label: const Text("Call Driver", style: TextStyle(color: Colors.white, fontSize: 13)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Simulated call to driver of '${widget.mover.name}' (Demo Only)"),
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (widget.mover.hasPhone && (widget.mover.hasWhatsApp == "yes" || widget.mover.hasWhatsApp == "unknown"))
                const SizedBox(width: 12),
              if (widget.mover.hasWhatsApp == "yes" || widget.mover.hasWhatsApp == "unknown")
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x1ACFC6B0)),
                    ),
                    child: TextButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFFFB5A1)),
                      label: const Text("Open WhatsApp", style: TextStyle(color: Colors.white, fontSize: 13)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Simulated WhatsApp Outreach to ${widget.mover.name} (Demo Only)"),
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),

          // Proceed Button
          SizedBox(
            width: double.infinity,
            child: PrimaryCTA(
              label: _isChecklistComplete
                  ? (widget.mover.isRegistered ? "Proceed to Prototype Booking" : "Proceed to Prototype Booking Simulation")
                  : "Complete Driver Checklist to Book",
              onPressed: _isChecklistComplete
                  ? () {
                      if (_validateBooking(context)) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => BookingConfirmationScreen(request: widget.request)),
                        );
                      }
                    }
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please complete the Driver Checklist first to proceed."),
                          backgroundColor: Color(0xFFD32F2F),
                        ),
                      );
                    },
            ),
          ),

          if (isTraceMode) ...[
            const SizedBox(height: 32),
            AgentTraceCard(
              trace: AgentTrace(
                stepName: "Outreach Agent Trace",
                observation: "Provider has public phone/website but is not registered on SafeShift.",
                inference: "In-app live chat is not available. User needs an outreach draft.",
                decision: "Generate a Roman Urdu/English contact message and offer Call / WhatsApp / Copy.",
                action: "Draft message generated. No real message sent in MVP. Simulated provider response shown for demo only.",
                outcome: "Awaiting user confirmation of driver contact & prototype booking lock.",
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _validateBooking(BuildContext context) {
    final req = widget.request;
    
    // 1. Pickup/dropoff must exist
    if (req.pickupLocation == null || req.pickupLocation!.isEmpty) {
      _showValidationError(context, "Pickup location is missing. Please restart the move planning.");
      return false;
    }
    if (req.dropoffLocation == null || req.dropoffLocation!.isEmpty) {
      _showValidationError(context, "Dropoff location is missing. Please restart the move planning.");
      return false;
    }

    // 2. Do not allow booking just because hasValidInventoryEvidence is true if inventoryItems is empty
    if (req.inventoryItems.isEmpty && req.hasValidInventoryEvidence) {
      _showValidationError(
        context,
        "Inventory items list is empty despite valid inventory evidence status. Please add items manually or upload a valid room/furniture photo.",
      );
      return false;
    }

    // 3. Inventory must exist or explicit low-confidence/no-inventory confirmation exists
    final bool hasItems = req.inventoryItems.isNotEmpty;
    final bool hasExplicitBypass = req.continueWithoutImageEvidence && req.inventorySource == 'none';
    if (!hasItems && !hasExplicitBypass) {
      _showValidationError(
        context,
        "SafeShift cannot create a reliable quote without inventory details. Please add items manually or upload a valid room/furniture photo, or explicitly choose Low-Confidence Mode.",
      );
      return false;
    }

    // 4. Quote confidence must be visible
    if (req.quoteConfidence == null || req.quoteConfidence!.isEmpty) {
      _showValidationError(
        context,
        "Quote confidence indicator is not visible or loaded. Please ensure the pricing engine completes valuation.",
      );
      return false;
    }

    // 5. Risk level must be assessed
    if (req.riskLevel == null || req.riskLevel!.isEmpty) {
      _showValidationError(context, "Inventory risk level has not been evaluated yet. Please view the risk assessment screen first.");
      return false;
    }

    // 6. Quote confidence score must be loaded
    if (req.confidenceScore == null) {
      _showValidationError(context, "Mover quote confidence score is missing. Cannot proceed with booking.");
      return false;
    }

    return true;
  }

  void _showValidationError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F25),
        title: const Text(
          "⚠️ Booking Blocked",
          style: TextStyle(fontFamily: 'Outfit', color: Color(0xFFFF8B8B), fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFFE4E1EA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFFFFB5A1), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
