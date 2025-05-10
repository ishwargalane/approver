import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:approver/models/approval_request.dart';
import 'package:approver/services/notification_service.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

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
      
      // Get the updated request to include in notification
      ApprovalRequest? request = await getApprovalRequest(requestId);
      if (request != null) {
        // Show a notification about the status change
        await _notificationService.showLocalNotification(
          title: 'Request Status Updated',
          body: 'Request "${request.title}" is now ${status.toString().split('.').last}',
          payload: '{"type": "status_update", "requestId": "$requestId", "status": "${status.toString().split('.').last}"}',
        );
      }
    } catch (e) {
      print('Error updating approval status: $e');
      throw e;
    }
  }

  // Create a new approval request (used by the Python client)
  Future<String> createApprovalRequest(ApprovalRequest request) async {
    try {
      DocumentReference docRef = await _approvalsCollection.add(request.toMap());
      
      // Update the request with its ID
      String requestId = docRef.id;
      request = request.copyWith(id: requestId);
      
      // Show a notification for the new request
      await _notificationService.showApprovalRequestNotification(request);
      
      return requestId;
    } catch (e) {
      print('Error creating approval request: $e');
      throw e;
    }
  }
  
  // Listen for new approval requests and show notifications
  void setupApprovalRequestListener() {
    _approvalsCollection
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            // Only process newly added documents
            if (change.type == DocumentChangeType.added) {
              final request = ApprovalRequest.fromFirestore(change.doc);
              
              // Don't show notifications for requests older than 1 minute
              // This prevents showing notifications for all existing requests when the app starts
              if (request.createdAt != null) {
                final now = DateTime.now();
                final requestTime = (request.createdAt as Timestamp).toDate();
                final difference = now.difference(requestTime).inMinutes;
                
                if (difference <= 1) {
                  _notificationService.showApprovalRequestNotification(request);
                }
              }
            }
          }
        });
  }
} 