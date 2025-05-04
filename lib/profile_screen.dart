import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore for fetching username
import 'login_page.dart';
import 'screens/update_password_screen.dart';
import 'terms_and_conditions_screen.dart'; // Import Terms and Conditions screen
import 'about_us_screen.dart'; // Import About Us screen
import 'package:provider/provider.dart';
import 'providers/saved_books_provider.dart'; // Import SavedBooksProvider

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _username;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _username = doc.data()?['username'] ?? 'User';
      });
    } catch (e) {
      print("Error fetching username: $e");
      setState(() {
        _username = 'User';
      });
    }
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
            // Profile Picture
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.deepPurple.shade100,
                child: user?.photoURL != null
                    ? ClipOval(
                        child: Image.network(
                          user!.photoURL!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        (_username ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
              ),
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
