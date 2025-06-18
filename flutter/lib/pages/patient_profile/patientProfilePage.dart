import 'dart:async';
import 'package:flutter/material.dart';
// Assuming your utils are in lib/utils/
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/utils/bottom_navbar.dart';
// Firebase Imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // <<< ADDED: For storage operations
// Other Package Imports
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

class PatientProfile extends StatefulWidget {
  final DocumentSnapshot patientData;

  const PatientProfile({super.key, required this.patientData});

  @override
  State<PatientProfile> createState() => _PatientProfileState();
}

class _PatientProfileState extends State<PatientProfile> {
  int _selectedIndex = 0; // For BottomNavBar

  // Audio Player State
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  String? get _currentDoctorId {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void initState() {
    super.initState();
    // Listen to player state changes
    _playerStateChangeSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _playerState = PlayerState.completed;
          _position = Duration.zero;
          _currentlyPlayingUrl = null;
        });
      }
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // <<< ADDED: Function to delete from both Firestore and Storage >>>
  Future<void> _deleteRecording(String patientId, String recordingId, String fileNameInStorage) async {
    final doctorId = _currentDoctorId;
    if (doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Could not authenticate doctor.")),
      );
      return;
    }
    if (!mounted) return; // Check if the widget is still in the tree

    try {
      // 1. Delete the Firestore document
      final firestoreDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .collection('patients')
          .doc(patientId)
          .collection('auscultation_recordings')
          .doc(recordingId);

      await firestoreDocRef.delete();

      // 2. Delete the file from Firebase Storage
      //    Ensure fileNameInStorage is not empty before attempting to delete.
      if (fileNameInStorage.isNotEmpty) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('patient_auscultations/$doctorId/$patientId/$fileNameInStorage');
        await storageRef.delete();
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Recording deleted successfully."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error message
      print("Error deleting recording: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete recording: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _playPauseAudio(String url) async {
    if (_currentlyPlayingUrl == url && _playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else if (_currentlyPlayingUrl == url && _playerState == PlayerState.paused) {
      await _audioPlayer.resume();
    } else {
      await _audioPlayer.stop();
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _duration = Duration.zero;
        });
      }
      await _audioPlayer.play(UrlSource(url));
      if (mounted) {
        setState(() {
          _currentlyPlayingUrl = url;
        });
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Widget _buildAudioPlayerControls(QueryDocumentSnapshot recordingDoc) {
    String audioUrl = recordingDoc['downloadUrl'] as String;
    bool isCurrentlyPlayingThis = _currentlyPlayingUrl == audioUrl;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Type: ${recordingDoc['auscultationType'] ?? 'N/A'}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              "Recorded: ${recordingDoc['recordedAt'] != null ? DateFormat('MMM d, yyyy - hh:mm a').format((recordingDoc['recordedAt'] as Timestamp).toDate()) : 'N/A'}",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            Text(
              "Filename: ${recordingDoc['originalEsp32FileName'] ?? recordingDoc['fileNameInStorage'] ?? 'N/A'}",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
            if (recordingDoc['durationSeconds'] != null)
              Text(
                "ESP32 Duration: ${recordingDoc['durationSeconds']}s",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    isCurrentlyPlayingThis && _playerState == PlayerState.playing
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 40,
                    color: darkBlue,
                  ),
                  onPressed: () => _playPauseAudio(audioUrl),
                ),
              ],
            ),
            if (isCurrentlyPlayingThis)
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: darkBlue,
                      inactiveTrackColor: darkBlue.withOpacity(0.3),
                      trackHeight: 2.0,
                      thumbColor: darkBlue,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                      overlayColor: darkBlue.withAlpha(0x29),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                    ),
                    child: Slider(
                      min: 0,
                      max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                      value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                      onChanged: (value) async {
                        final newPosition = Duration(seconds: value.toInt());
                        await _audioPlayer.seek(newPosition);
                        if (_playerState == PlayerState.paused || _playerState == PlayerState.completed) {
                          await _audioPlayer.resume();
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_position)),
                        Text(_formatDuration(_duration)),
                      ],
                    ),
                  ),
                ],
              ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text("${patient['firstName'] ?? ""} ${patient['lastName'] ?? ""}'s Profile"),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Patient Details",
                style: TextStyle(
                    color: darkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 22),
              ),
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
              Text(
                "Recording History",
                style: TextStyle(
                    color: darkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 22),
              ),
              const SizedBox(height: 10),
              if (doctorId == null)
                const Center(child: Text("Error: Could not identify doctor." ))
              else
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(doctorId)
                      .collection('patients')
                      .doc(patientId)
                      .collection('auscultation_recordings')
                      .orderBy('recordedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      print("Error fetching recordings: ${snapshot.error}");
                      return Center(child: Text("Error loading recordings: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("No recordings found for this patient.", style: TextStyle(fontSize: 16)),
                      ));
                    }

                    var recordings = snapshot.data!.docs;
                    // <<< MODIFIED: Changed to ListView from ListView.builder to apply Dismissible >>>
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recordings.length,
                      itemBuilder: (context, index) {
                        final recordingDoc = recordings[index];
                        final data = recordingDoc.data() as Map<String, dynamic>;
                        // Safely get the file name from the document.
                        final fileName = data['fileNameInStorage'] as String? ?? '';

                        // <<< MODIFIED: Wrapped the item in a Dismissible widget >>>
                        return Dismissible(
                          // Key must be unique, the document ID is perfect for this.
                          key: Key(recordingDoc.id),
                          // We only want to swipe from right to left.
                          direction: DismissDirection.endToStart,
                          // The function that is called when the item is dismissed.
                          onDismissed: (direction) {
                            // Call our new delete function.
                            _deleteRecording(patientId, recordingDoc.id, fileName);
                          },
                          // This is the background that appears when swiping.
                          background: Container(
                            color: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.centerRight,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          // The actual widget to display.
                          child: _buildAudioPlayerControls(recordingDoc),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}