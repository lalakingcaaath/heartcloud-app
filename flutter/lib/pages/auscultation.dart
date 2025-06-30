import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:heartcloud/utils/auth_provider.dart';
import 'package:heartcloud/utils/app_user.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class RandomWaveformWidget extends StatefulWidget {
  final Color waveColor;
  final double strokeWidth;
  const RandomWaveformWidget({ super.key, this.waveColor = _RecordAuscultationState.darkBlue, this.strokeWidth = 2.0 });
  @override
  State<RandomWaveformWidget> createState() => _RandomWaveformWidgetState();
}
class _RandomWaveformWidgetState extends State<RandomWaveformWidget> {
  List<double> _amplitudes = [];
  Timer? _animationTimer;
  final math.Random _random = math.Random();
  final int _numberOfBars = 50;
  @override
  void initState() {
    super.initState();
    _generateAmplitudes();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) _generateAmplitudes(); else timer.cancel();
    });
  }
  void _generateAmplitudes() => setState(() => _amplitudes = List.generate(_numberOfBars, (index) => _random.nextDouble()));
  @override
  void dispose() { _animationTimer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _WaveformPainter(amplitudes: _amplitudes, waveColor: widget.waveColor, strokeWidth: widget.strokeWidth), size: Size.infinite);
}
class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color waveColor;
  final double strokeWidth;
  _WaveformPainter({ required this.amplitudes, required this.waveColor, required this.strokeWidth });
  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;
    final paint = Paint()..color = waveColor..strokeWidth = strokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final double barWidth = size.width / amplitudes.length;
    final double centerY = size.height / 2;
    final double maxAmplitudeHeight = size.height * 0.4;
    for (int i = 0; i < amplitudes.length; i++) {
      final double barX = (i * barWidth) + (barWidth / 2);
      final double barHeight = (amplitudes[i] * 0.8 + 0.2) * maxAmplitudeHeight;
      canvas.drawLine(Offset(barX, centerY - barHeight / 2), Offset(barX, centerY + barHeight / 2), paint);
    }
  }
  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => oldDelegate.amplitudes != amplitudes || oldDelegate.waveColor != waveColor || oldDelegate.strokeWidth != strokeWidth;
}

class RecordAuscultation extends StatefulWidget {
  final Function(DocumentSnapshot) onViewProfile;
  const RecordAuscultation({super.key, required this.onViewProfile});

  @override
  State<RecordAuscultation> createState() => _RecordAuscultationState();
}

