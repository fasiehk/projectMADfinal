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

      final fetchedBooks = snapshot.docs.map((doc) => Book(
            title: doc['title'] ?? '',
            author: doc['author'] ?? '',
            key: doc['key'] ?? '',
            coverId: doc['coverId'],
          ));

      // Avoid duplication by clearing the list and adding only unique books
      _savedBooks.clear();
      _savedBooks.addAll(fetchedBooks);
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
      print("Saving book with key: ${book.key} for user: ${user.uid}");
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_books')
          .doc(book.key)
          .set({
        'title': book.title,
        'author': book.author,
        'key': book.key,
        'coverId': book.coverId,
      });

      // Add the book to the list only if it doesn't already exist
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
      print("Removing book with key: $bookKey for user: ${user.uid}");
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_books')
          .doc(bookKey)
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
