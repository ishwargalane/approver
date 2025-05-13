# Notification Guide for Approver App

This guide explains how to test notifications with actionable approve/reject buttons in the Approver app.

## Types of Notifications

The app supports two types of notifications:

1. **Regular notifications** - Basic notifications without action buttons
2. **Approval Request notifications** - Enhanced notifications with Approve/Reject action buttons

## Testing Notifications

### Using the Test Button in the App

The simplest way to test notifications is to use the bell icon (🔔) in the app:

1. Open the Approver app
2. Press the bell icon (floating action button) 
3. The app will alternate between two types of test notifications:
   - Regular test notification
   - Approval request notification with Approve/Reject buttons

### Testing with the Python Client

For more realistic testing that simulates production notifications, use the improved Python script:

```bash
python python_client/improved_approval_notification.py --service-account path/to/service-account-key.json
```

To test with a specific device token:

```bash
python python_client/improved_approval_notification.py --service-account path/to/service-account-key.json --token YOUR_FCM_TOKEN
```

To get your FCM token, look for the "FCM Token for testing" log message in the console when the app starts.

## Notification Actions

### How Approve/Reject Buttons Work

For approval request notifications:

1. When the app is in the **foreground**:
   - The notification will show in the system tray
   - You need to tap the notification to open the app
   - Approve/Reject from within the app

2. When the app is in the **background**:
   - Notification shows in the system tray with Approve/Reject buttons
   - Tapping a button should update Firestore directly without opening the app
   - The notification should be automatically dismissed after action is taken

3. When the app is **closed**:
   - Behavior is the same as when in background
   - Actions should work without needing to start the app

### Requirements for Action Buttons to Appear

For a notification to show action buttons, it must:

1. Have a `type` field set to `approval_request` in the FCM payload
2. Have a `requestId` field with a valid ID
3. Be sent properly with the correct payload structure
4. Have a corresponding document in Firestore with the same ID

## Current Known Issues and Workarounds

### Action Buttons Not Working

If you see the action buttons but tapping them has no effect:

1. **iOS Limitations**: iOS handles notification actions differently from Android. For iOS, you might need to:
   - Use the UNNotificationServiceExtension to handle background actions
   - Implement a notification content extension for custom UI

2. **Background Processing**: Ensure background processing is properly enabled:
   - Check that Firebase is properly initialized in the background handler
   - Verify the Firestore document exists and has the correct permissions
   - Make sure your device has network connectivity when tapping the action button

### Troubleshooting Steps

If the action buttons don't work:

1. **Check Logs**: Enable verbose logging in your device/emulator
2. **Test In-App Actions**: Use the in-app approval interface to confirm permissions are correct
3. **Verify Document**: Check that the Firestore document exists and is properly structured
4. **Network State**: Ensure the device has network connectivity

### Manual Testing

If you want to verify the action logic works:

1. Create a test document in Firestore with status "pending"
2. Use the app to approve/reject directly (not via notification)
3. Verify the document status updates correctly

## Platform Notes

- **Android**: Fully supports notification actions in the background
- **iOS**: Due to iOS limitations, full background notification action support may require additional implementation of notification service extensions

## To Fix Current Issues

For developers working on fixing the notification action issues:

1. Verify the VM entry point annotations are correct
2. Check Firebase initialization in background handlers
3. Ensure proper error handling for background actions
4. Consider implementing a notification service extension for iOS

```json
{
  "notification": {
    "title": "Your notification title",
    "body": "Your notification body"
  },
  "data": {
    "type": "approval_request",
    "requestId": "your-unique-request-id",
    "title": "Request title",
    "description": "Request description",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

The `type` and `requestId` fields are essential for the action buttons to appear. 