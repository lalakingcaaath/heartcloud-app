import 'dart:io'; // Needed for File
import 'package:flutter/material.dart';
import 'package:heartcloud/utils/colors.dart';
import 'package:heartcloud/utils/bottom_navbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // needed to get current user
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:firebase_storage/firebase_storage.dart'; // For uploading to Firebase Storage

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 0;
  File? _imageFile; // To store the picked image file
  String? _profileImageUrl; // To store the profile image URL from Firestore
  bool _isUploading = false; // To show a loading indicator during upload

  final ImagePicker _picker = ImagePicker(); // Instance of ImagePicker

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Handle navigation based on index if needed
      // For example:
      // if (index == 0) Navigator.pushReplacementNamed(context, '/home');
      // if (index == 1) Navigator.pushReplacementNamed(context, '/search');
      // etc.
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Load user profile data, including image URL
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

  // 🔹 Function to pick an image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        await _uploadProfilePicture(); // Upload after picking
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  // 🔹 Function to upload the profile picture to Firebase Storage
  Future<void> _uploadProfilePicture() async {
    if (_imageFile == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Create a reference to the Firebase Storage path
      final String fileName = 'profile_pictures/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.png';
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

      // Upload the file
      final UploadTask uploadTask = storageRef.putFile(_imageFile!);

      // Get the download URL
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update the user's profileImageUrl in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profileImageUrl': downloadUrl,
      });

      if (mounted) {
        setState(() {
          _profileImageUrl = downloadUrl; // Update the local state for immediate UI update
          _imageFile = null; // Clear the picked image
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


  @override
  Widget build(BuildContext context) {
    // Determine the image to display
    ImageProvider<Object> displayImage;
    if (_imageFile != null) {
      displayImage = FileImage(_imageFile!); // Show picked image if available
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      displayImage = NetworkImage(_profileImageUrl!); // Show network image from Firestore
    } else {
      displayImage = const NetworkImage( // Default placeholder
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
                    alignment: Alignment.center, // Better alignment for the loader
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundImage: displayImage,
                        backgroundColor: Colors.grey[200], // Placeholder bg
                        child: _isUploading ? const CircularProgressIndicator() : null,
                      ),
                      if (!_isUploading) // Only show button if not uploading
                        Positioned(
                          bottom: -10,
                          left: 80, // Adjusted for better positioning
                          child: Container( // Optional: Add a background to the icon button for better visibility
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {
                                _showImageSourceActionSheet(context); // Show options to pick image
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
                future: _getUserData(), // This will re-fetch, you might want to use the loaded _profileImageUrl if only name changes
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _profileImageUrl == null) { // Show loader only if initial data isn't loaded
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
                    children: patients.asMap().entries.map((entry) {
                      // int index = entry.key; // Not used in your current patient display
                      var patient = entry.value;
                      var patientData = patient.data() as Map<String, dynamic>?; // Cast data

                      // Alternate background color for cards
                      // Color cardColor = index.isEven
                      //     ? PatientCardColor1
                      //     : PatientCardColor2;

                      return Padding( // Added padding for better spacing
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "${patientData?['firstName'] ?? 'N/A'} ${patientData?['lastName'] ?? 'N/A'}",
                              style: TextStyle(color: darkBlue, fontSize: 16), // Added style
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 30), // Added for some bottom spacing
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