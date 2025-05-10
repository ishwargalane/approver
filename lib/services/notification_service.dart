import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:approver/models/approval_request.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize notification settings
  Future<void> init() async {
    // Request permission for iOS devices
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Handle FCM messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Instead of showing a local notification, we'll just print the notification
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
      }
    });
  }

  // Show notification for new approval request
  Future<void> showApprovalRequestNotification(ApprovalRequest request) async {
    // For now, we'll just print the notification
    print('New Approval Request: ${request.title}');
    print('From: ${request.requesterEmail}');
  }

  // Subscribe to topic (for FCM)
  Future<void> subscribeToApprovalRequests() async {
    await _firebaseMessaging.subscribeToTopic('approval_requests');
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromApprovalRequests() async {
    await _firebaseMessaging.unsubscribeFromTopic('approval_requests');
  }
} 