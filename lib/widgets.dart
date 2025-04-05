import 'package:flutter/material.dart';
import 'package:heartcloud/pages/patient_profile/patientProfilePage.dart';
import 'package:heartcloud/utils/colors.dart';


class FirstName extends StatelessWidget {
  final TextEditingController controller;

  const FirstName({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.person_2_outlined),
          labelText: "First Name",
          hintText: "First Name",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class LastName extends StatelessWidget {
  final TextEditingController controller;

  const LastName({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.person_2_outlined),
          labelText: "Last Name",
          hintText: "Last Name",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class EmailField extends StatelessWidget {

  const EmailField({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.email_outlined),
          labelText: "Email Address",
          hintText: "example@email.com",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class AgeField extends StatefulWidget {
  const AgeField({super.key});

  @override
  State<AgeField> createState() => _AgeFieldState();
}

class _AgeFieldState extends State<AgeField> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.email_outlined),
          labelText: "Age",
          hintText: "Input patient age",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}


class PasswordField extends StatefulWidget {
  const PasswordField({super.key});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextField(
        obscureText: _obscureText,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
          labelText: "Password",
          hintText: "*********",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class ConfirmPasswordField extends StatefulWidget {
  final TextEditingController passwordController;

  const ConfirmPasswordField({super.key, required this.passwordController});

  @override
  State<ConfirmPasswordField> createState() => _ConfirmPasswordFieldState();
}

class _ConfirmPasswordFieldState extends State<ConfirmPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextField(
        obscureText: _obscureText,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
          labelText: "Password",
          hintText: "*********",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class RoleDropdown extends StatefulWidget {
  final String? selectedRole;
  final Function(String) onRoleChanged;

  const RoleDropdown({Key? key, required this.selectedRole, required this.onRoleChanged}) : super(key: key);

  @override
  State<RoleDropdown> createState() => _RoleDropdownState();
}

class _RoleDropdownState extends State<RoleDropdown> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: DropdownButtonFormField<String>(
        value: widget.selectedRole,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.person_outline),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        items: const [
          DropdownMenuItem(value: 'Patient', child: Text('Patient')),
          DropdownMenuItem(value: 'Doctor', child: Text('Doctor')),
        ],
        onChanged: (value) {
          if (value != null) {
            widget.onRoleChanged(value);
          }
        },
      ),
    );
  }
}


class GenderDropdown extends StatefulWidget {
  const GenderDropdown({super.key});

  @override
  State<GenderDropdown> createState() => _GenderDropdownState();
}

class _GenderDropdownState extends State<GenderDropdown> {
  String _selectedGender = "Male";

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.person_outline), // Icon for consistency
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        items: const [
          DropdownMenuItem(value: 'Male', child: Text('Male')),
          DropdownMenuItem(value: 'Female', child: Text('Female')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedGender = value!;
          });
        },
      ),
    );
  }
}


class StatusCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final double? progress;

  const StatusCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.progress
  });

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: darkBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.progress != null)
            Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: widget.progress,
                  strokeWidth: 5,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation(Colors.green),
                ),
                Icon(
                  widget.icon, color: Colors.white, size: 30,
                )
              ],
            )
          else
            Icon(widget.icon, color: Colors.white, size: 40),
          SizedBox(height: 10),
          Text(
            widget.title, style: TextStyle(
            color: Colors.white, fontSize: 14,
          ),
          ),
          Text(
            widget.value, style: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold
          ),
          )
        ],
      ),
    );
  }
}

class PatientCard extends StatefulWidget {
  final String name;
  final String? time;
  final String date;
  final bool isHighlighted; // For alternating colors

  const PatientCard({
    super.key,
    required this.name,
    this.time,
    required this.date,
    this.isHighlighted = false, // Default to false
  });

  @override
  State<PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<PatientCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context) => PatientProfile()));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8), // Spacing between cards
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isHighlighted ? PatientCardColor1 : PatientCardColor2, // Alternating colors
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              "${widget.time ?? ''}, ${widget.date}", // Ensures time isn't null
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReplayButton extends StatefulWidget {
  const ReplayButton({super.key});

  @override
  State<ReplayButton> createState() => _ReplayButtonState();
}

class _ReplayButtonState extends State<ReplayButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){},
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(15)
        ),
        child: Row(
          children: [
            Icon(Icons.replay),
            Spacer(),
            Text("Replay")
          ],
        ),
      ),
    );
  }
}

class RecordButton extends StatefulWidget {
  const RecordButton({super.key});

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){},
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(15)
        ),
        child: Row(
          children: [
            Icon(Icons.fiber_manual_record),
            Spacer(),
            Text("Record")
          ],
        ),
      ),
    );
  }
}

class PatientButton extends StatefulWidget {
  const PatientButton({super.key});

  @override
  State<PatientButton> createState() => _PatientButtonState();
}

class _PatientButtonState extends State<PatientButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){},
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(15)
        ),
        child: Row(
          children: [
            Icon(Icons.person),
            Spacer(),
            Text("Patient")
          ],
        ),
      ),
    );;
  }
}

class StethologsCard extends StatefulWidget {
  const StethologsCard({super.key});

  @override
  State<StethologsCard> createState() => _StethologsCardState();
}

class _StethologsCardState extends State<StethologsCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(15),
        color: PatientCardColor2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "John Dela Cruz"
              )
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Last Visited: Mar 18, 2025"
              )
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Checkup Type: Heart Exam"
              )
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Status: Recorded"
              )
            ],
          )
        ],
      ),
    );
  }
}
