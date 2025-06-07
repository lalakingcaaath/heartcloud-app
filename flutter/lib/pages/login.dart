import 'package:flutter/material.dart';
import 'package:heartcloud/pages/homepage.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/widgets.dart';
import 'register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:heartcloud/pages/settings/password/changePassword.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose(){
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(), password: _passwordController.text.trim()
      );
      print("User signed in: ${userCredential.user?.email}");
      Navigator.push(context, MaterialPageRoute(builder: (context) => Homepage()));
    } catch (e) {
      print("Error signing in: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed. Please check your credentials."))
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
                    margin: EdgeInsets.only(top: 50),
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
                            onTap: (){
                              signIn();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: darkBlue,
                                  borderRadius: BorderRadius.circular(10)
                              ),
                              child: Center(
                                child: Text(
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