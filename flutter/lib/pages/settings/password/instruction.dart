import 'package:flutter/material.dart';
import 'package:heartcloud/utils/colors.dart';

class InstructionPage extends StatelessWidget {
  const InstructionPage({super.key});

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
              SizedBox(height: 200),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: darkBlue,
                  ),
                  child: Image.asset("images/icons8-inbox-100.png"),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  "Check your email", style: TextStyle(
                  color: darkBlue,
                  fontSize: 25,
                  fontWeight: FontWeight.bold
                ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Text("We have sent a password recover instructions to your email.", textAlign: TextAlign.center),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
