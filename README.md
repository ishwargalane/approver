# Approver

A Flutter application for managing approval requests with Firebase integration.

## Features

- Sign in with Google
- View pending approval requests
- Approve or reject requests
- Receive notifications for new requests
- Python client for submitting approval requests

## Setup

### Flutter App Setup

1. **Firebase Project Setup**

   - Create a new Firebase project at [console.firebase.google.com](https://console.firebase.google.com/)
   - Enable Firestore database
   - Set up Authentication and enable Google Sign-in

2. **Configure Firebase in Flutter**

   - Install FlutterFire CLI:
     ```
     dart pub global activate flutterfire_cli
     ```
   - Configure Firebase:
     ```
     flutterfire configure --project=your-firebase-project-id
     ```
   - This will generate the necessary configuration files for Android/iOS

3. **Run the App**

   - Install dependencies:
     ```
     flutter pub get
     ```
   - Run the app:
     ```
     flutter run
     ```

### Android Setup

1. **Configure Android**

   - Update `android/app/build.gradle` with your package name and applicationId
   - Ensure `minSdkVersion` is set to 21 or higher in `android/app/build.gradle`
   - Add Google Services plugin in `android/build.gradle`

2. **Google Sign-In Setup**

   - Follow the instructions at [Google Sign-In for Android](https://developers.google.com/identity/sign-in/android/start-integrating)
   - Add your SHA-1 key to Firebase project settings

### Python Client Setup

1. **Firebase Admin SDK**

   - Generate a new private key for your service account in Firebase Project Settings > Service Accounts
   - Save the JSON file securely

2. **Install Dependencies**

   ```
   cd python_client
   pip install -r requirements.txt
   ```

3. **Use the Client**

   ```
   # Create a new request
   python approval_client.py --credentials=/path/to/credentials.json create --title="New Request" --description="Request description" --requester-id="user123" --requester-email="user@example.com"
   
   # Check request status
   python approval_client.py --credentials=/path/to/credentials.json check --request-id=YOUR_REQUEST_ID
   ```

## Firestore Data Structure

The application uses the following Firestore structure:

```
/approvals/{document_id}
  - title: string
  - description: string
  - requesterId: string
  - requesterEmail: string
  - createdAt: timestamp
  - status: string (pending/approved/rejected)
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
