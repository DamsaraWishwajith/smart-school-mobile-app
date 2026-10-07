import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFViewerScreen extends StatelessWidget {
  const PDFViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final String url = args?['url'] ?? '';
    final String title = args?['title'] ?? 'PDF Viewer';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0077BE),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () {
              // Implementation for manual download if needed
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download started...')),
              );
            },
          ),
        ],
      ),
      body: url.isNotEmpty
          ? SfPdfViewer.network(
              url,
              onDocumentLoadFailed: (details) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to load PDF: ${details.description}')),
                );
              },
            )
          : const Center(
              child: Text('No PDF URL provided'),
            ),
    );
  }
}
