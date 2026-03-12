import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/firebase_service.dart';

// ─── Members Tab ──────────────────────────────────────────────────────────────
// Paginated view of paidMembers collection.
// Loads 30 records at a time; search filters the loaded set and triggers
// a new server query when the field is cleared.

class MembersTabWidget extends StatefulWidget {
  const MembersTabWidget({super.key});

  @override
  State<MembersTabWidget> createState() => _MembersTabWidgetState();
}

class _MembersTabWidgetState extends State<MembersTabWidget>
    with AutomaticKeepAliveClientMixin {
  static const _pageSize = 30;

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<QueryDocumentSnapshot> _docs = [];
  bool _loading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  String _searchText = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPage();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 300 &&
        !_loading &&
        _hasMore &&
        _searchText.isEmpty) {
      _loadPage();
    }
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      Query q = FirebaseService.instance.db
          .collection('paidMembers')
          .orderBy('fullName')
          .limit(_pageSize);

      if (!reset && _lastDoc != null) {
        q = q.startAfterDocument(_lastDoc!);
      }

      final snap = await q.get();
      final newDocs = snap.docs;

      setState(() {
        if (reset) _docs = [];
        _docs.addAll(newDocs);
        _hasMore = newDocs.length == _pageSize;
        if (newDocs.isNotEmpty) _lastDoc = newDocs.last;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String val) {
    setState(() => _searchText = val.trim().toLowerCase());
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _searchText = '');
  }

  List<QueryDocumentSnapshot> get _filtered {
    if (_searchText.isEmpty) return _docs;
    return _docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      final name  = (data['fullName']  as String? ?? '').toLowerCase();
      final phone = (data['phone']     as String? ?? '').toLowerCase();
      final email = (data['email']     as String? ?? '').toLowerCase();
      final state = (data['state']     as String? ?? '').toLowerCase();
      return name.contains(_searchText) ||
          phone.contains(_searchText) ||
          email.contains(_searchText) ||
          state.contains(_searchText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final items = _filtered;

    return Column(
      children: [
        // ── Search bar ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by name, phone, email or state…',
              hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF), fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF)),
              suffixIcon: _searchText.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Color(0xFF9CA3AF)),
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1976D2)),
              ),
            ),
          ),
        ),

        // ── Count row ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            children: [
              Text(
                _searchText.isNotEmpty
                    ? '${items.length} match${items.length == 1 ? '' : 'es'} in loaded records'
                    : '${_docs.length} clients loaded${_hasMore ? ' — scroll for more' : ' — all loaded'}',
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF6B7280)),
              ),
            ],
          ),
        ),

        // ── List ──────────────────────────────────────────────────────────
        Expanded(
          child: items.isEmpty && !_loading
              ? _emptyState()
              : ListView.separated(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length + (_hasMore && _searchText.isEmpty ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    if (i == items.length) {
                      return _loading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : TextButton(
                              onPressed: _loadPage,
                              child: Text('Load more',
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFF1976D2))),
                            );
                    }
                    final doc  = items[i];
                    final data = doc.data() as Map<String, dynamic>;
                    return _MemberCard(
                      data: data,
                      onTap: () => _showDetail(ctx, data),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded, size: 52, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            _searchText.isNotEmpty ? 'No matches found' : 'No clients loaded',
            style: GoogleFonts.inter(
                fontSize: 15, color: const Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => _MemberDetailDialog(data: data),
    );
  }
}

// ─── Member card ──────────────────────────────────────────────────────────────
class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _MemberCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name      = data['fullName']          as String? ?? 'Unknown';
    final phone     = data['phone']             as String? ?? '';
    final state     = data['state']             as String? ?? '';
    final condition = data['conditionCategory'] as String? ?? '';
    final year      = data['registrationYear'];
    final initials  = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    const Color(0xFF1976D2).withValues(alpha: 0.1),
                child: Text(
                  initials,
                  style: const TextStyle(
                      color: Color(0xFF1976D2), fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),

              // Name + phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      [if (phone.isNotEmpty) phone, if (state.isNotEmpty) state]
                          .join('  ·  '),
                      style: GoogleFonts.inter(
                          color: const Color(0xFF6B7280), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Right side chips
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (condition.isNotEmpty)
                    _Chip(label: condition, color: const Color(0xFFC55A11)),
                  if (year != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        year.toString(),
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF)),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFD1D5DB), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Detail dialog ────────────────────────────────────────────────────────────
class _MemberDetailDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MemberDetailDialog({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['fullName'] as String? ?? 'Unknown';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        const Color(0xFF1976D2).withValues(alpha: 0.12),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.w700,
                          fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: GoogleFonts.inter(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        if ((data['serialNo'] as String? ?? '').isNotEmpty)
                          Text(
                            'Client #${data['serialNo']}',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF6B7280)),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Contact
              _Section(label: 'Contact', children: [
                _Row('Phone',           data['phone']          as String?),
                _Row('Alternate Phone', data['alternatePhone'] as String?),
                _Row('Email',           data['email']          as String?),
                _Row('Phone Validity',  data['phoneValidity']  as String?),
              ]),

              // Location
              _Section(label: 'Location', children: [
                _Row('City',    data['city']    as String?),
                _Row('State',   data['state']   as String?),
                _Row('Country', data['country'] as String?),
              ]),

              // Health & Profile
              _Section(label: 'Health & Profile', children: [
                _Row('Age',                '${data['age'] ?? '—'}'),
                _Row('Age Group',          data['ageGroup']          as String?),
                _Row('Weight (kg)',        '${data['weightKg'] ?? '—'}'),
                _Row('Health Condition',   data['healthCondition']   as String?),
                _Row('Condition Category', data['conditionCategory'] as String?),
              ]),

              // Registration
              _Section(label: 'Registration', children: [
                _Row('Registration Date', data['registrationDate'] as String?),
                _Row('Registration Year', '${data['registrationYear'] ?? '—'}'),
                _Row('Payment Date',      data['paymentDate']      as String?),
              ]),

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF6B7280))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _Section({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    final visible = children
        .whereType<_Row>()
        .where((r) => r.value != null && r.value!.isNotEmpty && r.value != '—' && r.value != 'null')
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B7280),
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(children: visible),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String key2;
  final String? value;
  const _Row(this.key2, this.value);

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty || value == '—' || value == 'null') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(key2,
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF6B7280))),
          ),
          Expanded(
            child: Text(value!,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
