import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../data/mock_requests.dart';
import '../services/request_parser_service.dart';
import '../services/gemini_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_cta.dart';
import 'inventory_manifest_screen.dart';
import 'location_picker_screen.dart';
import '../widgets/interactive_map_widget.dart';
import '../providers/app_state.dart';
import '../models/inventory_item.dart';


class RequestInputScreen extends StatefulWidget {
  const RequestInputScreen({super.key});

  @override
  State<RequestInputScreen> createState() => _RequestInputScreenState();
}

class _RequestInputScreenState extends State<RequestInputScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  bool _isScanning = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller.text = mockSampleRequests["Main Scenario"]!;
  }

  Future<void> _takePictureAndAnalyze() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isEmpty) return;

      for (var image in images) {
        final bytes = await image.readAsBytes();
        final appState = Provider.of<AppState>(context, listen: false);

        final tempId = DateTime.now().millisecondsSinceEpoch.toString() + image.name;
        final newImg = UploadedImage(
          id: tempId,
          bytes: bytes,
          fileName: image.name,
          mimeType: image.mimeType ?? 'image/jpeg',
          scanStatus: 'analyzing',
          extractedItems: [],
        );

        appState.addUploadedImage(newImg);

        final geminiService = GeminiService();
        geminiService.validateImageRelevance(
          bytes, 
          image.mimeType ?? 'image/jpeg', 
          image.name
        ).then((validationJsonString) {
          if (!mounted) return;
          bool isValid = false;
          Map<String, dynamic> validationResult = {};
          if (validationJsonString != null && validationJsonString.trim().isNotEmpty) {
            try {
              final cleanJson = validationJsonString.replaceAll('```json', '').replaceAll('```', '').trim();
              validationResult = jsonDecode(cleanJson);
              final relevance = validationResult['image_relevance'];
              final items = validationResult['items'];
              if ((relevance == 'valid_inventory_image' || relevance == 'partially_useful_image') &&
                  items is List && items.isNotEmpty) {
                isValid = true;
              }
            } catch (e) {
              print("JSON parse error: $e");
            }
          }

          final String relevance;
          final double confidence;
          final String userMessage;
          final bool shouldBlock;
          final String scanStatus;
          List<InventoryItem> extractedItems = [];

          if (isValid) {
            relevance = validationResult['image_relevance'];
            confidence = (validationResult['confidence'] as num?)?.toDouble() ?? 0.9;
            userMessage = validationResult['user_message'] ?? 'Image analyzed successfully.';
            shouldBlock = validationResult['should_block_auto_inventory'] ?? false;
            
            final itemsList = validationResult['items'] as List;
            extractedItems = itemsList.map((item) {
              if (item is Map) {
                return InventoryItem.fromJson(Map<String, dynamic>.from(item));
              } else {
                return InventoryItem(
                  name: item.toString(),
                  quantity: 1,
                  category: 'other',
                  confidence: confidence,
                  weightClass: 'medium',
                  estimatedWeightRange: '10-25 kg',
                  volumeClass: 'medium',
                  handlingDifficulty: 'moderate',
                  fragile: false,
                  heavy: false,
                  needsDisassembly: false,
                  needsWrapping: false,
                  source: 'image',
                );
              }
            }).toList();

            scanStatus = shouldBlock 
                ? 'irrelevant_sensitive' 
                : (relevance == 'partially_useful_image' ? 'partially_useful' : 'valid_inventory');
          } else {
            final wasBlocked = validationResult['should_block_auto_inventory'] == true || 
                               validationResult['image_relevance'] == 'irrelevant_image' ||
                               validationResult['image_relevance'] == 'unsafe_or_sensitive_image';
            scanStatus = wasBlocked ? 'irrelevant_sensitive' : 'failed';
            relevance = 'irrelevant_image';
            confidence = 0.0;
            shouldBlock = true;
            userMessage = "Image analysis failed or returned invalid data. Please upload a room/furniture photo or add items manually.";
            extractedItems = [];
          }

          appState.updateUploadedImage(
            tempId,
            scanStatus: scanStatus,
            relevance: relevance,
            confidence: confidence,
            validationMessage: userMessage,
            extractedItems: extractedItems,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(shouldBlock ? "Blocked: $userMessage" : "Successfully scanned ${image.name}!"),
              backgroundColor: shouldBlock ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
            ),
          );
        }).catchError((e) {
          if (!mounted) return;
          appState.updateUploadedImage(
            tempId,
            scanStatus: 'failed',
            relevance: 'irrelevant_image',
            confidence: 0.0,
            validationMessage: e.toString(),
            extractedItems: [],
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error scanning image: $e"),
              backgroundColor: const Color(0xFFC62828),
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking image: $e")),
        );
      }
    }
  }

  Widget _buildImagePreview() {
    final appState = Provider.of<AppState>(context);
    if (appState.uploadedImages.isEmpty) return const SizedBox.shrink();

    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Uploaded Visual Evidence",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFB5A1),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: appState.uploadedImages.length,
                itemBuilder: (context, idx) {
                  final img = appState.uploadedImages[idx];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _getStatusColor(img.scanStatus).withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Image.memory(
                              img.bytes,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _getStatusIcon(img.scanStatus),
                                const SizedBox(width: 4),
                                Text(
                                  _getStatusLabel(img.scanStatus),
                                  style: const TextStyle(fontSize: 8, color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => appState.removeUploadedImage(img.id),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _buildScanningFeedbackBanner(appState),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'analyzing':
        return const Color(0xFF64B5F6);
      case 'valid_inventory':
        return const Color(0xFF81C784);
      case 'partially_useful':
        return const Color(0xFFFFB74D);
      case 'irrelevant_sensitive':
      case 'failed':
      default:
        return const Color(0xFFE57373);
    }
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'analyzing':
        return const SizedBox(
          width: 8,
          height: 8,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF64B5F6)),
        );
      case 'valid_inventory':
        return const Icon(Icons.check_circle, size: 10, color: Color(0xFF81C784));
      case 'partially_useful':
        return const Icon(Icons.warning, size: 10, color: Color(0xFFFFB74D));
      case 'irrelevant_sensitive':
      case 'failed':
      default:
        return const Icon(Icons.cancel, size: 10, color: Color(0xFFE57373));
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'analyzing':
        return "SCANNING";
      case 'valid_inventory':
        return "VERIFIED";
      case 'partially_useful':
        return "PARTIAL";
      case 'irrelevant_sensitive':
        return "BLOCKED";
      case 'failed':
      default:
        return "FAILED";
    }
  }

  Widget _buildScanningFeedbackBanner(AppState appState) {
    final isScanning = appState.uploadedImages.any((img) => img.scanStatus == 'analyzing');
    if (isScanning) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0x2264B5F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF64B5F6), size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Gemini is analyzing uploaded photos to extract inventory...",
                style: TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Color(0xFFE4E1EA)),
              ),
            ),
          ],
        ),
      );
    }

    final blockedImages = appState.uploadedImages.where((img) => img.scanStatus == 'irrelevant_sensitive').toList();
    if (blockedImages.isNotEmpty) {
      final messages = blockedImages.map((img) => img.validationMessage).toSet().join("\n");
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0x22E57373),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x44E57373)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.report_gmailerrorred_rounded, color: Color(0xFFE57373), size: 16),
                SizedBox(width: 8),
                Text(
                  "Visual Evidence Blocked",
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE57373)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              messages.isNotEmpty ? messages : "Some images do not contain room scans or are personal/selfie uploads. SafeShift requires valid moving room photos.",
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Color(0xFFFFCDD2)),
            ),
          ],
        ),
      );
    }

    if (!appState.hasValidInventoryEvidence) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0x22FFB74D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB74D), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "No valid room evidence uploaded. Please upload a clear photo of your rooms/furniture to avoid low-confidence buffer fees.",
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Color(0xFFFFE082)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: appState.continueWithoutImageEvidence,
                onChanged: (val) {
                  appState.updateImageValidation(continueWithoutImage: val);
                },
                activeColor: const Color(0xFFFFB5A1),
                checkColor: const Color(0xFF131319),
                side: const BorderSide(color: Color(0x66CFC6B0)),
              ),
              const Expanded(
                child: Text(
                  "Continue without verified visual evidence (Low-Confidence Mode)",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: Color(0xFFFFB5A1),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x2281C784),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF81C784), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Room photos scanned successfully! Total scanned confidence: ${(appState.imageInventoryConfidence * 100).toStringAsFixed(0)}%.",
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Color(0xFFC8E6C9)),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _analyzeRequest() async {
    final appState = Provider.of<AppState>(context, listen: false);

    // 1. Text description validation
    final rawInput = _controller.text.trim();
    if (rawInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a shifting description or scenario first."),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    // 2. Image validation block
    if (appState.uploadedImages.isNotEmpty) {
      if (!appState.hasValidInventoryEvidence && !appState.continueWithoutImageEvidence) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1F1F25),
            title: const Text(
              "⚠️ Image Verification Required",
              style: TextStyle(fontFamily: 'Outfit', color: Color(0xFFFFB5A1), fontWeight: FontWeight.bold),
            ),
            content: Text(
              appState.imageValidationMessage.isNotEmpty 
                  ? appState.imageValidationMessage 
                  : "One or more uploaded images do not contain valid inventory evidence. Please upload room photos, or select the option to continue in Low-Confidence Mode.",
              style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFFE4E1EA)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Color(0xFF908F9D))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB5A1)),
                onPressed: () {
                  appState.updateImageValidation(continueWithoutImage: true);
                  Navigator.pop(context);
                  _analyzeRequest(); // Retry
                },
                child: const Text("Bypass & Continue", style: TextStyle(color: Color(0xFF131319), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    
    final geminiService = GeminiService();
    final parser = RequestParserService(geminiService);
    
    final moveRequest = await parser.parseRequest(rawInput);
    
    moveRequest.pickupLocation = appState.pickupLocation;
    moveRequest.dropoffLocation = appState.dropoffLocation;
    
    // Copy validation state from AppState to MoveRequest object
    moveRequest.imageRelevance = appState.imageRelevance;
    moveRequest.imageInventoryConfidence = appState.imageInventoryConfidence;
    moveRequest.imageValidationMessage = appState.imageValidationMessage;
    moveRequest.hasValidInventoryEvidence = appState.hasValidInventoryEvidence;
    moveRequest.continueWithoutImageEvidence = appState.continueWithoutImageEvidence;

    // Determine inventory source
    if (appState.uploadedImages.isEmpty) {
      moveRequest.inventorySource = (moveRequest.inventoryItems.isNotEmpty || moveRequest.inventory.isNotEmpty)
          ? 'text'
          : 'none';
    } else if (appState.hasValidInventoryEvidence) {
      final hasPartial = appState.uploadedImages.any((img) => img.scanStatus == 'partially_useful');
      moveRequest.inventorySource = hasPartial ? 'mixed' : 'image';
    } else {
      moveRequest.inventorySource = 'none'; // Uploaded images were blocked
    }
    
    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InventoryManifestScreen(request: moveRequest),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF131319),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFCFC6B0)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Plan Your Move",
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, color: Color(0xFFCFC6B0)),
        ),
        actions: [
          Row(
            children: [
              Text(
                "Agent Trace Mode",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10,
                  color: context.watch<AppState>().isAgentTraceModeEnabled ? const Color(0xFFFFB5A1) : const Color(0xFF908F9D),
                ),
              ),
              Switch(
                value: context.watch<AppState>().isAgentTraceModeEnabled,
                onChanged: (val) => context.read<AppState>().toggleAgentTraceMode(),
                activeColor: const Color(0xFFFFB5A1),
                inactiveTrackColor: const Color(0x33CFC6B0),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background cultural texture/gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF131319), Color(0xFF1A1A24)],
                ),
              ),
            ),
          ),
          // Subtle radial glow at top
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x26CFC6B0).withOpacity(0.03),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      "What do you need?",
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFCFC6B0),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    duration: const Duration(milliseconds: 600),
                    child: const Text(
                      "Describe your moving needs below, or use the camera scan option to auto-extract inventory using Gemini Multimodal.",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        color: Color(0xFF908F9D),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // MULTIMODAL SECTION
                  FadeInUp(
                    delay: const Duration(milliseconds: 150),
                    duration: const Duration(milliseconds: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Color(0xFFFFB5A1), size: 18),
                            SizedBox(width: 8),
                            Text(
                              "MULTIMODAL ROOM SCANNER (GEMINI)",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFB5A1),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _isScanning ? null : _takePictureAndAnalyze,
                          child: Container(
                            width: double.infinity,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0x1ACFC6B0),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isScanning 
                                    ? const Color(0xFFFFB5A1) 
                                    : const Color(0x1ACFC6B0),
                                width: 1.5,
                              ),
                            ),
                            child: _isScanning
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFFFB5A1),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt_outlined, color: Color(0xFFCFC6B0), size: 28),
                                      SizedBox(width: 12),
                                      Text(
                                        "Take Photo of Room/Items",
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFFE4E1EA),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  
                  _buildImagePreview(),
                  
                  // Text Input Card (Glassmorphic)
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 600),
                    child: GlassCard(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 12.0, top: 8.0),
                            child: Text(
                              "INVENTORY DESCRIPTION",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF908F9D),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          TextField(
                            controller: _controller,
                            maxLines: 6,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              color: Color(0xFFE4E1EA),
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: "E.g., 2 bedroom flat shift karna hai...",
                              hintStyle: const TextStyle(color: Color(0x66CFC6B0), fontFamily: 'Outfit'),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Location Pickers (Real Coordinates)
                  FadeInUp(
                    delay: const Duration(milliseconds: 250),
                    duration: const Duration(milliseconds: 600),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.map_outlined, color: Color(0xFFFFB5A1), size: 18),
                              SizedBox(width: 8),
                              Text(
                                "ROUTING & LOCATION EVIDENCE",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF908F9D),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Pickup Point (Moving From)",
                            style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Color(0xFFCFC6B0)),
                          ),
                          const SizedBox(height: 8),
                          _buildLocationDropdown(context, isPickup: true),
                          const SizedBox(height: 16),
                          const Text(
                            "Drop-off Point (Moving To)",
                            style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Color(0xFFCFC6B0)),
                          ),
                          const SizedBox(height: 8),
                          _buildLocationDropdown(context, isPickup: false),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0x1ACFC6B0), height: 1),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "ESTIMATED ROUTE",
                                    style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: Color(0xFF908F9D), fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${appState.pickupLocation} → ${appState.dropoffLocation}",
                                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Color(0xFFE4E1EA), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32).withAlpha(30),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF2E7D32).withAlpha(50)),
                                ),
                                child: Text(
                                  "Approx. ${appState.calculatedDistance.toStringAsFixed(1)} km",
                                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF81C784)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Distance source: ${appState.routeLabel}${appState.routeSource != 'google' ? ' (Haversine × 1.3 road scaling)' : ''}",
                            style: const TextStyle(fontFamily: 'Outfit', fontSize: 10, color: Color(0xFF908F9D), fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Interactive Route Map Preview
                  FadeInUp(
                    delay: const Duration(milliseconds: 260),
                    duration: const Duration(milliseconds: 600),
                    child: InteractiveMapWidget(
                      pickupName: appState.pickupLocation,
                      dropoffName: appState.dropoffLocation,
                      height: 220,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Constraints & Wording Chips
                  FadeInUp(
                    delay: const Duration(milliseconds: 280),
                    duration: const Duration(milliseconds: 600),
                    child: const Text(
                      "Quick Constraints & Wording",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE4E1EA),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 600),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        "Fragile items",
                        "Need packing",
                        "No lift",
                        "Budget controlled",
                        "No hidden charges",
                        "Weekend move",
                        "Urgent move",
                      ].map((chip) {
                        return ActionChip(
                          label: Text(
                            chip,
                            style: const TextStyle(fontFamily: 'Outfit', fontSize: 12),
                          ),
                          backgroundColor: const Color(0x1AFFFFB5),
                          labelStyle: const TextStyle(color: Color(0xFFFFB5A1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0x33FFB5A1)),
                          ),
                          onPressed: () {
                            setState(() {
                              String currentText = _controller.text;
                              if (currentText.isNotEmpty && !currentText.endsWith(" ")) {
                                _controller.text = "$currentText, $chip";
                              } else {
                                _controller.text = "$currentText$chip";
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Quick Tags
                  FadeInUp(
                    delay: const Duration(milliseconds: 320),
                    duration: const Duration(milliseconds: 600),
                    child: const Text(
                      "Quick Scenarios",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE4E1EA),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    delay: const Duration(milliseconds: 350),
                    duration: const Duration(milliseconds: 600),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: mockSampleRequests.keys.map((key) {
                        return ChoiceChip(
                          label: Text(
                            key,
                            style: const TextStyle(fontFamily: 'Outfit', fontSize: 13),
                          ),
                          selected: _controller.text == mockSampleRequests[key],
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _controller.text = mockSampleRequests[key]!;
                              });
                              // Sync coordinates immediately on scenario select
                              final appState = Provider.of<AppState>(context, listen: false);
                              if (key == "Main Scenario") {
                                appState.updateLocations("Bahria Phase 7", "G-13 Islamabad");
                              } else if (key == "Ambiguous") {
                                appState.updateLocations("Saddar Rawalpindi", "F-10 Islamabad");
                              } else if (key == "Urgent") {
                                appState.updateLocations("Bahria Phase 8", "F-10 Islamabad");
                              } else if (key == "Budget Focus") {
                                appState.updateLocations("DHA Phase 1", "PWD");
                              } else if (key == "Recovery Demo") {
                                appState.updateLocations("Saddar Rawalpindi", "G-13 Islamabad");
                              }
                            }
                          },
                          selectedColor: const Color(0x33CFC6B0),
                          disabledColor: Colors.transparent,
                          backgroundColor: const Color(0x0DCFC6B0),
                          labelStyle: TextStyle(
                            color: _controller.text == mockSampleRequests[key]
                                ? const Color(0xFFFFB5A1)
                                : const Color(0xFF908F9D),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: _controller.text == mockSampleRequests[key]
                                  ? const Color(0x4DFFB5A1)
                                  : const Color(0x1ACFC6B0),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // CORE EDUCATION SECTION (Explaining real-world agentic solution)
                  if (context.watch<AppState>().isAgentTraceModeEnabled)
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0x0DFFB5A1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0x33FFB5A1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.sensor_occupied_rounded, color: Color(0xFFFFB5A1), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "AI Agent Outreach Model",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFB5A1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "SafeShift MVP uses a curated public-source provider registry with source links, ratings, contact availability, and synthetic review samples clearly labeled. Production could integrate Google Places, OLX/public listings where allowed, provider onboarding, and WhatsApp Business API.",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                color: const Color(0xFFE4E1EA).withOpacity(0.85),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check, color: Color(0xFF2E7D32), size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Public providers use AI-generated outreach drafts.",
                                    style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFF908F9D)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check, color: Color(0xFF2E7D32), size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Registered SafeShift partners can support in-app simulated chat in the MVP.",
                                    style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFF908F9D)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (context.watch<AppState>().isAgentTraceModeEnabled)
                    const SizedBox(height: 40),

                  
                  // Analyze Button
                  FadeInUp(
                    delay: const Duration(milliseconds: 450),
                    duration: const Duration(milliseconds: 600),
                    child: PrimaryCTA(
                      label: _isLoading ? "Running Agent Intelligence..." : "Analyze with SafeShift Agent",
                      isLoading: _isLoading || _isScanning,
                      onPressed: _analyzeRequest,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDropdown(BuildContext context, {required bool isPickup}) {
    final appState = Provider.of<AppState>(context);
    final selectedValue = isPickup ? appState.pickupLocation : appState.dropoffLocation;
    final source = isPickup ? appState.pickupLocationSource : appState.dropoffLocationSource;

    IconData sourceIcon = Icons.map_outlined;
    if (source == 'gps') {
      sourceIcon = Icons.my_location;
    } else if (source == 'places') {
      sourceIcon = Icons.search;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocationPickerScreen(isPickup: isPickup),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x33CFC6B0)),
        ),
        child: Row(
          children: [
            Icon(sourceIcon, color: const Color(0xFFFFB5A1), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedValue,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Color(0xFFE4E1EA),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (source == 'gps') ...[
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.5)),
                ),
                child: const Text(
                  "GPS",
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 9, color: Color(0xFF81C784), fontWeight: FontWeight.bold),
                ),
              ),
            ] else if (source == 'places') ...[
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB5A1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFB5A1).withOpacity(0.5)),
                ),
                child: const Text(
                  "Places",
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 9, color: Color(0xFFFFB5A1), fontWeight: FontWeight.bold),
                ),
              ),
            ],
            const Icon(Icons.edit_location_alt_outlined, color: Color(0xFFFFB5A1), size: 18),
          ],
        ),
      ),
    );
  }
}
