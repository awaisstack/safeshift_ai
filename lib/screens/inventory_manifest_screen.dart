import 'dart:math';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../models/move_request.dart';
import '../models/inventory_item.dart';
import '../providers/app_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_cta.dart';
import 'agent_understanding_screen.dart';

class InventoryManifestScreen extends StatefulWidget {
  final MoveRequest request;

  const InventoryManifestScreen({super.key, required this.request});

  @override
  State<InventoryManifestScreen> createState() => _InventoryManifestScreenState();
}

class _InventoryManifestScreenState extends State<InventoryManifestScreen> {
  late List<InventoryItem> _items;
  final TextEditingController _newItemNameController = TextEditingController();
  String _selectedCategory = 'furniture';
  bool _newFragile = false;
  bool _newHeavy = false;
  bool _newNeedsDisassembly = false;
  bool _newNeedsWrapping = false;

  @override
  void initState() {
    super.initState();
    // Merge prompt-parsed items with image-parsed items
    final appState = Provider.of<AppState>(context, listen: false);
    _items = _mergeInventory(widget.request.inventoryItems, appState.uploadedImages);
  }

  List<InventoryItem> _mergeInventory(List<InventoryItem> textItems, List<UploadedImage> images) {
    final Map<String, InventoryItem> merged = {};
    
    final Map<String, String> synonyms = {
      'refrigerator': 'fridge',
      'couch': 'sofa',
      'boxes': 'cartons',
      'box': 'cartons',
      'carton': 'cartons',
    };

    String normalizeKey(String key) {
      String k = key.trim().toLowerCase();
      return synonyms[k] ?? k;
    }

    // 1. Add all text items
    for (var item in textItems) {
      final key = normalizeKey(item.name);
      merged[key] = item.copyWith(name: key, source: 'text');
    }

    // 2. Merge image items
    for (var img in images) {
      if (img.scanStatus == 'valid_inventory' || img.scanStatus == 'partially_useful') {
        for (var item in img.extractedItems) {
          final key = normalizeKey(item.name);
          if (merged.containsKey(key)) {
            final existing = merged[key]!;
            merged[key] = existing.copyWith(
              quantity: max(existing.quantity, item.quantity),
              confidence: max(existing.confidence, item.confidence),
              source: 'mixed',
              fragile: existing.fragile || item.fragile,
              heavy: existing.heavy || item.heavy,
              bulky: existing.bulky || item.bulky,
              needsDisassembly: existing.needsDisassembly || item.needsDisassembly,
              needsWrapping: existing.needsWrapping || item.needsWrapping,
              needsTwoPersonLift: existing.needsTwoPersonLift || item.needsTwoPersonLift,
            );
          } else {
            merged[key] = item.copyWith(name: key, source: 'image');
          }
        }
      }
    }

    return merged.values.toList();
  }

  void _addItem() {
    final name = _newItemNameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _items.add(InventoryItem(
        name: name,
        quantity: 1,
        category: _selectedCategory,
        confidence: 1.0,
        weightClass: _newHeavy ? 'heavy' : 'medium',
        estimatedWeightRange: _newHeavy ? '30-60 kg' : '10-25 kg',
        volumeClass: _selectedCategory == 'furniture' ? 'bulky' : 'medium',
        handlingDifficulty: _newHeavy ? 'difficult' : 'moderate',
        fragile: _newFragile,
        heavy: _newHeavy,
        needsDisassembly: _newNeedsDisassembly,
        needsWrapping: _newNeedsWrapping,
        source: 'manual',
      ));
      
      // Reset form
      _newItemNameController.clear();
      _selectedCategory = 'furniture';
      _newFragile = false;
      _newHeavy = false;
      _newNeedsDisassembly = false;
      _newNeedsWrapping = false;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _incrementQuantity(int index) {
    setState(() {
      _items[index].quantity++;
    });
  }

  void _decrementQuantity(int index) {
    if (_items[index].quantity > 1) {
      setState(() {
        _items[index].quantity--;
      });
    } else {
      _removeItem(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final int totalQty = _items.fold(0, (sum, item) => sum + item.quantity);
    final int fragileCount = _items.where((e) => e.fragile).fold(0, (sum, item) => sum + item.quantity);
    final int heavyCount = _items.where((e) => e.heavy).fold(0, (sum, item) => sum + item.quantity);
    final int serviceCount = _items.where((e) => e.needsDisassembly || e.needsWrapping).fold(0, (sum, item) => sum + item.quantity);

    // Calculate image scanner verification confidence average
    final double avgConfidence = appState.imageInventoryConfidence;
    final bool isLowConfidence = appState.uploadedImages.isNotEmpty && avgConfidence < 0.75;

    return Scaffold(
      backgroundColor: const Color(0xFF131319),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A22),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFCFC6B0)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Structured Inventory Manifest",
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, color: Color(0xFFCFC6B0)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Confidence or Verification Badge
            if (isLowConfidence)
              Container(
                color: const Color(0x33FFB74D),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB74D), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Low scan confidence (${(avgConfidence * 100).toStringAsFixed(0)}%). SafeShift advises verifying items manually or adding packaging details below.",
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFFFFB74D)),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Statistics Summary Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: const Color(0xFF1A1A22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem("Total Items", totalQty.toString(), Icons.inventory_2_outlined, const Color(0xFF81C784)),
                  _buildStatItem("Fragile", fragileCount.toString(), Icons.gavel_rounded, const Color(0xFFE57373)),
                  _buildStatItem("Heavy", heavyCount.toString(), Icons.fitness_center_rounded, const Color(0xFFFFB74D)),
                  _buildStatItem("Special Serv.", serviceCount.toString(), Icons.plumbing_rounded, const Color(0xFF64B5F6)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Review & Verify Items",
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFCFC6B0)),
                    ),
                    const SizedBox(height: 12),
                    
