import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/saved_books_provider.dart';
import '../services/book_service.dart';

class BookDetailsScreen extends StatefulWidget {
  final String title;
  String author;
  final int? coverId;
  final String? olid;

   BookDetailsScreen({
    super.key,
    required this.title,
    required this.author,
    this.coverId,
    this.olid,
  });

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  bool _isLoading = true;
  String? _description;
  List<String>? _subjects;
  String? _publishers;

  @override
  void initState() {
    super.initState();
    if (widget.olid != null) {
      _fetchBookDetails(widget.olid!);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBookDetails(String olidOrKey) async {
    // Determine if the ID is for a book or a work
    final isWork = olidOrKey.startsWith('/works/');
    final sanitizedId = isWork
        ? olidOrKey.replaceFirst('/works/', '')
        : olidOrKey.replaceFirst('/books/', '');

    final url = Uri.parse(
        'https://openlibrary.org/${isWork ? 'works' : 'books'}/$sanitizedId.json'); // Correct URL structure
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _description = data['description'] is String
              ? data['description']
              : data['description']?['value'];
          _subjects = (data['subjects'] as List<dynamic>?)
              ?.map((subject) => subject.toString())
              .toList();
          _publishers = (data['publishers'] as List<dynamic>?)
              ?.map((publisher) => publisher.toString())
              .join(', ');

          // Parse authors correctly
          if (data['authors'] != null && data['authors'] is List) {
            final authors = data['authors'] as List;
            widget.author = authors.isNotEmpty
                ? authors.map((author) {
                    if (author is Map && author.containsKey('name')) {
                      return author['name'];
                    }
                    return 'Unknown Author';
                  }).join(', ')
                : 'Unknown Author';
          } else {
            widget.author = 'Unknown Author';
          }
        });
      } else {
        print("Failed to fetch book details: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching book details: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchBookUrl() async {
    if (widget.olid == null || widget.olid!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No URL available for this book')),
      );
      return;
    }

    // Determine if the ID is for a book or a work
    final isWork = widget.olid!.startsWith('/works/');
    final sanitizedId = isWork
        ? widget.olid!.replaceFirst('/works/', '')
        : widget.olid!.replaceFirst('/books/', '');

    final bookUrl = Uri.parse(
        'https://openlibrary.org/${isWork ? 'works' : 'books'}/$sanitizedId'); // Correct URL structure
    print("Attempting to launch URL: $bookUrl");

    try {
      if (await canLaunchUrl(bookUrl)) {
        await launchUrl(bookUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $bookUrl';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Could not open the book URL: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedBooksProvider = Provider.of<SavedBooksProvider>(context);
    final isSaved = savedBooksProvider.savedBooks.any((book) => book.olid == widget.olid);

    final isWork = widget.olid != null && widget.olid!.startsWith('/works/');
    final sanitizedId = isWork
        ? widget.olid!.replaceFirst('/works/', '')
        : widget.olid!.replaceFirst('/books/', '');
    final bookUrl = widget.olid != null
        ? 'https://openlibrary.org/${isWork ? 'works' : 'books'}/$sanitizedId'
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(isSaved ? Icons.bookmark_remove : Icons.bookmark_add),
            onPressed: () async {
              if (isSaved) {
                await savedBooksProvider.removeBook(widget.olid!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Book removed from saved list')),
                );
              } else {
                final book = Book(
                  title: widget.title,
                  author: widget.author,
                  key: widget.olid!,
                  coverId: widget.coverId,
                  olid: widget.olid,
                );
                await savedBooksProvider.saveBook(book);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Book saved successfully')),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView( // Make the screen scrollable
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ElevatedButton(
                        onPressed: _launchBookUrl,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        ),
                        child: const Text(
                          'Read Book',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    if (bookUrl != null)
                      Center(
                        child: TextButton(
                          onPressed: () async {
                            final uri = Uri.parse(bookUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open the book URL')),
                              );
                            }
                          },
                          child: Text(
                            bookUrl,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (widget.coverId != null)
                      Center(
                        child: Image.network(
                          'https://covers.openlibrary.org/b/id/${widget.coverId}-L.jpg',
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      widget.title,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Author: ${widget.author}',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    if (_description != null)
                      Text(
                        'Description:\n$_description',
                        style: const TextStyle(fontSize: 16),
                      ),
                    const SizedBox(height: 20),
                    if (_subjects != null && _subjects!.isNotEmpty)
                      Text(
                        'Subjects: ${_subjects!.join(', ')}',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    const SizedBox(height: 20),
                    if (_publishers != null)
                      Text(
                        'Publishers: $_publishers',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
