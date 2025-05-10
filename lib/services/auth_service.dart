import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:approver/models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Convert Firebase User to AppUser
  AppUser? _userFromFirebaseUser(User? user) {
    return user == null ? null : AppUser.fromFirebaseUser(user);
  }

  // Auth state change stream
  Stream<AppUser?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // Get current user
  AppUser? get currentUser {
    return _userFromFirebaseUser(_auth.currentUser);
  }

  // Sign in with email and password
  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('Signing in with email and password...');
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;
      
      if (user == null) {
        print('ERROR: Firebase user is null after sign in');
        throw 'Authentication failed';
      }
      
      print('Successfully signed in with email: ${user.email}');
      return _userFromFirebaseUser(user);
    } catch (e) {
      print('ERROR signing in with email/password: $e');
      
      // Provide user-friendly error messages
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw 'No user found with this email';
          case 'wrong-password':
            throw 'Wrong password provided';
          case 'invalid-email':
            throw 'Invalid email format';
          case 'user-disabled':
            throw 'This account has been disabled';
          default:
            throw 'Authentication failed: ${e.message}';
        }
      } else {
        rethrow;
      }
    }
  }

  // Register with email and password
  Future<AppUser?> registerWithEmailAndPassword(String email, String password) async {
    try {
      print('Registering with email and password...');
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;
      
      if (user == null) {
        print('ERROR: Firebase user is null after registration');
        throw 'Registration failed';
      }
      
      print('Successfully registered with email: ${user.email}');
      return _userFromFirebaseUser(user);
    } catch (e) {
      print('ERROR registering with email/password: $e');
      
      // Provide user-friendly error messages
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            throw 'Email is already in use';
          case 'weak-password':
            throw 'Password is too weak';
          case 'invalid-email':
            throw 'Invalid email format';
          default:
            throw 'Registration failed: ${e.message}';
        }
      } else {
        rethrow;
      }
    }
  }

  // Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    try {
      print('Starting Google Sign In process...');
      
      // Force a fresh sign-in flow each time
      await _googleSignIn.signOut();
      print('Previous Google Sign In session cleared');
      
      // Check if there's a client ID available
      final clientId = _googleSignIn.clientId;
      print('Google Sign In Client ID: ${clientId ?? "Not configured"}');
      
      print('Requesting Google Sign In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('Google Sign In was canceled by user or failed silently');
        return null;
      }

      print('Google Sign In successful: ${googleUser.email}, ${googleUser.displayName}');
      
      try {
        print('Requesting Google authentication tokens...');
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        print('Access token received: ${googleAuth.accessToken != null ? "Yes" : "No"}');
        print('ID token received: ${googleAuth.idToken != null ? "Yes" : "No"}');
        
        if (googleAuth.accessToken == null || googleAuth.idToken == null) {
          print('ERROR: Google authentication tokens missing');
          throw 'Google authentication failed: missing tokens';
        }
        
        print('Creating Firebase credential from Google tokens...');
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        print('Signing in to Firebase with Google credential...');
        final UserCredential authResult = await _auth.signInWithCredential(credential);
        final User? user = authResult.user;

        if (user == null) {
          print('ERROR: Firebase user is null after sign in');
          throw 'Firebase authentication failed';
        }
        
        print('Successfully signed in with Firebase: ${user.displayName}, ${user.email}');
        return _userFromFirebaseUser(user);
      } catch (e) {
        print('ERROR during Google/Firebase credential exchange: $e');
        rethrow;
      }
    } catch (e) {
      print('ERROR signing in with Google: $e');
      
      // Provide more specific error messages
      if (e.toString().contains('network_error')) {
        throw 'Network error occurred. Please check your internet connection.';
      } else if (e.toString().contains('10:')) {
        throw 'Developer error: SHA-1 certificate fingerprint (FF:07:EB:5D:05:82:2B:04:93:D4:28:58:7A:4E:A6:B5:13:EB:A3:47) needs to be registered in Firebase Console.';
      } else {
        rethrow;
      }
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('ERROR sending password reset email: $e');
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-email':
            throw 'Invalid email format';
          case 'user-not-found':
            throw 'No user found with this email';
          default:
            throw 'Password reset failed: ${e.message}';
        }
      } else {
        rethrow;
      }
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      throw e;
    }
  }
} 