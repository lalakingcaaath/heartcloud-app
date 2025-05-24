import 'package:flutter/material.dart';
import 'package:heartcloud/utils/colors.dart'; // Assuming darkBlue is defined here
import 'package:heartcloud/widgets.dart'; // Assuming StatusCard is defined here
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Import for Timer
import 'package:heartcloud/utils/bottom_navbar.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;

  // State variables for battery information
  String _batteryPercentageDisplay = "--%";
  double _batteryProgress = 0.0;
  String? _batteryErrorMessage;
  bool _isBatteryLoading = true;
  Timer? _batteryPollTimer;

  // State variable for device connection status
  String _deviceConnectionStatus = "Checking..."; // Initial status
  IconData _deviceConnectionIcon = Icons.wifi_tethering; // Initial icon

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _getBatteryInfo();
    _batteryPollTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _getBatteryInfo();
    });
  }

  Future<void> _getBatteryInfo() async {
    if (!mounted) return;

    // Set status to "Checking..." if it's not the very first load and we're retrying
    if (!_isBatteryLoading) { // Only set to checking if it's a subsequent poll
      setState(() {
        _deviceConnectionStatus = "Checking...";
        _deviceConnectionIcon = Icons.wifi_tethering; // Icon for checking
      });
    }


    try {
      final response = await http.get(Uri.parse('http://192.168.254.100/battery'))
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
        print('Battery: $percentage%');
      } else {
        print('Failed to load battery info. Status code: ${response.statusCode}');
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
      print('Error fetching battery info: $e');
      if (mounted) {
        setState(() {
          if (e is TimeoutException) {
            _batteryErrorMessage = 'Timeout';
          } else {
            _batteryErrorMessage = 'Error';
          }
          _isBatteryLoading = false;
          _deviceConnectionStatus = "Not Connected";
          _deviceConnectionIcon = Icons.wifi_off;
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
    Color batteryStatusIconColor = Theme.of(context).iconTheme.color ?? darkBlue;

    if (_isBatteryLoading && _batteryPercentageDisplay == '--%') {
      currentBatteryValue = "Loading...";
    } else if (_batteryErrorMessage != null) {
      currentBatteryValue = _batteryErrorMessage!;
      batteryStatusIconColor = Colors.red;
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
                  icon: Icons.battery_4_bar_outlined, // This could also be dynamic based on level
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
              padding: const EdgeInsets.only(left: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Recent Activity", style: TextStyle(
                      color: darkBlue,
                      fontSize: 22,
                      fontWeight: FontWeight.bold
                  ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
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