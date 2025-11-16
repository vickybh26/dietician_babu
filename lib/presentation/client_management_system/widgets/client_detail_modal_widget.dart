import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/client_management_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadClientDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClientDetails() async {
    try {
      setState(() => _isLoading = true);
      final clientData = await ClientManagementService.getClientProfile(widget.clientId);
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
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Profile'),
          Tab(text: 'Subscription'),
          Tab(text: 'Measurements'),
          Tab(text: 'Activity'),
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
        ],
      ),
    );
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