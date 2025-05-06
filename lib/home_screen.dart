import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'explore_screen.dart';
import 'saved_books_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _currentIndex = 0;
  String? _username;
  String? _photoURL;

  final List<Widget> _pages = [
    const ExploreScreen(),
    const SavedBooksScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _showWelcomeToast(); // Show welcome toast when the homepage is loaded
  }

  Future<void> _fetchUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _username = doc.data()?['username'] ?? 'User'; // Fetch username from Firestore
        _photoURL = doc.data()?['photoURL']; // Fetch profile picture URL from Firestore
      });
    } catch (e) {
      print("Error fetching user profile: $e");
      setState(() {
        _username = 'User'; // Fallback to "User" if fetching fails
      });
    }
  }

  void _showWelcomeToast() {
    final user = _auth.currentUser;
    final userIdentifier = _username ?? user?.email ?? "User"; // Use username, email, or fallback to "User"
    Fluttertoast.showToast(
      msg: "Hello $userIdentifier, Welcome to SmartLibrary",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.deepPurple,
      textColor: Colors.white,
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToPage(int index) {
    Navigator.pop(context); // Close the drawer
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60), // Reduced height
        child: AppBar(
          backgroundColor: Colors.deepPurple,
          elevation: 5,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20), // Rounded bottom corners
            ),
          ),
          title: const Text(
            'SmartLibrary',
            style: TextStyle(
              fontFamily: 'RobotoMono', // Custom font
              fontSize: 22, // Slightly larger font size
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true, // Center the title
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Open the navigation drawer
              },
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepPurple),
              accountName: Text(
                _username ?? "User", // Dynamically fetched username
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                user?.email ?? "No Email",
                style: const TextStyle(fontSize: 16),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: _photoURL != null ? NetworkImage(_photoURL!) : null,
                child: _photoURL == null
                    ? Text(
                        (_username ?? "U")[0].toUpperCase(),
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      )
                    : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.explore, color: Colors.deepPurple),
              title: const Text('Explore'),
              onTap: () => _navigateToPage(0),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark, color: Colors.deepPurple),
              title: const Text('Saved Books'),
              onTap: () => _navigateToPage(1),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.deepPurple),
              title: const Text('Profile'),
              onTap: () => _navigateToPage(2),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages, // Keeps the state of each page intact
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Saved Books',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}
