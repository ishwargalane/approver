import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:approver/models/approval_request.dart';
import 'package:approver/firebase_options.dart';

// Handle background actions
@pragma('vm:entry-point')
Future<void> onActionReceivedBackground(NotificationResponse notificationResponse) async {
  // Debug logging
  print('🔔 ACTION RECEIVED IN BACKGROUND: ${notificationResponse.actionId}');
  print('🔔 NOTIFICATION PAYLOAD: ${notificationResponse.payload}');
  print('🔔 NOTIFICATION ID: ${notificationResponse.id}');
  
  try {
    // Initialize Firebase with default options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('🔔 Firebase initialized successfully with default options');

    // Process the notification action
    await _handleAction(notificationResponse);
    
    // For debugging, always write to a special document to confirm action was received
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore.collection('debug_logs').doc('action_received').set({
        'actionId': notificationResponse.actionId,
        'timestamp': FieldValue.serverTimestamp(),
        'payload': notificationResponse.payload,
      });
      print('🔔 Debug log recorded');
    } catch (e) {
      print('🔔 Error recording debug log: $e');
    }
  } catch (e) {
    print('🔔 ERROR IN BACKGROUND ACTION HANDLER: $e');
  }
}

// Process the notification action (approve or reject)
Future<void> _handleAction(NotificationResponse notificationResponse) async {
  final String? payload = notificationResponse.payload;
  final String actionId = notificationResponse.actionId ?? '';
  
  print('🔔 Processing action: $actionId with payload: $payload');
  
  if (payload == null) {
    print('🔔 Payload is null, cannot process action');
    return;
  }
  
  try {
    final Map<String, dynamic> data = json.decode(payload);
    print('🔔 Decoded payload data: $data');
    
    final String requestId = data['requestId'] ?? '';
    
    if (requestId.isEmpty) {
      print('🔔 RequestId is empty, cannot process action');
      return;
    }
    
    print('🔔 Processing action for request: $requestId');
    
    // Connect to Firestore
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference requestRef = firestore.collection('approvals').doc(requestId);
    
    // Check if document exists
    final docSnapshot = await requestRef.get();
    if (!docSnapshot.exists) {
      print('🔔 Document does not exist: $requestId');
      return;
    }
    
    print('🔔 Document exists: ${docSnapshot.data()}');
    
    // Update the approval status based on the action
    if (actionId == 'approve') {
      await requestRef.update({
        'status': 'approved'
      });
      print('✅ Request $requestId approved from notification');
    } else if (actionId == 'reject') {
      await requestRef.update({
        'status': 'rejected'
      });
      print('❌ Request $requestId rejected from notification');
    } else {
      print('🔔 Unknown action: $actionId');
    }
  } catch (e) {
    print('🔔 Error processing notification action: $e');
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
        cancelNotification: true,
      ),
      const AndroidNotificationAction(
        'reject', 
        'Reject',
        icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        showsUserInterface: false,
        cancelNotification: true,
      ),
    ];
  }
} 