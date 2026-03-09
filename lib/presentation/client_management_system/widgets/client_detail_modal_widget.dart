import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/client_management_service.dart';
import '../../../services/firebase_service.dart';

class ClientDetailModalWidget extends StatefulWidget {
  final String clientId;

  const ClientDetailModalWidget({
    super.key,
    required this.clientId,
  });

  @override
  State<ClientDetailModalWidget> createState() => _ClientDetailModalWidgetState();
}

class _ClientDetailModalWidgetState extends State<ClientDetailModalWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _clientData;

  // Admin settings controllers
  final _doctorNameCtrl = TextEditingController();
  final _consultDateCtrl = TextEditingController();
  final _consultTimeCtrl = TextEditingController();
  final _targetCalCtrl = TextEditingController();
  final _targetWaterCtrl = TextEditingController();
  String _consultType = 'video';
  bool _isSavingSettings = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadClientDetails();
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

  Future<void> _loadClientDetails() async {
    try {
      setState(() => _isLoading = true);
      final clientData =
          await ClientManagementService.getClientProfile(widget.clientId);

      // Load Firebase settings for admin fields
      final fbSnap = await FirebaseService.instance.clients
          .doc(widget.clientId)
          .get();
      if (fbSnap.exists) {
        final data = fbSnap.data()!;
        final nc = data['nextConsultation'] as Map<String, dynamic>?;
        _doctorNameCtrl.text = nc?['doctorName'] as String? ?? '';
        _consultDateCtrl.text = nc?['date'] as String? ?? '';
        _consultTimeCtrl.text = nc?['time'] as String? ?? '';
        _consultType = nc?['type'] as String? ?? 'video';
        _targetCalCtrl.text =
            data['targetCalories']?.toString() ?? '1800';
        _targetWaterCtrl.text =
            data['targetWaterMl']?.toString() ?? '2500';
      }

      setState(() {
        _clientData = clientData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading client details: $e')),
        );
      }
    }
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
            // Header
            _buildHeader(),
            
            // Tab Bar
            _buildTabBar(),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _clientData == null
                      ? const Center(child: Text('Client not found'))
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1976D2),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              _getInitials(_clientData?['full_name'] ?? 'Unknown'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _clientData?['full_name'] ?? 'Loading...',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _clientData?['email'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
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
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Profile'),
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
          _buildSectionHeader('Personal Information'),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Full Name',
                  _clientData?['full_name'] ?? 'N/A',
                  Icons.person,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  'Email',
                  _clientData?['email'] ?? 'N/A',
                  Icons.email,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Phone',
                  _clientData?['phone'] ?? 'N/A',
                  Icons.phone,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  'Date of Birth',
                  _formatDate(_clientData?['date_of_birth']),
                  Icons.cake,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Account Information'),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Member Since',
                  _formatDate(_clientData?['created_at']),
                  Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  'Last Updated',
                  _formatDate(_clientData?['updated_at']),
                  Icons.update,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildAdminSettingsSection(),
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
              Icon(Icons.admin_panel_settings,
                  color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Admin Settings',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Next Consultation',
            style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _doctorNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Name',
                    hintText: 'e.g. Dr. Sharma',
                    prefixIcon: Icon(Icons.person, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatefulBuilder(
                  builder: (ctx, setSt) => DropdownButtonFormField<String>(
                    value: _consultType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'video', child: Text('Video')),
                      DropdownMenuItem(
                          value: 'in-person', child: Text('In-Person')),
                      DropdownMenuItem(value: 'phone', child: Text('Phone')),
                    ],
                    onChanged: (v) => setState(() => _consultType = v!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _consultDateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Date (YYYY-MM-DD)',
                    hintText: '2024-12-01',
                    prefixIcon: Icon(Icons.calendar_today, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _consultTimeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    hintText: '10:00 AM',
                    prefixIcon: Icon(Icons.access_time, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Daily Targets',
            style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _targetCalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Calories (kcal)',
                    hintText: '1800',
                    prefixIcon:
                        Icon(Icons.local_fire_department, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _targetWaterCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Water (ml)',
                    hintText: '2500',
                    prefixIcon: Icon(Icons.water_drop, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSavingSettings ? null : _saveAdminSettings,
              icon: _isSavingSettings
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(
                  _isSavingSettings ? 'Saving...' : 'Save Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAdminSettings() async {
    setState(() => _isSavingSettings = true);
    try {
      final targetCal =
          int.tryParse(_targetCalCtrl.text.trim()) ?? 1800;
      final targetWater =
          int.tryParse(_targetWaterCtrl.text.trim()) ?? 2500;
      final Map<String, dynamic> updateData = {
        'targetCalories': targetCal,
        'targetWaterMl': targetWater,
      };
      if (_doctorNameCtrl.text.trim().isNotEmpty) {
        updateData['nextConsultation'] = {
          'doctorName': _doctorNameCtrl.text.trim(),
          'date': _consultDateCtrl.text.trim(),
          'time': _consultTimeCtrl.text.trim(),
          'type': _consultType,
        };
      }
      await FirebaseService.instance.clients
          .doc(widget.clientId)
          .set(updateData, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client settings saved ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSavingSettings = false);
    }
  }

  Widget _buildSubscriptionTab() {
    final subscriptions = _clientData?['subscriptions'] as List? ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Active Subscriptions'),
          const SizedBox(height: 16),
          
          if (subscriptions.isEmpty)
            const Center(
              child: Text(
                'No subscription found',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...subscriptions.map((subscription) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subscription['diet_plans']?['title'] ?? 'Custom Plan',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(subscription['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          subscription['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(subscription['status']),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Fee',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '₹${subscription['monthly_fee'] ?? '0'}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Date',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              _formatDate(subscription['start_date']),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End Date',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              _formatDate(subscription['end_date']),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (subscription['notes'] != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Notes',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      subscription['notes'],
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ],
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildMeasurementsTab() {
    final measurements = _clientData?['client_measurements'] as List? ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Body Measurements'),
          const SizedBox(height: 16),
          
          if (measurements.isEmpty)
            const Center(
              child: Text(
                'No measurements recorded',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: measurements.length,
              itemBuilder: (context, index) {
                final measurement = measurements[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getMeasurementIcon(measurement['measurement_type']),
                        color: const Color(0xFF1976D2),
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${measurement['value']} ${_getMeasurementUnit(measurement['measurement_type'])}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        measurement['measurement_type']?.toString().toUpperCase() ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    final foodLogs = _clientData?['food_logs'] as List? ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Recent Food Logs'),
          const SizedBox(height: 16),
          
          if (foodLogs.isEmpty)
            const Center(
              child: Text(
                'No activity recorded',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...foodLogs.take(10).map((log) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getMealIcon(log['meal_type']),
                      color: const Color(0xFF1976D2),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log['food_name'] ?? 'Unknown Food',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${log['meal_type']?.toString().toUpperCase() ?? ''} • ${log['calories']} calories',
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(log['logged_at']),
                    style: GoogleFonts.inter(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildCheckInsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.instance.weeklyUpdates
          .where('clientId', isEqualTo: widget.clientId)
          .orderBy('submittedAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in_outlined,
                    size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('No check-ins yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                SizedBox(height: 6),
                Text('Weekly check-ins will appear here',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final submittedAt = data['submittedAt'] as Timestamp?;
            final date = submittedAt?.toDate();
            final dateStr = date != null
                ? '${date.day}/${date.month}/${date.year}'
                : 'Unknown date';
            final weight = data['weight'];
            final notes = data['notes'] as String? ?? '';
            // Extra fields to display
            final extraKeys = data.keys
                .where((k) => !['clientId', 'submittedAt', 'weight', 'notes']
                    .contains(k))
                .toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateStr,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1976D2),
                          fontSize: 14,
                        ),
                      ),
                      if (weight != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Text(
                            '$weight kg',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      notes,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                  if (extraKeys.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: extraKeys.map((k) {
                        final v = data[k];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$k: $v',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.blue[700]),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    return name
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .take(2)
        .join('');
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
      case 'suspended':
        return Colors.orange;
      case 'cancelled':
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getMeasurementIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'weight':
        return Icons.fitness_center;
      case 'height':
        return Icons.height;
      case 'chest':
      case 'waist':
      case 'hips':
        return Icons.straighten;
      default:
        return Icons.analytics;
    }
  }

  String _getMeasurementUnit(String? type) {
    switch (type?.toLowerCase()) {
      case 'weight':
        return 'kg';
      case 'height':
        return 'cm';
      case 'chest':
      case 'waist':
      case 'hips':
      case 'arms':
      case 'thighs':
        return 'cm';
      case 'body_fat':
      case 'muscle_mass':
        return '%';
      default:
        return '';
    }
  }

  IconData _getMealIcon(String? mealType) {
    switch (mealType?.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'lunch':
        return Icons.wb_sunny_outlined;
      case 'dinner':
        return Icons.nightlight;
      case 'snack':
        return Icons.local_cafe;
      default:
        return Icons.restaurant;
    }
  }
}