import 'package:flutter/material.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/pages/login.dart';

void main() {
  runApp(const SplashScreen());
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage())
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [darkBlue, mediumBlue, lightBlue],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SingleChildScrollView(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 100),
                          child: Image.asset('images/hclogo-nobg(white).png'),
                        ),
                        const Text(
                          "HeartCloud",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 50
                          ),
                        ),
                        const Text(
                          "Auscultation",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontStyle: FontStyle.italic
                          ),
                        ),
                        const Text(
                          "Reimagined",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontStyle: FontStyle.italic
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 60),
                          child: const Text(
                            "Tap to start",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
              ),
            ),
          ),
        )
    );
  }
}
