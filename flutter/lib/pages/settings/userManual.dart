import 'package:flutter/material.dart';
import 'package:heartcloud/utils/colors.dart';

class UserManualScreen extends StatelessWidget {
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
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.arrow_back,
                      size: 35,
                    ),
                  ),
                  SizedBox(width: 20),
                  Text(
                    "User Manual",
                    style: TextStyle(
                      color: darkBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    ),
                  )
                ],
              ),
              SizedBox(height: 30),
              _buildSectionTitle("1. Introduction", darkBlue),
              SizedBox(height: 10),
              _buildSectionContent("Welcome to HeartCloud, a health-tracking platform designed for patients and doctors to securely monitor health data. This guide provides step-by-step instructions on how to use the app."),
              SizedBox(height: 10),
              _buildSectionTitle("2. Getting Started", darkBlue),
              SizedBox(height: 10),
              _buildSectionContent("This section will guide you through system requirements and account registration."),
              SizedBox(height: 10),
              _buildSectionTitle("3. Account Registration", darkBlue),
              _buildBulletPoints([
                "Patients: Open the HeartCloud app, sign up, and enter your details.",
                "Doctors: Open the HeartCloud app, sign up, and enter your details.",
              ]),
              SizedBox(height: 10),
              _buildSectionTitle("4. Using HeartCloud", darkBlue),
              SizedBox(height: 10),
              _buildSectionContent("After logging in, you'll see your health dashboard with vital metrics and history."),
              SizedBox(height: 10),
              _buildSectionTitle("5. Recording Health Data", darkBlue),
              _buildBulletPoints([
                "Tap 'Start Recording' to log health data.",
                "Connect a wearable device if available.",
                "Save the recorded data to track progress.",
              ]),
              SizedBox(height: 10),
              _buildSectionTitle("6. Viewing Health Data", darkBlue),
              _buildBulletPoints([
                "Patients can view their past health records in the history tab.",
                "Doctors (with patient consent) can access patient data.",
              ]),
              SizedBox(height: 10),
              _buildSectionTitle("7. Privacy & Security", darkBlue),
              _buildBulletPoints([
                "End-to-end encryption for stored and transmitted data.",
                "Patient-controlled access for doctors.",
                "No data selling or unauthorized sharing.",
              ]),
              SizedBox(height: 10),
              _buildSectionTitle("8. Contact Support", darkBlue),
              _buildSectionContent("For any issues, contact us at support@heartcloud.com."),
              SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        )
      ],
    );
  }

  Widget _buildSectionContent(String content) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                content,
                softWrap: true,
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildBulletPoints(List<String> points) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: points
                .map((point) => ListTile(
              leading: Icon(Icons.circle, size: 8),
              title: Text(point),
            ))
                .toList(),
          ),
        )
      ],
    );
  }
}
