import 'package:flutter/material.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/utils/bottom_navbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientProfile extends StatefulWidget {
  final DocumentSnapshot patientData;

  const PatientProfile({super.key, required this.patientData});

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
    // Access the patient data passed to the widget
    var patient = widget.patientData;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(left: 40, right: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 70),
              Text(
                "Patient Details",
                style: TextStyle(
                    color: darkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 25),
              ),
              const SizedBox(height: 40),
              const Text("FIRST NAME"),
              const SizedBox(height: 20),
              Text(patient['firstName'] ?? "No first name"),
              const SizedBox(height: 20),
              const Text("LAST NAME"),
              const SizedBox(height: 20),
              Text(patient['lastName'] ?? "No last name"),
              const SizedBox(height: 20),
              const Text("Gender"),
              const SizedBox(height: 20),
              Text(patient['gender'] ?? "No gender"),
              const SizedBox(height: 20),
              const Text("Contact Information"),
              const SizedBox(height: 20),
              Text(patient['contactInfo'] ?? "No contact information"),
              const SizedBox(height: 40),
              Text(
                "Recording History",
                style: TextStyle(
                    color: darkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 25),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}