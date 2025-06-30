// addpatient.dart - CORRECTED WITH DOCTOR ASSIGNMENT LOGIC

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:heartcloud/widgets.dart';
import 'package:heartcloud/utils/colors.dart';
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
  // FIX: Added a controller for the patient's email
  final TextEditingController _emailController = TextEditingController();
  String? _selectedGender;
  bool _isLoading = false; // To show a loading indicator

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _contactInfo.dispose();
    _ageController.dispose();
    _emailController.dispose(); // Dispose the new controller
    super.dispose();
  }

  // FIX: Encapsulated the logic into a separate function
  Future<void> _addAndAssignPatient() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final String firstName = _firstName.text.trim();
      final String lastName = _lastName.text.trim();
      final String contactInfo = _contactInfo.text.trim();
      final String ageText = _ageController.text.trim();
      final String patientEmail = _emailController.text.trim().toLowerCase();
      final int? age = int.tryParse(ageText);
      final String? doctorId = FirebaseAuth.instance.currentUser?.uid;

      if (doctorId == null) {
        throw Exception("Doctor not logged in.");
      }

      if (firstName.isEmpty ||
          lastName.isEmpty ||
          contactInfo.isEmpty ||
          age == null ||
          _selectedGender == null ||
          patientEmail.isEmpty) {
        throw Exception("Please fill out all fields correctly.");
      }

      // Step 1: Find the patient's user document by their email.
      final patientQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: patientEmail)
          .where('role', isEqualTo: 'patient') // Ensure we only find patients
          .limit(1)
          .get();

      if (patientQuery.docs.isEmpty) {
        throw Exception("No patient found with the email: $patientEmail");
      }

      final patientDoc = patientQuery.docs.first;
      final String patientId = patientDoc.id;

      // Step 2: Add the patient's details to the DOCTOR's subcollection.
      // This is what you were already doing.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .collection('patients')
          .doc(patientId) // Use patient's UID as doc ID for consistency
          .set({
        'firstName': firstName,
        'lastName': lastName,
        'email': patientEmail,
        'contactInfo': contactInfo,
        'age': age,
        'gender': _selectedGender,
        'createdAt': FieldValue.serverTimestamp(),
        // Storing the UID is good practice
        'uid': patientId,
      });

      // Step 3: Update the PATIENT's main user document with the doctor's ID.
      // This is the critical new step.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .update({
        'assignedDoctorId': doctorId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Patient added and assigned successfully!")),
        );
        // Navigate back or clear fields
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString().replaceFirst("Exception: ", "")}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Patient"),
        backgroundColor: Colors.white,
        foregroundColor: darkBlue,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Makes button stretch
            children: [
              const SizedBox(height: 20),
              // FIX: Added an email field for the doctor to find the patient.
              EmailField(controller: _emailController),
              const SizedBox(height: 20),
              FirstName(controller: _firstName),
              const SizedBox(height: 20),
              LastName(controller: _lastName),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                hint: const Text("Select Gender"),
                items: ["Male", "Female"].map((String gender) {
                  return DropdownMenuItem<String>(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedGender = newValue);
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Gender",
                ),
              ),
              const SizedBox(height: 20),
              AgeField(controller: _ageController),
              const SizedBox(height: 20),
              ContactInformation(controller: _contactInfo),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _addAndAssignPatient,
                style: ElevatedButton.styleFrom(
                    backgroundColor: darkBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: _isLoading
                    ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                )
                    : const Text("Add and Assign Patient", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}