import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:heartcloud/utils/auth_provider.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _imageFile;
  String? _profileImageUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _durationSubscription, _positionSubscription, _playerCompleteSubscription, _playerStateChangeSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadUserProfile();
    });

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

  Future<void> _loadUserProfile() async {
    final userData = await _getUserData();
    if (mounted && userData != null && userData.containsKey('profileImageUrl')) {
      setState(() {
        _profileImageUrl = userData['profileImageUrl'];
      });
    }
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
        await _uploadProfilePicture();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_imageFile == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isUploading = true);
    try {
      final String fileName = 'profile_pictures/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.png';
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(_imageFile!);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'profileImageUrl': downloadUrl});
      if (mounted) {
        setState(() {
          _profileImageUrl = downloadUrl;
          _imageFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated successfully!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload profile picture: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  }),
              ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  }),
            ],
          ),
        );
      },
    );
  }

  // **** START OF FIX ****
  Future<void> _signOut() async {
    // This function now handles both the patient and doctor logout flows correctly.
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // For the doctor role, this page is pushed on top of the Settings page.
      // We pop it first to prevent the UI from getting stuck.
      // For the patient role, this page is a main tab, so canPop is false and nothing happens.
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      await authProvider.signOut();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to sign out: ${e.toString()}')));
    }
  }
  // **** END OF FIX ****

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.appUser;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    ImageProvider<Object> displayImage;
    if (_imageFile != null) {
      displayImage = FileImage(_imageFile!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      displayImage = NetworkImage(_profileImageUrl!);
    } else {
      displayImage = const AssetImage('images/blank-pfp.png');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Account"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: darkBlue,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                      radius: 70,
                      backgroundImage: displayImage,
                      backgroundColor: Colors.grey[200]),
                  if (_isUploading) const CircularProgressIndicator(),
                  if (!_isUploading)
                    Positioned(
                      bottom: -10,
                      left: 80,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), shape: BoxShape.circle),
                        child: IconButton(
                          onPressed: () => _showImageSourceActionSheet(context),
                          icon: Icon(Icons.add_a_photo, color: darkBlue, size: 28),
                        ),
                      ),
                    )
                ],
              ),
              const SizedBox(height: 20),
              Text(user.fullName, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: darkBlue)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text("My Recording History", style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold, fontSize: 22)),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collectionGroup('auscultation_recordings')
                    .where('patientId', isEqualTo: user.uid)
                    .orderBy('recordedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No recordings found.")));

                  var recordings = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recordings.length,
                    itemBuilder: (context, index) {
                      final recordingDoc = recordings[index];
                      return _buildAudioPlayerControls(recordingDoc);
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
            Text("Type: ${recordingDoc['auscultationType'] ?? 'N/A'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text("Recorded: ${recordingDoc['recordedAt'] != null ? DateFormat('MMM d, yyyy - hh:mm a').format((recordingDoc['recordedAt'] as Timestamp).toDate()) : 'N/A'}", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    icon: Icon(isCurrentlyPlayingThis && _playerState == PlayerState.playing ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 40, color: darkBlue),
                    onPressed: () => _playPauseAudio(audioUrl)
                )
              ],
            ),
            if (isCurrentlyPlayingThis)
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(activeTrackColor: darkBlue, inactiveTrackColor: darkBlue.withOpacity(0.3), trackHeight: 2.0, thumbColor: darkBlue, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0), overlayColor: darkBlue.withAlpha(0x29), overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0)),
                    child: Slider(
                      min: 0,
                      max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                      value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                      onChanged: (value) async {
                        await _audioPlayer.seek(Duration(seconds: value.toInt()));
                        if (_playerState != PlayerState.playing) await _audioPlayer.resume();
                      },
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(_position)),
                            Text(_formatDuration(_duration))
                          ]
                      )
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}