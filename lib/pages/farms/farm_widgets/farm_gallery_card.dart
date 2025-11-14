import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';

class FarmGalleryCard extends StatelessWidget {
  final Map<String, dynamic> farm;

  const FarmGalleryCard({
    super.key,
    required this.farm,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Added padding here
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farm Gallery',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            // Gallery Column with 3 images
            Column(
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    height: 135, // Fixed height
                    width: double.infinity, // Full width
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 48,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            )
          ],
        ),
      ),
    );
  }
}
