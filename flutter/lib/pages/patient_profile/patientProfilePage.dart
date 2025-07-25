import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

class PatientProfile extends StatefulWidget {
  final DocumentSnapshot patientData;
  final VoidCallback onBack;
  const PatientProfile({super.key, required this.patientData, required this.onBack});

  @override
  State<PatientProfile> createState() => _PatientProfileState();
}

class _PatientProfileState extends State<PatientProfile> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _durationSubscription, _positionSubscription, _playerCompleteSubscription, _playerStateChangeSubscription;
  String? get _currentDoctorId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _playerStateChangeSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
    _durationSubscription = _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => _duration = newDuration);
    });
    _positionSubscription = _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => _position = newPosition);
    });
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) setState(() { _playerState = PlayerState.completed; _position = Duration.zero; _currentlyPlayingUrl = null; });
    });
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _deleteRecording(String patientId, String recordingId, String fileNameInStorage) async {
    final doctorId = _currentDoctorId;
    if (doctorId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Could not authenticate doctor.")));
      return;
    }
    try {
      final firestoreDocRef = FirebaseFirestore.instance.collection('users').doc(doctorId).collection('patients').doc(patientId).collection('auscultation_recordings').doc(recordingId);
      await firestoreDocRef.delete();
      if (fileNameInStorage.isNotEmpty) {
        final storageRef = FirebaseStorage.instance.ref().child('patient_auscultations/$doctorId/$patientId/$fileNameInStorage');
        await storageRef.delete();
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recording deleted successfully."), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete recording: ${e.toString()}"), backgroundColor: Colors.red));
    }
  }

  Future<void> _playPauseAudio(String url) async {
    if (_currentlyPlayingUrl == url && _playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else if (_currentlyPlayingUrl == url && _playerState == PlayerState.paused) {
      await _audioPlayer.resume();
    } else {
      await _audioPlayer.stop();
      if (mounted) setState(() { _position = Duration.zero; _duration = Duration.zero; });
      await _audioPlayer.play(UrlSource(url));
      if (mounted) setState(() => _currentlyPlayingUrl = url);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  // **** START OF NEW FEATURE: Add/Edit Comment Logic ****
  Future<void> _saveComment(String patientId, String recordingId, String comment) async {
    final doctorId = _currentDoctorId;
    if (doctorId == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .collection('patients')
          .doc(patientId)
          .collection('auscultation_recordings')
          .doc(recordingId);

      await docRef.update({'doctorComment': comment});

      if(mounted) {
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Comment saved."), backgroundColor: Colors.green,));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save comment: $e"), backgroundColor: Colors.red));
    }
  }

  void _showCommentDialog(QueryDocumentSnapshot recordingDoc) {
    final String patientId = widget.patientData.id;
    final String recordingId = recordingDoc.id;
    final String currentComment = (recordingDoc.data() as Map<String, dynamic>).containsKey('doctorComment')
        ? recordingDoc['doctorComment']
        : "";

    final TextEditingController commentController = TextEditingController(text: currentComment);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Doctor's Comment"),
          content: TextField(
            controller: commentController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: "Enter your findings here...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _saveComment(patientId, recordingId, commentController.text);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
  // **** END OF NEW FEATURE ****


  Widget _buildAudioPlayerControls(QueryDocumentSnapshot recordingDoc) {
    String audioUrl = recordingDoc['downloadUrl'] as String;
    bool isCurrentlyPlayingThis = _currentlyPlayingUrl == audioUrl;

    final data = recordingDoc.data() as Map<String, dynamic>;
    final String doctorComment = data.containsKey('doctorComment') ? data['doctorComment'] : "";

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row for title and edit button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Type: ${data['auscultationType'] ?? 'N/A'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                IconButton(
                  icon: const Icon(Icons.edit_note, color: Colors.blueGrey),
                  tooltip: "Add/Edit Comment",
                  onPressed: () => _showCommentDialog(recordingDoc),
                )
              ],
            ),
            const SizedBox(height: 4),
            Text("Recorded: ${data['recordedAt'] != null ? DateFormat('MMM d, yyyy - hh:mm a').format((data['recordedAt'] as Timestamp).toDate()) : 'N/A'}", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            Text("Filename: ${data['fileNameInStorage'] ?? 'N/A'}", style: TextStyle(fontSize: 13, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
            if (data['durationSeconds'] != null) Text("ESP32 Duration: ${data['durationSeconds']}s", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [IconButton(icon: Icon(isCurrentlyPlayingThis && _playerState == PlayerState.playing ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 40, color: darkBlue), onPressed: () => _playPauseAudio(audioUrl))],
            ),
            if (isCurrentlyPlayingThis)
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(activeTrackColor: darkBlue, inactiveTrackColor: darkBlue.withOpacity(0.3), trackHeight: 2.0, thumbColor: darkBlue, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0), overlayColor: darkBlue.withAlpha(0x29), overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0)),
                    child: Slider(
                      min: 0, max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0, value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                      onChanged: (value) async {
                        final newPosition = Duration(seconds: value.toInt());
                        await _audioPlayer.seek(newPosition);
                        if (_playerState != PlayerState.playing) await _audioPlayer.resume();
                      },
                    ),
                  ),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_formatDuration(_position)), Text(_formatDuration(_duration))])),
                ],
              ),

            // **** START OF NEW FEATURE: Display Comment ****
            const Divider(height: 24),
            Text("Doctor's Comment:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4)
              ),
              child: Text(
                doctorComment.isNotEmpty ? doctorComment : "No comment added yet.",
                style: TextStyle(fontStyle: doctorComment.isNotEmpty ? FontStyle.normal : FontStyle.italic, color: Colors.grey.shade700),
              ),
            ),
            // **** END OF NEW FEATURE ****
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var patient = widget.patientData;
    String patientId = widget.patientData.id;
    String? doctorId = _currentDoctorId;

    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: widget.onBack,
                ),
                Expanded(
                  child: Text(
                    "${patient['firstName'] ?? ""} ${patient['lastName'] ?? ""}'s Profile",
                    style: TextStyle(
                      color: darkBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text("Patient Details", style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow("FIRST NAME:", patient['firstName'] ?? "N/A"),
                    _buildDetailRow("LAST NAME:", patient['lastName'] ?? "N/A"),
                    _buildDetailRow("GENDER:", patient['gender'] ?? "N/A"),
                    _buildDetailRow("CONTACT INFO:", patient['contactInfo'] ?? "N/A"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text("Recording History", style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 10),
            if (doctorId == null)
              const Center(child: Text("Error: Could not identify doctor."))
            else
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(doctorId).collection('patients').doc(patientId).collection('auscultation_recordings').orderBy('recordedAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error loading recordings: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("No recordings found for this patient.", style: TextStyle(fontSize: 16)),
                      ),
                    );
                  } else {
                    var recordings = snapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recordings.length,
                      itemBuilder: (context, index) {
                        final recordingDoc = recordings[index];
                        final data = recordingDoc.data() as Map<String, dynamic>;
                        final fileName = data['fileNameInStorage'] as String? ?? '';
                        return Dismissible(
                          key: Key(recordingDoc.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) => _deleteRecording(patientId, recordingDoc.id, fileName),
                          background: Container(color: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 20), alignment: Alignment.centerRight, child: const Icon(Icons.delete, color: Colors.white)),
                          child: _buildAudioPlayerControls(recordingDoc),
                        );
                      },
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}