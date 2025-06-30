import 'package:flutter/material.dart';
import 'package:heartcloud/utils/auth_provider.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:provider/provider.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap; // This is crucial

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final List<BottomNavigationBarItem> patientItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
      const BottomNavigationBarItem(icon: Icon(Icons.fiber_manual_record), label: "Record"),
      const BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
      const BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
    ];

    final List<BottomNavigationBarItem> doctorItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: "Patient"),
      const BottomNavigationBarItem(icon: Icon(Icons.fiber_manual_record), label: "Record"),
      const BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
      const BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
    ];

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap, // We just pass the tap event up to the parent
      selectedItemColor: darkBlue,
      unselectedItemColor: darkBlue,
      selectedIconTheme: const IconThemeData(size: 24),
      unselectedIconTheme: const IconThemeData(size: 24),
      type: BottomNavigationBarType.fixed,
      items: authProvider.isDoctor ? doctorItems : patientItems,
    );
  }
}