import 'package:flareline/core/models/assocs_model.dart';
import 'package:flutter/material.dart';

class AssociationHeader extends StatelessWidget {
  final Association association;
  final bool isMobile;

  const AssociationHeader({
    super.key,
    required this.association,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = isMobile ? 80.0 : 120.0;
    final coverHeight = isMobile ? 160.0 : 240.0;

    // Get the image URL from sector data, default to null if not available
    final imgUrl = association.imageUrl as String?;

 

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: coverHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imgUrl != null && imgUrl.isNotEmpty
                  ? NetworkImage('https://res.cloudinary.com/dk41ykxsq/image/upload/v1750587301/hvc_huuaeg.jpg') // Use network image if URL exists
                  : const AssetImage('assets/cover/cover-01.png')
                      as ImageProvider, // Fallback to asset
              fit: BoxFit.cover,
            ),
            color: theme.colorScheme.primaryContainer,
          ),
        ),
        Positioned(
          bottom: -size / 2,
          left: isMobile ? 16 : 24,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.surface,
                width: 4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
