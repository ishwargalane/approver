# Approver Python Client - Quick Start Guide

This guide will help you quickly get started with the Python client scripts for testing your Approver app.

## Prerequisites

1. Make sure you have downloaded the service account key from Firebase:
   - Go to Firebase Console > Project Settings > Service accounts
   - Click "Generate new private key"
   - Save the JSON file as `service-account-key.json` in the `python_client` directory

2. Make sure dependencies are installed:
   ```
   pip install -r requirements.txt
   ```

## One-Step Request Creation and Monitoring

The simplest way to test your app is to use the all-in-one script that creates a request and watches for status changes:

```bash
python3 create_and_watch_request.py
```

This will:
1. Create a request with random title and description
2. Display the request ID
3. Watch the request for 10 minutes (configurable) until it's approved or rejected
4. Show real-time progress and final decision

You can also specify the request details:
```bash
python3 create_and_watch_request.py --title="Server maintenance" --description="Need approval for weekend server maintenance" --timeout=300
```

## Generate Multiple Test Requests

To quickly populate your Firestore database with multiple test approval requests:

```bash
python3 generate_test_data.py --count=5
```

This will create 5 random approval requests with different titles, descriptions, and requesters.

## Create and Monitor a Single Request

To create a single request and monitor it until it's approved or rejected:

```bash
python3 monitor_approval.py --title="Urgent approval needed" --description="This is a test request that needs immediate attention"
```

This script will:
1. Create a new approval request
2. Show a live progress bar while waiting for someone to approve/reject
3. Print the final decision when the request status changes

You can customize the timeout (default is 5 minutes):
```bash
python3 monitor_approval.py --timeout=600  # Wait for 10 minutes
```

## Watch an Existing Request

If you have an existing request ID and want to monitor its status:

```bash
python3 watch_request.py --request-id=abcd1234
```

This will monitor the specified request until its status changes or until timeout.

## Example Workflow

1. Create a request and watch for approval:
   ```bash
   python3 create_and_watch_request.py
   ```

2. Open your Approver app on your device and see the pending request

3. Approve or reject the request in your app

4. See the terminal update with the final decision!

## Advanced Usage

For more advanced testing scenarios:

1. Generate multiple requests:
   ```bash
   python3 generate_test_data.py --count=10
   ```

2. Watch a specific request from the generated batch:
   ```bash
   python3 watch_request.py --request-id=YOUR_REQUEST_ID
   ```

## Testing Notifications

In addition to the approval request generation tools, this folder includes scripts to test notifications:

### Scripts for Notification Testing

1. **test_notifications.py** - Sends basic test notifications
2. **test_approval_notification.py** - Sends simulated approval request notifications

### Testing Commands

```bash
# Send a basic notification to all devices subscribed to the topic:
python test_notifications.py --service-account service-account-key.json --topic approval_requests

# Send a notification to a specific device token:
python test_notifications.py --service-account service-account-key.json --token "YOUR_DEVICE_TOKEN"

# Send an approval request notification:
python test_approval_notification.py --service-account service-account-key.json --topic approval_requests
```

Find more details in the test_notifications_README.md file. 