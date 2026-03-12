import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

/// Admin-only screen for managing the food item catalogue.
/// Each document in `foodCatalogue/{id}` stores:
///   name        : String
///   category    : String  (e.g. 'Grain', 'Protein', 'Vegetable', 'Fruit', …)
///   defaultQty  : String  (e.g. '1 cup', '2 rotis')
///   calories    : int     (per defaultQty)
///   protein     : double  (g)
///   carbs       : double  (g)
///   fat         : double  (g)
///   tags        : List<String>  (e.g. ['Veg', 'Gluten Free'])
///   createdAt   : Timestamp
class FoodCatalogueScreen extends StatefulWidget {
  const FoodCatalogueScreen({super.key});

  @override
  State<FoodCatalogueScreen> createState() => _FoodCatalogueScreenState();
}

class _FoodCatalogueScreenState extends State<FoodCatalogueScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterCategory = 'All';

  static const _categories = [
    'All', 'Grain', 'Protein', 'Vegetable', 'Fruit',
    'Dairy', 'Fat & Oil', 'Legume', 'Beverage', 'Snack', 'Other',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Firestore ──────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseService.instance.db.collection('foodCatalogue');

  Future<void> _delete(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> _upsert(Map<String, dynamic> data, {String? id}) async {
    if (id == null) {
      await _col.add({...data, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await _col.doc(id).update(data);
    }
  }

  // ── Dialog ─────────────────────────────────────────────────────────────────

  Future<void> _showEditDialog({Map<String, dynamic>? existing, String? docId}) async {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final qtyCtrl = TextEditingController(text: existing?['defaultQty'] ?? '');
    final calCtrl = TextEditingController(
        text: existing?['calories'] != null ? '${existing!['calories']}' : '');
    final proteinCtrl = TextEditingController(
        text: existing?['protein'] != null ? '${existing!['protein']}' : '');
    final carbsCtrl = TextEditingController(
        text: existing?['carbs'] != null ? '${existing!['carbs']}' : '');
    final fatCtrl = TextEditingController(
        text: existing?['fat'] != null ? '${existing!['fat']}' : '');

    String category = existing?['category'] as String? ?? 'Other';
    final selectedTags = Set<String>.from(
        (existing?['tags'] as List? ?? []).map((e) => e.toString()));

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: Text(docId == null ? 'Add Food Item' : 'Edit Food Item'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Food name *',
                        hintText: 'e.g. Brown Rice, Paneer, Almonds',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Category
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .where((c) => c != 'All')
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setDs(() => category = v!),
                    ),
                    const SizedBox(height: 12),

                    // Qty + Calories in a row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: qtyCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Default qty *',
                              hintText: '1 cup',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: calCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Calories *',
                              hintText: 'kcal',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (int.tryParse(v.trim()) == null) return 'Number';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Macros row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: proteinCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Protein (g)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: carbsCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Carbs (g)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: fatCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Fat (g)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Diet Tags
                    Text('Diet tags',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        'Veg', 'Non-Veg', 'Vegan', 'Gluten Free',
                        'Dairy Free', 'Keto', 'High Protein', 'Low Carb',
                      ].map((tag) {
                        final selected = selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag,
                              style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          onSelected: (v) => setDs(() {
                            if (v) {
                              selectedTags.add(tag);
                            } else {
                              selectedTags.remove(tag);
                            }
                          }),
                          selectedColor:
                              AppTheme.lightTheme.colorScheme.primary.withOpacity(0.15),
                          checkmarkColor:
                              AppTheme.lightTheme.colorScheme.primary,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                await _upsert(
                  {
                    'name': nameCtrl.text.trim(),
                    'category': category,
                    'defaultQty': qtyCtrl.text.trim(),
                    'calories': int.parse(calCtrl.text.trim()),
                    'protein': double.tryParse(proteinCtrl.text.trim()) ?? 0.0,
                    'carbs': double.tryParse(carbsCtrl.text.trim()) ?? 0.0,
                    'fat': double.tryParse(fatCtrl.text.trim()) ?? 0.0,
                    'tags': selectedTags.toList(),
                  },
                  id: docId,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(docId == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete food item?'),
        content: Text('Remove "$name" from the catalogue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await _delete(id);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Food Menu Catalogue',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w700, color: Colors.grey[900]),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showEditDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Item'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search + category filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search food items…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final sel = _filterCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _filterCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppTheme.lightTheme.colorScheme.primary
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _col
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var items = snapshot.data?.docs ?? [];

                // Apply category filter
                if (_filterCategory != 'All') {
                  items = items
                      .where((d) => d.data()['category'] == _filterCategory)
                      .toList();
                }

                // Apply search
                if (_searchQuery.isNotEmpty) {
                  items = items
                      .where((d) => (d.data()['name'] as String? ?? '')
                          .toLowerCase()
                          .contains(_searchQuery))
                      .toList();
                }

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _filterCategory != 'All'
                              ? 'No items match your filter'
                              : 'No food items yet',
                          style: GoogleFonts.inter(
                              color: Colors.grey[500], fontSize: 15),
                        ),
                        if (_searchQuery.isEmpty && _filterCategory == 'All') ...[
                          const SizedBox(height: 8),
                          Text(
                            'Tap "+ Add Item" to build your catalogue',
                            style: GoogleFonts.inter(
                                color: Colors.grey[400], fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final doc = items[i];
                    final data = doc.data();
                    return _FoodItemTile(
                      data: data,
                      docId: doc.id,
                      onEdit: () => _showEditDialog(existing: data, docId: doc.id),
                      onDelete: () => _confirmDelete(doc.id, data['name'] ?? ''),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Food Item Tile ─────────────────────────────────────────────────────────────

class _FoodItemTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FoodItemTile({
    required this.data,
    required this.docId,
    required this.onEdit,
    required this.onDelete,
  });

  static const _categoryColors = <String, Color>{
    'Grain': Color(0xFFFF9800),
    'Protein': Color(0xFF1976D2),
    'Vegetable': Color(0xFF4CAF50),
    'Fruit': Color(0xFFE91E63),
    'Dairy': Color(0xFF00BCD4),
    'Fat & Oil': Color(0xFF9C27B0),
    'Legume': Color(0xFF795548),
    'Beverage': Color(0xFF607D8B),
    'Snack': Color(0xFFFF5722),
    'Other': Color(0xFF9E9E9E),
  };

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? '';
    final category = data['category'] as String? ?? 'Other';
    final qty = data['defaultQty'] as String? ?? '';
    final cal = data['calories'];
    final protein = data['protein'];
    final carbs = data['carbs'];
    final fat = data['fat'];
    final tags = (data['tags'] as List? ?? []).map((e) => e.toString()).toList();
    final color = _categoryColors[category] ?? const Color(0xFF9E9E9E);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.restaurant_outlined, color: color, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(name,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            // Category chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(category,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text('$qty  •  ', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                Text('${cal ?? '—'} kcal',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800])),
                if (protein != null || carbs != null || fat != null) ...[
                  Text('  |  ', style: TextStyle(color: Colors.grey[400])),
                  Text(
                    'P:${protein ?? '—'}g  C:${carbs ?? '—'}g  F:${fat ?? '—'}g',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: tags.map((t) => Chip(
                  label: Text(t, style: const TextStyle(fontSize: 10)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.grey[100],
                )).toList(),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18),
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
