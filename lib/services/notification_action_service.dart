import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:approver/models/approval_request.dart';

// Handle background actions
@pragma('vm:entry-point')
Future<void> onActionReceivedBackground(NotificationResponse notificationResponse) async {
  // Initialize Firebase
  await Firebase.initializeApp();

  // Process the notification action
  await _handleAction(notificationResponse);
}

// Process the notification action (approve or reject)
Future<void> _handleAction(NotificationResponse notificationResponse) async {
  final String? payload = notificationResponse.payload;
  final String actionId = notificationResponse.actionId ?? '';
  
  print('Background action received: $actionId');
  
  if (payload == null) return;
  
  try {
    final Map<String, dynamic> data = json.decode(payload);
    final String requestId = data['requestId'] ?? '';
    
    if (requestId.isEmpty) return;
    
    // Connect to Firestore
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference requestRef = firestore.collection('approvals').doc(requestId);
    
    // Update the approval status based on the action
    if (actionId == 'approve') {
      await requestRef.update({
        'status': 'approved'
      });
      print('Request $requestId approved from notification');
    } else if (actionId == 'reject') {
      await requestRef.update({
        'status': 'rejected'
      });
      print('Request $requestId rejected from notification');
    }
  } catch (e) {
    print('Error processing notification action: $e');
  }
}

class NotificationActionService {
  static const String approveAction = 'approve';
  static const String rejectAction = 'reject';
  
  // Configure notification actions
  static List<AndroidNotificationAction> getApprovalActions() {
    return [
      const AndroidNotificationAction(
        'approve', 
        'Approve',
        icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        showsUserInterface: false,
      ),
      const AndroidNotificationAction(
        'reject', 
        'Reject',
        icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        showsUserInterface: false,
      ),
    ];
  }
} 