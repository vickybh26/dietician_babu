import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/client_management_service.dart';
import '../../../services/firebase_service.dart';

class ClientDetailModalWidget extends StatefulWidget {
  final Map<String, dynamic> clientData;
  final List<String> nudges;
  final Function(int, int, String) onSaveTargets;

  const ClientDetailModalWidget({
    super.key,
    required this.clientData,
    required this.nudges,
    required this.onSaveTargets,
  });

  @override
  State<ClientDetailModalWidget> createState() => _ClientDetailModalWidgetState();
}

class _ClientDetailModalWidgetState extends State<ClientDetailModalWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Admin settings controllers
  final _doctorNameCtrl = TextEditingController();
  final _consultDateCtrl = TextEditingController();
  final _consultTimeCtrl = TextEditingController();
  final _targetCalCtrl = TextEditingController();
  final _targetWaterCtrl = TextEditingController();
  String _consultType = 'video';
  String _country = 'India';
  bool _isSavingSettings = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeFields();
  }

  void _initializeFields() {
    final data = widget.clientData;
    final nc = data['nextConsultation'] as Map<String, dynamic>?;
    
    _doctorNameCtrl.text = nc?['doctorName'] as String? ?? '';
    _consultDateCtrl.text = nc?['date'] as String? ?? '';
    _consultTimeCtrl.text = nc?['time'] as String? ?? '';
    _consultType = nc?['type'] as String? ?? 'video';
    
    _targetCalCtrl.text = data['targetCalories']?.toString() ?? '1800';
    _targetWaterCtrl.text = data['targetWaterMl']?.toString() ?? '2500';
    _country = data['country'] as String? ?? 'India';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _doctorNameCtrl.dispose();
    _consultDateCtrl.dispose();
    _consultTimeCtrl.dispose();
    _targetCalCtrl.dispose();
    _targetWaterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProfileTab(),
                        _buildSubscriptionTab(),
                        _buildMeasurementsTab(),
                        _buildActivityTab(),
                        _buildCheckInsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hasNudge = widget.nudges.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasNudge ? Colors.red[700] : const Color(0xFF1976D2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: hasNudge 
              ? const Icon(Icons.notifications_active, color: Colors.white)
              : Text(_getInitials(widget.clientData['name'] ?? 'Unknown'), style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.clientData['name'] ?? 'Unknown Client',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (hasNudge)
                  Text(
                    'URGENT: Requested ${widget.nudges.join(", ")} updates',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF1976D2),
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: const Color(0xFF1976D2),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: 'Profile & Targets'),
          Tab(text: 'Subscription'),
          Tab(text: 'Measurements'),
          Tab(text: 'Activity'),
          Tab(text: 'Check-ins'),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdminSettingsSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Personal Details'),
          const SizedBox(height: 16),
          _buildInfoCard('Email', widget.clientData['email'] ?? 'N/A', Icons.email),
        ],
      ),
    );
  }

  Widget _buildAdminSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text('Update Targets & Country', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[700])),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _targetCalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Daily Calories (kcal)', border: OutlineInputBorder(), isDense: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _targetWaterCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Daily Water (ml)', border: OutlineInputBorder(), isDense: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _country,
            decoration: const InputDecoration(labelText: 'Assign Country (for Meal Times)', border: OutlineInputBorder(), isDense: true),
            items: const [
              DropdownMenuItem(value: 'India', child: Text('India (Default)')),
              DropdownMenuItem(value: 'USA', child: Text('USA')),
              DropdownMenuItem(value: 'UK', child: Text('UK')),
            ],
            onChanged: (v) => setState(() => _country = v!),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSavingSettings ? null : () async {
                setState(() => _isSavingSettings = true);
                await widget.onSaveTargets(
                  int.tryParse(_targetCalCtrl.text) ?? 1800,
                  int.tryParse(_targetWaterCtrl.text) ?? 2500,
                  _country,
                );
                if (mounted) {
                  setState(() => _isSavingSettings = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Targets updated successfully!')));
                }
              },
              icon: _isSavingSettings ? const CircularProgressIndicator(strokeWidth: 2) : const Icon(Icons.save),
              label: Text(_isSavingSettings ? 'Saving...' : 'Save Targets'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTab() => const Center(child: Text('Subscription details'));
  Widget _buildMeasurementsTab() => const Center(child: Text('Measurement history'));
  Widget _buildActivityTab() => const Center(child: Text('Activity logs'));
  Widget _buildCheckInsTab() => const Center(child: Text('Weekly check-ins'));

  Widget _buildSectionHeader(String title) {
    return Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]));
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 16, color: Colors.grey[600]), const SizedBox(width: 8), Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]))]),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    return name.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').take(2).join('');
  }
}
