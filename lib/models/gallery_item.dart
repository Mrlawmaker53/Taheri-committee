class GalleryItem {
  final String? imageUrl;
  final String title;
  final String description;
  final String? assetPath; // For local assets

  const GalleryItem({
    required this.title,
    required this.description,
    this.imageUrl,
    this.assetPath,
  });
}

class GalleryData {
  static const List<GalleryItem> items = [
    GalleryItem(
      title: 'Gallery Image 1',
      description: 'Beautiful view of Mazar-e-Fakhri during prayer time',
      assetPath: 'assets/images/gallery1.jpg',
    ),
    GalleryItem(
      title: 'Gallery Image 2',
      description: 'Community members gathered for Sunday service',
      assetPath: 'assets/images/gallery2.jpg',
    ),
  ];
}
