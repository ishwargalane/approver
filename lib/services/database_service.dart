import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:approver/models/approval_request.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  final CollectionReference _approvalsCollection = 
      FirebaseFirestore.instance.collection('approvals');

  // Get all approval requests for a user (assigned to them)
  Stream<List<ApprovalRequest>> getApprovalRequests() {
    return _approvalsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => 
                ApprovalRequest.fromFirestore(doc)).toList());
  }

  // Get approval requests with pending status
  Stream<List<ApprovalRequest>> getPendingApprovalRequests() {
    return _approvalsCollection
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => 
                ApprovalRequest.fromFirestore(doc)).toList());
  }

  // Get a specific approval request
  Future<ApprovalRequest?> getApprovalRequest(String requestId) async {
    try {
      DocumentSnapshot doc = await _approvalsCollection.doc(requestId).get();
      if (doc.exists) {
        return ApprovalRequest.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting approval request: $e');
      return null;
    }
  }

  // Update approval request status
  Future<void> updateApprovalStatus(String requestId, ApprovalStatus status) async {
    try {
      await _approvalsCollection.doc(requestId).update({
        'status': status.toString().split('.').last,
      });
    } catch (e) {
      print('Error updating approval status: $e');
      throw e;
    }
  }

  // Create a new approval request (used by the Python client)
  Future<String> createApprovalRequest(ApprovalRequest request) async {
    try {
      DocumentReference docRef = await _approvalsCollection.add(request.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating approval request: $e');
      throw e;
    }
  }
} 