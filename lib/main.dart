import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/saved_books_provider.dart'; // Import SavedBooksProvider
import 'signup_screen.dart';
import 'login_page.dart';
import 'home_screen.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Ensure Firebase is initialized
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SavedBooksProvider(), // Ensure this is registered
        ),
      ],
      child: MaterialApp(
        title: '',
        theme: ThemeData(primarySwatch: Colors.deepPurple),
        debugShowCheckedModeBanner: false, // Hide the debug banner
        home: SplashScreen(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text('Login'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                );
              },
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
