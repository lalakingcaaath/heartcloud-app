import 'package:flutter/material.dart';
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                      onTap: (){
                      Navigator.pop(context);
                    },
                      child: Icon(Icons.arrow_back, size: 35)),
                  SizedBox(width: 10),
                  Text(
                    "Back",
                    style: TextStyle(
                        fontSize: 25
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.info_rounded, size: 35, color: darkBlue)
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
                child: EmailField(),
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
                            child: Text(
                              "Reset Password", style: TextStyle(
                              color: Colors.white,
                              fontSize: 18
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
