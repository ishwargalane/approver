# Approver Python Client

This is a Python client for interacting with the Approver application's Firebase backend.

## Setup

1. Download a service account key from Firebase:
   - Go to Firebase Console > Project Settings > Service accounts
   - Click "Generate new private key"
   - Save the JSON file as `service-account-key.json` in this directory

2. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

## Generating Test Data

To generate test approval requests:

```
python generate_test_data.py --credentials=service-account-key.json --count=10
```

This will create 10 random approval requests in the Firestore database.

## Using the Approval Client Directly

You can also create specific approval requests using the approval_client.py script:

```
python approval_client.py --credentials=service-account-key.json create --title="Title" --description="Description" --requester-id="user1" --requester-email="user@example.com"
```

To check the status of an existing request:

```
python approval_client.py --credentials=service-account-key.json check --request-id=YOUR_REQUEST_ID
```

## Troubleshooting

If you encounter any issues:

1. Make sure your service account key is valid and has proper permissions
2. Verify that Firebase rules allow write access to the 'approvals' collection
3. Check that your Python environment has all required dependencies installed

# Approver App Testing Tools

This folder contains Python scripts for testing the Approver app, particularly the notification functionality.

## Prerequisites

1. Python 3.x installed
2. Required Python packages:
   ```
   pip install requests PyJWT
   ```
3. Firebase service account key file (service-account-key.json)

## Testing Notifications

### 1. Basic Notification Test

To send a basic test notification:

```bash
# To a specific device token:
python test_notifications.py --service-account service-account-key.json --token "YOUR_DEVICE_TOKEN"

# To the default topic (all devices):
python test_notifications.py --service-account service-account-key.json --topic approval_requests
```

### 2. Approval Request Notification Test

To send a more realistic approval request notification:

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

## Security Best Practices

For enhanced security, you can use environment variables instead of storing service account keys in files:

### Setting Up Environment Variables

1. **Using the setup script:**
   ```
   ./setup_env.sh path/to/your/service-account-key.json
   ```
   This will extract the necessary values and show you how to set them up.

2. **Manually setting variables:**
   ```
   export FIREBASE_PROJECT_ID='your-project-id'
   export FIREBASE_PRIVATE_KEY='-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n'
   export FIREBASE_CLIENT_EMAIL='firebase-adminsdk-xxxx@your-project.iam.gserviceaccount.com'
   ```

3. **Running scripts with environment variables:**
   Once environment variables are set, you can run the test scripts without specifying a service account file:
   ```
   python test_notifications.py --topic approval_requests
   ```

For more details, see `test_notifications_README.md` or run:
```
python test_notifications.py --env-help
``` 