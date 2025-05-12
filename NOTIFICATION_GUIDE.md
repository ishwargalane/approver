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

For more realistic testing that simulates production notifications, use the improved Python client:

1. Make sure you have a service account key file (JSON) from Firebase
2. Run the improved Python script:

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
   - Tapping a button updates Firestore directly without opening the app
   - The notification is automatically dismissed after action is taken

3. When the app is **closed**:
   - Behavior is the same as when in background
   - Actions work without needing to start the app

### Requirements for Action Buttons to Appear

For a notification to show action buttons, it must:

1. Have a `type` field set to `approval_request` in the FCM payload
2. Have a `requestId` field with a valid ID
3. Be constructed properly (see examples in Python scripts)

## Troubleshooting

If you're not seeing action buttons:

1. Check that the notification is properly formatted with `type` and `requestId` fields
2. Ensure the app has been built with the latest code (with notification action support)
3. Try using the `improved_approval_notification.py` script for a properly formatted notification
4. Check logs for any error messages

## Platform Notes

- **Android**: Fully supports notification actions in the background
- **iOS**: Due to iOS limitations, the experience may be different and may require opening the app

## Using in Your Own Code

If you're integrating this into your own code, ensure your FCM payload follows this format:

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