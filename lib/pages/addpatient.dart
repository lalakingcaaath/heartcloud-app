import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:heartcloud/widgets.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/utils/bottom_navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Addpatient extends StatefulWidget {
  const Addpatient({super.key});

  @override
  State<Addpatient> createState() => _AddpatientState();
}

class _AddpatientState extends State<Addpatient> {
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _contactInfo = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _contactInfo.dispose();
    _ageController.dispose();
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
              const SizedBox(height: 70),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Patient Profile Data Entry",
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              Center(child: FirstName(controller: _firstName)),
              const SizedBox(height: 20),
              Center(child: LastName(controller: _lastName)),
              const SizedBox(height: 20),

              // Gender Dropdown
              Center(
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  hint: const Text("Select Gender"),
                  items: ["Male", "Female"].map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Gender",
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Center(child: AgeField(controller: _ageController)),
              const SizedBox(height: 20),
              Center(child: ContactInformation(controller: _contactInfo)),
              const SizedBox(height: 30),

              // Add Patient Button
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          final String firstName = _firstName.text.trim();
                          final String lastName = _lastName.text.trim();
                          final String contactInfo = _contactInfo.text.trim();
                          final String ageText = _ageController.text.trim();
                          final int? age = int.tryParse(ageText);

                          // Field validation
                          if (firstName.isEmpty ||
                              lastName.isEmpty ||
                              contactInfo.isEmpty ||
                              age == null ||
                              _selectedGender == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please fill out all fields correctly."),
                              ),
                            );
                            return;
                          }

                          final user = FirebaseAuth.instance.currentUser;
                          String? doctorId = user?.uid;

                          // Store data to Firestore
                          await FirebaseFirestore.instance.collection('users')
                          .doc(doctorId)
                          .collection('patients')
                              .add({
                            'firstName': firstName,
                            'lastName': lastName,
                            'contactInfo': contactInfo,
                            'age': age,
                            'gender': _selectedGender, // Add gender to database
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Patient added successfully!"),
                            ),
                          );

                          // Clear fields after submission
                          _firstName.clear();
                          _lastName.clear();
                          _contactInfo.clear();
                          _ageController.clear();
                          setState(() {
                            _selectedGender = null;
                          });
                        } catch (e) {
                          print("Error adding patient: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to add patient."),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: darkBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            "Add Patient",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}