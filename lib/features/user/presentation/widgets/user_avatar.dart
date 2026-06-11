import 'dart:io';
import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String? displayName;
  final String? photoUrl;
  final File? imageFile;
  final double radius;
  final VoidCallback? onEdit;

  const UserAvatar({
    super.key,
    this.displayName,
    this.photoUrl,
    this.imageFile,
    this.radius = 20,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;

    if (imageFile != null) {
      imageProvider = FileImage(imageFile!);
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(photoUrl!);
    }

    Widget avatar;
    if (imageProvider != null) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      );
    } else {
      final String initials = _getInitials(displayName);
      final Color backgroundColor = _getColorFromName(displayName);

      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Text(
          initials,
          style: TextStyle(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.8,
          ),
        ),
      );
    }

    if (onEdit == null) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.deepTurquoise,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final List<String> parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color _getColorFromName(String? name) {
    if (name == null || name.isEmpty) return AppColors.vibrantTeal;
    final int hash = name.hashCode;
    final int index = hash.abs() % AppColors.selectionColors.length;
    return AppColors.selectionColors[index];
  }
}
