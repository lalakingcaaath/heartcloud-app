import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/widgets.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose(){
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> changePassword(String email, BuildContext context) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password reset email sent. Please check your inbox."),
          backgroundColor: darkBlue,
        ),
      );
    } catch (e) {
      print("Error changing password: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to send reset email. Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(left: 40, right: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 70),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                      onPressed: (){
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.arrow_back, size: 35, color: darkBlue)
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Back",
                    style: TextStyle(
                        fontSize: 25
                    ),
                  ),
                  Spacer(),
                  IconButton(
                      onPressed: (){
                        showDialog(
                            context: context,
                            builder: (BuildContext context) => Dialog(
                              backgroundColor: darkBlue,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: 200,
                                  minHeight: 100,
                                  maxWidth: 300
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(25),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Enter your email address and tap 'Reset Passsword'.\n\n"
                                            "We'll send you an email with instructions to create new password.",
                                        softWrap: true, textAlign: TextAlign.justify, style: TextStyle(
                                          color: Colors.white
                                        ),
                                      ),
                                      TextButton(
                                          onPressed: (){
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            "Close", style: TextStyle(
                                            color: Colors.white
                                          ),
                                          )
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            )
                        );
                      },
                      icon: Icon(Icons.info_outline, size: 35, color: darkBlue)
                  )
                ],
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  Text(
                    "Reset password", style: TextStyle(
                    color: darkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 25
                  ),
                  )
                ],
              ),
              SizedBox(height: 20),
              Column(
                children: [
                  Text("Enter the email associated with your account and we'll send an email with instructions to reset your password.", softWrap: true)
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Text("Email Address")
                ],
              ),
              SizedBox(height: 10),
              Center(
                child: EmailField(controller: _emailController),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                      child: GestureDetector(
                        onTap: (){},
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: darkBlue,
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                if (_emailController.text.isNotEmpty) {
                                  changePassword(_emailController.text.trim(), context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Please enter your email."),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                "Reset Password", style: TextStyle(
                                color: Colors.white,
                                fontSize: 18
                              ),
                              ),
                            ),
                          ),
                        ),
                      )
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
