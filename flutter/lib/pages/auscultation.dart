import 'dart:async';
import 'dart:io'; // For File, Uint8List
import 'dart:typed_data'; // For Uint8List
import 'dart:math' as math; // Added for Random
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'patient_profile/patientProfilePage.dart'; // Make sure this import is correct
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

// New StatefulWidget for the Random Waveform Animation
class RandomWaveformWidget extends StatefulWidget {
  final Color waveColor;
  final double strokeWidth;

  const RandomWaveformWidget({
    super.key,
    this.waveColor = _RecordAuscultationState.darkBlue, // Use the same darkBlue
    this.strokeWidth = 2.0,
  });

  @override
  State<RandomWaveformWidget> createState() => _RandomWaveformWidgetState();
}

class _RandomWaveformWidgetState extends State<RandomWaveformWidget> {
  List<double> _amplitudes = [];
  Timer? _animationTimer;
  final math.Random _random = math.Random();
  final int _numberOfBars = 50; // Number of bars in the waveform

  @override
  void initState() {
    super.initState();
    _generateAmplitudes();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        _generateAmplitudes();
      } else {
        timer.cancel();
      }
    });
  }

  void _generateAmplitudes() {
    setState(() {
      _amplitudes = List.generate(
        _numberOfBars,
            (index) => _random.nextDouble(), // Generates a value between 0.0 and 1.0
      );
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WaveformPainter(
        amplitudes: _amplitudes,
        waveColor: widget.waveColor,
        strokeWidth: widget.strokeWidth,
      ),
      size: Size.infinite, // Take up available space in parent
    );
  }
}

