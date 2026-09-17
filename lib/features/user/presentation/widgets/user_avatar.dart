import 'package:funances/core/files/picked_document.dart';
import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_spacing.dart';

class UserAvatar extends StatelessWidget {
  final String? displayName;
  final String? photoUrl;
  final PickedDocument? imageFile;
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
      // MemoryImage e não FileImage: o recorte chega em bytes, que é o
      // que a web tem, e evita uma segunda leitura do disco fora dela.
      imageProvider = MemoryImage(imageFile!.bytes);
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
          // O tamanho das iniciais é proporcional ao raio do avatar (que vai
          // de 12 num chip a 50 no perfil), então aqui o `fontSize` é dado de
          // layout e não um degrau da escala.
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.inkInverse,
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
              padding: AppSpacing.allXxs,
              decoration: const BoxDecoration(
                color: AppColors.surfaceDeep,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: AppColors.inkInverse,
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
    if (name == null || name.isEmpty) return AppColors.tealInk;
    final int hash = name.hashCode;
    final int index = hash.abs() % AppColors.selectionColors.length;
    return AppColors.selectionColors[index];
  }
}
