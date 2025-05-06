import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import 'dart:io';
import 'login_page.dart';
import 'screens/update_password_screen.dart';
import 'terms_and_conditions_screen.dart';
import 'about_us_screen.dart';
import 'package:provider/provider.dart';
import 'providers/saved_books_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? _username;
  String? _photoURL;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _username = doc.data()?['username'] ?? 'User';
        _photoURL = doc.data()?['photoURL'];
      });
    } catch (e) {
      print("Error fetching user profile: $e");
      setState(() {
        _username = 'User';
      });
    }
  }

  Future<void> _updateProfilePicture() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Pick an image from the gallery
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      final File imageFile = File(pickedFile.path);

      // Upload the image to Firebase Storage
      final storageRef = _storage.ref().child('profile_pictures/${user.uid}.jpg');
      final uploadTask = await storageRef.putFile(imageFile);
      final downloadURL = await uploadTask.ref.getDownloadURL();

      // Update the Firestore document with the new photoURL
      await _firestore.collection('users').doc(user.uid).update({'photoURL': downloadURL});

      // Update the UI
      setState(() {
        _photoURL = downloadURL;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully')),
      );
    } catch (e) {
      print("Error updating profile picture: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteProfilePicture() async {
    final user = _auth.currentUser;
    if (user == null || _photoURL == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete your profile picture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      // Delete the image from Firebase Storage
      final storageRef = _storage.refFromURL(_photoURL!);
      await storageRef.delete();

      // Remove the photoURL field from Firestore
      await _firestore.collection('users').doc(user.uid).update({'photoURL': FieldValue.delete()});

      // Update the UI
      setState(() {
        _photoURL = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture deleted successfully')),
      );
    } catch (e) {
      print("Error deleting profile picture: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showProfilePictureOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.deepPurple),
            title: const Text('Update Profile Picture'),
            onTap: () {
              Navigator.pop(context);
              _updateProfilePicture();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Profile Picture'),
            onTap: () {
              Navigator.pop(context);
              _deleteProfilePicture();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _sendPasswordResetEmail(BuildContext context) async {
    final shouldSendEmail = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Password Reset'),
        content: const Text('Do you want to send a password reset email to your registered email address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (shouldSendEmail == true) {
      final user = _auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is currently signed in')),
        );
        return;
      }

      try {
        await _auth.sendPasswordResetEmail(email: user.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _navigateToUpdatePasswordScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UpdatePasswordScreen()),
    );
  }

  void _navigateToTermsAndConditions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()),
    );
  }

  void _navigateToAboutUs(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutUsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final String userEmail = user?.email ?? "No Email";
    final savedBooksProvider = Provider.of<SavedBooksProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Picture with Edit Icon
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.deepPurple.shade100,
                  backgroundImage: _photoURL != null ? NetworkImage(_photoURL!) : null,
                  child: _photoURL == null
                      ? Text(
                          (_username ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: -10,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.deepPurple, size: 28),
                    onPressed: _showProfilePictureOptions,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // User Name
            Center(
              child: Text(
                "Hello, ${_username ?? 'User'}!",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            const SizedBox(height: 5),
            // User Email
            Center(
              child: Text(
                userEmail,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Account Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: const [
                  Text(
                    "Account",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 1, color: Colors.grey),
            // Total Saved Books
            ListTile(
              leading: const Icon(Icons.book, color: Colors.deepPurple),
              title: const Text('Total Saved Books'),
              trailing: Text(
                '${savedBooksProvider.savedBooks.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            // Update Password Option
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.deepPurple),
              title: const Text('Update Password'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _navigateToUpdatePasswordScreen(context),
            ),
            // Forgot Password Option
            ListTile(
              leading: const Icon(Icons.email, color: Colors.deepPurple),
              title: const Text('Forgot Password'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _sendPasswordResetEmail(context),
            ),
            const SizedBox(height: 20),
            // Information Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: const [
                  Text(
                    "Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 1, color: Colors.grey),
            // Terms and Conditions Option
            ListTile(
              leading: const Icon(Icons.description, color: Colors.deepPurple),
              title: const Text('Terms and Conditions'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _navigateToTermsAndConditions(context),
            ),
            // About Us Option
            ListTile(
              leading: const Icon(Icons.info, color: Colors.deepPurple),
              title: const Text('About Us'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _navigateToAboutUs(context),
            ),
            const SizedBox(height: 20),
            // Security Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: const [
                  Text(
                    "Security",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 1, color: Colors.grey),
            // Logout Option
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.deepPurple),
              title: const Text('Logout'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}
