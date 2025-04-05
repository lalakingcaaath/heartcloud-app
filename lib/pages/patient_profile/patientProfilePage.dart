import 'package:flutter/material.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/utils/bottom_navbar.dart';
import 'package:heartcloud/widgets.dart';

class PatientProfile extends StatefulWidget {
  const PatientProfile({super.key});

  @override
  State<PatientProfile> createState() => _PatientProfileState();
}

class _PatientProfileState extends State<PatientProfile> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(left: 40, right: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 70),
              Text(
                "Patient Details", style: TextStyle(
                color: darkBlue,
                fontWeight: FontWeight.bold,
                fontSize: 25
              ),
              ),
              SizedBox(height: 40),
              Text(
                "FIRST NAME"
              ),
              SizedBox(height: 20),
              Text(
                "John"
              ),
              SizedBox(height: 20),
              Text(
                "LAST NAME"
              ),
              SizedBox(height: 20),
              Text(
                "Dela Cruz"
              ),
              SizedBox(height: 20),
              Text(
                  "Gender"
              ),
              SizedBox(height: 20),
              Text(
                  "Male"
              ),
              SizedBox(height: 20),
              Text(
                  "Contact Information"
              ),
              SizedBox(height: 20),
              Text(
                  "+63 927 1140 157"
              ),
              SizedBox(height: 40),
              Text(
                "Recording History", style: TextStyle(
                color: darkBlue,
                fontWeight: FontWeight.bold,
                fontSize: 25
              ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped
      ),
    );
  }
}
