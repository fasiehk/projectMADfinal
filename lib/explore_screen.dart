import 'package:flutter/material.dart';
import 'package:finalwe/services/book_service.dart';
import 'package:finalwe/widgets/book_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:finalwe/screens/book_details_screen.dart';
import 'package:finalwe/screens/science_fiction_screen.dart';
import 'package:finalwe/screens/romance_screen.dart';
import 'package:finalwe/screens/history_screen.dart';
import 'package:finalwe/screens/children_books_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Book> _books = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Science Fiction', 'image': 'assets/science_fiction.jpg', 'screen': const ScienceFictionScreen()},
    {'title': 'Romance', 'image': 'assets/romance.jpg', 'screen': const RomanceScreen()},
    {'title': 'History', 'image': 'assets/history.jpg', 'screen': const HistoryScreen()},
    {'title': "Children's Books", 'image': 'assets/children_books.jpg', 'screen': const ChildrenBooksScreen()},
  ];

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

  Future<Book?> _fetchBookDetails(String bookKey) async {
    final url = Uri.parse('https://openlibrary.org/works/$bookKey.json');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Book(
          title: data['title'] ?? 'Unknown Title',
          author: (data['authors'] != null && data['authors'].isNotEmpty)
              ? data['authors'][0]['name']
              : 'Unknown Author',
          key: bookKey,
          coverId: data['covers'] != null && data['covers'].isNotEmpty
              ? data['covers'][0]
              : null,
          olid: bookKey, // Use the book key as the OLID
        );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Books'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Categories Section
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => category['screen'],
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: AssetImage(category['image']!),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      child: Text(
                        category['title']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Search and Book List Section
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
                  return GestureDetector(
                    onTap: () async {
                      final bookDetails = await _fetchBookDetails(book.key);
                      if (bookDetails != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetailsScreen(
                              title: bookDetails.title,
                              author: bookDetails.author,
                              coverId: bookDetails.coverId,
                              olid: bookDetails.olid,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to load book details')),
                        );
                      }
                    },
                    child: BookCard(
                      title: book.title,
                      author: book.author,
                      coverId: book.coverId,
                      bookKey: book.key,
                      olid: book.olid,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
