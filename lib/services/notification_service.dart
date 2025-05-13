import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:approver/models/approval_request.dart';
import 'package:approver/services/notification_action_service.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

// Define a top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Need to ensure Firebase is initialized here too if using other Firebase services
  print('Handling a background message: ${message.messageId}');
  
  // You can't show visual notifications directly from this handler
  // But you can process the data and store it for later
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // Channel IDs
  static const String _channelId = 'approver_channel';
  static const String _channelName = 'Approver Notifications';
  static const String _channelDescription = 'Notifications for approval requests';
  
  // Initialization
  Future<void> init() async {
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Request permission for iOS devices
    if (Platform.isIOS || Platform.isMacOS) {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: true,
        provisional: false,
      );
      
      print('User granted permission: ${settings.authorizationStatus}');
      
      // iOS-specific setup
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      // Request permission for Android devices (Android 13+)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
        provisional: false,
      );
      
      print('User granted permission: ${settings.authorizationStatus}');
    }
    
    // Get and print token for testing
    String? token = await getToken();
    print('FCM Token for testing: $token');
    
    // Initialize local notifications
    await _initLocalNotifications();
    
    // Handle FCM messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle notification tap when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Check if app was opened from a notification
    await _checkInitialMessage();
    
    // Subscribe to approval requests topic
    await subscribeToApprovalRequests();
  }
  
  // Initialize local notifications
  Future<void> _initLocalNotifications() async {
    // Android initialization
    final AndroidInitializationSettings androidInitSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization with categories for action buttons
    final DarwinInitializationSettings iosInitSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Already requested in FCM
      requestBadgePermission: false, // Already requested in FCM
      requestSoundPermission: false, // Already requested in FCM
      notificationCategories: [
        DarwinNotificationCategory(
          'APPROVAL_REQUEST',
          actions: [
            DarwinNotificationAction.plain(
              'approve',
              'Approve',
              options: {DarwinNotificationActionOption.destructive}, // Remove foreground option
            ),
            DarwinNotificationAction.plain(
              'reject',
              'Reject',
              options: {DarwinNotificationActionOption.destructive}, // Remove foreground option
            ),
          ],
          options: {
            DarwinNotificationCategoryOption.allowAnnouncement,
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
          },
        ),
      ],
    );
    
    // Initialize settings
    final InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );
    
    // Initialize plugin with background handlers for actions
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
        _handleLocalNotificationTap(details.payload);
      },
      onDidReceiveBackgroundNotificationResponse: onActionReceivedBackground,
    );
    
    // Create the notification channel for Android
    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
        AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
    }
  }
  
  // Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification?.title}, ${message.notification?.body}');
    
    // Determine if this is an approval request by checking multiple possible fields
    bool isApprovalRequest = false;
    String requestId = '';
    
    // Check for type field
    if (message.data['type'] == 'approval_request') {
      isApprovalRequest = true;
      requestId = message.data['requestId'] ?? '';
    } 
    // Check for requestId field
    else if (message.data['requestId'] != null && message.data['requestId'].toString().isNotEmpty) {
      isApprovalRequest = true;
      requestId = message.data['requestId'] ?? '';
    }
    // Python client specific check
    else if (message.data['title']?.toString().toLowerCase().contains('approval') == true) {
      isApprovalRequest = true;
      // Generate a request ID if one doesn't exist
      requestId = message.data['requestId'] ?? 'gen-${DateTime.now().millisecondsSinceEpoch}';
    }
    
    // For debugging Python client messages
    print('Is approval request: $isApprovalRequest, Request ID: $requestId');
    print('Full message data: ${message.data}');
    
    if (message.notification != null) {
      // Show a local notification when app is in foreground
      if (isApprovalRequest) {
        // If it's an approval request, add action buttons
        showApprovalNotificationWithActions(
          title: message.notification?.title ?? 'New Approval Request',
          body: message.notification?.body ?? 'Check the app for details',
          requestId: requestId,
          payload: json.encode(message.data),
        );
      } else {
        // Regular notification without actions
        showLocalNotification(
          title: message.notification?.title ?? 'New Notification',
          body: message.notification?.body ?? 'Check the app for details',
          payload: json.encode(message.data),
        );
      }
    } else if (message.data.isNotEmpty) {
      // If there's no notification but there is data, create a notification from data
      final String title = message.data['title'] ?? 'New Notification';
      final String body = message.data['body'] ?? 'Check the app for details';
      
      if (isApprovalRequest) {
        // If it's an approval request, add action buttons
        showApprovalNotificationWithActions(
          title: title,
          body: body,
          requestId: requestId,
          payload: json.encode(message.data),
        );
      } else {
        // Regular notification without actions
        showLocalNotification(
          title: title,
          body: body,
          payload: json.encode(message.data),
        );
      }
    }
  }
  
  // Show regular local notification without actions
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      visibility: NotificationVisibility.public,
      enableLights: true,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
    );
    
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    
    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, // Random ID based on current time
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
  
  // Show approval notification with approve/reject actions
  Future<void> showApprovalNotificationWithActions({
    required String title,
    required String body,
    required String requestId,
    String? payload,
  }) async {
    // Create a proper payload with requestId if not provided
    final String finalPayload = payload ?? json.encode({
      'requestId': requestId, 
      'type': 'approval_request',
    });
    
    // Debug log the payload
    print('🔔 Showing notification with payload: $finalPayload');
    
    // Add approve/reject actions for Android
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      visibility: NotificationVisibility.public,
      enableLights: true,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      category: AndroidNotificationCategory.message,
      fullScreenIntent: true,
      actions: NotificationActionService.getApprovalActions(),
    );
    
    // iOS notification with category for actions
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: 'APPROVAL_REQUEST', // Link to the category defined in initialization
    );
    
    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Use the request ID as part of the notification ID to ensure uniqueness
    // Convert the ID to an integer (hash code) since notification IDs must be integers
    int notificationId = requestId.hashCode;
    if (notificationId < 0) notificationId = -notificationId; // Ensure positive
    
    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformDetails,
      payload: finalPayload,
    );
  }
  
  // Check if app was opened from a notification
  Future<void> _checkInitialMessage() async {
    // Get any message that caused the app to open
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }
  
  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    // Navigate to appropriate screen
    // This will typically be handled in your app's main.dart or wrapper
  }
  
  // Handle local notification tap
  void _handleLocalNotificationTap(String? payload) {
    if (payload != null) {
      try {
        final Map<String, dynamic> data = json.decode(payload);
        print('Local notification tapped with data: $data');
        // Navigate to appropriate screen
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }
  
  // Get FCM token for this device
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
  
  // Show notification for new approval request
  Future<void> showApprovalRequestNotification(ApprovalRequest request) async {
    await showApprovalNotificationWithActions(
      title: 'New Approval Request: ${request.title}',
      body: 'From: ${request.requesterEmail}',
      requestId: request.id,
      payload: json.encode({
        'type': 'approval_request',
        'requestId': request.id,
        'title': request.title,
        'requesterEmail': request.requesterEmail,
      }),
    );
  }
  
  // Subscribe to topic (for FCM)
  Future<void> subscribeToApprovalRequests() async {
    await _firebaseMessaging.subscribeToTopic('approval_requests');
    print('Subscribed to approval_requests topic');
  }
  
  // Unsubscribe from topic
  Future<void> unsubscribeFromApprovalRequests() async {
    await _firebaseMessaging.unsubscribeFromTopic('approval_requests');
    print('Unsubscribed from approval_requests topic');
  }
  
  // For testing notifications manually from within the app
  Future<void> testManualNotification() async {
    // Alternate between two types of notifications from Python client
    if (DateTime.now().second % 2 == 0) {
      await simulateApprovalRequestNotification();
    } else {
      await simulateGenericTestNotification();
    }
  }
  
  // Simulates the test_notifications.py script from Python client
  Future<void> simulateGenericTestNotification() async {
    final Map<String, dynamic> dataPayload = {
      'type': 'test',
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
    };
    
    await showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from Firebase Cloud Messaging',
      payload: json.encode(dataPayload),
    );
    
    print('Simulated generic test notification (test_notifications.py)');
  }
  
  // Simulates the test_approval_notification.py script from Python client
  Future<void> simulateApprovalRequestNotification() async {
    final String requestId = 'test-${DateTime.now().millisecondsSinceEpoch}';
    final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Create a Firestore document for the test request
    try {
      await FirebaseFirestore.instance.collection('approvals').doc(requestId).set({
        'title': 'Test Approval',
        'description': 'This is a test approval request',
        'requesterEmail': 'test@example.com',
        'requesterId': 'app-client',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending'
      });
      print('Created Firestore document for test notification: $requestId');
    } catch (e) {
      print('Error creating Firestore document: $e');
    }
    
    final Map<String, dynamic> dataPayload = {
      'type': 'approval_request',
      'requestId': requestId,
      'title': 'Test Approval',
      'description': 'This is a test approval request',
      'requesterEmail': 'test@example.com',
      'createdAt': timestamp.toString(),
      'click_action': 'FLUTTER_NOTIFICATION_CLICK'
    };
    
    await showApprovalNotificationWithActions(
      title: 'New Approval Request',
      body: 'Please review the request from test@example.com',
      requestId: requestId,
      payload: json.encode(dataPayload),
    );
    
    print('Simulated approval request notification with document ID: $requestId');
  }
} 