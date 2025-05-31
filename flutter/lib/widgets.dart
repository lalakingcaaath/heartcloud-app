import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heartcloud/pages/patient_profile/patientProfilePage.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:waveform_flutter/waveform_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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
  final TextEditingController controller;

  const EmailField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.email_outlined),
          labelText: "Email Address",
          hintText: "example@email.com",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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

class AgeField extends StatelessWidget {
  final TextEditingController controller;

  const AgeField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.cake_outlined),
          labelText: "Age",
          hintText: "Input patient age",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
  final TextEditingController controller;

  const PasswordField({super.key, required this.controller});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextField(
        controller: widget.controller,
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
  final TextEditingController controller;

  const ConfirmPasswordField({super.key, required this.controller});

  @override
  State<ConfirmPasswordField> createState() => _ConfirmPasswordFieldState();
}

class _ConfirmPasswordFieldState extends State<ConfirmPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextField(
        controller: widget.controller,
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
          labelText: "Confirm Password",
          hintText: "*********",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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

class ContactInformation extends StatelessWidget {
  final TextEditingController controller;

  const ContactInformation({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.contacts),
          labelText: "Contact Information",
          hintText: "Contact Information",
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
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold
          ),
          )
        ],
      ),
    );
  }
}

class PatientCard extends StatefulWidget {
  final String name;
  final String date;
  final Color backgroundColor; // Use Color for background
  final dynamic patientData;  // Add this line to hold patient data

  const PatientCard({
    super.key,
    required this.name,
    required this.date,
    required this.backgroundColor, // Accept background color directly
    required this.patientData
  });

  @override
  State<PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<PatientCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => PatientProfile(
          patientData: widget.patientData,
        )));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8), // Spacing between cards
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.backgroundColor, // Use the passed backgroundColor
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black),
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
              "${widget.date}", // Ensures time isn't null
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
    );
  }
}

class StethologsCard extends StatelessWidget {
  final QueryDocumentSnapshot recordingData;

  const StethologsCard({super.key, required this.recordingData});

  Future<void> _navigateToPatientProfile(BuildContext context, String doctorId, String patientId) async {
    try {
      DocumentSnapshot patientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .collection('patients')
          .doc(patientId)
          .get();

      if (patientDoc.exists) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientProfile(patientData: patientDoc),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patient profile not found.'), duration: Duration(seconds: 2))
        );
        print("Patient document not found for patientId: $patientId under doctorId: $doctorId");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading patient profile: ${e.toString().split('\n').first}'))
      );
      print("Error fetching patient document for profile: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    // Extract data safely with fallbacks
    String patientFirstName = recordingData.get('patientFirstName') ?? 'N/A';
    String patientLastName = recordingData.get('patientLastName') ?? 'N/A';
    String patientFullName = (patientFirstName == 'N/A' && patientLastName == 'N/A') ? 'Unknown Patient' : '$patientFirstName $patientLastName'.trim();

    Timestamp? recordedAtTimestamp = recordingData.get('recordedAt') as Timestamp?;
    String recordedDate = recordedAtTimestamp != null
        ? DateFormat('MMM d, yyyy - hh:mm a').format(recordedAtTimestamp.toDate())
        : 'Date N/A';

    String checkupType = recordingData.get('auscultationType') ?? 'Type N/A';
    String doctorId = recordingData.get('doctorId') ?? ''; // Needed for patient profile navigation
    String patientId = recordingData.get('patientId') ?? ''; // Needed for patient profile navigation


    return InkWell( // Make the card tappable
      onTap: () {
        if (doctorId.isNotEmpty && patientId.isNotEmpty) {
          _navigateToPatientProfile(context, doctorId, patientId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Patient information missing for navigation.'), duration: Duration(seconds: 2))
          );
          print("Error: doctorId or patientId is missing in recording document.");
        }
      },
      child: Container(
        padding: const EdgeInsets.all(15), // Increased padding
        margin: const EdgeInsets.only(bottom: 15), // Added margin between cards
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300), // Softer border
          borderRadius: BorderRadius.circular(12), // Softer radius
          color: PatientCardColor2, // Ensure this color is defined in your colors.dart
          boxShadow: [ // Optional: Add a subtle shadow
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
          children: [
            Text(
              patientFullName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: darkBlue, // Assuming darkBlue is defined
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today_outlined, "Recorded: $recordedDate"),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.medical_services_outlined, "Type: $checkupType"),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.check_circle_outline, "Status: Recorded", color: Colors.green.shade700),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded( // Allow text to wrap if too long
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: color ?? Colors.black87),
          ),
        ),
      ],
    );
  }
}

class WaveForm extends StatefulWidget {
  const WaveForm({super.key});

  @override
  State<WaveForm> createState() => _WaveFormState();
}

class _WaveFormState extends State<WaveForm> {
  final Stream<Amplitude> _amplitudeStream = createRandomAmplitudeStream();

  @override
  Widget build(BuildContext context) => AnimatedWaveList(
      stream: _amplitudeStream,
      barBuilder: (animation, amplitude) => WaveFormBar(
        amplitude: amplitude,
        animation: animation,
        color: Colors.red,
      )
  );
}
