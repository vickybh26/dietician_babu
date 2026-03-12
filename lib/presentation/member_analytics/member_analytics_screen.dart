import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../services/firebase_service.dart';
import '../admin_dashboard_overview/widgets/admin_scaffold.dart';

// ─── Member Analytics Screen ───────────────────────────────────────────────
// Reads pre-aggregated stats from  paidMembersStats/*  (7 small docs)
// so we never load all 3 500+ member records client-side.

class MemberAnalyticsScreen extends StatefulWidget {
  const MemberAnalyticsScreen({super.key});

  @override
  State<MemberAnalyticsScreen> createState() => _MemberAnalyticsScreenState();
}

class _MemberAnalyticsScreenState extends State<MemberAnalyticsScreen> {
  final _db = FirebaseService.instance.db;
  bool _loading = true;

  // stats docs
  Map<String, dynamic> _summary          = {};
  Map<String, dynamic> _byCountry        = {};
  Map<String, dynamic> _byState          = {};
  Map<String, dynamic> _byAgeGroup       = {};
  Map<String, dynamic> _byCondCategory   = {};
  Map<String, dynamic> _byPhoneValidity  = {};
  Map<String, dynamic> _byYear           = {};

  static const _ageOrder = [
    'Under 20', '21\u201330', '31\u201340', '41\u201350', '51\u201360', '61+', 'Unknown'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final coll = _db.collection('paidMembersStats');
      final results = await Future.wait([
        coll.doc('summary').get(),
        coll.doc('byCountry').get(),
        coll.doc('byState').get(),
        coll.doc('byAgeGroup').get(),
        coll.doc('byConditionCategory').get(),
        coll.doc('byPhoneValidity').get(),
        coll.doc('byYear').get(),
      ]);
      setState(() {
        _summary         = results[0].data() ?? {};
        _byCountry       = results[1].data() ?? {};
        _byState         = results[2].data() ?? {};
        _byAgeGroup      = results[3].data() ?? {};
        _byCondCategory  = results[4].data() ?? {};
        _byPhoneValidity = results[5].data() ?? {};
        _byYear          = results[6].data() ?? {};
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading member analytics: $e')),
        );
      }
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────
  int _int(String key, [Map<String, dynamic>? map]) =>
      ((map ?? _summary)[key] as num?)?.toInt() ?? 0;

  double _double(String key) =>
      (_summary[key] as num?)?.toDouble() ?? 0;

  Map<String, int> _sortedIntMap(Map<String, dynamic> raw,
      {int limit = 100, List<String>? order}) {
    final filtered = Map<String, dynamic>.from(raw)..remove('updatedAt');
    if (order != null) {
      return {for (final k in order) if (filtered.containsKey(k)) k: (filtered[k] as num).toInt()};
    }
    final sorted = filtered.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    return {
      for (final e in sorted.take(limit)) e.key: (e.value as num).toInt()
    };
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Member Analytics',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 24),
                    _buildKpiRow(),
                    const SizedBox(height: 24),
                    _buildSection(
                      'Registration Trend (by Year)',
                      Icons.timeline_rounded,
                      const Color(0xFF1E3A8A),
                      _buildYearChart(),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(builder: (ctx, c) {
                      if (c.maxWidth >= 780) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildSection('Clients by Country', Icons.public_rounded, const Color(0xFF7030A0), _buildBarList(_sortedIntMap(_byCountry, limit: 12)))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildSection('Top States (India)', Icons.location_on_rounded, const Color(0xFF375623), _buildBarList(_sortedIntMap(_byState, limit: 12)))),
                          ],
                        );
                      }
                      return Column(children: [
                        _buildSection('Clients by Country', Icons.public_rounded, const Color(0xFF7030A0), _buildBarList(_sortedIntMap(_byCountry, limit: 12))),
                        const SizedBox(height: 16),
                        _buildSection('Top States (India)', Icons.location_on_rounded, const Color(0xFF375623), _buildBarList(_sortedIntMap(_byState, limit: 12))),
                      ]);
                    }),
                    const SizedBox(height: 20),
                    LayoutBuilder(builder: (ctx, c) {
                      if (c.maxWidth >= 780) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildSection('Age Group Distribution', Icons.people_alt_rounded, const Color(0xFF833C00), _buildBarList(_sortedIntMap(_byAgeGroup, order: _ageOrder)))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildSection('Health Conditions', Icons.medical_services_rounded, const Color(0xFFC55A11), _buildBarList(_sortedIntMap(_byCondCategory)))),
                          ],
                        );
                      }
                      return Column(children: [
                        _buildSection('Age Group Distribution', Icons.people_alt_rounded, const Color(0xFF833C00), _buildBarList(_sortedIntMap(_byAgeGroup, order: _ageOrder))),
                        const SizedBox(height: 16),
                        _buildSection('Health Conditions', Icons.medical_services_rounded, const Color(0xFFC55A11), _buildBarList(_sortedIntMap(_byCondCategory))),
                      ]);
                    }),
                    const SizedBox(height: 20),
                    _buildSection(
                      'Phone Validity',
                      Icons.phone_rounded,
                      const Color(0xFF1976D2),
                      _buildPhoneValidityPanel(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Page header ────────────────────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Member Analytics',
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            Text('Based on ${NumberFormat('#,###').format(_int('totalMembers'))} client records',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500])),
          ],
        ),
        IconButton(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[100],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  // ── KPI cards ─────────────────────────────────────────────────────────────
  Widget _buildKpiRow() {
    final total       = _int('totalMembers');
    final withCond    = _int('withConditions');
    final noCond      = _int('noConditions');
    final intl        = _int('internationalCount');
    final avgAge      = _double('averageAge');
    final validPhones = _int('phoneValidCount');

    final cards = [
      _KpiCard(label: 'Total Clients',         value: NumberFormat('#,###').format(total),      icon: Icons.groups_rounded,            color: const Color(0xFF1E3A8A)),
      _KpiCard(label: 'With Health Issues',   value: NumberFormat('#,###').format(withCond),   icon: Icons.medical_services_outlined,  color: const Color(0xFFC55A11)),
      _KpiCard(label: 'No Health Issues',     value: NumberFormat('#,###').format(noCond),     icon: Icons.check_circle_outline,       color: const Color(0xFF375623)),
      _KpiCard(label: 'International Members',value: NumberFormat('#,###').format(intl),       icon: Icons.public_rounded,             color: const Color(0xFF7030A0)),
      _KpiCard(label: 'Average Age',          value: '$avgAge yrs',                           icon: Icons.cake_rounded,               color: const Color(0xFF833C00)),
      _KpiCard(label: 'Valid Phone Numbers',  value: NumberFormat('#,###').format(validPhones),icon: Icons.phone_rounded,              color: const Color(0xFF1976D2)),
    ];

    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth >= 1100 ? 6 : c.maxWidth >= 750 ? 3 : 2;
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.55,
        children: cards,
      );
    });
  }

  // ── Section wrapper ────────────────────────────────────────────────────────
  Widget _buildSection(String title, IconData icon, Color color, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  // ── Year chart ─────────────────────────────────────────────────────────────
  Widget _buildYearChart() {
    final data = _sortedIntMap(_byYear);
    if (data.isEmpty) return _emptyState();

    // Sort by year ascending
    final sorted = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxVal = sorted.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: sorted.map((e) {
          final pct = maxVal > 0 ? e.value / maxVal : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat('#,###').format(e.value),
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    height: (90 * pct).clamp(4.0, 90.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E75B6),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [const Color(0xFF1E3A8A), const Color(0xFF4A90D9)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(e.key,
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500]),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Generic horizontal bar list ────────────────────────────────────────────
  Widget _buildBarList(Map<String, int> data) {
    if (data.isEmpty) return _emptyState();
    final total = data.values.fold<int>(0, (s, v) => s + v);
    final maxVal = data.values.reduce((a, b) => a > b ? a : b);

    final barColors = [
      const Color(0xFF2E75B6), const Color(0xFF375623), const Color(0xFF7030A0),
      const Color(0xFFC55A11), const Color(0xFF833C00), const Color(0xFF1976D2),
      const Color(0xFF00897B), const Color(0xFFE91E63), const Color(0xFF5C6BC0),
      const Color(0xFF00838F), const Color(0xFF558B2F), const Color(0xFF6D4C41),
    ];

    return Column(
      children: data.entries.toList().asMap().entries.map((entry) {
        final idx   = entry.key;
        final label = entry.value.key;
        final count = entry.value.value;
        final pct   = maxVal > 0 ? count / maxVal : 0.0;
        final pctOfTotal = total > 0 ? count / total * 100 : 0.0;
        final color = barColors[idx % barColors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(label,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text(
                    '${NumberFormat('#,###').format(count)}  ${pctOfTotal.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Phone validity panel ───────────────────────────────────────────────────
  Widget _buildPhoneValidityPanel() {
    final total   = _int('totalMembers');
    final valid   = _int('phoneValidCount');
    final invalid = _int('phoneInvalidCount');
    final validPct = total > 0 ? valid / total : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PhoneStatBox(
                label: 'Valid',
                count: valid,
                pct: validPct * 100,
                color: const Color(0xFF375623),
                icon: Icons.check_circle_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PhoneStatBox(
                label: 'Invalid / Empty',
                count: invalid,
                pct: (1 - validPct) * 100,
                color: const Color(0xFFC55A11),
                icon: Icons.cancel_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: validPct,
            backgroundColor: const Color(0xFFC55A11).withOpacity(0.25),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF375623)),
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 12),
        // Detailed breakdown
        ..._sortedIntMap(_byPhoneValidity).entries.map((e) {
          final isValid = e.key.startsWith('✅');
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle_outline : Icons.highlight_off_rounded,
                  size: 14,
                  color: isValid ? const Color(0xFF375623) : const Color(0xFFC55A11),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(e.key,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis),
                ),
                Text(
                  NumberFormat('#,###').format(e.value),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text('No data available', style: GoogleFonts.inter(color: Colors.grey)),
    ),
  );
}

// ── KPI Card ──────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
              overflow: TextOverflow.ellipsis, maxLines: 2),
        ],
      ),
    );
  }
}

// ── Phone stat box ────────────────────────────────────────────────────────────
class _PhoneStatBox extends StatelessWidget {
  final String label;
  final int count;
  final double pct;
  final Color color;
  final IconData icon;

  const _PhoneStatBox({
    required this.label, required this.count,
    required this.pct, required this.color, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(NumberFormat('#,###').format(count),
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                Text('$label  (${pct.toStringAsFixed(1)}%)',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
