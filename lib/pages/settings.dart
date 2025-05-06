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
  final TextEditingController _passwordController = TextEditingController();
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
                  GestureDetector(
                      onTap: (){
                        Navigator.pop(context);
                      },
                      child: Icon(Icons.arrow_back, size: 35)
                  ),
                  SizedBox(width: 20),
                  Text(
                    "Settings", style: TextStyle(
                    color: darkBlue,
                    fontSize: 25,
                    fontWeight: FontWeight.bold
                  ),
                  )
                ],
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  const Text(
                    "General", style: TextStyle(
                    fontSize: 20
                  ),
                  )
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.wifi),
                  SizedBox(width: 20),
                  Text(
                    "Connect to Stethoscope", style: TextStyle(
                    fontSize: 17
                  ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: (){},
                    child: Icon(Icons.arrow_forward),
                  )
                ],
              ),
              SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PlacementGuide()
                      )
                  );
                },
                child: Row(
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
                    GestureDetector(
                      onTap: (){},
                      child: Icon(Icons.arrow_forward),
                    )
                  ],
                ),
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  const Text(
                    "Account & Security", style: TextStyle(
                      fontSize: 20
                  ),
                  )
                ],
              ),
              SizedBox(height: 30),
              GestureDetector(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ProfilePage()
                  )
                  );
                },
                child: Row(
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
                    GestureDetector(
                      onTap: (){},
                      child: Icon(Icons.arrow_forward),
                    )
                  ],
                ),
              ),
              SizedBox(height: 30),
              GestureDetector(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ChangePassword()
                  )
                  );
                },
                child: Row(
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
                    GestureDetector(
                      onTap: (){},
                      child: Icon(Icons.arrow_forward),
                    )
                  ],
                ),
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  const Text(
                    "Account & Security", style: TextStyle(
                      fontSize: 20
                  ),
                  )
                ],
              ),
              SizedBox(height: 30),
              GestureDetector(
                onTap: (){
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UserManualScreen()
                      )
                  );
                },
                child: Row(
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
                    GestureDetector(
                      onTap: (){},
                      child: Icon(Icons.arrow_forward),
                    )
                  ],
                ),
              ),
              SizedBox(height: 30),
              GestureDetector(
                onTap: (){
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TermsPage()
                      )
                  );
                },
                child: Row(
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
                    GestureDetector(
                      onTap: (){},
                      child: Icon(Icons.arrow_forward),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
