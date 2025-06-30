import 'package:cloud_firestore/cloud_firestore.dart' hide Settings; // Fixes name collision
import 'package:flutter/material.dart';
import 'package:heartcloud/pages/homepage.dart';
import 'package:heartcloud/pages/logs/stethologs.dart';
import 'package:heartcloud/pages/patient.dart';
import 'package:heartcloud/pages/auscultation.dart';
import 'package:heartcloud/pages/settings/manageProfile.dart';
import 'package:heartcloud/pages/settings.dart';
import 'package:heartcloud/pages/patient_profile/patientProfilePage.dart';
import 'package:heartcloud/utils/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:heartcloud/utils/bottom_navbar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  DocumentSnapshot? _selectedPatientData;
  bool get _isShowingProfile => _selectedPatientData != null;

  void _showPatientProfile(DocumentSnapshot patientData) {
    setState(() {
      _selectedPatientData = patientData;
    });
  }

  void _hidePatientProfile() {
    setState(() {
      _selectedPatientData = null;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedPatientData = null;
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final List<Widget> doctorPages = [
      const Homepage(),
      PatientList(onPatientSelected: _showPatientProfile),
      RecordAuscultation(onViewProfile: _showPatientProfile),
      StethoLogs(onPatientSelected: _showPatientProfile),
      const Settings(),
    ];

    final List<Widget> patientPages = [
      const Homepage(),
      const ProfilePage(),
      RecordAuscultation(onViewProfile: (data) {}),
      StethoLogs(onPatientSelected: (data) {}),
      const Settings(),
    ];

    final List<Widget> pages = authProvider.isDoctor ? doctorPages : patientPages;

    return Scaffold(
      body: _isShowingProfile
          ? PatientProfile(
        patientData: _selectedPatientData!,
        onBack: _hidePatientProfile,
      )
          : pages[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}