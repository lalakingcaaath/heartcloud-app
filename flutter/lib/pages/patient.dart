import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/widgets.dart';
import 'package:heartcloud/pages/addpatient.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientList extends StatefulWidget {
  final Function(DocumentSnapshot) onPatientSelected;
  const PatientList({super.key, required this.onPatientSelected});

  @override
  State<PatientList> createState() => _PatientListState();
}

class _PatientListState extends State<PatientList> {
  String formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(left: 40, right: 40),
          child: Column(
            children: [
              const SizedBox(height: 70),
              const SearchBar(leading: Icon(Icons.search), hintText: "Search for patients"),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("Patient List", style: TextStyle(color: darkBlue, fontSize: 25, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Icon(Icons.sort),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  Text("Name", style: TextStyle(fontSize: 14)),
                  Spacer(),
                  Text("Registered Date", style: TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 50),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('patients')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No Patient Available", style: TextStyle(fontSize: 18, color: darkBlue)));
                  }
                  final patients = snapshot.data!.docs;
                  return Column(
                    children: patients.asMap().entries.map((entry) {
                      int index = entry.key;
                      var patient = entry.value;
                      String formattedDate;
                      try {
                        formattedDate = formatDate(patient['createdAt']);
                      } catch (e) {
                        formattedDate = "No date available";
                      }
                      Color cardColor = index.isEven ? PatientCardColor1 : PatientCardColor2;
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              widget.onPatientSelected(patient);
                            },
                            child: PatientCard(
                              name: "${patient['firstName']} ${patient['lastName']}",
                              patientData: patient,
                              date: formattedDate,
                              backgroundColor: cardColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const Addpatient()));
        },
        backgroundColor: darkBlue,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}