import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/saved_books_provider.dart';
import '../widgets/book_card.dart';

class SavedBooksScreen extends StatefulWidget {
  const SavedBooksScreen({super.key});

  @override
  State<SavedBooksScreen> createState() => _SavedBooksScreenState();
}

class _SavedBooksScreenState extends State<SavedBooksScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedBooks();
  }

  Future<void> _loadSavedBooks() async {
    final savedBooksProvider = Provider.of<SavedBooksProvider>(context, listen: false);
    try {
      print("Fetching saved books...");
      await savedBooksProvider.fetchSavedBooks();
      print("Fetched ${savedBooksProvider.savedBooks.length} saved books.");
    } catch (e) {
      print("Error fetching saved books: $e");
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedBooksProvider = Provider.of<SavedBooksProvider>(context);

    if (_isLoading) {
      return  Scaffold(
        appBar: AppBar(
          title: Text('Saved Books'),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Saved Books'),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(
          child: Text(
            'Failed to load saved books: $_errorMessage',
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    final savedBooks = savedBooksProvider.savedBooks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Books'),
        backgroundColor: Colors.deepPurple,
      ),
      body: savedBooks.isEmpty
          ? const Center(
              child: Text(
                'Your saved books will appear here.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
          : ListView.builder(
              itemCount: savedBooks.length,
              itemBuilder: (context, index) {
                final book = savedBooks[index];
                return BookCard(
                  title: book.title,
                  author: book.author,
                  coverId: book.coverId,
                  bookKey: book.key,
                  isInSavedBooksScreen: true, // Pass true for SavedBooksScreen
                  olid: book.olid, // Ensure the OLID is passed correctly
                );
              },
            ),
    );
  }
}
