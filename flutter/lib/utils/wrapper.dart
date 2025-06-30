import 'package:flutter/material.dart';
import 'package:heartcloud/utils/mainscreen.dart';
import 'package:heartcloud/pages/login.dart';
import 'package:heartcloud/utils/auth_provider.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the AuthProvider for any changes in the user's login state.
    final authProvider = Provider.of<AuthProvider>(context);

    // If the provider is still trying to figure out if a user is logged in
    // (e.g., when the app first starts), show a loading screen.
    // This can replace your initial splash screen's loading purpose.
    if (authProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xff5c8fe6), // Using your lightBlue color
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    // If the provider has confirmed a user is logged in, show the MainScreen.
    if (authProvider.isLoggedIn) {
      return const MainScreen();
    }
    // Otherwise, if there is no user, show the LoginPage.
    else {
      return const LoginPage();
    }
  }
}
