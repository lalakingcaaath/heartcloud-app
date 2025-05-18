import 'package:flutter/material.dart';
import 'package:heartcloud/pages/login.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    try {
      // Register user with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      // Store additional info in Firestore
      await FirebaseFirestore.instance.collection("users").doc(user!.uid).set({
        "uid": user.uid,
        "firstName": _firstName.text.trim(),
        "lastName": _lastName.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Successful!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [darkBlue, mediumBlue, lightBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.only(left: 40, right: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(top: 60),
                  child: Text(
                    "Register",
                    style: TextStyle(color: headerColor1, fontSize: 40),
                  ),
                ),
                Container(
                  child: Text(
                    "Welcome to HeartCloud - Let's create your account",
                    style: TextStyle(color: headerColor1, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 50),
                Center(child: FirstName(controller: _firstName)),
                const SizedBox(height: 20),
                Center(child: LastName(controller: _lastName)),
                const SizedBox(height: 20),
                Center(child: EmailField(controller: _emailController)), // <- Updated here
                const SizedBox(height: 20),
                Center(child: PasswordField(controller: _passwordController)), // <- Updated here
                const SizedBox(height: 20),
                Center(child: ConfirmPasswordField(controller: _confirmPasswordController)), // <- Updated here
                const SizedBox(height: 50),
                Center(
                  child: ElevatedButton(
                    onPressed: _registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Register"),
                  ),
                ),
                const SizedBox(height: 50),
                Center(
                  child: Text(
                    "Already have an account?",
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
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: Text(
                      "Sign In",
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
    );
  }
}
