import 'package:flutter/material.dart';
import 'package:heartcloud/utils/auth_provider.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool _isPageLoading = true;
  String _batteryPercentageDisplay = "--%";
  double _batteryProgress = 0.0;
  String _deviceConnectionStatus = "Checking...";
  IconData _deviceConnectionIcon = Icons.wifi_tethering;
  Timer? _batteryPollTimer;

  int _numberOfPatients = 0;
  int _numberOfRecordings = 0;
  String get _patientToString => _numberOfPatients.toString();
  String get _recordingToString => _numberOfRecordings.toString();

  int _patientRecordingCount = 0;
  String get _patientRecordingToString => _patientRecordingCount.toString();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _batteryPollTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) _getBatteryInfo();
    });
  }

  @override
  void dispose() {
    _batteryPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final List<Future> dataFutures = [
      _getBatteryInfo(isInitialLoad: true),
    ];

    if (authProvider.isDoctor) {
      dataFutures.add(_fetchDoctorStats());
    } else {
      dataFutures.add(_fetchPatientRecordingCount());
    }

    await Future.wait(dataFutures);

    if (mounted) {
      setState(() => _isPageLoading = false);
    }
  }

  Future<void> _fetchPatientRecordingCount() async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).appUser;
      if (user == null) {
        print("Homepage Debug: User is null, cannot fetch recordings.");
        return;
      }

      // This print statement will help you confirm the right ID is being used.
      print("Homepage Debug: Fetching recordings for patientId: ${user.uid}");

      final recordingsQuery = await FirebaseFirestore.instance
          .collectionGroup('auscultation_recordings')
          .where('patientId', isEqualTo: user.uid)
          .get();

      // This will tell you how many recordings the query found.
      print("Homepage Debug: Firestore query found ${recordingsQuery.docs.length} recordings.");

      if (mounted) {
        setState(() {
          _patientRecordingCount = recordingsQuery.docs.length;
        });
      }
    } catch (e) {
      // This will print the exact error if the query fails.
      print("!!!!!!!! ERROR fetching patient recording count !!!!!!!!");
      print(e.toString());
    }
  }

  Future<void> _fetchDoctorStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doctorId = user.uid;
      final patientsCollectionRef = FirebaseFirestore.instance.collection('users').doc(doctorId).collection('patients');
      final patientsSnapshot = await patientsCollectionRef.get();
      if (!mounted) return;
      final numPatients = patientsSnapshot.docs.length;
      int totalRecordings = 0;
      for (var patientDoc in patientsSnapshot.docs) {
        final recordingsSnapshot = await patientsCollectionRef.doc(patientDoc.id).collection('auscultation_recordings').get();
        if (!mounted) return;
        totalRecordings += recordingsSnapshot.docs.length;
      }
      if (mounted) {
        setState(() {
          _numberOfPatients = numPatients;
          _numberOfRecordings = totalRecordings;
        });
      }
    } catch (e) {
      print('Error fetching doctor stats: $e');
    }
  }

  Future<void> _getBatteryInfo({bool isInitialLoad = false}) async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.1.112/battery'))
          .timeout(const Duration(seconds: 5));

      if (mounted) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final int percentage = data["percentage"] is int
              ? data["percentage"]
              : int.tryParse(data["percentage"].toString()) ?? 0;
          setState(() {
            _batteryPercentageDisplay = '$percentage%';
            _batteryProgress = percentage / 100.0;
            _deviceConnectionStatus = "Connected";
            _deviceConnectionIcon = Icons.wifi;
          });
        } else {
          setState(() {
            _deviceConnectionStatus = "Not Connected";
            _deviceConnectionIcon = Icons.wifi_off;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _batteryPercentageDisplay = (e is TimeoutException) ? 'Timeout' : 'Error';
          _deviceConnectionStatus = "Not Connected";
          _deviceConnectionIcon = Icons.wifi_off;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_isPageLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      color: Colors.white,
      child: authProvider.isDoctor
          ? _buildDoctorView(context)
          : _buildPatientView(context),
    );
  }

  Widget _buildDoctorView(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('images/hclogo-nobg.png', width: 120),
                const SizedBox(width: 10),
                const Text("Device Status", style: TextStyle(color: Color(0xFF0A3D62), fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StatusCard(title: "Battery", value: _batteryPercentageDisplay, icon: Icons.battery_4_bar_outlined, progress: _batteryProgress),
                StatusCard(title: "Status", value: _deviceConnectionStatus, icon: _deviceConnectionIcon),
              ],
            ),
            const SizedBox(height: 40),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Total Number of Patients", style: TextStyle(color: Color(0xFF0A3D62), fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            StatusCard(title: "Patients", value: _patientToString, icon: Icons.person),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Total Number of Recordings", style: TextStyle(color: Color(0xFF0A3D62), fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            StatusCard(title: "Recordings", value: _recordingToString, icon: Icons.history_rounded),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientView(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('images/hclogo-nobg.png', width: 120),
                const SizedBox(width: 10),
                const Text("Device Status", style: TextStyle(color: Color(0xFF0A3D62), fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StatusCard(title: "Battery", value: _batteryPercentageDisplay, icon: Icons.battery_4_bar_outlined, progress: _batteryProgress),
                StatusCard(title: "Status", value: _deviceConnectionStatus, icon: _deviceConnectionIcon),
              ],
            ),
            const SizedBox(height: 40),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Total Number of Recordings", style: TextStyle(color: Color(0xFF0A3D62), fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            StatusCard(title: "My Recordings", value: _patientRecordingToString, icon: Icons.history_rounded),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}