import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class BookDetailsScreen extends StatefulWidget {
  final String title;
  final String author;
  final int? coverId;
  final String? olid;

  const BookDetailsScreen({
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

  Future<void> _fetchBookDetails(String olid) async {
    final url = Uri.parse('https://openlibrary.org/books/$olid.json');
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

    final bookUrl = Uri.parse('https://openlibrary.org/books/${widget.olid}');
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
    final bookUrl = widget.olid != null
        ? 'https://openlibrary.org/books/${widget.olid}'
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        backgroundColor: Colors.deepPurple,
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
