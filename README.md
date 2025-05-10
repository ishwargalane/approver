# Approver

A Flutter application for managing approval requests with Firebase integration. This app allows users to submit requests for approval, view pending requests, and approve or reject them.

## Features

- User authentication (Email/Password and Google Sign-In)
- Dashboard view of all approval requests
- Detailed request viewing with approval/rejection capability
- Firestore database integration for real-time updates
- Python client toolkit for testing and automation

## Getting Started

This guide will help you set up the Approver app for development.

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) (stable channel)
- [Firebase account](https://firebase.google.com/)
- [Git](https://git-scm.com/)
- [Python](https://www.python.org/) 3.7+ (for testing tools)

### 1. Clone the Repository

```bash
git clone https://github.com/ishwargalane/approver.git
cd approver
```

### 2. Firebase Project Setup

1. **Create a Firebase Project**:
   - Go to the [Firebase Console](https://console.firebase.google.com/)
   - Click "Add project" and follow the setup wizard
   - Enable Google Analytics if desired

2. **Enable Authentication Methods**:
   - In the Firebase Console, go to Authentication > Sign-in method
   - Enable Email/Password
   - Enable Google Sign-in
   
3. **Set Up Firestore Database**:
   - Go to Firestore Database in the Firebase Console
   - Create a database (start in test mode for development)
   - Choose a location close to your users

4. **Register Your App**:
   - In the Firebase project settings, add a new Android/iOS app
   - Use package name `com.approverapp.approver` for Android
   - Download the google-services.json file (for Android) or GoogleService-Info.plist (for iOS)

5. **Add Security Rules**:
   - Copy and paste the following rules into Firestore Rules:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /approvals/{approvalId} {
         allow read: if request.auth != null;
         allow create: if request.auth != null;
         allow update: if request.auth != null;
         allow delete: if request.auth != null && resource.data.requesterId == request.auth.uid;
       }
     }
   }
   ```

### 3. Flutter App Configuration

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Configure Firebase for Flutter**:
   - Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
   
   - Configure Firebase:
   ```bash
   flutterfire configure --project=your-firebase-project-id
   ```
   - Select the platforms you want to support

3. **Android-specific Setup**:
   - Place the google-services.json in android/app/
   - Get your SHA-1 fingerprint:
   ```bash
   cd android && ./gradlew signingReport
   ```
   - Add the SHA-1 fingerprint to your Firebase project in Project Settings > Your Apps > Android Apps > Add fingerprint

4. **iOS-specific Setup**:
   - Place the GoogleService-Info.plist in ios/Runner/
   - Update iOS deployment target to 12.0 or higher in Xcode

5. **Run the App**:
   ```bash
   flutter run
   ```

### 4. Python Testing Tools Setup

The project includes Python scripts for testing and generating sample requests:

1. **Set Up Firebase Admin SDK**:
   - Go to Firebase Console > Project Settings > Service Accounts
   - Click "Generate new private key"
   - Save the JSON file as `python_client/service-account-key.json`

2. **Install Dependencies**:
   ```bash
   cd python_client
   pip install -r requirements.txt
   ```

3. **Using the Testing Tools**:
   - Create and monitor a request:
   ```bash
   python3 create_and_watch_request.py
   ```
   
   - Generate multiple test requests:
   ```bash
   python3 generate_test_data.py --count=5
   ```
   
   - Watch an existing request:
   ```bash
   python3 watch_request.py --request-id=YOUR_REQUEST_ID
   ```

   See `python_client/README_QUICK_START.md` for more details.

## Project Structure

- `lib/`: Flutter application code
  - `models/`: Data models
  - `screens/`: UI screens
  - `services/`: Firebase integration services
  - `widgets/`: Reusable UI components
- `python_client/`: Python tools for testing
- `android/`: Android-specific code
- `ios/`: iOS-specific code

## Firestore Data Structure

```
/approvals/{document_id}
  - title: string
  - description: string
  - requesterId: string
  - requesterEmail: string
  - createdAt: timestamp
  - status: string (pending/approved/rejected)
```

## Troubleshooting

- **Google Sign-In Issues**: Ensure SHA-1 fingerprint is correctly added to Firebase
- **Firebase Connection Errors**: Verify firebase_options.dart is correctly generated
- **Android Build Failures**: Check compileSdk and targetSdk versions in build.gradle.kts

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.
