# Testing Notifications in Approver App

This document provides instructions for testing the notification functionality in the Approver app.

## Prerequisites

1. You need a Firebase service account key file (JSON) for your project
2. Python 3.x installed with the following packages:
   - `requests`
   - `PyJWT`

Install required Python packages:
```
pip install requests PyJWT
```

## Step 1: Build and Run the App

1. Make sure you have enough disk space (at least 2GB free) to build the app
2. Run the app on your emulator or physical device:
   ```
   flutter run
   ```

## Step 2: Get a Device Token

There are two ways to get a device token:

### Option 1: Add Code to Print Token in App

Temporarily add this code to your app to print the FCM token:

```dart
// In NotificationService class, modify the init() method:
Future<void> init() async {
  // ... existing code ...
  
  // Get and print token
  String? token = await getToken();
  print('FCM Token: $token');
  
  // ... rest of the method ...
}
```

### Option 2: Use the Topic-based Approach

If you can't get a device token, use the topic-based approach. The app is already subscribed to the `approval_requests` topic.

## Step 3: Send a Test Notification

Use the provided Python script to send a test notification:

```bash
# To send to a specific device token:
python test_notifications.py --service-account path/to/service-account-key.json --token YOUR_DEVICE_TOKEN

# To send to the 'approval_requests' topic:
python test_notifications.py --service-account path/to/service-account-key.json --topic approval_requests
```

## Expected Behavior

- When the app is in the foreground: The notification should be displayed as a local notification
- When the app is in the background: The notification should appear in the system tray
- When the app is closed: The notification should appear in the system tray and launching it should open the app

## Troubleshooting

1. **Notification Not Showing in Foreground**: 
   - Check `NotificationService._handleForegroundMessage()` method
   - Verify that `showLocalNotification()` is being called

2. **Notification Not Showing in Background**:
   - Verify Android manifest has all required permissions 
   - Ensure the background handler is properly registered

3. **Notification Taps Not Working**:
   - Check the notification tap handlers in `NotificationService`

4. **"No space left on device" Error**:
   - Free up disk space or use a device with more available storage

5. **Firebase Configuration Issues**:
   - Verify the Firebase project is properly configured
   - Check that the correct package name is used in Firebase console (com.approverapp.approver)
   - Verify SHA-1 fingerprint is added for Google authentication 