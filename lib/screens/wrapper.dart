import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:approver/models/app_user.dart';
import 'package:approver/screens/login_screen.dart';
import 'package:approver/screens/home_screen.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the user data from the provider
    final user = Provider.of<AppUser?>(context);

    // Return either Home or Login screen based on authentication status
    if (user == null) {
      return const LoginScreen();
    } else {
      return const HomeScreen();
    }
  }
} 