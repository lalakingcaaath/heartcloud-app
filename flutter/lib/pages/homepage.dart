import 'package:flutter/material.dart';
import 'package:heartcloud/utils/colors.dart'; // Assuming darkBlue is defined here
import 'package:heartcloud/widgets.dart'; // Assuming StatusCard is defined here
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Import for Timer
import 'package:heartcloud/utils/bottom_navbar.dart';

// Add these Firebase imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Assuming you use Firebase Auth

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;
  int _numberOfPatients = 0;
  int _numberOfRecordings = 0;
  String get _patientToString => _numberOfPatients.toString();
  String get _recordingToString => _numberOfRecordings.toString();

  // State variables for battery information
  String _batteryPercentageDisplay = "--%";
  double _batteryProgress = 0.0;
  String? _batteryErrorMessage;
  bool _isBatteryLoading = true;
  Timer? _batteryPollTimer;

  // State variable for device connection status
  String _deviceConnectionStatus = "Checking..."; // Initial status
  IconData _deviceConnectionIcon = Icons.wifi_tethering; // Initial icon

  // New state variable for loading patient/recording stats
  bool _isLoadingStats = true;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // You might want to add navigation or other actions based on the index
    // Example:
    // if (index == 1) {
    //   Navigator.pushNamed(context, '/patientListPage');
    // }
  }

  @override
  void initState() {
    super.initState();
    _getBatteryInfo();
    _batteryPollTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _getBatteryInfo();
    });
    _fetchPatientAndRecordingStats(); // Fetch stats on init
  }

  Future<void> _getBatteryInfo() async {
    if (!mounted) return;
    if (!_isBatteryLoading) {
      setState(() {
        _deviceConnectionStatus = "Checking...";
        _deviceConnectionIcon = Icons.wifi_tethering;
      });
    }

    try {
      final response = await http.get(Uri.parse('http://192.168.1.112/battery'))
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final int percentage = data["percentage"] is int ? data["percentage"] : int.tryParse(data["percentage"].toString()) ?? 0;
        if (mounted) {
          setState(() {
            _batteryPercentageDisplay = '$percentage%';
            _batteryProgress = percentage / 100.0;
            _batteryErrorMessage = null;
            _isBatteryLoading = false;
            _deviceConnectionStatus = "Connected";
            _deviceConnectionIcon = Icons.wifi;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _batteryErrorMessage = 'Failed (${response.statusCode})';
            _isBatteryLoading = false;
            _deviceConnectionStatus = "Not Connected";
            _deviceConnectionIcon = Icons.wifi_off;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _batteryErrorMessage = (e is TimeoutException) ? 'Timeout' : 'Error';
          _isBatteryLoading = false;
          _deviceConnectionStatus = "Not Connected";
          _deviceConnectionIcon = Icons.wifi_off;
        });
      }
    }
  }

  // Updated method to fetch patient and recording counts from Firestore
  // with detailed logging and error handling
  Future<void> _fetchPatientAndRecordingStats() async {
    if (!mounted) {
      print("_fetchPatientAndRecordingStats: [DEBUG] Widget not mounted at start, aborting.");
      return;
    }
    print("_fetchPatientAndRecordingStats: [DEBUG] Starting to fetch stats...");
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("_fetchPatientAndRecordingStats: [DEBUG] User not logged in. Cannot fetch stats.");
        if (mounted) {
          setState(() {
            _numberOfPatients = 0;
            _numberOfRecordings = 0;
            _isLoadingStats = false; // Set loading to false
            print("_fetchPatientAndRecordingStats: [DEBUG] User null, _isLoadingStats set to false.");
          });
        }
        return;
      }
      // 'doctorId' is user.uid, which is correct based on your register.dart
      final doctorId = user.uid;
      print("_fetchPatientAndRecordingStats: [DEBUG] Current User (Doctor) ID: $doctorId");

      // Fetch number of patients
      print("_fetchPatientAndRecordingStats: [DEBUG] Attempting to fetch patients from collection: users/$doctorId/patients");
      final patientsCollectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId) // This path is correct
          .collection('patients');

      final patientsSnapshot = await patientsCollectionRef.get().timeout(const Duration(seconds: 20), onTimeout: (){
        print("_fetchPatientAndRecordingStats: [DEBUG] Timeout occurred while fetching patients.");
        throw TimeoutException('Fetching patients timed out for user $doctorId');
      });

      if (!mounted) {
        print("_fetchPatientAndRecordingStats: [DEBUG] Widget unmounted after fetching patients snapshot. Aborting.");
        return;
      }
      final numPatients = patientsSnapshot.docs.length;
      print("_fetchPatientAndRecordingStats: [DEBUG] Successfully fetched patients. Count: $numPatients for user $doctorId");

      // Fetch number of recordings
      int totalRecordings = 0;
      print("_fetchPatientAndRecordingStats: [DEBUG] Starting to iterate through $numPatients patients to get recordings count.");

      for (var patientDoc in patientsSnapshot.docs) {
        // patientDoc.id is the auto-generated ID for the patient document.
        print("_fetchPatientAndRecordingStats: [DEBUG] For patient ID: ${patientDoc.id}, attempting to fetch recordings from users/$doctorId/patients/${patientDoc.id}/auscultation_recordings");

        // Option 1: Get all documents then count (your current method)
        final recordingsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(doctorId)
            .collection('patients')
            .doc(patientDoc.id)
            .collection('auscultation_recordings')
            .get().timeout(const Duration(seconds: 20), onTimeout: (){
          print("_fetchPatientAndRecordingStats: [DEBUG] Timeout occurred while fetching recordings for patient ${patientDoc.id}.");
          throw TimeoutException('Fetching recordings for patient ${patientDoc.id} timed out');
        });

        // Option 2: More efficient count (if your cloud_firestore version supports it well, typically >3.2.0 or >4.1.0)
        // final recordingCountSnapshot = await FirebaseFirestore.instance
        //     .collection('users')
        //     .doc(doctorId)
        //     .collection('patients')
        //     .doc(patientDoc.id)
        //     .collection('auscultation_recordings')
        //     .count()
        //     .get().timeout(const Duration(seconds: 20), onTimeout: (){
        //         print("_fetchPatientAndRecordingStats: [DEBUG] Timeout occurred while fetching recordings count for patient ${patientDoc.id}.");
        //         throw TimeoutException('Fetching recordings count for patient ${patientDoc.id} timed out');
        //     });

        if (!mounted) {
          print("_fetchPatientAndRecordingStats: [DEBUG] Widget unmounted while fetching recordings for patient ${patientDoc.id}. Aborting loop.");
          return;
        }

        totalRecordings += recordingsSnapshot.docs.length; // Use for Option 1
        // totalRecordings += recordingCountSnapshot.count ?? 0; // Use for Option 2

        print("_fetchPatientAndRecordingStats: [DEBUG] Patient ${patientDoc.id} has ${recordingsSnapshot.docs.length} recordings. Current total recordings: $totalRecordings");
      }

      print("_fetchPatientAndRecordingStats: [DEBUG] Finished fetching all data. Total Patients: $numPatients, Total Recordings: $totalRecordings");
      if (mounted) {
        setState(() {
          _numberOfPatients = numPatients;
          _numberOfRecordings = totalRecordings;
          _isLoadingStats = false; // CRUCIAL: Set to false on success
          print("_fetchPatientAndRecordingStats: [DEBUG] State updated successfully. _isLoadingStats is now false.");
        });
      }
    } catch (e, stackTrace) {
      print('---------- ERROR FETCHING STATS ----------');
      print('_fetchPatientAndRecordingStats: [ERROR] Failed to fetch patient/recording stats: $e');
      if (e is FirebaseException) {
        print('Firebase Error Code: ${e.code}'); // Very useful for diagnosing permission issues etc.
        print('Firebase Error Message: ${e.message}');
      }
      print('Stack trace: $stackTrace');
      print('------------------------------------------');
      if (mounted) {
        setState(() {
          _numberOfPatients = 0;
          _numberOfRecordings = 0;
          _isLoadingStats = false; // CRUCIAL: Set to false on error too
          print("_fetchPatientAndRecordingStats: [DEBUG] Error caught. _isLoadingStats set to false in catch block.");
        });
      }
    }
  }

  @override
  void dispose() {
    _batteryPollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String currentBatteryValue = _batteryPercentageDisplay;
    if (_isBatteryLoading && _batteryPercentageDisplay == '--%') {
      currentBatteryValue = "Loading...";
    } else if (_batteryErrorMessage != null) {
      currentBatteryValue = _batteryErrorMessage!;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'images/hclogo-nobg.png',
                  width: 120,
                ),
                const SizedBox(width: 10),
                Text(
                  "Device Status", style: TextStyle(
                    color: darkBlue,
                    fontSize: 28,
                    fontWeight: FontWeight.bold
                ),
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                StatusCard(
                  title: "Battery",
                  value: currentBatteryValue,
                  icon: Icons.battery_4_bar_outlined,
                  progress: _batteryProgress,
                ),
                StatusCard(
                  title: "Status",
                  value: _deviceConnectionStatus,
                  icon: _deviceConnectionIcon,
                )
              ],
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Total Number of Patients", style: TextStyle(
                      color: darkBlue,
                      fontSize: 22,
                      fontWeight: FontWeight.bold
                  ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StatusCard(
                      title: "Patients",
                      value: _isLoadingStats ? "Loading..." : _patientToString,
                      icon: Icons.person
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Total Number of Recordings", // Corrected typo from "Recording"
                    style: TextStyle(
                        color: darkBlue,
                        fontSize: 22,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StatusCard(
                      title: "Recordings",
                      value: _isLoadingStats ? "Loading..." : _recordingToString,
                      icon: Icons.history_rounded
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped
      ),
    );
  }
}