import 'package:flutter/material.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/widgets.dart';
import 'package:heartcloud/utils/bottom_navbar.dart';


class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'images/hclogo-nobg.png',
                  width: 150,
                ),
                Text(
                  "Device Status", style: TextStyle(
                  color: darkBlue,
                  fontSize: 30,
                  fontWeight: FontWeight.bold
                ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                StatusCard(
                  title: "Battery",
                  value: "80%",
                  icon: Icons.battery_4_bar_outlined,
                  progress: 0.8,
                ),
                SizedBox(width: 40),
                StatusCard(
                    title: "Status",
                    value: "Connected",
                    icon: Icons.wifi)
              ],
            ),
            SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 50),
                  child: Text(
                    "Recent Activity", style: TextStyle(
                    color: darkBlue,
                    fontSize: 25,
                    fontWeight: FontWeight.bold
                  ),
                  ),
                )
              ],
            ),
            SizedBox(
              height: 75,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  PatientCard(
                    name: "John Dela Cruz",
                    time: "10:30AM",
                    date: "Mar. 25, 2025",
                    isHighlighted: true,
                  )
                ],
              ),
            ),
            SizedBox(
              height: 75,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  PatientCard(
                    name: "Mary Grace Piattos",
                    time: "1:30PMAM",
                    date: "Feb. 25, 2025",
                  )
                ],
              ),
            ),
            SizedBox(
              height: 75,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  PatientCard(
                    name: "John Dela Cruz",
                    time: "10:30AM",
                    date: "Mar. 25, 2025",
                    isHighlighted: true,
                  )
                ],
              ),
            ),
            SizedBox(
              height: 75,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  PatientCard(
                    name: "Mary Grace Piattos",
                    time: "1:30PMAM",
                    date: "Feb. 25, 2025",
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