// CustomPainter for drawing the waveform
class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color waveColor;
  final double strokeWidth;

  _WaveformPainter({
    required this.amplitudes,
    required this.waveColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final paint = Paint()
      ..color = waveColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double barWidth = size.width / amplitudes.length;
    final double centerY = size.height / 2;
    final double maxAmplitudeHeight = size.height * 0.4; // Max height of a bar (40% of total height)

    for (int i = 0; i < amplitudes.length; i++) {
      final double barX = (i * barWidth) + (barWidth / 2);
      // Scale amplitude: 0.0-1.0 to a fraction of maxAmplitudeHeight, ensure some minimum movement
      final double barHeight = (amplitudes[i] * 0.8 + 0.2) * maxAmplitudeHeight;

      canvas.drawLine(
        Offset(barX, centerY - barHeight / 2),
        Offset(barX, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    // Repaint if amplitudes change, or if color/stroke changes (though not dynamic here)
    return oldDelegate.amplitudes != amplitudes ||
        oldDelegate.waveColor != waveColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}


class RecordAuscultation extends StatefulWidget {
  const RecordAuscultation({super.key});

  @override
  State<RecordAuscultation> createState() => _RecordAuscultationState();
}

class _RecordAuscultationState extends State<RecordAuscultation> {
  String? _selectedPatientId;
  String? _selectedOption = 'Heart';
  FlutterSoundRecorder? _recorder;

  bool _isRecording = false;
  bool _isLoadingCommand = false;
  bool _isProcessingAudio = false;
  String _esp32IpAddress = '192.168.1.112';
  int _currentRecordingDuration = 0;
  double? _uploadProgress;

  String _timerText = '00:00 / --:--';
  Timer? _timer;
  int _secondsElapsed = 0;
  String statusMessage = "Idle. Select a patient and duration to record from ESP32.";

  // If your colors.dart is not imported, define darkBlue here or ensure the import works
  static const Color darkBlue = Color(0xFF003366); // Fallback if not imported

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
      _showPermissionDialog('Microphone Permission', 'Microphone permission is recommended.');
    } else if (micStatus.isPermanentlyDenied) {
      _showOpenSettingsDialog('Microphone Permission', 'Microphone permission permanently denied.');
    }
    if (micStatus.isGranted && (_recorder?.isStopped ?? true)) {
      await _recorder?.openRecorder();
      print("FlutterSoundRecorder opened.");
    }

    bool storagePermissionsGranted = false;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        PermissionStatus audioPermStatus = await Permission.audio.request();
        storagePermissionsGranted = audioPermStatus.isGranted;
        if (!mounted) return;
        if (audioPermStatus.isDenied) _showPermissionDialog('Audio Permission', 'Audio permission required on Android 13+.');
        else if (audioPermStatus.isPermanentlyDenied) _showOpenSettingsDialog('Audio Permission', 'Audio permission permanently denied.');
      } else {
        PermissionStatus storagePermStatus = await Permission.storage.request();
        storagePermissionsGranted = storagePermStatus.isGranted;
        if (!mounted) return;
        if (storagePermStatus.isDenied) _showPermissionDialog('Storage Permission', 'Storage permission required.');
        else if (storagePermStatus.isPermanentlyDenied) _showOpenSettingsDialog('Storage Permission', 'Storage permission permanently denied.');
      }
    } else {
      PermissionStatus photosPermStatus = await Permission.photos.request();
      storagePermissionsGranted = photosPermStatus.isGranted;
      if (!mounted) return;
      if (photosPermStatus.isDenied) _showPermissionDialog('Media Library Permission', 'Media Library permission required on iOS.');
      else if (photosPermStatus.isPermanentlyDenied) _showOpenSettingsDialog('Media Library Permission', 'Media Library permission permanently denied.');
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

    final String esp32Url = 'http://$_esp32IpAddress/$commandPath';
    bool success = false;
    try {
      print("Sending command: http://$esp32Url with timeout: $timeoutSeconds seconds");
      final response = await http.get(Uri.parse(esp32Url)).timeout(Duration(seconds: timeoutSeconds));
      if (!mounted) return false;
      if (response.statusCode == 200) {
        print("ESP32 Response ($commandPath): ${response.body}");
        success = true;
      } else {
        if (mounted) setState(() {statusMessage = 'ESP32 Error ($commandPath): ${response.statusCode} - ${response.body}';});
      }
    } catch (e) {
      if (mounted) setState(() {statusMessage = 'ESP32 Command Failed ($commandPath): ${e.toString().split('\n').first}';});
    }
    return success;
  }

  Future<void> _initiateEsp32Recording(int duration) async {
    if (_isRecording || _isLoadingCommand || _isProcessingAudio) return;
    if (_currentDoctorId == null) {
      if (mounted) setState(() { statusMessage = "Error: Doctor not logged in."; }); return;
    }
    if (_selectedPatientId == null || _selectedPatientId!.isEmpty) {
      if (mounted) setState(() { statusMessage = "Please select a patient before recording."; }); return;
    }

    if (mounted) {
      setState(() {
        _isLoadingCommand = true;
        statusMessage = 'Initializing $duration-second recording...';
        _currentRecordingDuration = duration;
        _isRecording = true;
        _secondsElapsed = 0;
        _timerText = _formatTime(_secondsElapsed, _currentRecordingDuration);
        _uploadProgress = null;
      });
    }

    bool commandSuccess = await _sendEsp32Command('start_recording?duration=$duration', timeoutSeconds: 30);
    if (!mounted) return;

    if (commandSuccess) {
      setState(() {
        statusMessage = 'Recording for $duration seconds... 0/${_currentRecordingDuration}s';
        _isLoadingCommand = false;
      });
      _startTimer();
    } else {
      setState(() {
        _isRecording = false;
        _currentRecordingDuration = 0;
        _timerText = _formatTime(0,0);
        _isLoadingCommand = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRecording && timer.isActive) { timer.cancel(); return; }
      if (_secondsElapsed < _currentRecordingDuration) {
        if (mounted) setState(() { _secondsElapsed++; _timerText = _formatTime(_secondsElapsed, _currentRecordingDuration); statusMessage = 'Recording... $_secondsElapsed/${_currentRecordingDuration}s'; });
      } else {
        _timer?.cancel();
        if (mounted) {
          setState(() { _isRecording = false; statusMessage = 'Recording finished on ESP32 ($_currentRecordingDuration s). Processing audio...'; });
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
    final String? patientId = _selectedPatientId; // This is the patient's document ID

    // --- Essential checks (doctorId, patientId, _currentRecordingDuration) ---
    if (doctorId == null) {
      if (mounted) setState(() { statusMessage = "Error: Doctor not logged in."; _isProcessingAudio = false; _isLoadingCommand = false;});
      return;
    }
    if (patientId == null || patientId.isEmpty) {
      if (mounted) setState(() { statusMessage = "Error: No patient selected."; _isProcessingAudio = false; _isLoadingCommand = false;});
      return;
    }
    if (_currentRecordingDuration == 0) {
      if (mounted) setState(() { statusMessage = "Error: Recording duration zero."; _isProcessingAudio = false; _isLoadingCommand = false;});
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessingAudio = true;
        _isLoadingCommand = true;
        _uploadProgress = null;
        statusMessage = "Fetching audio from ESP32...";
      });
    }

    // --- Fetch patient's first and last name for denormalization ---
    String patientFirstName = 'Unknown';
    String patientLastName = 'Patient';
    try {
      DocumentSnapshot patientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .collection('patients')
          .doc(patientId)
          .get();
      if (patientDoc.exists) {
        patientFirstName = patientDoc.get('firstName') ?? 'Unknown'; // Ensure 'firstName' is the correct field name
        patientLastName = patientDoc.get('lastName') ?? 'Patient';   // Ensure 'lastName' is the correct field name
      } else {
        print("Warning: Patient document not found for denormalization. patientId: $patientId");
        if (mounted) setState(() { statusMessage = "Warning: Patient details not found.";});
        // Decide if you want to proceed or stop if patient details are critical for the recording log
      }
    } catch (e) {
      print("Error fetching patient details for denormalization: $e");
      if (mounted) setState(() { statusMessage = "Warning: Could not fetch patient name. $e";});
    }
    // --- End fetch patient name ---

    final http.Client httpClient = http.Client();
    String fetchedFileName = "recorded_audio_${_currentRecordingDuration}s.wav"; // Default

    try {
      final audioUrl = Uri.parse('http://$_esp32IpAddress/audio.wav');
      final request = http.Request('GET', audioUrl);
      final http.StreamedResponse streamedResponse = await httpClient.send(request).timeout(Duration(seconds: _currentRecordingDuration + 45));

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
          if (mounted) setState(() { _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes; statusMessage = "Uploading: ${(_uploadProgress! * 100).toStringAsFixed(1)}%"; });
        });

        await uploadTask;
        if (!mounted) { httpClient.close(); return; }
        final String downloadUrl = await storageRef.getDownloadURL();

        if (mounted) setState(() { statusMessage = "Upload successful! Saving metadata..."; _uploadProgress = null; });

        // *** THIS IS THE DATA BEING SAVED TO THE 'auscultation_recordings' DOCUMENT ***
        Map<String, dynamic> recordingMetaDataToSave = {
          'fileNameInStorage': firebaseFileName,
          'originalEsp32FileName': fetchedFileName,
          'downloadUrl': downloadUrl,
          'storagePath': storageRef.fullPath,
          'auscultationType': _selectedOption,
          'durationSeconds': _currentRecordingDuration,
          'recordedAt': FieldValue.serverTimestamp(),
          'esp32Ip': _esp32IpAddress,
          'fileSizeBytes': audioData.lengthInBytes,
          // --- DENORMALIZED FIELDS ---
          'doctorId': doctorId,                 // Essential for the StethoLogs query
          'patientId': patientId,               // Essential for navigation & linking
          'patientFirstName': patientFirstName,   // For search and direct display in StethoLogsCard
          'patientLastName': patientLastName,     // For search and direct display in StethoLogsCard
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(doctorId)
            .collection('patients')
            .doc(patientId)
            .collection('auscultation_recordings')
            .add(recordingMetaDataToSave);

        if (!mounted) { httpClient.close(); return; }
        print("Metadata saved to Firestore: $recordingMetaDataToSave");
        if (mounted) setState(() { statusMessage = "Process complete! Audio uploaded and metadata saved.";});

      } else {
        String errorBody = "Unknown error"; try { errorBody = await streamedResponse.stream.bytesToString(); } catch(_){}
        throw Exception("ESP32 fetch error: ${streamedResponse.statusCode} - $errorBody");
      }
    } catch (e) {
      print("Error in _processAndUploadEsp32Audio: $e");
      if (mounted) setState(() { statusMessage = "Error processing audio: ${e.toString().split('\n').first}"; _uploadProgress = null; });
    } finally {
      httpClient.close();
      if (mounted) setState(() { _isProcessingAudio = false; _isLoadingCommand = false; });
    }
  }

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

  Future<void> _navigateToPatientProfile() async { // Changed to Future<void> for async operations
    if (_isLoadingCommand || _isRecording || _isProcessingAudio) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please wait for the current operation to complete.'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating)
        );
      }
      return;
    }

    final String? doctorId = _currentDoctorId;
    final String? patientId = _selectedPatientId;

    if (doctorId == null) {
      if (mounted) setState(() { statusMessage = "Error: Doctor not logged in."; });
      return;
    }
    if (patientId == null || patientId.isEmpty) {
      if (mounted) {
        setState(() { statusMessage = "Please select a patient to view their profile."; });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a patient first.'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating)
        );
      }
      return;
    }

    if (mounted) setState(() { _isLoadingCommand = true; statusMessage = "Loading patient profile..."; });

    try {
      DocumentSnapshot patientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .collection('patients')
          .doc(patientId)
          .get();

      if (!mounted) return;

      if (patientDoc.exists) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientProfile(patientData: patientDoc),
          ),
        );
        // Reset status message after successful navigation attempt
        if(mounted) setState(() {statusMessage = "Idle.";});

      } else {
        if(mounted) setState(() { statusMessage = "Error: Patient profile not found."; });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patient profile could not be loaded.'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating)
        );
      }
    } catch (e) {
      if (mounted) setState(() { statusMessage = "Error loading profile: ${e.toString().split('\n').first}"; });
      print("Error fetching patient document: $e");
    } finally {
      if (mounted) setState(() { _isLoadingCommand = false; });
    }
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                child: Center(
                    child: _isRecording
                        ? const RandomWaveformWidget() // Display waveform when recording
                        : Text(
                      _isProcessingAudio ? "Processing Audio..." : "Waveform (ESP32 audio after processing)",
                      style: TextStyle(color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    )
                ),
              ),
              const SizedBox(height: 30),
              Text(_timerText, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w300), textAlign: TextAlign.center),
              Icon(Icons.mic_none, size: 48, color: _isRecording ? Colors.red.shade700 : Colors.grey.shade700),
              const SizedBox(height: 20),
              Text("Select Recording Duration:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBlue), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Wrap(spacing: 10.0, runSpacing: 10.0, alignment: WrapAlignment.center, children: [_buildDurationButton(15), _buildDurationButton(30), _buildDurationButton(45), _buildDurationButton(60)]),
              const SizedBox(height: 20),
              if (statusMessage.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Text(statusMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: statusMessage.toLowerCase().contains("error") || statusMessage.toLowerCase().contains("failed") ? Colors.red.shade700 : Colors.black87))),
              if (_isProcessingAudio && _uploadProgress != null && _uploadProgress! >= 0 && _uploadProgress! <= 1)
                Padding(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 40), child: LinearProgressIndicator(value: _uploadProgress, minHeight: 6)),
              const SizedBox(height: 20),
              const Divider(),
              Text("Select Patient", style: TextStyle(color: darkBlue, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              if (doctorId == null)
                const Padding(padding: EdgeInsets.all(8.0), child: Text("Loading user information or user not logged in...", style: TextStyle(color: Colors.orange), textAlign: TextAlign.center))
              else
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(doctorId).collection('patients').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError) return Text("Error fetching patients: ${snapshot.error}", style: const TextStyle(color: Colors.red), textAlign: TextAlign.center);
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text("No Patients Found for this Doctor", textAlign: TextAlign.center);

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
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_search_outlined),
                label: const Text("View Selected Patient Profile"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: darkBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16)
                ),
                onPressed: (_isLoadingCommand || _isRecording || _isProcessingAudio) ? null : _navigateToPatientProfile,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
