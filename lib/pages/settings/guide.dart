import 'package:flutter/material.dart';
import 'package:heartcloud/utils/colors.dart';

class PlacementGuide extends StatelessWidget {
  const PlacementGuide({super.key});

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
                      child: Icon(
                          Icons.arrow_back, size: 35,
                      )
                  ),
                  SizedBox(width: 20),
                  Text(
                    "Settings", style: TextStyle(
                    color: darkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 25
                  ),
                  )
                ],
              )
            ],
          ),
        ),
      )
    );
  }
}
