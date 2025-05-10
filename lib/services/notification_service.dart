import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:approver/models/approval_request.dart';
import 'dart:io';
import 'dart:convert';

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
    
    // iOS initialization
    final DarwinInitializationSettings iosInitSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Already requested in FCM
      requestBadgePermission: false, // Already requested in FCM
      requestSoundPermission: false, // Already requested in FCM
    );
    
    // Initialize settings
    final InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );
    
    // Initialize plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
        _handleLocalNotificationTap(details.payload);
      },
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
          importance: Importance.high,
        ),
      );
    }
  }
  
  // Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
    
    if (message.notification != null) {
      // Show a local notification when app is in foreground
      showLocalNotification(
        title: message.notification?.title ?? 'New Approval Request',
        body: message.notification?.body ?? 'Check the app for details',
        payload: json.encode(message.data),
      );
    } else if (message.data.isNotEmpty) {
      // If there's no notification but there is data, create a notification from data
      final String title = message.data['title'] ?? 'New Approval Request';
      final String body = message.data['body'] ?? 'Check the app for details';
      
      showLocalNotification(
        title: title,
        body: body,
        payload: json.encode(message.data),
      );
    }
  }
  
  // Show local notification - made public so it can be called from other services
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
    );
    
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
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
    await showLocalNotification(
      title: 'New Approval Request: ${request.title}',
      body: 'From: ${request.requesterEmail}',
      payload: json.encode({
        'type': 'approval_request',
        'requestId': request.id,
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
} 