import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/book_service.dart';
import '../providers/saved_books_provider.dart';

class BookCard extends StatelessWidget {
  final String title;
  final String author;
  final int? coverId;
  final String bookKey;
  final bool isInSavedBooksScreen; // Add a flag to differentiate screens

  const BookCard({
    super.key,
    required this.title,
    required this.author,
    this.coverId,
    required this.bookKey,
    this.isInSavedBooksScreen = false, // Default to false for ExploreScreen
  });

  @override
  Widget build(BuildContext context) {
    final savedBooksProvider = Provider.of<SavedBooksProvider>(context);

    final isSaved = savedBooksProvider.savedBooks.any((book) => book.key == bookKey);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: coverId != null
            ? Image.network(
                'https://covers.openlibrary.org/b/id/$coverId-M.jpg',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.book, size: 50),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(author),
        trailing: IconButton(
          icon: Icon(isSaved ? Icons.bookmark_remove : Icons.bookmark_add),
          onPressed: () async {
            try {
              if (isInSavedBooksScreen) {
                // Directly remove the book if in SavedBooksScreen
                await savedBooksProvider.removeBook(bookKey);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Book removed successfully!')),
                );
              } else if (isSaved) {
                // Show error message if the book is already saved
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Book already exists in saved books!')),
                );
              } else {
                // Save the book
                final sanitizedKey = bookKey.split('/').last;
                final book = Book(
                  title: title,
                  author: author,
                  key: sanitizedKey, // Use sanitized key
                  coverId: coverId,
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
    );
  }
}
