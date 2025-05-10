import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:approver/models/app_user.dart';
import 'package:approver/screens/login_screen.dart';
import 'package:approver/screens/home_screen.dart';
import 'package:approver/services/database_service.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  final DatabaseService _databaseService = DatabaseService();
  bool _listenerInitialized = false;

  @override
  Widget build(BuildContext context) {
    // Access the user data from the provider
    final user = Provider.of<AppUser?>(context);

    // Initialize notification listener when user logs in
    if (user != null && !_listenerInitialized) {
      _databaseService.setupApprovalRequestListener();
      _listenerInitialized = true;
    }

    // Return either Home or Login screen based on authentication status
    if (user == null) {
      _listenerInitialized = false; // Reset when user logs out
      return const LoginScreen();
    } else {
      return const HomeScreen();
    }
  }
} 