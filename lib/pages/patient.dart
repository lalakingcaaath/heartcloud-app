import 'package:flutter/material.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/utils/bottom_navbar.dart';
import 'package:heartcloud/widgets.dart';
import 'addpatient.dart';

class PatientList extends StatefulWidget {
  const PatientList({super.key});

  @override
  State<PatientList> createState() => _PatientListState();

}

class _PatientListState extends State<PatientList> {
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
              SearchBar(
                leading: const Icon(Icons.search),
                hintText: "Search for patients",
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Patient List", style: TextStyle(
                    color: darkBlue,
                    fontSize: 25,
                    fontWeight: FontWeight.bold
                  ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: (){},
                    child: Icon(Icons.sort),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Name", style: TextStyle(
                    fontSize: 14
                  ),
                  ),
                  Spacer(),
                  Text(
                    "Registered Date", style: TextStyle(
                      fontSize: 14
                  ),
                  ),
                ],
              ),
              SizedBox(
                height: 75,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: const [
                    PatientCard(
                      name: "John Dela Cruz",
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
                      date: "Feb. 25, 2025",
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Addpatient()
              )
          );
        },
        backgroundColor: darkBlue,
        shape: const CircleBorder(),
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
