import 'package:flutter/material.dart';
import 'package:heartcloud/utils/colors.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

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
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Terms of Service", style: TextStyle(
                      color: darkBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 25
                    ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "1. Introduction", style: TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20
                    ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "Welcome to HeartCloud. By using our platform, you agree to these Terms of Service. HeartCloud is designed to assist patients and healthcare professionals in monitoring health data securely and confidentially.",
                            softWrap: true,
                            textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "2. User Eligibility", style: TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20
                    ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "HeartCloud is available for use by both patients and licensed healthcare professionals. By registering, you confirm that you are either a patient managing your health data or a doctor authorized to handle patient data.",
                            softWrap: true,
                            textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "3. Use of Service", style: TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20
                    ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("Patients may record, track, and monitor their health data."),
                          ),
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("Doctors may access patient data with consent for medical analysis and care."),
                          ),
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("Users must not misuse or share unauthorized access to data."),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "4. Confidentiality and Security", style: TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20
                    ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "HeartCloud takes data security seriously. All medical and personal information is protected through encryption and access control. Users must not attempt to breach security or access data they are not authorized to view.",
                            softWrap: true,
                            textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "5. Data Ownership", style: TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20
                    ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "Patients retain ownership of their data. Healthcare providers may access it only with patient consent. HeartCloud does not sell or distribute personal health data to third parties.",
                            softWrap: true,
                            textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "6. Prohibited Conduct", style: TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20
                    ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "Users must not:",
                                softWrap: true,
                                textAlign: TextAlign.justify,
                              ),
                            ],
                          ),
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("Patients may record, track, and monitor their health data."),
                          ),
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("Doctors may access patient data with consent for medical analysis and care."),
                          ),
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("Users must not misuse or share unauthorized access to data."),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "7. Modifications and Terminations", style: TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20
                    ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "HeartCloud reserves the right to update these terms and modify or terminate services at any time. Users will be notified of significant changes.",
                            softWrap: true,
                            textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Privacy Policy", style: TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 25
                    ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "1. Data Collection", style: TextStyle(
                                  color: darkBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20
                              ),
                              )
                            ],
                          ),
                          Text(
                            "We collect personal health data to enhance user experience, including:",
                            softWrap: true,
                            textAlign: TextAlign.justify,
                          ),
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("Name, contact details, and medical history (for registered users)"),
                          ),
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("Health records and biometric data entered by users"),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "2. How We Use Your Data", style: TextStyle(
                                  color: darkBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20
                              ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "Your data is used for:",
                                softWrap: true,
                                textAlign: TextAlign.justify,
                              ),
                            ],
                          ),
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("Personalized health tracking"),
                          ),
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("Medical insights for healthcare professionals (with consent)"),
                          ),
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("Service improvement and security enhancements"),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "3. Data Protection", style: TextStyle(
                                  color: darkBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20
                              ),
                              )
                            ],
                          ),
                          Text(
                            "We implement strict security measures, including:",
                            softWrap: true,
                            textAlign: TextAlign.justify,
                          ),
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("End-to-end encryption for stored and transmitted data"),
                          ),
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("Limited access control based on user roles"),
                          ),
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("Regular audits to ensure data integrity"),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "4. Data Sharing and Third Parties", style: TextStyle(
                                  color: darkBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20
                              ),
                              )
                            ],
                          ),
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("We do not sell or share patient data with third parties for marketing purposes."),
                          ),
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("Data is shared only with authorized doctors and medical personnel with patient consent."),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "5. User Rights", style: TextStyle(
                                  color: darkBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20
                              ),
                              )
                            ],
                          ),
                          Text(
                            "Patients and doctors have the right to:",
                            softWrap: true,
                            textAlign: TextAlign.justify,
                          ),
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("Access, update, or delete their personal data"),
                          ),
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("Withdraw consent for data sharing"),
                          ),
                          ListTile(
                            leading: Icon(Icons.circle, size: 8),
                            title: Text("Request clarification on data usage"),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "6. Retention Policty", style: TextStyle(
                                  color: darkBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20
                              ),
                              )
                            ],
                          ),
                          Text(
                            "We retain user data for as long as the account remains active or as required by law. Users may request data deletion at any time.",
                            softWrap: true,
                            textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "7. Contact Information", style: TextStyle(
                                  color: darkBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20
                              ),
                              )
                            ],
                          ),
                          Text(
                            "For inquiries regarding our Terms of Service or Privacy Policy, contact us at support@heartcloud.com.",
                            softWrap: true,
                            textAlign: TextAlign.justify,
                          )
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 70)
              ],
            ),
          ),
        )
    );
  }
}
