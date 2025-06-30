import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:heartcloud/pages/login.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Best practice: Use an enum for roles to prevent typos.
enum UserRole { patient, doctor }

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  bool _agreeToTerms = false;

  // --- NEW: State variable to hold the selected role ---
  // We default to 'patient' for a better user experience.
  UserRole _selectedRole = UserRole.patient;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please agree to the terms and conditions.")),
      );
      return;
    }

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    try {
      // Show a loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator(color: headerColor1)),
      );

      // Register user with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      // --- MODIFIED: Added 'role' to the Firestore document ---
      // We convert the enum to a simple string for storage.
      String roleString = _selectedRole.toString().split('.').last;

      // Store additional info in Firestore
      await FirebaseFirestore.instance.collection("users").doc(user!.uid).set({
        "uid": user.uid,
        "firstName": _firstName.text.trim(),
        "lastName": _lastName.text.trim(),
        "email": email, // It's good practice to store the email here too.
        "role": roleString, // Storing the user's selected role.
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Hide the loading indicator
      if(mounted) Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Successful!")),
      );

      if(mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false, // This removes all previous routes
        );
      }

    } on FirebaseAuthException catch (e) {
      // Hide the loading indicator
      if(mounted) Navigator.of(context).pop();
      // Provide more specific error messages
      String message = "An error occurred. Please try again.";
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if(mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred: ${e.toString()}")),
      );
    }
  }

  void _showPolicyDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(content),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const String combinedPolicies = '''
Terms & Conditions

Please read these Terms and Conditions ("Terms") carefully before using the HeartCloud mobile application (the "Service") operated by us.

1. Agreement to Terms
By creating an account and using our Service, you agree to be bound by these Terms. If you do not agree to these Terms, do not use the Service.

2. User Accounts
- Account Creation: To use our Service, you must register for an account. You agree to provide information that is accurate, complete, and current at all times.
- Account Responsibility: You are responsible for safeguarding the password that you use to access the Service and for any activities or actions under your password.
- Account Security: You agree not to disclose your password to any third party. You must notify us immediately upon becoming aware of any breach of security or unauthorized use of your account.

3. Acceptable Use
You agree not to use the Service for any purpose that is illegal or prohibited by these Terms.

4. Intellectual Property
The Service and its original content, features, and functionality are and will remain the exclusive property of HeartCloud and its licensors.

5. Termination
We may terminate or suspend your account and bar access to the Service immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.

6. Disclaimer of Warranties
The Service is provided on an "AS IS" and "AS AVAILABLE" basis. Your use of the Service is at your sole risk.

7. Limitation of Liability
In no event shall HeartCloud, nor its directors, employees, or partners, be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of the Service.

8. Governing Law
These Terms shall be governed and construed in accordance with the laws of the Republic of the Philippines.

9. Changes to Terms
We reserve the right to modify or replace these Terms at any time.

10. Contact Us
If you have any questions about these Terms, please contact us at: support@heartcloud.app


------------------------------------


Confidentiality Policy


Welcome to HeartCloud. We are committed to protecting your privacy and handling your personal data in an open and transparent manner.

1. Information We Collect
- Account Information: Your first name, last name, and email address.
- User Content: Any data you voluntarily create within the application.
- Usage Data: Information about how you interact with our service.

2. How We Use Your Information
- To Provide and Maintain Our Service.
- To Improve Our Service.
- To Communicate With You.
- For Security and Safety.

3. How We Share and Disclose Information
We do not sell your personal data. We only share information with third-party service providers like Google Firebase for backend infrastructure, or for legal reasons if required by law.

4. Data Security
We implement strong security measures to protect your information, including encryption. However, no system is 100% secure.

5. Data Retention
We retain your personal information as long as your account is active. You can delete your account at any time.

6. Children's Privacy
Our service is not directed to individuals under the age of 13.

7. Changes to This Policy
We may update this Confidentiality Policy from time to time. We will notify you of any changes by posting the new policy within our application.

8. Contact Us
If you have any questions about this Confidentiality Policy, please contact us at: support@heartcloud.app
''';
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [darkBlue, mediumBlue, lightBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.only(left: 40, right: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(top: 60),
                  child: Text(
                    "Register",
                    style: TextStyle(color: headerColor1, fontSize: 40),
                  ),
                ),
                Container(
                  child: Text(
                    "Welcome to HeartCloud - Let's create your account",
                    style: TextStyle(color: headerColor1, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 50),
                Center(child: FirstName(controller: _firstName)),
                const SizedBox(height: 20),
                Center(child: LastName(controller: _lastName)),
                const SizedBox(height: 20),
                Center(child: EmailField(controller: _emailController)),
                const SizedBox(height: 20),
                Center(child: PasswordField(controller: _passwordController)),
                const SizedBox(height: 20),
                Center(
                    child: ConfirmPasswordField(
                        controller: _confirmPasswordController)),
                const SizedBox(height: 20),
                Text(
                  "I am a:",
                  style: TextStyle(color: headerColor1, fontSize: 16),
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<UserRole>(
                        title: Text('Patient', style: TextStyle(color: headerColor1)),
                        value: UserRole.patient,
                        groupValue: _selectedRole,
                        onChanged: (UserRole? value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                        activeColor: headerColor1,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<UserRole>(
                        title: Text('Doctor', style: TextStyle(color: headerColor1)),
                        value: UserRole.doctor,
                        groupValue: _selectedRole,
                        onChanged: (UserRole? value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                        activeColor: headerColor1,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (bool? value) {
                        setState(() {
                          _agreeToTerms = value!;
                        });
                      },
                      checkColor: lightBlue,
                      activeColor: darkBlue,
                      side: BorderSide(color: headerColor1),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: 'I agree to the ',
                          style: TextStyle(color: headerColor1, fontSize: 12),
                          children: <TextSpan>[
                            TextSpan(
                                text: 'Terms, Conditions, and Policy',
                                style: TextStyle(
                                    color: headerColor2,
                                    decoration: TextDecoration.underline),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    _showPolicyDialog(
                                        "HeartCloud Policies", combinedPolicies);
                                  }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: _registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 120, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Register"),
                  ),
                ),
                const SizedBox(height: 50),
                Center(
                  child: Text(
                    "Already have an account?",
                    style: TextStyle(
                      color: headerColor1,
                      fontSize: 18,
                    ),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: Text(
                      "Sign In",
                      style: TextStyle(
                        color: headerColor2,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40), // Added padding at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}
