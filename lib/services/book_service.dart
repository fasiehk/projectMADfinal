import 'dart:convert';
import 'package:http/http.dart' as http;

class Book {
  final String title;
  final String author;
  final String key;
  final int? coverId;

  Book({
    required this.title,
    required this.author,
    required this.key,
    this.coverId,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'] ?? 'Unknown Title',
      author: (json['author_name'] != null && json['author_name'].isNotEmpty)
          ? json['author_name'][0]
          : 'Unknown Author',
      key: json['key'] ?? '',
      coverId: json['cover_i'],
    );
  }
}

Future<List<Book>> fetchBooks(String query) async {
  final url = Uri.parse('https://openlibrary.org/search.json?q=$query');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final List books = data['docs'] ?? [];
    return books.map((book) => Book.fromJson(book)).toList();
  } else {
    throw Exception('Failed to fetch books');
  }
}
