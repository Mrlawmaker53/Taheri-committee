class MissionImageItem {
  final String imagePath;
  final String title;
  final String description;

  const MissionImageItem({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

class MissionImageData {
  static const List<MissionImageItem> items = [
    MissionImageItem(
      imagePath: 'assets/images/mission1.jpg',
      title: 'Sunday Service',
      description: 'Serving visitors every Sunday with dedication and respect',
    ),
    MissionImageItem(
      imagePath: 'assets/images/mission2.jpg',
      title: 'Ashara Mubarak',
      description: 'Performing khidmat during Ashara Mubarak and the Urs Mubarak of Syedna Fakhruddin Shaheed (RA) with devotion and unity',
    ),
    MissionImageItem(
      imagePath: 'assets/images/mission3.jpg',
      title: 'Community Unity',
      description: 'Strengthening unity and community service through sincere khidmat',
    ),
  ];
}
