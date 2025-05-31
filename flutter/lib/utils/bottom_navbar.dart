import 'package:flutter/material.dart';
import 'package:heartcloud/pages/homepage.dart';
import 'package:heartcloud/pages/logs/stethologs.dart';
import 'package:heartcloud/pages/patient.dart';
import 'package:heartcloud/pages/auscultation.dart';
import 'package:heartcloud/pages/settings.dart';
import 'package:heartcloud/utils/colors.dart';


class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        onTap (index);
        _navigateToPage(context, index);
      },
      selectedItemColor: darkBlue,
      unselectedItemColor: darkBlue,
      selectedIconTheme: const IconThemeData(size: 24),
      unselectedIconTheme: const IconThemeData(size: 24),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Patient",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fiber_manual_record),
          label: "Record",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: "History",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: "Settings",
        ),
      ],
    );
  }
}

void _navigateToPage(BuildContext context, int index) {
  Widget page;
  switch (index) {
    case 0:
      page = const Homepage();
      break;
    case 1:
      page = const PatientList();
      break;
    case 2:
      page = const RecordAuscultation();
      break;
    case 3:
      page = const StethoLogs();
      break;
    case 4:
      page = const Settings();
    default:
      return;

  }
  
  Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page)
  );
}