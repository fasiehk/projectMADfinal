import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../screens/book_details_screen.dart';
import '../providers/saved_books_provider.dart';
import '../services/book_service.dart';

class BookCard extends StatefulWidget {
  final String title;
  final String author;
  final int? coverId;
  final String bookKey;
  final String? olid;
  final bool isInSavedBooksScreen;

  const BookCard({
    super.key,
    required this.title,
    required this.author,
    this.coverId,
    required this.bookKey,
    this.olid,
    this.isInSavedBooksScreen = false,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  static bool _isNavigating = false; // Global flag to prevent multiple navigations
  bool _isLoading = false;

  Future<void> _navigateToDetails(BuildContext context) async {
    if (_isNavigating) return; // Prevent multiple navigations
    setState(() {
      _isLoading = true;
      _isNavigating = true;
    });

    try {
      // Fetch book details directly from the OpenLibrary API
      final bookDetails = await _fetchBookDetails(widget.bookKey);

      if (bookDetails != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailsScreen(
              title: bookDetails['title'] ?? 'Unknown Title',
              author: bookDetails['author'] ?? 'Unknown Author',
              coverId: bookDetails['coverId'],
              olid: widget.bookKey, // Use the book key as the OLID
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load book details')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isNavigating = false; // Reset the flag after navigation
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchBookDetails(String bookKey) async {
    // Ensure the bookKey is sanitized (e.g., remove leading/trailing slashes)
    final sanitizedKey = bookKey.startsWith('/works/')
        ? bookKey.replaceFirst('/works/', '')
        : bookKey;

    final url = Uri.parse('https://openlibrary.org/works/$sanitizedKey.json');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'title': data['title'],
          'author': (data['authors'] != null && data['authors'].isNotEmpty)
              ? data['authors'][0]['name']
              : 'Unknown Author',
          'coverId': (data['covers'] != null && data['covers'].isNotEmpty)
              ? data['covers'][0]
              : null,
        };
      } else {
        print("Failed to fetch book details: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching book details: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final savedBooksProvider = Provider.of<SavedBooksProvider>(context);
    final isSaved = savedBooksProvider.savedBooks.any((book) => book.key == widget.bookKey);

    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      child: Stack(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              splashColor: Colors.deepPurple.withOpacity(0.1), // Reduced ripple effect opacity
              onTap: () => _navigateToDetails(context),
              child: ListTile(
                leading: widget.coverId != null
                    ? Image.network(
                        'https://covers.openlibrary.org/b/id/${widget.coverId}-M.jpg',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.book, size: 50),
                title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(widget.author),
                trailing: IconButton(
                  icon: Icon(isSaved ? Icons.bookmark_remove : Icons.bookmark_add),
                  onPressed: () async {
                    try {
                      if (isSaved) {
                        await savedBooksProvider.removeBook(widget.bookKey);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Book removed from saved list')),
                        );
                      } else {
                        final book = Book(
                          title: widget.title,
                          author: widget.author,
                          key: widget.bookKey,
                          coverId: widget.coverId,
                          olid: widget.olid,
                        );
                        await savedBooksProvider.saveBook(book);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Book saved successfully')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
