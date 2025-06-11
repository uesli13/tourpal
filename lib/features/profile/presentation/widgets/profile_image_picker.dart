import 'package:flutter/material.dart';
import 'dart:io';

class ProfileImagePicker extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;
  final VoidCallback onTap;
  final double radius;

  const ProfileImagePicker({
    super.key,
    this.imageFile,
    this.imageUrl,
    required this.onTap,
    this.radius = 60,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundImage: _getImageProvider(),
            child: _getImageProvider() == null
                ? Icon(Icons.person, size: radius)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: onTap,
                iconSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getImageProvider() {
    if (imageFile != null) {
      return FileImage(imageFile!);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      return NetworkImage(imageUrl!);
    }
    return null;
  }
}