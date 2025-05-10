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