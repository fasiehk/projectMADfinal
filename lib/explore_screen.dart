import 'package:flutter/material.dart';
import 'package:finalwe/services/book_service.dart';
import 'package:finalwe/widgets/book_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Book> _books = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRandomBooks();
  }

  Future<void> _fetchRandomBooks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final books = await fetchBooks('random');
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

  Future<void> _searchBooks() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });
    try {
      final books = await fetchBooks(query);
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
        title: const Text('Explore Books'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for books...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchBooks,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: ListView.builder(
                itemCount: _books.length,
                itemBuilder: (context, index) {
                  final book = _books[index];
                  return BookCard(
                    title: book.title,
                    author: book.author,
                    coverId: book.coverId,
                    bookKey: book.key, // Pass the book key
                    olid: book.olid, // Pass the OLID if available
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
