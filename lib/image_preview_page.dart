import 'package:flutter/material.dart';

class ImagePreviewPage extends StatelessWidget {
  final String imageUrl;

  const ImagePreviewPage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set background color for better contrast
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Close the preview screen
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true, // Allow panning
          scaleEnabled: true, // Allow pinch-to-zoom
          maxScale: 4.0, // Allow up to 4x zoom
          minScale: 1.0, // No downscaling below original size
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain, // Ensure the image retains its original size
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child; // Image loaded
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
