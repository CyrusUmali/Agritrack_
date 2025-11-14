import 'package:flutter/material.dart';

class SectorHeader extends StatelessWidget {
  final Map<String, dynamic> sector;
  final bool isMobile;

  const SectorHeader({
    super.key,
    required this.sector,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = isMobile ? 80.0 : 120.0;
    final coverHeight = isMobile ? 160.0 : 240.0;

    // Get the image URL from sector data, default to null if not available
    final imgUrl = sector['imgUrl'] as String?;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: coverHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imgUrl != null && imgUrl.isNotEmpty
                  ? NetworkImage(imgUrl) // Use network image if URL exists
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
