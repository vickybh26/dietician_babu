import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

/// Full CRUD service for Phase 1 Client Profile tabs.
/// Firestore schema:
///   clients/{uid}                         — health profile (existing)
///   clients/{uid}/progressEntries/{id}    — weight/BMI log  ← NEW
///   clients/{uid}/notes/{id}              — admin notes      ← NEW
///   users/{uid}                           — identity (existing)
///   plans/{planId}  (clientId == uid)     — assigned plans (existing)
///   weeklyUpdates   (clientId == uid)     — client-submitted check-ins (existing)
class ClientProfileService {
  static final _fs = FirebaseService.instance;

  // ─── Subcollection refs ───────────────────────────────────────────────────

  static CollectionReference<Map<String, dynamic>> progressEntries(String uid) =>
      _fs.clients.doc(uid).collection('progressEntries');

  static CollectionReference<Map<String, dynamic>> clientNotes(String uid) =>
      _fs.clients.doc(uid).collection('notes');

  // ─── Full profile fetch ───────────────────────────────────────────────────

  /// Merges users/{uid} + clients/{uid} into one map.
  static Future<Map<String, dynamic>> getFullProfile(String uid) async {
    final userSnap = await _fs.users.doc(uid).get();
    final clientSnap = await _fs.clients.doc(uid).get();

    final data = <String, dynamic>{'uid': uid};
    if (userSnap.exists) data.addAll(userSnap.data()!);
    if (clientSnap.exists) data.addAll(clientSnap.data()!);
    return data;
  }

  /// Update personal info fields that live in users/{uid}
  static Future<void> updatePersonalInfo(
      String uid, Map<String, dynamic> updates) async {
    await _fs.users.doc(uid).set(updates, SetOptions(merge: true));
  }

  /// Update health profile fields that live in clients/{uid}
  static Future<void> updateHealthProfile(
      String uid, Map<String, dynamic> updates) async {
    await _fs.clients.doc(uid).set(updates, SetOptions(merge: true));
  }

  // ─── Progress Entries ─────────────────────────────────────────────────────

  /// Streams progress entries for a client, newest first.
  static Stream<List<Map<String, dynamic>>> streamProgressEntries(String uid) {
    return progressEntries(uid)
        .orderBy('entryDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final m = d.data();
              m['id'] = d.id;
              return m;
            }).toList());
  }

  /// Streams weekly check-ins from client app (weightKg, mood, adherence).
  static Stream<List<Map<String, dynamic>>> streamWeeklyCheckins(String uid) {
    return _fs.weeklyUpdates
        .where('clientId', isEqualTo: uid)
        .orderBy('submittedAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final m = d.data();
              m['id'] = d.id;
              return m;
            }).toList());
  }

  /// Add a manual progress entry (admin-entered measurements).
  static Future<void> addProgressEntry(
      String uid, Map<String, dynamic> entry) async {
    entry['recordedAt'] = FieldValue.serverTimestamp();
    entry['source'] = 'admin';
    await progressEntries(uid).add(entry);
  }

  /// Update an existing progress entry.
  static Future<void> updateProgressEntry(
      String uid, String entryId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await progressEntries(uid).doc(entryId).update(updates);
  }

  /// Delete a progress entry.
  static Future<void> deleteProgressEntry(
      String uid, String entryId) async {
    await progressEntries(uid).doc(entryId).delete();
  }

  // ─── Admin Notes ──────────────────────────────────────────────────────────

  /// Streams notes for a client, newest first.
  static Stream<List<Map<String, dynamic>>> streamNotes(String uid) {
    return clientNotes(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final m = d.data();
              m['id'] = d.id;
              return m;
            }).toList());
  }

  /// Add a new note.
  static Future<void> addNote(
      String uid, String content, String category) async {
    await clientNotes(uid).add({
      'content': content,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': 'admin',
    });
  }

  /// Update an existing note.
  static Future<void> updateNote(
      String uid, String noteId, String content, String category) async {
    await clientNotes(uid).doc(noteId).update({
      'content': content,
      'category': category,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a note.
  static Future<void> deleteNote(String uid, String noteId) async {
    await clientNotes(uid).doc(noteId).delete();
  }

  // ─── Diet Plans ───────────────────────────────────────────────────────────

  /// Streams all plans assigned to a client.
  static Stream<List<Map<String, dynamic>>> streamClientPlans(String uid) {
    return _fs.plans
        .where('clientId', isEqualTo: uid)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final m = d.data();
              m['id'] = d.id;
              return m;
            }).toList());
  }

  /// Unassign / soft-delete a plan from a client (set status = 'archived').
  static Future<void> archivePlan(String planId) async {
    await _fs.plans.doc(planId).update({'status': 'archived'});
  }

  /// Set a plan as the active plan for a client.
  static Future<void> setActivePlan(String uid, String planId) async {
    // First deactivate all plans for this client
    final snap = await _fs.plans.where('clientId', isEqualTo: uid).get();
    final batch = _fs.db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isActive': false});
    }
    batch.update(_fs.plans.doc(planId), {'isActive': true});
    await batch.commit();
  }

  // ─── Dashboard helpers ────────────────────────────────────────────────────

  /// Count of clients who have at least one active plan.
  static Future<int> countClientsWithActivePlans() async {
    try {
      final snap = await _fs.plans
          .where('isActive', isEqualTo: true)
          .get();
      final uids = snap.docs.map((d) => d.data()['clientId']).toSet();
      return uids.length;
    } catch (_) {
      return 0;
    }
  }

  /// Count of total progress entries logged this month.
  static Future<int> countProgressEntriesThisMonth() async {
    // This requires a collection group query on 'progressEntries'
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final snap = await _fs.db
          .collectionGroup('progressEntries')
          .where('recordedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }
}
