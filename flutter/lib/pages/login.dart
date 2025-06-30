// login.dart - CORRECTED

import 'package:flutter/material.dart';
import 'package:heartcloud/utils/auth_provider.dart'; // FIX: Import AuthProvider
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/widgets.dart';
import 'package:provider/provider.dart'; // FIX: Import Provider
import 'register.dart';
import 'package:heartcloud/pages/settings/password/changePassword.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers are correct
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSigningIn = false; // To disable the button during sign-in

  @override
  void dispose(){
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // FIX: Updated signIn method to use the AuthProvider
  Future<void> signIn() async {
    // Prevent multiple sign-in attempts
    if (_isSigningIn) return;

    setState(() {
      _isSigningIn = true;
    });

    // Get the AuthProvider instance
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Call the signInWithEmail method from the provider
      await authProvider.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // IMPORTANT: DO NOT NAVIGATE HERE.
      // The Wrapper will handle navigation automatically when the auth state changes.

    } catch (e) {
      // If sign-in fails, show an error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login failed. Please check your credentials."))
        );
      }
    } finally {
      // Re-enable the button after the attempt is finished
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [darkBlue, mediumBlue, lightBlue],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          margin: const EdgeInsets.only(left: 40, right: 40),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Image.asset(
                      'images/authentication.png',
                      width: 200,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 50),
                    child: Text(
                      "WELCOME BACK",
                      style: TextStyle(
                        color: headerColor1,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Container(
                    child: Text(
                      "Account Log In",
                      style: TextStyle(
                        color: headerColor2,
                        fontWeight: FontWeight.w600,
                        fontSize: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(child: EmailField(controller: _emailController)),
                  const SizedBox(height: 20),
                  Center(child: PasswordField(controller: _passwordController)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePassword()));
                        },
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(color: headerColor2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: GestureDetector(
                            onTap: _isSigningIn ? null : signIn, // Disable tap when signing in
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: darkBlue,
                                  borderRadius: BorderRadius.circular(10)
                              ),
                              child: Center(
                                child: _isSigningIn
                                    ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                )
                                    : const Text(
                                  "Sign In", style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18
                                ),
                                ),
                              ),
                            ),
                          )
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  Center(
                    child: Text(
                      "Don't have an account?",
                      style: TextStyle(
                        color: headerColor1,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: Text(
                        "Register",
                        style: TextStyle(
                          color: headerColor2,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}