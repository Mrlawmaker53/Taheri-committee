import 'package:flutter/material.dart';

class MissionItem {
  final IconData icon;
  final String text;

  const MissionItem({
    required this.icon,
    required this.text,
  });
}

class MissionData {
  static const List<MissionItem> items = [
    MissionItem(
      icon: Icons.star,
      text: 'Serving visitors every Sunday with dedication and respect',
    ),
    MissionItem(
      icon: Icons.mosque,
      text:
          'Performing khidmat during Ashara Mubarak and the Urs Mubarak of Syedna Fakhruddin Shaheed (RA) with devotion and unity',
    ),
    MissionItem(
      icon: Icons.campaign,
      text:
          'Our team always strives to be among the first to answer the call of "labbaik ya dai allah" in the service of Moula',
    ),
    MissionItem(
      icon: Icons.people,
      text: 'Assisting guests and families during their visit',
    ),
    MissionItem(
      icon: Icons.cleaning_services,
      text: 'Maintaining cleanliness, comfort, and discipline around the Mazar',
    ),
    MissionItem(
      icon: Icons.handshake,
      text: 'Strengthening unity and community service through sincere khidmat',
    ),
  ];
}
