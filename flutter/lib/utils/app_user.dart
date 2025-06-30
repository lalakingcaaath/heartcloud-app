import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { patient, doctor, unknown }

class AppUser {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final UserRole role;

  // Computed property for convenience
  String get fullName => '$firstName $lastName';

  AppUser({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
  });

  // A factory constructor to create an AppUser from a Firestore document.
  // This is a common pattern for converting database data into Dart objects.
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Default to 'patient' if role is missing for any reason.
    String roleString = data['role'] ?? 'patient';
    UserRole role;
    if (roleString == 'doctor') {
      role = UserRole.doctor;
    } else {
      role = UserRole.patient;
    }

    return AppUser(
      uid: data['uid'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      role: role,
    );
  }
}
