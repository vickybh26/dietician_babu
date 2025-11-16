import 'package:supabase_flutter/supabase_flutter.dart';

class ClientManagementService {
  static final _supabase = Supabase.instance.client;

  // Get all clients with their subscription info
  static Future<List<Map<String, dynamic>>> getAllClients({
    String? status,
    String? searchQuery,
  }) async {
    try {
      var query = _supabase
          .from('profiles')
          .select('''
            id,
            full_name,
            email,
            phone,
            date_of_birth,
            created_at,
            updated_at,
            subscriptions (
              id,
              status,
              start_date,
              end_date,
              monthly_fee,
              diet_plans (title)
            )
          ''')
          .eq('role', 'client');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('full_name.ilike.%$searchQuery%,email.ilike.%$searchQuery%');
      }

      final response = await query.order('created_at', ascending: false);

      // Filter by subscription status if provided
      if (status != null) {
        return response.where((client) {
          final subscriptions = client['subscriptions'] as List?;
          if (subscriptions == null || subscriptions.isEmpty) {
            return status == 'inactive';
          }
          return subscriptions.any((sub) => sub['status'] == status);
        }).toList();
      }

      return response;
    } catch (e) {
      throw Exception('Failed to fetch clients: $e');
    }
  }

  // Get pending client approvals
  static Future<List<Map<String, dynamic>>> getPendingApprovals() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('''
            id,
            full_name,
            email,
            phone,
            date_of_birth,
            created_at,
            subscriptions (
              id,
              status,
              plan_id,
              diet_plans (title, calories_per_day)
            )
          ''')
          .eq('role', 'client')
          .is_('updated_at', null)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      throw Exception('Failed to fetch pending approvals: $e');
    }
  }

  // Approve client
  static Future<bool> approveClient(String clientId) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', clientId);

      // Activate their subscription if exists
      await _supabase
          .from('subscriptions')
          .update({'status': 'active'})
          .eq('client_id', clientId);

      return true;
    } catch (e) {
      throw Exception('Failed to approve client: $e');
    }
  }

  // Reject client
  static Future<bool> rejectClient(String clientId, String reason) async {
    try {
      // Update subscription to cancelled
      await _supabase
          .from('subscriptions')
          .update({
            'status': 'cancelled',
            'notes': 'Rejected: $reason'
          })
          .eq('client_id', clientId);

      return true;
    } catch (e) {
      throw Exception('Failed to reject client: $e');
    }
  }

  // Update client status
  static Future<bool> updateClientStatus(String clientId, String status) async {
    try {
      await _supabase
          .from('subscriptions')
          .update({'status': status})
          .eq('client_id', clientId);

      return true;
    } catch (e) {
      throw Exception('Failed to update client status: $e');
    }
  }

  // Get client detailed profile
  static Future<Map<String, dynamic>?> getClientProfile(String clientId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('''
            id,
            full_name,
            email,
            phone,
            date_of_birth,
            created_at,
            updated_at,
            subscriptions (
              id,
              status,
              start_date,
              end_date,
              monthly_fee,
              notes,
              diet_plans (title, description, calories_per_day, plan_image_url)
            ),
            client_measurements (
              id,
              measurement_type,
              value,
              recorded_at
            ),
            food_logs (
              id,
              meal_type,
              food_name,
              calories,
              logged_at
            )
          ''')
          .eq('id', clientId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch client profile: $e');
    }
  }

  // Send message to client (mock implementation)
  static Future<bool> sendMessageToClient(String clientId, String message) async {
    try {
      // In a real app, this would integrate with email service or messaging system
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Bulk operations
  static Future<bool> bulkApproveClients(List<String> clientIds) async {
    try {
      for (String clientId in clientIds) {
        await approveClient(clientId);
      }
      return true;
    } catch (e) {
      throw Exception('Failed to bulk approve clients: $e');
    }
  }

  // Export client data
  static Future<String> exportClientData({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final clients = await getAllClients(status: status);
      
      // Generate CSV content
      StringBuffer csv = StringBuffer();
      csv.writeln('Name,Email,Phone,Status,Subscription Plan,Monthly Fee,Start Date');
      
      for (var client in clients) {
        final subscriptions = client['subscriptions'] as List?;
        final subscription = subscriptions?.isNotEmpty == true ? subscriptions!.first : null;
        
        csv.writeln([
          client['full_name'] ?? '',
          client['email'] ?? '',
          client['phone'] ?? '',
          subscription?['status'] ?? 'No subscription',
          subscription?['diet_plans']?['title'] ?? '',
          subscription?['monthly_fee'] ?? '',
          subscription?['start_date'] ?? '',
        ].join(','));
      }
      
      return csv.toString();
    } catch (e) {
      throw Exception('Failed to export client data: $e');
    }
  }
}