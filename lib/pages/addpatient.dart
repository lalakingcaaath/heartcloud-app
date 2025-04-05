import 'package:flutter/material.dart';
import 'package:heartcloud/widgets.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/utils/bottom_navbar.dart';

class Addpatient extends StatefulWidget {
  const Addpatient({super.key});

  @override
  State<Addpatient> createState() => _AddpatientState();
}

class _AddpatientState extends State<Addpatient> {
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose(){
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
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
                    "Patient Profile Data Entry", style: TextStyle(
                    color: darkBlue,
                    fontSize: 25,
                    fontWeight: FontWeight.bold
                  ),
                  )
                ],
              ),
              SizedBox(height: 50),
              SizedBox(height: 20),
              Center(child: GenderDropdown()),
              SizedBox(height: 20),
              Center(child: AgeField()),
              SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                      child: GestureDetector(
                        onTap: (){},
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: darkBlue,
                              borderRadius: BorderRadius.circular(10)
                          ),
                          child: Center(
                            child: Text(
                              "Add patient", style: TextStyle(
                                color: Colors.white,
                                fontSize: 18
                            ),
                            ),
                          ),
                        ),
                      )
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped
      ),
    );
  }
}
