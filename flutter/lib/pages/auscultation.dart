import 'dart:async';
import 'dart:io'; // For File, Uint8List
import 'dart:typed_data'; // For Uint8List

import 'package:audioplayers/audioplayers.dart'; // Keep if any other part of app uses it, otherwise can be removed
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for currentUser
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart'; // Keep for getApplicationDocumentsDirectory if needed elsewhere, or for potential future local caching
import 'package:permission_handler/permission_handler.dart';
// import 'package:waveform_flutter/waveform_flutter.dart';

class RecordAuscultation extends StatefulWidget {
  const RecordAuscultation({super.key});

  @override
  State<RecordAuscultation> createState() => _RecordAuscultationState();
}

class _RecordAuscultationState extends State<RecordAuscultation> {
  String? _selectedPatientId; // Stores the document ID of the selected patient
  String? _selectedOption = 'Heart';
  FlutterSoundRecorder? _recorder;

  bool _isRecording = false; // True when ESP32 is actively recording (UI perspective)
  bool _isLoadingCommand = false; // True during any command to ESP32 or initial phase of processing
  bool _isProcessingAudio = false; // True during fetching from ESP32 and uploading to Firebase
  String _esp32IpAddress = '192.168.254.100'; // Current IP address
  int _currentRecordingDuration = 0;
  // String? _lastLocalAudioFilePath; // REMOVED
  double? _uploadProgress;

  String _timerText = '00:00 / --:--';
  Timer? _timer;
  int _secondsElapsed = 0;
  String statusMessage = "Idle. Select a patient and duration to record from ESP32.";

  static const Color darkBlue = Color(0xFF003366); // Example dark blue

  String? get _currentDoctorId {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _initializeRecorderAndPermissions();
    _timerText = _formatTime(0, 0);
  }

