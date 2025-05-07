import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'pdf_viewer_screen.dart';

class OfflineBooksScreen extends StatefulWidget {
  const OfflineBooksScreen({super.key});

  @override
  State<OfflineBooksScreen> createState() => _OfflineBooksScreenState();
}

class _OfflineBooksScreenState extends State<OfflineBooksScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Map<String, dynamic>> _offlineBooks = [];
  bool _isLoading = true;
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _fetchOfflineBooks();
    _fetchProfilePicture(); // Fetch profile picture
  }

  Future<void> _fetchOfflineBooks() async {
    try {
      final snapshot = await _firestore.collection('offline_books').get();
      final books = snapshot.docs.map((doc) => doc.data()).toList();

      for (var book in books) {
        try {
          final pdfPath = book['pdfPath'] as String;
          final coverPath = book['coverPath'] as String;

          // Fetch URLs for PDF and cover image
          final pdfUrl = await _storage.ref(pdfPath).getDownloadURL();
          final coverUrl = await _storage.ref(coverPath).getDownloadURL();

          book['pdfUrl'] = pdfUrl;
          book['coverUrl'] = coverUrl;
        } catch (e) {
          print("Error fetching file for book '${book['title']}': $e");
          book['pdfUrl'] = null; // Mark as unavailable
          book['coverUrl'] = null; // Mark as unavailable
        }
      }

      setState(() {
        _offlineBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching offline books: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchProfilePicture() async {
    try {
      final userId = "unique_user_id"; // Replace with logic to get the current user's ID
      final profilePicturePath = 'profile_pictures/$userId.jpg';
      final url = await _storage.ref(profilePicturePath).getDownloadURL();
      setState(() {
        _profilePictureUrl = url;
      });
    } catch (e) {
      print("Error fetching profile picture: $e");
    }
  }

  Future<String> _downloadPdfLocally(String pdfUrl, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    // Check if the file already exists
    if (await file.exists()) {
      return filePath; // Return the existing file path
    }

    // Show a progress indicator while downloading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return filePath; // Return the local file path
      } else {
        throw Exception('Failed to download PDF');
      }
    } catch (e) {
      print("Error downloading PDF: $e");
      throw Exception('Error downloading PDF: $e');
    } finally {
      Navigator.pop(context); // Close the progress indicator
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Books'),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('User Name'), // Replace with actual user name
              accountEmail: const Text('user@example.com'), // Replace with actual user email
              currentAccountPicture: CircleAvatar(
                backgroundImage: _profilePictureUrl != null
                    ? NetworkImage(_profilePictureUrl!)
                    : const AssetImage('assets/default_profile.png') as ImageProvider,
                onBackgroundImageError: (_, __) => const Icon(Icons.person),
              ),
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Offline Books'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            // Add more menu items here
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Display two books per row
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.7, // Adjust the aspect ratio for book covers
              ),
              itemCount: _offlineBooks.length,
              itemBuilder: (context, index) {
                final book = _offlineBooks[index];
                final coverUrl = book['coverUrl'] ?? ''; // Default to empty string if null
                final title = book['title'] ?? 'Unknown Title'; // Default title
                final author = book['author'] ?? 'Unknown Author'; // Default author

                return GestureDetector(
                  onTap: book['pdfUrl'] != null
                      ? () async {
                          try {
                            final localPath = await _downloadPdfLocally(
                              book['pdfUrl'],
                              '$title.pdf',
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PDFViewerScreen(
                                  pdfUrl: localPath,
                                  title: title,
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to open PDF: $e')),
                            );
                          }
                        }
                      : null, // Disable tap if PDF is unavailable
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            child: coverUrl.isNotEmpty
                                ? Image.network(
                                    coverUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image, size: 50),
                                  )
                                : const Icon(Icons.broken_image, size: 50), // Fallback if coverUrl is empty
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                author,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
