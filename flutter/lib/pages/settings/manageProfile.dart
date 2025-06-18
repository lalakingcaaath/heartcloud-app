import 'dart:io';
import 'package:flutter/material.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/utils/bottom_navbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

// No need to import LoginPage here when using named routes
// import 'package:heartcloud/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 0;
  File? _imageFile;
  String? _profileImageUrl;
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final userData = await _getUserData();
    if (userData != null && mounted) {
      setState(() {
        _profileImageUrl = userData['profileImageUrl'];
      });
    }
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        await _uploadProfilePicture();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_imageFile == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final String fileName = 'profile_pictures/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.png';
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

      final UploadTask uploadTask = storageRef.putFile(_imageFile!);
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profileImageUrl': downloadUrl,
      });

      if (mounted) {
        setState(() {
          _profileImageUrl = downloadUrl;
          _imageFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload profile picture: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
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
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    try {
      await FirebaseAuth.instance.signOut();

      // <<< MODIFIED: Using pushNamedAndRemoveUntil with the '/login' route name >>>
      // This is the correct way to use this method.
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: ${e.toString()}')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    ImageProvider<Object> displayImage;
    if (_imageFile != null) {
      displayImage = FileImage(_imageFile!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      displayImage = NetworkImage(_profileImageUrl!);
    } else {
      displayImage = const NetworkImage(
        'https://media.istockphoto.com/id/1316947194/vector/messenger-profile-icon-on-white-isolated-background-vector-illustration.jpg?s=612x612&w=0&k=20&c=1iQ926GXQTJkopoZAdYXgU17NCDJIRUzx6bhzgLm9ps=',
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 70),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "My Account",
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundImage: displayImage,
                        backgroundColor: Colors.grey[200],
                        child: _isUploading ? const CircularProgressIndicator() : null,
                      ),
                      if (!_isUploading)
                        Positioned(
                          bottom: -10,
                          left: 80,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {
                                _showImageSourceActionSheet(context);
                              },
                              icon: Icon(Icons.add_a_photo, color: darkBlue, size: 28),
                            ),
                          ),
                        )
                    ],
                  )
                ],
              ),
              const SizedBox(height: 20),
              FutureBuilder<Map<String, dynamic>?>(
                future: _getUserData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _profileImageUrl == null) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return const Text("Error loading name");
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    return const Text("No user data found for name");
                  }

                  final userData = snapshot.data!;
                  final firstName = userData['firstName'] ?? '';
                  final lastName = userData['lastName'] ?? '';

                  return Text(
                    '$firstName $lastName'.trim(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: darkBlue,
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("My Patients", style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: darkBlue
                  )),
                ],
              ),
              const SizedBox(height: 30),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('patients')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No Patient Available",
                        style: TextStyle(fontSize: 18, color: darkBlue),
                      ),
                    );
                  }

                  final patients = snapshot.data!.docs;

                  return Column(
                    children: patients.map((patient) {
                      var patientData = patient.data() as Map<String, dynamic>?;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "${patientData?['firstName'] ?? 'N/A'} ${patientData?['lastName'] ?? 'N/A'}",
                              style: TextStyle(color: darkBlue, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 50),
              ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Log Out',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 30),
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
}