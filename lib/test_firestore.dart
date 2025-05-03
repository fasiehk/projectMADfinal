import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestFirestore extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firestore Test')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              print("Testing Firestore connection...");
              await FirebaseFirestore.instance
                  .collection('test')
                  .add({'message': 'Hello, Firestore!'});
              print("Data added successfully to Firestore.");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Data added successfully!')),
              );
            } catch (e) {
              print("Error: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          },
          child: Text('Test Firestore Connection'),
        ),
      ),
    );
  }
}
