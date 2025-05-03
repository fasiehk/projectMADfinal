import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ExploreScreen(),
    const SavedBooksScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _showWelcomeToast(); // Show welcome toast when the homepage is loaded
  }

  void _showWelcomeToast() {
    final user = _auth.currentUser;
    final userIdentifier = user?.email ?? "User"; // Use email or fallback to "User"
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartLibrary'),
        backgroundColor: Colors.deepPurple,
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
