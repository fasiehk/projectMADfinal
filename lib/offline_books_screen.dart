import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'dart:io';
import 'pdf_viewer_screen.dart'; // Import the PDF Viewer Screen
import 'package:path_provider/path_provider.dart'; // Import path_provider for local storage
import 'package:http/http.dart' as http; // Import http for downloading files

class OfflineBooksScreen extends StatefulWidget {
  const OfflineBooksScreen({super.key});

  @override
  State<OfflineBooksScreen> createState() => _OfflineBooksScreenState();
}

class _OfflineBooksScreenState extends State<OfflineBooksScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // Initialize Firebase Storage
  List<Map<String, dynamic>> _offlineBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOfflineBooks();
  }

  Future<void> _fetchOfflineBooks() async {
    try {
      final snapshot = await _firestore.collection('offline_books').get();
      final books = snapshot.docs.map((doc) => doc.data()).toList();

      // Fetch download URLs for each book's PDF
      for (var book in books) {
        final pdfPath = book['pdfPath'] as String;
        final downloadUrl = await _storage.ref(pdfPath).getDownloadURL();
        // Append the access token to the URL
        final pdfUrlWithToken = '$downloadUrl?alt=media&token=117d3228-6a20-4ac3-abf7-6e7c78064c61';
        book['pdfUrl'] = pdfUrlWithToken; // Add the download URL with token to the book data
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

  Future<String> _downloadPdfLocally(String pdfUrl, String fileName) async {
    try {
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode == 200) {
        // Ensure the directory is available
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath; // Return the local file path
      } else {
        throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print("Error downloading PDF: $e");
      throw Exception('Error downloading PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Books'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _offlineBooks.length,
              itemBuilder: (context, index) {
                final book = _offlineBooks[index];
                return ListTile(
                  title: Text(book['title']),
                  subtitle: Text(book['author']),
                  trailing: const Icon(Icons.picture_as_pdf, color: Colors.deepPurple),
                  onTap: () async {
                    try {
                      final localPath = await _downloadPdfLocally(
                        book['pdfUrl'],
                        '${book['title']}.pdf',
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PDFViewerScreen(
                            pdfUrl: localPath, // Pass the local file path
                            title: book['title'],
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to open PDF: $e')),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
