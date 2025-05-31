import 'package:flutter/material.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/utils/bottom_navbar.dart';
import 'package:heartcloud/widgets.dart'; // This should contain the updated StethologsCard
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For current user

class StethoLogs extends StatefulWidget {
  const StethoLogs({super.key});

  @override
  State<StethoLogs> createState() => _StethoLogsState();
}

class _StethoLogsState extends State<StethoLogs> {
  int _selectedIndex = 0;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Handle navigation if your BottomNavBar does that
  }

  String? get _currentDoctorId {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? doctorId = _currentDoctorId;

    return Scaffold(
      body: SingleChildScrollView( // Keep SingleChildScrollView for overall page scroll
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Adjusted margin
          padding: const EdgeInsets.only(top: 50), // Adjusted padding for status bar
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Align content to start
            crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
            children: [
              Text(
                "Stethoscope Logs",
                style: TextStyle(
                  color: darkBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "View past patient checkups and recorded stethoscope sessions.",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 13, // Slightly larger for readability
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              SearchBar( // Using Flutter's official SearchBar
                controller: _searchController,
                leading: const Icon(Icons.search),
                hintText: "Search by patient name or type...",
                onChanged: (query) { // For live search
                  setState(() {
                    _searchQuery = query.toLowerCase();
                  });
                },
                // elevation: MaterialStateProperty.all(1.0), // Optional: subtle elevation
              ),
              const SizedBox(height: 20),
              if (doctorId == null)
                const Center(child: Text("Please log in to view stethoscope logs."))
              else
                StreamBuilder<QuerySnapshot>(
                  // Querying the 'auscultation_recordings' collection group
                  // and filtering by the current doctor's ID.
                  // This requires 'doctorId' field in your recording documents.
                  stream: FirebaseFirestore.instance
                      .collectionGroup('auscultation_recordings')
                      .where('doctorId', isEqualTo: doctorId)
                      .orderBy('recordedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      print("Error fetching stetho logs: ${snapshot.error}");
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('No stethoscope logs found for your patients.', style: TextStyle(fontSize: 16)),
                          )
                      );
                    }

                    var allRecordings = snapshot.data!.docs;
                    List<QueryDocumentSnapshot> filteredRecordings = allRecordings;

                    if (_searchQuery.isNotEmpty) {
                      filteredRecordings = allRecordings.where((doc) {
                        String patientFirstName = (doc.get('patientFirstName') as String? ?? '').toLowerCase();
                        String patientLastName = (doc.get('patientLastName') as String? ?? '').toLowerCase();
                        String auscultationType = (doc.get('auscultationType') as String? ?? '').toLowerCase();

                        return patientFirstName.contains(_searchQuery) ||
                            patientLastName.contains(_searchQuery) ||
                            auscultationType.contains(_searchQuery);
                      }).toList();
                    }

                    if (filteredRecordings.isEmpty && _searchQuery.isNotEmpty) {
                      return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('No logs match your search.', style: TextStyle(fontSize: 16)),
                          )
                      );
                    }


                    // Use ListView.builder for dynamic list
                    return ListView.builder(
                      shrinkWrap: true, // Important for ListView inside SingleChildScrollView
                      physics: const NeverScrollableScrollPhysics(), // Disable ListView's own scrolling
                      itemCount: filteredRecordings.length,
                      itemBuilder: (context, index) {
                        return StethologsCard(recordingData: filteredRecordings[index]);
                      },
                    );
                  },
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