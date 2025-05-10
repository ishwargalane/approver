# Notification Testing Tools

This folder includes Python scripts for testing notifications in the Approver app.

## Prerequisites

1. Python 3.x installed
2. Required Python packages:
   ```
   pip install requests PyJWT
   ```
3. Firebase service account key file (service-account-key.json)

## Scripts Overview

1. **test_notifications.py** - Basic notification test script
2. **test_approval_notification.py** - Approval request notification test script

## Testing Notifications

### Basic Notification Test

Send a simple test notification:

```bash
# To a specific device token:
python test_notifications.py --service-account service-account-key.json --token "YOUR_DEVICE_TOKEN"

# To the default topic (all devices):
python test_notifications.py --service-account service-account-key.json --topic approval_requests
```

### Approval Request Notification Test

Send a more realistic approval request notification:

```bash
# To a specific device token:
python test_approval_notification.py --service-account service-account-key.json --token "YOUR_DEVICE_TOKEN"

# To the default topic (all devices):
python test_approval_notification.py --service-account service-account-key.json --topic approval_requests

# With a custom request ID:
python test_approval_notification.py --service-account service-account-key.json --topic approval_requests --request-id "custom-123"
```

## Getting a Device Token

To get a device token from your app, look for the log message:
```
FCM Token for testing: [your-token-here]
```

This will be printed when the app starts up. You can copy this token to use in the testing scripts.

## Testing Scenarios

1. **App in Foreground**: 
   - Make sure the app is open on screen
   - Send a notification
   - Verify it appears as an in-app notification

2. **App in Background**:
   - Put the app in the background
   - Send a notification
   - Verify it appears in the system notification tray
   - Tap the notification to ensure it opens the app

3. **App Closed**:
   - Close the app completely
   - Send a notification
   - Verify it appears in the system notification tray
   - Tap the notification to ensure it launches the app
