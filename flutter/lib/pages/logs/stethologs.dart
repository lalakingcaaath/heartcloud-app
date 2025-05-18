import 'package:flutter/material.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/utils/bottom_navbar.dart';
import 'package:heartcloud/widgets.dart';

class StethoLogs extends StatefulWidget {
  const StethoLogs({super.key});

  @override
  State<StethoLogs> createState() => _StethoLogsState();
}

class _StethoLogsState extends State<StethoLogs> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                    "Stethoscope Logs", style: TextStyle(
                    color: darkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 25
                  ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "View past patient checkups and recorded stethoscope sessions.", style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 9
                  ),
                  )
                ],
              ),
              SizedBox(height: 20),
              SearchBar(
                leading: const Icon(Icons.search),
                hintText: "Search for patients",
              ),
              SizedBox(height: 20),
              StethologsCard(),
              SizedBox(height: 20),
              StethologsCard(),
              SizedBox(height: 20),
              StethologsCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
          currentIndex: _selectedIndex, onTap: _onItemTapped
      ),
    );
  }
}