  Future<void> _initializeRecorderAndPermissions() async {
    PermissionStatus micStatus = await Permission.microphone.request();
    if (!mounted) return;
    if (micStatus.isDenied) {
      _showPermissionDialog('Microphone Permission', 'Microphone permission is recommended for full app functionality.');
    } else if (micStatus.isPermanentlyDenied) {
      _showOpenSettingsDialog('Microphone Permission', 'Microphone permission has been permanently denied. Please enable it in settings.');
    }
    if (micStatus.isGranted && (_recorder?.isStopped ?? true)) {
      await _recorder?.openRecorder();
      print("FlutterSoundRecorder opened (if needed for other features).");
    }

    // Permissions for potential temporary file storage if http package needs it,
    // or if other parts of the app save files.
    // For direct memory operations, these might be less critical but good for robustness.
    bool storagePermissionsGranted = false;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // For Android 13+, specific media permissions might be needed if saving to shared storage.
        // As we are primarily operating in memory or app-specific directory,
        // general permissions might suffice, or even none if strictly app-internal.
        // However, requesting Permission.audio can be a good measure.
        PermissionStatus audioPermStatus = await Permission.audio.request();
        storagePermissionsGranted = audioPermStatus.isGranted;
        if (!mounted) return;
        if (audioPermStatus.isDenied) _showPermissionDialog('Audio Permission', 'Audio permission might be required on Android 13+ for some operations.');
        else if (audioPermStatus.isPermanentlyDenied) _showOpenSettingsDialog('Audio Permission', 'Audio permission permanently denied. Enable in settings if issues arise.');
      } else {
        PermissionStatus storagePermStatus = await Permission.storage.request();
        storagePermissionsGranted = storagePermStatus.isGranted;
        if (!mounted) return;
        if (storagePermStatus.isDenied) _showPermissionDialog('Storage Permission', 'Storage permission is required for some file operations.');
        else if (storagePermStatus.isPermanentlyDenied) _showOpenSettingsDialog('Storage Permission', 'Storage permission permanently denied. Enable in settings.');
      }
    } else { // iOS
      PermissionStatus photosPermStatus = await Permission.photos.request(); // For saving to gallery if needed
      storagePermissionsGranted = photosPermStatus.isGranted;
      if (!mounted) return;
      if (photosPermStatus.isDenied) _showPermissionDialog('Media Library Permission', 'Media Library permission might be required on iOS for some operations.');
      else if (photosPermStatus.isPermanentlyDenied) _showOpenSettingsDialog('Media Library Permission', 'Media Library permission permanently denied. Enable in settings.');
    }
    print("Initial storage/audio related permissions granted: $storagePermissionsGranted");
  }

  void _showPermissionDialog(String title, String content) {
    if (!mounted) return;
    showDialog(context: context, builder: (context) => AlertDialog(title: Text(title), content: Text(content), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))]));
  }

  void _showOpenSettingsDialog(String title, String content) {
    if (!mounted) return;
    showDialog(context: context, builder: (context) => AlertDialog(title: Text(title), content: Text(content), actions: [TextButton(onPressed: () async { Navigator.of(context).pop(); await openAppSettings(); }, child: const Text('Open Settings')), TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))]));
  }

  Future<bool> _sendEsp32Command(String commandPath, {int timeoutSeconds = 10}) async {
    if (_esp32IpAddress.isEmpty) {
      if (mounted) setState(() { statusMessage = 'ESP32 IP Address is not set.'; _isLoadingCommand = false; });
      return false;
    }
    // _isLoadingCommand is generally set by the calling function like _initiateEsp32Recording
    // to true before this call, and to false after this call completes (success or failure).
    // If called directly, ensure _isLoadingCommand is managed.
    // For clarity, _initiateEsp32Recording will set it.

    final String esp32Url = 'http://$_esp32IpAddress/$commandPath';
    bool success = false;
    try {
      // Timeout is now passed as a parameter, default is 10s.
      // _initiateEsp32Recording will pass a longer one for 'start_recording'.
      print("Sending command: $esp32Url with timeout: $timeoutSeconds seconds");
      final response = await http.get(Uri.parse(esp32Url)).timeout(Duration(seconds: timeoutSeconds));

      if (!mounted) return false;

      if (response.statusCode == 200) {
        print("ESP32 Response ($commandPath): ${response.body}");
        // Specific status messages are set by the calling function based on context.
        // statusMessage = 'ESP32 command successful ($commandPath).';
        success = true;
      } else {
        statusMessage = 'ESP32 Error ($commandPath): ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      if (mounted) {
        statusMessage = 'ESP32 Command Failed ($commandPath): ${e.toString().split('\n').first}';
      }
    }
    return success;
  }

  Future<void> _initiateEsp32Recording(int duration) async {
    if (_isRecording || _isLoadingCommand || _isProcessingAudio) return;

    if (_currentDoctorId == null) {
      if (mounted) setState(() { statusMessage = "Error: Doctor not logged in."; });
      return;
    }
    if (_selectedPatientId == null || _selectedPatientId!.isEmpty) {
      if (mounted) setState(() { statusMessage = "Please select a patient before recording."; });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingCommand = true; // Indicate that a command is being sent
        statusMessage = 'Initializing $duration-second recording...';
        _currentRecordingDuration = duration;
        _isRecording = true; // Optimistically set, will be reset on command failure
        _secondsElapsed = 0;
        _timerText = _formatTime(_secondsElapsed, _currentRecordingDuration);
        // _lastLocalAudioFilePath = null; // REMOVED
        _uploadProgress = null;
      });
    }

    // Pass a longer timeout for the start_recording command
    bool commandSuccess = await _sendEsp32Command('start_recording?duration=$duration', timeoutSeconds: 30);

    if (!mounted) return;

    if (commandSuccess) {
      setState(() {
        statusMessage = 'Recording for $duration seconds... 0/${_currentRecordingDuration}s';
        _isLoadingCommand = false; // Command successful, ESP32 is recording, UI is responsive for timer
        // _isRecording remains true
      });
      _startTimer();
    } else {
      setState(() {
        _isRecording = false; // Reset if command failed
        _currentRecordingDuration = 0;
        _timerText = _formatTime(0,0);
        _isLoadingCommand = false; // Reset loading state
        // statusMessage is already set by _sendEsp32Command on failure
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRecording && timer.isActive) { // If recording is stopped externally
        timer.cancel();
        return;
      }
      if (_secondsElapsed < _currentRecordingDuration) {
        if (mounted) {
          setState(() {
            _secondsElapsed++;
            _timerText = _formatTime(_secondsElapsed, _currentRecordingDuration);
            statusMessage = 'Recording... $_secondsElapsed/${_currentRecordingDuration}s';
          });
        }
      } else { // Recording duration reached
        _timer?.cancel();
        if (mounted) {
          setState(() {
            _isRecording = false; // ESP32 recording phase is done
            statusMessage = 'Recording finished on ESP32 ($_currentRecordingDuration s). Processing audio...';
            // _isLoadingCommand will be set to true by _processAndUploadEsp32Audio
          });
          _processAndUploadEsp32Audio();
        }
      }
    });
  }

  String _formatTime(int elapsedSeconds, int totalDuration) {
    final int eh = elapsedSeconds ~/ 3600;
    final int em = (elapsedSeconds % 3600) ~/ 60;
    final int es = elapsedSeconds % 60;

    if (totalDuration == 0 && elapsedSeconds == 0) return '00:00 / --:--';
    if (totalDuration == 0 && elapsedSeconds > 0) return '${eh.toString().padLeft(2, '0')}:${em.toString().padLeft(2, '0')}:${es.toString().padLeft(2, '0')} / Calculating...';

    final int th = totalDuration ~/ 3600;
    final int tm = (totalDuration % 3600) ~/ 60;
    final int ts = totalDuration % 60;

    if (th == 0 && eh == 0) return '${em.toString().padLeft(2, '0')}:${es.toString().padLeft(2, '0')} / ${tm.toString().padLeft(2, '0')}:${ts.toString().padLeft(2, '0')}';
    return '${eh.toString().padLeft(2, '0')}:${em.toString().padLeft(2, '0')}:${es.toString().padLeft(2, '0')} / ${th.toString().padLeft(2, '0')}:${tm.toString().padLeft(2, '0')}:${ts.toString().padLeft(2, '0')}';
  }

  Future<void> _processAndUploadEsp32Audio() async {
    final String? doctorId = _currentDoctorId;
    final String? patientId = _selectedPatientId;

    if (doctorId == null) {
      if (mounted) setState(() { statusMessage = "Error: Doctor not logged in. Cannot process."; _isProcessingAudio = false; _isLoadingCommand = false;});
      return;
    }
    if (patientId == null || patientId.isEmpty) {
      if (mounted) setState(() { statusMessage = "Error: No patient selected. Cannot process audio."; _isProcessingAudio = false; _isLoadingCommand = false;});
      return;
    }
    if (_currentRecordingDuration == 0) {
      if (mounted) setState(() { statusMessage = "Error: Recording duration was zero."; _isProcessingAudio = false; _isLoadingCommand = false;});
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessingAudio = true;
        _isLoadingCommand = true; // Disable UI during this entire process
        _uploadProgress = null;
        statusMessage = "Fetching audio from ESP32...";
      });
    }

    final http.Client httpClient = http.Client();
    String fetchedFileName = "recorded_audio_${_currentRecordingDuration}s.wav"; // Default

    try {
      final audioUrl = Uri.parse('http://$_esp32IpAddress/audio.wav');
      final request = http.Request('GET', audioUrl);
      final http.StreamedResponse streamedResponse = await httpClient.send(request).timeout(Duration(seconds: _currentRecordingDuration + 45)); // Generous timeout for download

      if (!mounted) { httpClient.close(); return; }

      if (streamedResponse.statusCode == 200) {
        final String? disposition = streamedResponse.headers['content-disposition'];
        if (disposition != null) {
          final RegExpMatch? match = RegExp('filename="([^"]*)"').firstMatch(disposition);
          if (match != null && match.groupCount >= 1) fetchedFileName = match.group(1)!;
        }
        if (mounted) setState(() { statusMessage = "Audio stream received. Reading data..."; });

        final Uint8List audioData = await streamedResponse.stream.toBytes();
        if (!mounted) { httpClient.close(); return; }
        if (audioData.isEmpty) throw Exception("Received empty audio stream from ESP32.");

        // Local saving is removed
        // if (mounted) setState(() { statusMessage = "Audio data read. Uploading to Firebase Storage..."; });
        if (mounted) setState(() { statusMessage = "Uploading to Firebase Storage..."; });


        final String firebaseFileName = 'auscultation_${_selectedOption?.replaceAll(' ', '_') ?? "UnknownType"}_${DateTime.now().millisecondsSinceEpoch}_$fetchedFileName';

        final firebase_storage.Reference storageRef = firebase_storage.FirebaseStorage.instance
            .ref('patient_auscultations')
            .child(doctorId)
            .child(patientId)
            .child(firebaseFileName);

        final firebase_storage.UploadTask uploadTask = storageRef.putData(
            audioData, firebase_storage.SettableMetadata(contentType: 'audio/wav'));

        uploadTask.snapshotEvents.listen((firebase_storage.TaskSnapshot snapshot) {
          if (mounted) {
            setState(() {
              _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
              statusMessage = "Uploading: ${(_uploadProgress! * 100).toStringAsFixed(1)}%";
            });
          }
        });

        await uploadTask;
        if (!mounted) { httpClient.close(); return; }
        final String downloadUrl = await storageRef.getDownloadURL();

        if (mounted) setState(() { statusMessage = "Upload successful! Saving metadata..."; _uploadProgress = null; });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(doctorId)
            .collection('patients')
            .doc(patientId)
            .collection('auscultation_recordings')
            .add({
          'fileNameInStorage': firebaseFileName,
          'originalEsp32FileName': fetchedFileName,
          'downloadUrl': downloadUrl,
          'storagePath': storageRef.fullPath,
          'auscultationType': _selectedOption,
          'durationSeconds': _currentRecordingDuration,
          'recordedAt': FieldValue.serverTimestamp(),
          'esp32Ip': _esp32IpAddress,
          // 'localCopyPath': _lastLocalAudioFilePath, // REMOVED
          'fileSizeBytes': audioData.lengthInBytes,
        });
        if (!mounted) { httpClient.close(); return; }
        print("Metadata saved to Firestore.");
        if (mounted) setState(() { statusMessage = "Process complete! Audio uploaded and metadata saved.";});

      } else {
        String errorBody = "Unknown error";
        try { errorBody = await streamedResponse.stream.bytesToString(); } catch(_){}
        throw Exception("ESP32 fetch error: ${streamedResponse.statusCode} - $errorBody");
      }
    } catch (e) {
      print("Error in _processAndUploadEsp32Audio: $e");
      if (mounted) setState(() { statusMessage = "Error processing audio: ${e.toString().split('\n').first}"; _uploadProgress = null; });
    } finally {
      httpClient.close();
      if (mounted) setState(() { _isProcessingAudio = false; _isLoadingCommand = false; }); // Reset flags
    }
  }

  // downloadAudioManually() and playAudio() REMOVED

  @override
  void dispose() {
    _timer?.cancel();
    _recorder?.closeRecorder();
    super.dispose();
  }

  Widget _buildDurationButton(int duration) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: darkBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
      onPressed: _isLoadingCommand || _isRecording || _isProcessingAudio ? null : () => _initiateEsp32Recording(duration),
      child: Text("Record ${duration}s"),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? doctorId = _currentDoctorId;

    return Scaffold(
      appBar: AppBar(title: const Text("Record Auscultation")),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.only(top: 20, bottom: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              DropdownButton<String>(
                value: _selectedOption, isExpanded: true,
                onChanged: (_isLoadingCommand || _isRecording || _isProcessingAudio) ? null : (String? newValue) { if (mounted) setState(() { _selectedOption = newValue; }); },
                items: <String>['Heart', 'Lungs'].map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(value: value, child: Text(value, style: TextStyle(fontSize: 20, color: darkBlue)))).toList(),
              ),
              const SizedBox(height: 30),
              Container(
                height: 100, width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                child: Center(child: Text(
                    _isRecording ? "ESP32 Recording..."
                        : _isProcessingAudio ? "Processing Audio..."
                        : "Waveform (ESP32 audio after processing)",
                    style: TextStyle(color: Colors.grey.shade700)
                )),
              ),
              const SizedBox(height: 30),
              Text(_timerText, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w300)),
              Icon(Icons.mic_none, size: 48, color: _isRecording ? Colors.red.shade700 : Colors.grey.shade700),
              const SizedBox(height: 20),
              Text("Select Recording Duration:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBlue)),
              const SizedBox(height: 10),
              Wrap(spacing: 10.0, runSpacing: 10.0, alignment: WrapAlignment.center, children: [_buildDurationButton(15), _buildDurationButton(30), _buildDurationButton(45), _buildDurationButton(60)]),
              const SizedBox(height: 20),
              if (statusMessage.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Text(statusMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: statusMessage.toLowerCase().contains("error") || statusMessage.toLowerCase().contains("failed") ? Colors.red.shade700 : Colors.black87))),
              // Show progress only during actual upload phase of processing
              if (_isProcessingAudio && _uploadProgress != null && _uploadProgress! > 0 && _uploadProgress! < 1)
                Padding(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 40), child: LinearProgressIndicator(value: _uploadProgress, minHeight: 6)),
              const SizedBox(height: 20),
              const Divider(),
              Text("Select Patient", style: TextStyle(color: darkBlue, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (doctorId == null)
                const Padding(padding: EdgeInsets.all(8.0), child: Text("Loading user information or user not logged in...", style: TextStyle(color: Colors.orange)))
              else
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(doctorId).collection('patients').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError) return Text("Error fetching patients: ${snapshot.error}", style: const TextStyle(color: Colors.red));
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text("No Patients Found for this Doctor");

                    List<DropdownMenuItem<String>> patientItems = snapshot.data!.docs.map((doc) {
                      String firstName = doc.get('firstName') ?? 'N/A';
                      String lastName = doc.get('lastName') ?? 'N/A';
                      return DropdownMenuItem<String>(value: doc.id, child: Text('$firstName $lastName'));
                    }).toList();

                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      isExpanded: true, hint: const Text("Select Patient"), value: _selectedPatientId,
                      onChanged: (_isLoadingCommand || _isRecording || _isProcessingAudio) ? null : (String? newValue) { if (mounted) setState(() { _selectedPatientId = newValue; }); },
                      items: patientItems,
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
