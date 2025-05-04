import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/book_service.dart';
import '../providers/saved_books_provider.dart';
import '../screens/book_details_screen.dart';

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
  bool _isLoading = false;

  Future<void> _navigateToDetails(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? resolvedOlid = widget.olid;

      // If the OLID is missing, fetch it in real-time
      if (resolvedOlid == null || resolvedOlid.isEmpty) {
        final savedBooksProvider = Provider.of<SavedBooksProvider>(context, listen: false);
        final book = savedBooksProvider.savedBooks.firstWhere(
          (b) => b.key == widget.bookKey,
          orElse: () => Book(
            title: widget.title,
            author: widget.author,
            key: widget.bookKey,
            coverId: widget.coverId,
            olid: null,
          ),
        );
        resolvedOlid = book.olid;
      }

      // Navigate to the BookDetailsScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookDetailsScreen(
            title: widget.title,
            author: widget.author,
            coverId: widget.coverId,
            olid: resolvedOlid,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load book details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      child: Stack(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                icon: Icon(
                  widget.isInSavedBooksScreen ? Icons.bookmark_remove : Icons.bookmark_add,
                ),
                onPressed: () async {
                  try {
                    final savedBooksProvider = Provider.of<SavedBooksProvider>(context, listen: false);
                    if (widget.isInSavedBooksScreen) {
                      await savedBooksProvider.removeBook(widget.bookKey);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Book removed successfully!')),
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
                        const SnackBar(content: Text('Book saved successfully!')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update book: $e')),
                    );
                  }
                },
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
