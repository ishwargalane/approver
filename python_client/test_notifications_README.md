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

## Authentication Options

There are two ways to authenticate with Firebase:

### Option 1: Service Account Key File

1. Download a service account key file from the Firebase Console
2. Save it as `service-account-key.json` in this directory
3. Pass the path to the file when running the scripts

```bash
python test_notifications.py --service-account service-account-key.json --topic approval_requests
```

### Option 2: Environment Variables (Recommended for Security)

You can use environment variables instead of storing the service account key in a file:

```bash
# Required variables
export FIREBASE_PROJECT_ID='your-project-id'
export FIREBASE_PRIVATE_KEY='-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n'
export FIREBASE_CLIENT_EMAIL='firebase-adminsdk-xxxx@your-project.iam.gserviceaccount.com'

# Optional variables
export FIREBASE_PRIVATE_KEY_ID='private-key-id'
export FIREBASE_CLIENT_ID='client-id'
export FIREBASE_CLIENT_X509_CERT_URL='cert-url'
```

Then run the scripts without the service account parameter:

```bash
python test_notifications.py --topic approval_requests
```

For help with environment variables, run:

```bash
python test_notifications.py --env-help
```
