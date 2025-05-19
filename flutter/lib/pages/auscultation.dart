import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:http/http.dart' as http show get;
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:waveform_flutter/waveform_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class RecordAuscultation extends StatefulWidget {
  const RecordAuscultation({super.key});

  @override
  State<RecordAuscultation> createState() => _RecordAuscultationState();
}

class _RecordAuscultationState extends State<RecordAuscultation> {
  String? _selectedPatient = 'Select Patient';
  String? _selectedOption = 'Heart';
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String _timerText = '00:00:00';
  Timer? _timer;
  int _seconds = 0;
  String statusMessage = "Idle";

  Future<void> downloadAudio() async {
    try {
      setState(() {
        statusMessage = "Connecting to ESP32...";
      });

      final response = await http.get(Uri.parse('http://192.168.254.121/audio.wav'));

      if (response.statusCode == 200) {
        // Save the audio file locally
        final directory = await getExternalStorageDirectory();
        final file = File('${directory?.path}/audio.wav');
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          statusMessage = "Download successful! Saved at ${file.path}";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download successful! File saved at ${file.path}')),
        );

        print("Audio downloaded, size: ${response.bodyBytes.length} bytes");
      } else {
        setState(() {
          statusMessage = "Failed to download audio. Status: ${response.statusCode}";
        });
        print("Failed to download audio: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        statusMessage = "Error: ${e.toString()}";
      });
      print("Error downloading audio: $e");
    }
  }

  Future<void> playAudio() async {
    try {
      final directory = await getExternalStorageDirectory();
      final filePath = '${directory?.path}/audio.wav';

      if (await File(filePath).exists()) {
        final player = AudioPlayer();
        await player.play(DeviceFileSource(filePath));
        print("Playing audio from: $filePath");
      } else {
        print("Audio file not found at: $filePath");
      }
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      PermissionStatus status = await Permission.microphone.request();
      if (status.isGranted) {
        await _recorder?.openRecorder();
        print("Microphone permission granted");
      } else if (status.isDenied) {
        _showPermissionDeniedDialog();
      } else if (status.isPermanentlyDenied) {
        _showOpenSettingsDialog();
      }
    } catch (e) {
      print("Error checking permissions: $e");
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: const Text(
          'Microphone permission is required to record sounds. Please allow access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Permanently Denied'),
        content: const Text(
          'Please open settings to enable microphone permission manually.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _startRecording() async {
    PermissionStatus status = await Permission.microphone.status;
    if (status.isGranted) {
      await _recorder?.startRecorder(toFile: 'audio.aac');
      setState(() {
        _isRecording = true;
        _startTimer();
      });
      print("Recording started");
    } else {
      print("Microphone permission is not granted");
      _checkPermissions();
    }
  }

  void _stopRecording() async {
    await _recorder?.stopRecorder();
    setState(() {
      _isRecording = false;
      _stopTimer();
    });
    print("Recording stopped");
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        _timerText = _formatTime(_seconds);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _seconds = 0;
  }

  String _formatTime(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 70),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 30),
                  ),
                  const SizedBox(width: 30),
                  DropdownButton<String>(
                    value: _selectedOption,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedOption = newValue;
                      });
                    },
                    items: <String>['Heart', 'Lungs'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(fontSize: 20, color: darkBlue),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🎵 Waveform widget
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: AnimatedWaveList(
                        stream: Stream.empty(), // Replace with your actual audio stream
                        barBuilder: (animation, amplitude) => WaveFormBar(
                          amplitude: amplitude,
                          animation: animation,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _timerText,
                    style: const TextStyle(fontSize: 50),
                  ),
                  const Icon(Icons.mic, size: 50),
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow, size: 40),
                        onPressed: _isRecording ? null : _startRecording,
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop, size: 40),
                        onPressed: _isRecording ? _stopRecording : null,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("Select Patient", style: TextStyle(color: darkBlue, fontSize: 25, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('patient').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text("No Patient"); // Handle the case where no data is fetched
                  }

                  // Fetch both firstName and lastName from each document
                  List<String> patients = snapshot.data!.docs.map((doc) {
                    String firstName = doc['firstName'] as String;
                    String lastName = doc['lastName'] as String;
                    return '$firstName $lastName'; // Concatenate firstName and lastName
                  }).toList();

                  // Add a placeholder value to the patients list to allow 'Select Patient'
                  patients.insert(0, "Select Patient");

                  return DropdownButton<String>(
                    value: _selectedPatient,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedPatient = newValue;
                      });
                    },
                    items: patients.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 100),
                  GestureDetector(
                    onTap: (){
                      downloadAudio();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.black)
                      ),
                      child: Text("Download", style: TextStyle(
                          color: darkBlue,
                          fontSize: 25
                      ),
                      ),
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 100),
                  GestureDetector(
                    onTap: playAudio,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Text("Play", style: TextStyle(color: darkBlue, fontSize: 25)),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}