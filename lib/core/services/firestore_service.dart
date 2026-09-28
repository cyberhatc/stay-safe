import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Future<void> saveUser({
    required String userId,
    required String name,
    required String phone,
    required String fcmToken,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'name': name,
      'phone': phone,
      'fcmToken': fcmToken,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFcmToken(String userId, String token) async {
    await _firestore.collection('users').doc(userId).update({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> createLocationRequest({
    required String requesterId,
    required String requesterName,
    required String targetUserId,
    required String type,
  }) async {
    final requestId = _uuid.v4();
    await _firestore.collection('location_requests').doc(requestId).set({
      'requesterId': requesterId,
      'requesterName': requesterName,
      'targetUserId': targetUserId,
      'type': type,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return requestId;
  }

  Future<void> respondToLocationRequest({
    required String requestId,
    required String status,
    double? latitude,
    double? longitude,
  }) async {
    await _firestore.collection('location_requests').doc(requestId).update({
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot> listenToLocationRequest(String requestId) {
    return _firestore.collection('location_requests').doc(requestId).snapshots();
  }

  Stream<QuerySnapshot> listenToPendingRequests(String userId) {
    return _firestore
        .collection('location_requests')
        .where('targetUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<String> startTrackingSession({
    required String requesterId,
    required String targetUserId,
    required String targetUserName,
  }) async {
    final sessionId = _uuid.v4();
    await _firestore.collection('tracking_sessions').doc(sessionId).set({
      'requesterId': requesterId,
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return sessionId;
  }

  Future<void> updateTrackingLocation({
    required String sessionId,
    required double latitude,
    required double longitude,
  }) async {
    await _firestore.collection('tracking_sessions').doc(sessionId).update({
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> stopTrackingSession(String sessionId) async {
    await _firestore.collection('tracking_sessions').doc(sessionId).update({
      'isActive': false,
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot> listenToTrackingSession(String sessionId) {
    return _firestore.collection('tracking_sessions').doc(sessionId).snapshots();
  }

  Stream<QuerySnapshot> listenToActiveTrackingSessions(String userId) {
    return _firestore
        .collection('tracking_sessions')
        .where('requesterId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  Future<String?> getUserFcmToken(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['fcmToken'] as String?;
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }
}
