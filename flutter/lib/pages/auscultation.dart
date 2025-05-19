import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart'; // Kept if used by other parts (e.g. waveform later)
import 'package:heartcloud/utils/colors.dart'; // Assuming this file exists and defines 'darkBlue'
import 'package:http/http.dart' as http; // Changed to full import for clarity, can use 'show get' if preferred
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:waveform_flutter/waveform_flutter.dart'; // Kept, but live ESP32 stream not implemented
import 'package:cloud_firestore/cloud_firestore.dart';

class RecordAuscultation extends StatefulWidget {
  const RecordAuscultation({super.key});

  @override
  State<RecordAuscultation> createState() => _RecordAuscultationState();
}

class _RecordAuscultationState extends State<RecordAuscultation> {
  String? _selectedPatient = 'Select Patient';
  String? _selectedOption = 'Heart'; // Or your default
  FlutterSoundRecorder? _recorder; // Kept for potential future use with waveform or if other parts use it

  // --- State for ESP32 Interaction ---
  bool _isRecording = false; // This will now reflect ESP32 recording state
  bool _isLoadingCommand = false; // To disable buttons during ESP32 communication
  String _esp32IpAddress = '192.168.254.118'; // Your ESP32 IP Address
  // --- End ESP32 State ---

  String _timerText = '00:00:00';
  Timer? _timer;
  int _seconds = 0;
  String statusMessage = "Idle. Press Start to record from ESP32.";

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _initializeRecorderAndPermissions(); // Combines permission and recorder opening
  }

  Future<void> _initializeRecorderAndPermissions() async {
    // Request microphone permission (primarily for flutter_sound if used, good practice)
    PermissionStatus micStatus = await Permission.microphone.request();
    if (micStatus.isDenied) {
      _showPermissionDialog('Microphone Permission', 'Microphone permission is recommended for full app functionality.');
    } else if (micStatus.isPermanentlyDenied) {
      _showOpenSettingsDialog('Microphone Permission', 'Microphone permission has been permanently denied. Please enable it in settings.');
    }
    if (micStatus.isGranted) {
      await _recorder?.openRecorder();
      print("FlutterSoundRecorder opened (if needed for other features).");
    }

    // Request storage permission for saving/loading audio files
    PermissionStatus storageStatus = await Permission.storage.request();
    if (storageStatus.isDenied) {
      _showPermissionDialog('Storage Permission', 'Storage permission is required to save and play audio recordings.');
    } else if (storageStatus.isPermanentlyDenied) {
      _showOpenSettingsDialog('Storage Permission', 'Storage permission has been permanently denied. Please enable it in settings to save/play audio.');
    }
  }

  void _showPermissionDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Dismiss current dialog
              await openAppSettings(); // Open app settings
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

  // --- Generic function to send commands to ESP32 ---
  Future<bool> _sendEsp32Command(String commandPath) async {
    if (_esp32IpAddress.isEmpty) {
      setState(() {
        statusMessage = 'ESP32 IP Address is not set.';
      });
      return false;
    }

    setState(() {
      _isLoadingCommand = true;
      statusMessage = 'Sending $commandPath command to ESP32...';
    });

    final String esp32Url = 'http://$_esp32IpAddress/$commandPath';
    bool success = false;

    try {
      final response = await http.get(Uri.parse(esp32Url)).timeout(const Duration(seconds: 10));
      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            statusMessage = 'ESP32: ${response.body}';
          });
          success = true;
        } else {
          setState(() {
            statusMessage = 'ESP32 Error ($commandPath): ${response.statusCode} - ${response.body}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          statusMessage = 'ESP32 Command Failed ($commandPath): $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCommand = false;
        });
      }
    }
    return success;
  }

  // --- Modified to control ESP32 recording ---
  void _startRecording() async {
    if (_isRecording) return; // Already recording (from ESP32 perspective)

    bool success = await _sendEsp32Command('start_record');
    if (success) {
      setState(() {
        _isRecording = true; // ESP32 is now recording
        _seconds = 0;        // Reset timer
        _timerText = _formatTime(_seconds);
      });
      _startTimer(); // Start UI timer
      print("ESP32 recording started command sent.");
    }
  }

  // --- Modified to control ESP32 recording ---
  void _stopRecording() async {
    if (!_isRecording && _seconds == 0) return; // Not recording or timer not started

    bool success = await _sendEsp32Command('stop_record');
    if (success) {
      setState(() {
        _isRecording = false; // ESP32 has stopped recording
      });
      _stopTimer(); // Stop UI timer
      print("ESP32 recording stopped command sent. Audio ready for download.");
      // Optionally, you could automatically trigger download here or enable a download button
      // e.g., downloadAudio();
    }
  }

  // --- Timer logic (can remain as is, controlled by _startRecording/_stopRecording) ---
  void _startTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRecording && timer.isActive) { // Safety check, stop if ESP32 isn't recording
        timer.cancel();
        return;
      }
      setState(() {
        _seconds++;
        _timerText = _formatTime(_seconds);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    // _seconds = 0; // Keep _seconds to show final duration until next recording
  }

  String _formatTime(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // --- Your existing downloadAudio and playAudio methods ---
  // Minor modification: use _esp32IpAddress and handle _isLoadingCommand
  Future<void> downloadAudio() async {
    if (_isLoadingCommand) return;
    setState(() {
      _isLoadingCommand = true; // Use the general loading flag
      statusMessage = "Connecting to ESP32 for download...";
    });

    File? savedFile; // To store the file reference

    try {
      final response = await http.get(Uri.parse('http://$_esp32IpAddress/audio.wav')).timeout(const Duration(seconds: 20)); // Increased timeout for download

      if (response.statusCode == 200) {
        final directory = await getExternalStorageDirectory(); // Ensure permissions are handled
        if (directory == null) {
          throw Exception("Could not get external storage directory. Check permissions.");
        }
        final file = File('${directory.path}/auscultation_audio.wav'); // More specific name
        await file.writeAsBytes(response.bodyBytes);
        savedFile = file; // Store file reference

        if (mounted) {
          setState(() {
            statusMessage = "Download successful! Saved at ${file.path}";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download successful! File saved at ${file.path}')),
          );
        }
        print("Audio downloaded, size: ${response.bodyBytes.length} bytes to ${file.path}");
      } else {
        if (mounted) {
          setState(() {
            statusMessage = "Failed to download audio. Status: ${response.statusCode} - ${response.body}";
          });
        }
        print("Failed to download audio: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          statusMessage = "Error downloading audio: ${e.toString()}";
        });
      }
      print("Error downloading audio: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCommand = false;
        });
      }
    }
  }

  Future<void> playAudio() async {
    if (_isLoadingCommand) return; // Prevent action during other ESP32 ops

    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      setState(() { statusMessage = "Storage directory not found.";});
      return;
    }
    final filePath = '${directory.path}/auscultation_audio.wav';

    try {
      if (await File(filePath).exists()) {
        final player = AudioPlayer(); // Create a new player instance each time or manage one
        await player.play(DeviceFileSource(filePath));
        player.onPlayerComplete.first.then((_) {
          if(mounted) setState(() { statusMessage = "Playback finished.";});
        });
        setState(() { statusMessage = "Playing audio from ESP32 recording..."; });
        print("Playing audio from: $filePath");
      } else {
        if (mounted) setState(() { statusMessage = "Audio file not found. Download first."; });
        print("Audio file not found at: $filePath. Download it first.");
      }
    } catch (e) {
      if (mounted) setState(() { statusMessage = "Error playing audio: $e"; });
      print("Error playing audio: $e");
    }
  }


  @override
  void dispose() {
    _timer?.cancel();
    _recorder?.closeRecorder(); // Close flutter_sound recorder if it was opened
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define darkBlue or import it from your utils.colors
    // For example, if it's not imported:
    // const Color darkBlue = Color(0xFF0D47A1); // Example blue color

    return Scaffold(
      // appBar: AppBar(title: const Text("Record Auscultation")), // Optional AppBar
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20), // Adjusted margin
          padding: const EdgeInsets.only(top: 40), // Added padding for status bar
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 30), // Adjusted from 70
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 30),
                  ),
                  const SizedBox(width: 10), // Adjusted
                  DropdownButton<String>(
                    value: _selectedOption,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedOption = newValue;
                      });
                    },
                    items: <String>['Heart', 'Lungs'] // Add more if needed
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(fontSize: 20, color: darkBlue), // Assuming darkBlue is defined
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // 🎵 Waveform widget (currently static or for flutter_sound)
              Container(
                height: 100, // Adjusted height
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.grey.shade200, // Lighter grey
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400)
                ),
                child: Center(
                  child: _isRecording // Show a simple text indicator for ESP32 recording
                      ? Text("ESP32 Recording...", style: TextStyle(color: Colors.red.shade700, fontSize: 16))
                      : Text("Waveform (ESP32 audio after download)", style: TextStyle(color: Colors.grey.shade700)),
                  // AnimatedWaveList( // This needs a live stream or post-processing
                  //   stream: Stream.empty(),
                  //   barBuilder: (animation, amplitude) => WaveFormBar(
                  //     amplitude: amplitude,
                  //     animation: animation,
                  //     color: Colors.red,
                  //   ),
                  // ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                _timerText,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300), // Adjusted style
              ),
              Icon(Icons.mic_none, size: 48, color: _isRecording ? Colors.red.shade700 : Colors.grey.shade700), // Visual feedback
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Better spacing
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("START"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    onPressed: _isLoadingCommand || _isRecording ? null : _startRecording,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: const Text("STOP"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    onPressed: _isLoadingCommand || !_isRecording ? null : _stopRecording,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (statusMessage.isNotEmpty) // Display status message
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(statusMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: statusMessage.toLowerCase().contains("error") || statusMessage.toLowerCase().contains("failed") ? Colors.red.shade700 : Colors.black87)),
                ),
              const SizedBox(height: 20),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("  Select Patient", style: TextStyle(color: darkBlue, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('patient').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text("No Patients Found");
                  }

                  List<DropdownMenuItem<String>> patientItems = snapshot.data!.docs.map((doc) {
                    String firstName = doc.get('firstName') ?? 'N/A';
                    String lastName = doc.get('lastName') ?? 'N/A';
                    return DropdownMenuItem<String>(
                      value: doc.id, // Use document ID as value
                      child: Text('$firstName $lastName'),
                    );
                  }).toList();

                  // Add a placeholder if needed, ensure _selectedPatient is of type String? (doc.id)
                  // For simplicity, let's assume _selectedPatient is updated correctly
                  // If _selectedPatient is 'Select Patient', it won't match any doc.id.
                  // Handle this by ensuring _selectedPatient is either null or a valid doc.id.

                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    isExpanded: true,
                    hint: const Text("Select Patient"), // Show hint if _selectedPatient is null
                    value: snapshot.data!.docs.any((doc) => doc.id == _selectedPatient) ? _selectedPatient : null,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedPatient = newValue;
                      });
                    },
                    items: patientItems,
                  );
                },
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Spacing for buttons
                children: [
                  Expanded( // Make buttons take available space
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text("Download ESP32 Audio"),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: _isLoadingCommand || _isRecording ? null : downloadAudio,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_circle_filled),
                      label: const Text("Play Downloaded Audio"),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: _isLoadingCommand || _isRecording ? null : playAudio,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}