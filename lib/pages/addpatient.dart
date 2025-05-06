import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:heartcloud/widgets.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/utils/bottom_navbar.dart';

class Addpatient extends StatefulWidget {
  const Addpatient({super.key});

  @override
  State<Addpatient> createState() => _AddpatientState();
}

class _AddpatientState extends State<Addpatient> {
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactInfo = TextEditingController();
  final _ageController = TextEditingController();
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose(){
    _firstName.dispose();
    _lastName.dispose();
    _emailController.dispose();
    _contactInfo.dispose();
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
                  Text(
                    "Patient Profile Data Entry", style: TextStyle(
                    color: darkBlue,
                    fontSize: 25,
                    fontWeight: FontWeight.bold
                  ),
                  )
                ],
              ),
              SizedBox(height: 50),
              Center(child: FirstName(controller: _firstName)),
              SizedBox(height: 20),
              Center(child: LastName(controller: _lastName)),
              SizedBox(height: 20),
              Center(child: GenderDropdown()),
              SizedBox(height: 20),
              Center(child: AgeField(controller: _ageController)),
              SizedBox(height: 20),
              Center(child: ContactInformation(controller: _contactInfo)),
              SizedBox(height: 30),
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

                            // Optionally, validate fields
                            if (firstName.isEmpty || lastName.isEmpty || contactInfo.isEmpty || age == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Please fill out all fields correctly."))
                              );
                              return;
                            }

                            // Store to Firestore
                            await FirebaseFirestore.instance.collection('patient').add({
                              'firstName': firstName,
                              'lastName': lastName,
                              'contactInfo': contactInfo,
                              'age': age,
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Patient added successfully!"))
                            );

                            // Optionally clear fields
                            _firstName.clear();
                            _lastName.clear();
                            _contactInfo.clear();
                            _ageController.clear();

                          } catch (e) {
                            print("Error adding patient: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Failed to add patient."))
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: darkBlue,
                              borderRadius: BorderRadius.circular(10)
                          ),
                          child: Center(
                            child: Text(
                              "Add patient", style: TextStyle(
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
      bottomNavigationBar: BottomNavBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped
      ),
    );
  }
}
