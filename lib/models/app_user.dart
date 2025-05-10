import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  factory AppUser.fromFirebaseUser(User firebaseUser) {
    // Extract username from email if displayName is empty
    String name = firebaseUser.displayName ?? '';
    if (name.isEmpty && firebaseUser.email != null) {
      // Use the part of the email before @ as fallback display name
      name = firebaseUser.email!.split('@').first;
    }
    
    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: name,
      photoUrl: firebaseUser.photoURL,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }
} 