import 'package:flutter/material.dart';
import 'package:finalwe/services/book_service.dart';
import 'package:finalwe/widgets/book_card.dart';

class RomanceScreen extends StatefulWidget {
  const RomanceScreen({super.key});

  @override
  State<RomanceScreen> createState() => _RomanceScreenState();
}

class _RomanceScreenState extends State<RomanceScreen> {
  List<Book> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    try {
      final books = await fetchBooks('romance');
      setState(() {
        _books = books;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch books: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Romance'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? const Center(
                  child: Text(
                    'No books found.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    return BookCard(
                      title: book.title,
                      author: book.author,
                      coverId: book.coverId,
                      bookKey: book.key,
                      olid: book.olid,
                    );
                  },
                ),
    );
  }
}
