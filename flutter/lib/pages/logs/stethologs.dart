import 'package:flutter/material.dart';
import 'package:heartcloud/utils/auth_provider.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/pages/patient_profile/patientProfilePage.dart';
import 'package:heartcloud/pages/settings/manageProfile.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:heartcloud/utils/app_user.dart';

class StethoLogs extends StatefulWidget {
  final Function(DocumentSnapshot) onPatientSelected;
  const StethoLogs({super.key, required this.onPatientSelected});

  @override
  State<StethoLogs> createState() => _StethoLogsState();
}

class _StethoLogsState extends State<StethoLogs> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isPatient = authProvider.isPatient;
    final AppUser? currentUser = authProvider.appUser;

    final String subtitle = isPatient
        ? "View your past recorded stethoscope sessions."
        : "View past patient checkups and recorded stethoscope sessions.";

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.only(top: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Stethoscope Logs",
                style: TextStyle(
                  color: darkBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              SearchBar(
                controller: _searchController,
                leading: const Icon(Icons.search),
                hintText: "Search by patient name or type...",
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 20),
              if (currentUser == null)
                const Center(child: Text("Please log in to view logs."))
              else
                StreamBuilder<QuerySnapshot>(
                  stream: () {
                    Query query = FirebaseFirestore.instance.collectionGroup('auscultation_recordings');
                    if (isPatient) {
                      return query
                          .where('patientId', isEqualTo: currentUser.uid)
                          .orderBy('recordedAt', descending: true)
                          .snapshots();
                    } else {
                      return query
                          .where('doctorId', isEqualTo: currentUser.uid)
                          .orderBy('recordedAt', descending: true)
                          .snapshots();
                    }
                  }(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Error: ${snapshot.error}\n\nThis query may require a Firestore index. Please check the debug console for a link to create it.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('No stethoscope logs found.', style: TextStyle(fontSize: 16)),
                          )
                      );
                    }

                    var allRecordings = snapshot.data!.docs;
                    List<QueryDocumentSnapshot> filteredRecordings = allRecordings;

                    if (_searchQuery.isNotEmpty) {
                      filteredRecordings = allRecordings.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final String patientFirstName = (data['patientFirstName'] as String? ?? '').toLowerCase();
                        final String patientLastName = (data['patientLastName'] as String? ?? '').toLowerCase();
                        final String auscultationType = (data['auscultationType'] as String? ?? '').toLowerCase();

                        return patientFirstName.contains(_searchQuery) ||
                            patientLastName.contains(_searchQuery) ||
                            auscultationType.contains(_searchQuery);
                      }).toList();
                    }

                    if (filteredRecordings.isEmpty) {
                      return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('No logs match your search.', style: TextStyle(fontSize: 16)),
                          )
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredRecordings.length,
                      itemBuilder: (context, index) {
                        return StethologsCard(
                          recordingData: filteredRecordings[index],
                          onPatientSelected: widget.onPatientSelected,
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class StethologsCard extends StatelessWidget {
  final QueryDocumentSnapshot recordingData;
  final Function(DocumentSnapshot) onPatientSelected;

  const StethologsCard({
    super.key,
    required this.recordingData,
    required this.onPatientSelected
  });

  Future<void> _navigateToPatientProfileForDoctor(BuildContext context) async {
    final String doctorId = recordingData.get('doctorId') ?? '';
    final String patientId = recordingData.get('patientId') ?? '';

    try {
      DocumentSnapshot patientDoc = await FirebaseFirestore.instance.collection('users').doc(doctorId).collection('patients').doc(patientId).get();
      if (patientDoc.exists) {
        onPatientSelected(patientDoc);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient profile not found.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading patient profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    String patientFirstName = recordingData.get('patientFirstName') ?? 'N/A';
    String patientLastName = recordingData.get('patientLastName') ?? 'N/A';
    String patientFullName = '$patientFirstName $patientLastName'.trim();
    Timestamp? recordedAtTimestamp = recordingData.get('recordedAt') as Timestamp?;
    String recordedDate = recordedAtTimestamp != null ? DateFormat('MMM d, yyyy - hh:mm a').format(recordedAtTimestamp.toDate()) : 'Date N/A';
    String checkupType = recordingData.get('auscultationType') ?? 'Type N/A';

    return InkWell(
      onTap: () {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        if (authProvider.isDoctor) {
          _navigateToPatientProfileForDoctor(context);
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: PatientCardColor2,
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(patientFullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: darkBlue)),
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
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: color ?? Colors.black87),
          ),
        ),
      ],
    );
  }
}