                    if (_items.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Text(
                            "No items added yet. Use the manual form below or upload pictures to scan.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Outfit', color: const Color(0xFFCFC6B0).withOpacity(0.5)),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return FadeInUp(
                            duration: const Duration(milliseconds: 300),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildItemCard(item, index),
                            ),
                          );
                        },
                      ),
                    
                    const SizedBox(height: 16),
                    const Divider(color: Color(0x33CFC6B0)),
                    const SizedBox(height: 16),
                    
                    const Text(
                      "Add Custom/Missing Item",
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFCFC6B0)),
                    ),
                    const SizedBox(height: 12),
                    _buildManualAddForm(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            
            // Bottom Action CTAs
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A22),
                border: Border(top: BorderSide(color: Color(0x22CFC6B0))),
              ),
              child: PrimaryCTA(
                label: "Confirm Manifest & Continue",
                onPressed: () {
                  if (_items.isEmpty) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1F1F25),
                        title: const Text(
                          "⚠️ Empty Inventory Manifest",
                          style: TextStyle(fontFamily: 'Outfit', color: Color(0xFFFFB5A1), fontWeight: FontWeight.bold),
                        ),
                        content: const Text(
                          "SafeShift cannot create a reliable quote without inventory details. Please add items manually or upload a valid room/furniture photo.",
                          style: TextStyle(fontFamily: 'Outfit', color: Color(0xFFE4E1EA), height: 1.4),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Add Items Manually", style: TextStyle(color: Color(0xFFFFB5A1), fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Force bypass states on the request and appState
                              final appState = Provider.of<AppState>(context, listen: false);
                              appState.updateImageValidation(
                                continueWithoutImage: true,
                                source: 'none',
                                hasValidEvidence: false,
                                confidence: 0.0,
                              );
                              widget.request.continueWithoutImageEvidence = true;
                              widget.request.inventorySource = 'none';
                              widget.request.imageInventoryConfidence = 0.0;
                              widget.request.hasValidInventoryEvidence = false;
                              
                              widget.request.inventoryItems = _items;
                              widget.request.syncLegacyFields();
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AgentUnderstandingScreen(request: widget.request),
                                ),
                              );
                            },
                            child: const Text("Continue with low-confidence estimate", style: TextStyle(color: Color(0xFF908F9D))),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  // Save items to request
                  widget.request.inventoryItems = _items;
                  widget.request.syncLegacyFields();
                  
                  // Navigate to Agent Understanding
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AgentUnderstandingScreen(request: widget.request),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          label,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 10, color: Color(0xFF908F9D)),
        ),
      ],
    );
  }

  Widget _buildItemCard(InventoryItem item, int index) {
    Color badgeColor = const Color(0xFF908F9D);
    IconData sourceIcon = Icons.keyboard_rounded;
    if (item.source == 'image') {
      badgeColor = const Color(0xFF81C784);
      sourceIcon = Icons.photo_camera_rounded;
    } else if (item.source == 'mixed') {
      badgeColor = const Color(0xFF64B5F6);
      sourceIcon = Icons.merge_type_rounded;
    }

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title, Quantity & Source Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        // Source Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: badgeColor.withOpacity(0.5), width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(sourceIcon, color: badgeColor, size: 10),
                              const SizedBox(width: 3),
                              Text(
                                item.source.toUpperCase(),
                                style: TextStyle(fontFamily: 'Outfit', fontSize: 8, fontWeight: FontWeight.bold, color: badgeColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Category: ${item.category.toUpperCase()} | Weight Class: ${item.weightClass.toUpperCase()}",
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Color(0xFF908F9D)),
                    ),
                  ],
                ),
              ),
              
              // Quantity Counter
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFFFB5A1), size: 22),
                    onPressed: () => _decrementQuantity(index),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    item.quantity.toString(),
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF81C784), size: 22),
                    onPressed: () => _incrementQuantity(index),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          const Divider(color: Color(0x11CFC6B0), height: 1),
          const SizedBox(height: 10),

          // Action Checklist (Fragile, Heavy, Disassembly, Wrapping, 2-Man lift)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildToggleChip(
                label: "Fragile ⚠️",
                value: item.fragile,
                activeColor: const Color(0xFFE57373),
                onChanged: (val) {
                  setState(() {
                    item.fragile = val;
                  });
                },
              ),
              _buildToggleChip(
                label: "Heavy ⚖️",
                value: item.heavy,
                activeColor: const Color(0xFFFFB74D),
                onChanged: (val) {
                  setState(() {
                    item.heavy = val;
                  });
                },
              ),
              _buildToggleChip(
                label: "Needs Disassembly 🔧",
                value: item.needsDisassembly,
                activeColor: const Color(0xFF81C784),
                onChanged: (val) {
                  setState(() {
                    item.needsDisassembly = val;
                  });
                },
              ),
              _buildToggleChip(
                label: "Needs Wrapping 📦",
                value: item.needsWrapping,
                activeColor: const Color(0xFF64B5F6),
                onChanged: (val) {
                  setState(() {
                    item.needsWrapping = val;
                  });
                },
              ),
              _buildToggleChip(
                label: "2-Person Lift 👥",
                value: item.needsTwoPersonLift,
                activeColor: const Color(0xFFBA68C8),
                onChanged: (val) {
                  setState(() {
                    item.needsTwoPersonLift = val;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: value ? activeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? activeColor : const Color(0x33CFC6B0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: value ? FontWeight.bold : FontWeight.normal,
            color: value ? activeColor : const Color(0xFF908F9D),
          ),
        ),
      ),
    );
  }

  Widget _buildManualAddForm() {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _newItemNameController,
            style: const TextStyle(color: Colors.white, fontFamily: 'Outfit'),
            decoration: const InputDecoration(
              hintText: "Enter item name (e.g. Dining Table, King Mattress)",
              hintStyle: TextStyle(color: Color(0xFF908F9D), fontSize: 13),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0x22CFC6B0))),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFB5A1))),
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              const Text(
                "Category:",
                style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF908F9D), fontSize: 13),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  dropdownColor: const Color(0xFF1F1F25),
                  style: const TextStyle(color: Colors.white, fontFamily: 'Outfit'),
                  underline: const SizedBox.shrink(),
                  items: ['furniture', 'appliance', 'carton', 'other']
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          const Text(
            "Attributes:",
            style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF908F9D), fontSize: 13),
          ),
          const SizedBox(height: 6),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildToggleChip(
                label: "Fragile ⚠️",
                value: _newFragile,
                activeColor: const Color(0xFFE57373),
                onChanged: (val) => setState(() => _newFragile = val),
              ),
              _buildToggleChip(
                label: "Heavy ⚖️",
                value: _newHeavy,
                activeColor: const Color(0xFFFFB74D),
                onChanged: (val) => setState(() => _newHeavy = val),
              ),
              _buildToggleChip(
                label: "Needs Disassembly 🔧",
                value: _newNeedsDisassembly,
                activeColor: const Color(0xFF81C784),
                onChanged: (val) => setState(() => _newNeedsDisassembly = val),
              ),
              _buildToggleChip(
                label: "Needs Wrapping 📦",
                value: _newNeedsWrapping,
                activeColor: const Color(0xFF64B5F6),
                onChanged: (val) => setState(() => _newNeedsWrapping = val),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB5A1),
            ).onPressed(
              onPressed: _addItem,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Color(0xFF131319), size: 16),
                  SizedBox(width: 4),
                  Text("Add Item", style: TextStyle(color: Color(0xFF131319), fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to allow simpler elevated buttons creation in manual add
extension ButtonStyleExtensions on ButtonStyle {
  Widget onPressed({required VoidCallback onPressed, required Widget child}) {
    return ElevatedButton(
      style: this,
      onPressed: onPressed,
      child: child,
    );
  }
}
