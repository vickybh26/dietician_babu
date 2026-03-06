import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class ClientManagementService {
  static final _fs = FirebaseService.instance;

  /// Get all clients, optionally filtered by subscriptionStatus
  static Future<List<Map<String, dynamic>>> getAllClients(
      {String? status}) async {
    try {
      var query = _fs.users.where('role', isEqualTo: 'client');
      final usersSnap = await query.get();
      final List<Map<String, dynamic>> clients = [];
      for (final doc in usersSnap.docs) {
        final userData = doc.data();
        userData['uid'] = doc.id;
        final clientSnap = await _fs.clients.doc(doc.id).get();
        if (clientSnap.exists) {
          final clientData = clientSnap.data()!;
          // Filter by status if provided
          if (status != null) {
            final subStatus = clientData['subscriptionStatus'] as String? ?? 'none';
            if (subStatus != status) continue;
          }
          userData.addAll(clientData);
        } else if (status != null) {
          continue; // No profile yet, skip if filtering
        }
        final plansSnap = await _fs.plans
            .where('clientId', isEqualTo: doc.id)
            .orderBy('uploadedAt', descending: true)
            .limit(1)
            .get();
        if (plansSnap.docs.isNotEmpty) {
          userData['latestPlan'] = plansSnap.docs.first.data()['title'];
        }
        clients.add(userData);
      }
      return clients;
    } catch (e) {
      throw Exception('Failed to fetch clients: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingApprovals(
      {String? status}) async {
    final snap = await _fs.clients
        .where('subscriptionStatus', isEqualTo: status ?? 'none')
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      data['uid'] = d.id;
      return data;
    }).toList();
  }

  static Future<Map<String, dynamic>?> getClientDetails(String uid) async {
    try {
      final userSnap = await _fs.users.doc(uid).get();
      final clientSnap = await _fs.clients.doc(uid).get();
      if (!userSnap.exists) return null;
      final data = userSnap.data()!;
      data['uid'] = uid;
      if (clientSnap.exists) data.addAll(clientSnap.data()!);
      final plansSnap = await _fs.plans
          .where('clientId', isEqualTo: uid)
          .orderBy('uploadedAt', descending: true)
          .get();
      data['plans'] = plansSnap.docs.map((d) => d.data()).toList();
      final checkinsSnap = await _fs.weeklyUpdates
          .where('clientId', isEqualTo: uid)
          .orderBy('submittedAt', descending: true)
          .limit(10)
          .get();
      data['weeklyUpdates'] = checkinsSnap.docs.map((d) => d.data()).toList();
      return data;
    } catch (e) {
      throw Exception('Failed to fetch client details: $e');
    }
  }

  /// Alias used by client_detail_modal_widget
  static Future<Map<String, dynamic>?> getClientProfile(String uid) =>
      getClientDetails(uid);

  static Future<bool> approveClient(String uid) async {
    await _fs.clients
        .doc(uid)
        .set({'subscriptionStatus': 'approved'}, SetOptions(merge: true));
    return true;
  }

  static Future<bool> rejectClient(String uid, [String? reason]) async {
    await _fs.clients.doc(uid).set({
      'subscriptionStatus': 'rejected',
      if (reason != null) 'rejectionReason': reason,
    }, SetOptions(merge: true));
    return true;
  }

  static Future<bool> bulkApproveClients(List<String> uids) async {
    final batch = _fs.db.batch();
    for (final uid in uids) {
      batch.set(_fs.clients.doc(uid), {'subscriptionStatus': 'approved'},
          SetOptions(merge: true));
    }
    await batch.commit();
    return true;
  }

  static Future<bool> updateClientStatus(String uid, String status) async {
    await _fs.clients
        .doc(uid)
        .set({'subscriptionStatus': status}, SetOptions(merge: true));
    return true;
  }

  static Future<bool> sendMessageToClient(String uid, String message) async {
    await _fs.db.collection('messages').add({
      'clientId': uid,
      'message': message,
      'sentAt': FieldValue.serverTimestamp(),
      'sentBy': 'admin',
      'read': false,
    });
    return true;
  }

  static Future<List<Map<String, dynamic>>> exportClientData() async =>
      getAllClients();

  static Future<void> updateClientProfile(
      String uid, Map<String, dynamic> updates) async {
    await _fs.clients.doc(uid).set(updates, SetOptions(merge: true));
  }

  static Future<void> addFollowUp(
      String clientId, DateTime scheduledAt, String notes) async {
    await _fs.followUps.add({
      'clientId': clientId,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'notes': notes,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> getFollowUps() async {
    final snap =
        await _fs.followUps.orderBy('scheduledAt', descending: false).get();
    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
  }
}
