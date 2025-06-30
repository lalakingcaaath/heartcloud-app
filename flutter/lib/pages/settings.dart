import 'package:flutter/material.dart';
import 'package:heartcloud/pages/settings/manageProfile.dart';
import 'package:heartcloud/pages/settings/password/changePassword.dart';
import 'package:heartcloud/pages/settings/terms.dart';
import 'package:heartcloud/pages/settings/userManual.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/pages/settings/guide.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    // The Scaffold has been removed. This widget now only returns the content.
    // The MainScreen provides the Scaffold, AppBar (if any), and BottomNavBar.
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(left: 40, right: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Changed to start
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 70),
            // This Row no longer needs a back button. It just displays the title.
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Settings", style: TextStyle(
                    color: darkBlue,
                    fontSize: 25,
                    fontWeight: FontWeight.bold
                ),
                )
              ],
            ),
            const SizedBox(height: 30),
            const Row(
              children: [
                Text(
                  "General", style: TextStyle(
                    fontSize: 20
                ),
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.wifi),
                const SizedBox(width: 20),
                const Text(
                  "Connect to Stethoscope", style: TextStyle(
                    fontSize: 17
                ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: (){},
                  child: const Icon(Icons.arrow_forward),
                )
              ],
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                // This navigation is correct for pushing a detail screen.
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PlacementGuide()
                    )
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_pin),
                  SizedBox(width: 20),
                  Text(
                    "Stethoscope Placement Guide", style: TextStyle(
                      fontSize: 17
                  ),
                  ),
                  Spacer(),
                  // This nested GestureDetector is redundant. The outer one handles the tap.
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Row(
              children: [
                Text(
                  "Account & Security", style: TextStyle(
                    fontSize: 20
                ),
                )
              ],
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const ProfilePage()
                )
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 20),
                  Text(
                    "Manage Profile", style: TextStyle(
                      fontSize: 17
                  ),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const ChangePassword()
                )
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline),
                  SizedBox(width: 20),
                  Text(
                    "Change Password", style: TextStyle(
                      fontSize: 17
                  ),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Row(
              children: [
                // This seems like a duplicate heading. You may want to remove it.
                Text(
                  "Account & Security", style: TextStyle(
                    fontSize: 20
                ),
                )
              ],
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: (){
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UserManualScreen()
                    )
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.book),
                  SizedBox(width: 20),
                  Text(
                    "User Manual", style: TextStyle(
                      fontSize: 17
                  ),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: (){
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TermsPage()
                    )
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.rule),
                  SizedBox(width: 20),
                  Text(
                    "Terms & Privacy Policy", style: TextStyle(
                      fontSize: 17
                  ),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
