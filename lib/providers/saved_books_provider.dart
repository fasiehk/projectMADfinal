import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/book_service.dart';

class SavedBooksProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Book> _savedBooks = [];
  List<Book> get savedBooks => _savedBooks;

  Future<void> fetchSavedBooks() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    try {
      print("Fetching saved books for user: ${user.uid}");
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_books')
          .get();

      final fetchedBooks = snapshot.docs.map((doc) {
        final data = doc.data();
        return Book(
          title: data['title'] ?? 'Unknown Title',
          author: data['author'] ?? 'Unknown Author',
          key: data['key'] ?? '',
          coverId: data['coverId'],
          olid: data['olid'] ?? data['key'], // Use `key` as fallback for `olid`
        );
      }).toList(); // Convert to List<Book>

      _savedBooks.clear();
      _savedBooks.addAll(fetchedBooks); // Add fetched books to the list
      print("Fetched ${_savedBooks.length} saved books.");
      notifyListeners();
    } catch (e) {
      print("Error fetching saved books: $e");
      throw Exception('Failed to fetch saved books: $e');
    }
  }

  Future<void> saveBook(Book book) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    try {
      // Sanitize the key to use only the last segment as the document ID
      final sanitizedKey = book.key.split('/').last;

      print("Saving book with sanitized key: $sanitizedKey for user: ${user.uid}");
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_books')
          .doc(sanitizedKey) // Use sanitized key as the document ID
          .set({
        'title': book.title,
        'author': book.author,
        'key': book.key, // Save the full key for later use
        'coverId': book.coverId,
        'olid': book.olid, // Ensure the OLID is saved
      });

      if (!_savedBooks.any((savedBook) => savedBook.key == book.key)) {
        _savedBooks.add(book);
        print("Book saved successfully.");
        notifyListeners();
      } else {
        print("Book already exists in the saved list.");
      }
    } catch (e) {
      print("Error saving book: $e");
      throw Exception('Failed to save book: $e');
    }
  }

  Future<void> removeBook(String bookKey) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    try {
      // Extract the last segment of the key to use as the document ID
      final sanitizedKey = bookKey.split('/').last;

      print("Removing book with sanitized key: $sanitizedKey for user: ${user.uid}");
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_books')
          .doc(sanitizedKey) // Use sanitized key as the document ID
          .delete();

      _savedBooks.removeWhere((book) => book.key == bookKey);
      print("Book removed successfully.");
      notifyListeners();
    } catch (e) {
      print("Error removing book: $e");
      throw Exception('Failed to remove book: $e');
    }
  }
}