class _RecordAuscultationState extends State<RecordAuscultation> {
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  bool _isLoadingCommand = false;
  bool _isProcessingAudio = false;
  String? _selectedOption = 'Heart';
  final String _esp32IpAddress = '192.168.1.112';
  int _currentRecordingDuration = 0;
  double? _uploadProgress;
  String _timerText = '00:00 / --:--';
  Timer? _timer;
  int _secondsElapsed = 0;
  String statusMessage = "Loading...";
  static const Color darkBlue = Color(0xFF003366);
  String? _assignedDoctorId;
  String? _selectedPatientId;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _initializeRecorderAndPermissions();
    _timerText = _formatTime(0, 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isPatient) {
          _loadPatientData(authProvider.appUser);
          setState(() => statusMessage = "Ready to record your own auscultation.");
        } else {
          setState(() => statusMessage = "Idle. Select a patient and duration to record.");
        }
      }
    });
  }

  Future<void> _loadPatientData(AppUser? patientUser) async {
    if (patientUser == null) return;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(patientUser.uid).get();
      if (mounted && userDoc.exists) {
        setState(() {
          _assignedDoctorId = userDoc.get('assignedDoctorId');
          if (_assignedDoctorId == null) statusMessage = "You must be assigned to a doctor to save recordings.";
        });
      }
    } catch (e) {
      if (mounted) setState(() => statusMessage = "Error loading your profile. Cannot record.");
    }
  }

  Map<String, String>? _getDoctorAndPatientIds(AppUser currentUser, bool isPatient) {
    if (isPatient) {
      if (_assignedDoctorId == null || _assignedDoctorId!.isEmpty) {
        if (mounted) setState(() => statusMessage = "Error: You are not assigned to a doctor.");
        return null;
      }
      return {'doctorId': _assignedDoctorId!, 'patientId': currentUser.uid};
    } else {
      if (_selectedPatientId == null || _selectedPatientId!.isEmpty) {
        if (mounted) setState(() => statusMessage = "Please select a patient before recording.");
        return null;
      }
      return {'doctorId': currentUser.uid, 'patientId': _selectedPatientId!};
    }
  }

  Future<void> _initiateEsp32Recording(int duration) async {
    if (_isRecording || _isLoadingCommand || _isProcessingAudio) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.appUser == null) return;
    final ids = _getDoctorAndPatientIds(authProvider.appUser!, authProvider.isPatient);
    if (ids == null) return;

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
      setState(() { statusMessage = 'Recording...'; _isLoadingCommand = false; });
      _startTimer();
    } else {
      setState(() { _isRecording = false; _currentRecordingDuration = 0; _timerText = _formatTime(0, 0); _isLoadingCommand = false; });
    }
  }

  Future<void> _processAndUploadEsp32Audio() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.appUser == null) return;
    final ids = _getDoctorAndPatientIds(authProvider.appUser!, authProvider.isPatient);
    if (ids == null) {
      if (mounted) setState(() { _isProcessingAudio = false; _isLoadingCommand = false; });
      return;
    }
    final String doctorId = ids['doctorId']!;
    final String patientId = ids['patientId']!;

    if (mounted) setState(() { _isProcessingAudio = true; _isLoadingCommand = true; _uploadProgress = null; statusMessage = "Fetching audio from ESP32..."; });

    String patientFirstName = 'Unknown'; String patientLastName = 'Patient';
    try {
      DocumentSnapshot patientDoc = await FirebaseFirestore.instance.collection('users').doc(doctorId).collection('patients').doc(patientId).get();
      if (patientDoc.exists) {
        patientFirstName = patientDoc.get('firstName') ?? 'Unknown';
        patientLastName = patientDoc.get('lastName') ?? 'Patient';
      }
    } catch (e) {
      print("Error fetching patient name: $e");
    }

    final http.Client httpClient = http.Client();

    try {
      final audioUrl = Uri.parse('http://$_esp32IpAddress/audio.wav');
      final request = http.Request('GET', audioUrl);
      final http.StreamedResponse streamedResponse = await httpClient.send(request).timeout(Duration(seconds: _currentRecordingDuration + 45));
      if (!mounted) { httpClient.close(); return; }

      if (streamedResponse.statusCode == 200) {
        final Uint8List audioData = await streamedResponse.stream.toBytes();
        if (!mounted || audioData.isEmpty) throw Exception("Received empty audio stream.");

        if (mounted) setState(() { statusMessage = "Uploading to Firebase Storage..."; });
        final String firebaseFileName = 'auscultation_${_selectedOption?.replaceAll(' ', '_') ?? "Unknown"}_${DateTime.now().millisecondsSinceEpoch}.wav';
        final firebase_storage.Reference storageRef = firebase_storage.FirebaseStorage.instance.ref('patient_auscultations/$doctorId/$patientId/$firebaseFileName');

        final firebase_storage.UploadTask uploadTask = storageRef.putData(audioData, firebase_storage.SettableMetadata(contentType: 'audio/wav'));
        uploadTask.snapshotEvents.listen((s) => setState(() => _uploadProgress = s.bytesTransferred / s.totalBytes));
        await uploadTask;
        if (!mounted) { httpClient.close(); return; }
        final String downloadUrl = await storageRef.getDownloadURL();
        if (mounted) setState(() { statusMessage = "Saving metadata..."; _uploadProgress = null; });

        await FirebaseFirestore.instance.collection('users').doc(doctorId).collection('patients').doc(patientId).collection('auscultation_recordings').add({
          'fileNameInStorage': firebaseFileName, 'downloadUrl': downloadUrl, 'storagePath': storageRef.fullPath, 'auscultationType': _selectedOption, 'durationSeconds': _currentRecordingDuration, 'recordedAt': FieldValue.serverTimestamp(), 'esp32Ip': _esp32IpAddress, 'fileSizeBytes': audioData.lengthInBytes, 'doctorId': doctorId, 'patientId': patientId, 'patientFirstName': patientFirstName, 'patientLastName': patientLastName,
        });

        if (mounted) setState(() { statusMessage = "Process complete!"; });
      } else {
        throw Exception("ESP32 fetch error: ${streamedResponse.statusCode}");
      }
    } catch (e) {
      if (mounted) setState(() { statusMessage = "Error: ${e.toString().split(':').last}"; _uploadProgress = null; });
    } finally {
      httpClient.close();
      if (mounted) setState(() { _isProcessingAudio = false; _isLoadingCommand = false; });
    }
  }

  Future<void> _navigateToPatientProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final doctorId = authProvider.appUser?.uid;

    if (doctorId == null || _selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a patient first.")));
      return;
    }

    try {
      DocumentSnapshot patientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .collection('patients')
          .doc(_selectedPatientId)
          .get();

      if (patientDoc.exists) {
        widget.onViewProfile(patientDoc);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not find patient profile.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder?.closeRecorder();
    super.dispose();
  }

  Future<void> _initializeRecorderAndPermissions() async {
    PermissionStatus micStatus = await Permission.microphone.request();
    if (!mounted) return;
    if (micStatus.isDenied) _showPermissionDialog('Microphone Permission', 'Microphone permission is recommended for certain features.');
    if (micStatus.isPermanentlyDenied) _showOpenSettingsDialog('Microphone Permission', 'Microphone permission has been permanently denied. Please enable it in settings.');
    if (micStatus.isGranted && (_recorder?.isStopped ?? true)) await _recorder?.openRecorder();
  }

  void _showPermissionDialog(String title, String content) {
    if(mounted) showDialog(context: context, builder: (c) => AlertDialog(title: Text(title), content: Text(content), actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: const Text("OK"))]));
  }

  void _showOpenSettingsDialog(String title, String content) {
    if(mounted) showDialog(context: context, builder: (c) => AlertDialog(title: Text(title), content: Text(content), actions: [TextButton(onPressed: (){Navigator.pop(c); openAppSettings();}, child: const Text("Open Settings")), TextButton(onPressed: ()=>Navigator.pop(c), child: const Text("Cancel"))]));
  }

  Future<bool> _sendEsp32Command(String path, {int timeoutSeconds = 10}) async {
    try {
      final response = await http.get(Uri.parse('http://$_esp32IpAddress/$path')).timeout(Duration(seconds: timeoutSeconds));
      if (!mounted) return false;
      if (response.statusCode == 200) {
        return true;
      } else {
        setState(() { statusMessage = 'ESP32 Error: Status ${response.statusCode}'; });
        return false;
      }
    } catch (e) {
      if (mounted) setState(() { statusMessage = 'ESP32 Command Failed: ${e.toString().split('\n').first}';});
      return false;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRecording && timer.isActive) { timer.cancel(); return; }
      if (_secondsElapsed < _currentRecordingDuration) {
        if (mounted) setState(() { _secondsElapsed++; _timerText = _formatTime(_secondsElapsed, _currentRecordingDuration); });
      } else {
        _timer?.cancel();
        if (mounted) {
          setState(() { _isRecording = false; statusMessage = 'Processing audio...'; });
          _processAndUploadEsp32Audio();
        }
      }
    });
  }

  String _formatTime(int elapsedSeconds, int totalSeconds) {
    if(totalSeconds == 0) return "00:00 / --:--";
    String format(int s) => (s % 60).toString().padLeft(2, '0');
    return "${(elapsedSeconds~/60).toString().padLeft(2, '0')}:${format(elapsedSeconds)} / ${(totalSeconds~/60).toString().padLeft(2, '0')}:${format(totalSeconds)}";
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isLoggedIn || authProvider.appUser == null) {
      return const Center(child: Text("Please log in."));
    }
    return authProvider.isPatient ? _buildPatientRecordingView(authProvider) : _buildDoctorRecordingView(authProvider);
  }

  Widget _buildDoctorRecordingView(AuthProvider authProvider) {
    final String? doctorId = authProvider.appUser?.uid;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRecordingControls(authProvider),
          const SizedBox(height: 20),
          const Divider(),
          const Text("Select Patient", style: TextStyle(color: darkBlue, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          if (doctorId == null)
            const Center(child: Text("Loading user information..."))
          else
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(doctorId).collection('patients').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Text("Error: ${snapshot.error}");
                if (snapshot.data!.docs.isEmpty) return const Text("No Patients Found", textAlign: TextAlign.center);
                List<DropdownMenuItem<String>> patientItems = snapshot.data!.docs.map((doc) =>
                    DropdownMenuItem<String>(value: doc.id, child: Text('${doc.get('firstName') ?? ''} ${doc.get('lastName') ?? ''}'))).toList();
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  isExpanded: true, hint: const Text("Select Patient"), value: _selectedPatientId,
                  onChanged: (_isLoadingCommand || _isRecording || _isProcessingAudio) ? null : (v) => setState(() => _selectedPatientId = v),
                  items: patientItems,
                );
              },
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_search_outlined),
            label: const Text("View Selected Patient Profile"),
            onPressed: (_isLoadingCommand || _isRecording || _isProcessingAudio) ? null : _navigateToPatientProfile,
            style: ElevatedButton.styleFrom(backgroundColor: darkBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientRecordingView(AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRecordingControls(authProvider),
          const SizedBox(height: 20),
          if (_assignedDoctorId == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
              child: const Text("You are not currently assigned to a doctor. Recordings cannot be saved until your doctor adds you to their patient list.", textAlign: TextAlign.center),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
              child: const Text("You are ready to record. Recordings will be saved to your profile.", textAlign: TextAlign.center),
            )
        ],
      ),
    );
  }

  Widget _buildRecordingControls(AuthProvider authProvider) {
    final bool isPatient = authProvider.isPatient;
    final bool canRecord = isPatient ? _assignedDoctorId != null : _selectedPatientId != null;
    final bool isBusy = _isLoadingCommand || _isRecording || _isProcessingAudio;

    return Column(
      children: [
        DropdownButton<String>(
          value: _selectedOption, isExpanded: true,
          onChanged: isBusy ? null : (v) => setState(() => _selectedOption = v),
          items: <String>['Heart', 'Lungs'].map((v) => DropdownMenuItem<String>(value: v, child: Text(v, style: const TextStyle(fontSize: 20, color: darkBlue)))).toList(),
        ),
        const SizedBox(height: 30),
        Container(
          height: 100, width: double.infinity,
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
          child: Center(
              child: _isRecording
                  ? const RandomWaveformWidget()
                  : Text(_isProcessingAudio ? "Processing Audio..." : "Waveform will appear here", style: TextStyle(color: Colors.grey.shade700))),
        ),
        const SizedBox(height: 30),
        Text(_timerText, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w300), textAlign: TextAlign.center),
        Icon(Icons.mic_none, size: 48, color: _isRecording ? Colors.red.shade700 : Colors.grey.shade700),
        const SizedBox(height: 20),
        const Text("Select Recording Duration:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBlue), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10.0, runSpacing: 10.0, alignment: WrapAlignment.center,
          children: [15, 30, 45, 60].map((d) => ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: darkBlue, foregroundColor: Colors.white),
            onPressed: isBusy || !canRecord ? null : () => _initiateEsp32Recording(d),
            child: Text("Record ${d}s"),
          )).toList(),
        ),
        const SizedBox(height: 20),
        if (statusMessage.isNotEmpty)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Text(statusMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: statusMessage.toLowerCase().contains("error") ? Colors.red.shade700 : Colors.black87))),
        if (_isProcessingAudio && _uploadProgress != null)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 40),
              child: LinearProgressIndicator(value: _uploadProgress, minHeight: 6)),
      ],
    );
  }
}