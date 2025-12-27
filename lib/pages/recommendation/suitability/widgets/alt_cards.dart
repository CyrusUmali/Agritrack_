import 'package:flareline/pages/recommendation/suitability/widgets/suitabillity_helper.dart';
import 'package:flutter/material.dart';

class AlternativesCard extends StatelessWidget {
  final List alternatives;
  final bool isSmallScreen;
  final double padding;

  const AlternativesCard({
    super.key,
    required this.alternatives,
    required this.isSmallScreen,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.green[900]!.withOpacity(0.3)
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.compare_arrows,
                  color: isDark ? Colors.green[300] : Colors.green[600],
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Alternative Crops',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[200] : Colors.grey[800],
                      fontSize: isSmallScreen ? 18 : 20,
                    ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.green[900]!.withOpacity(0.3)
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.green[700]! : Colors.green[200]!,
                  ),
                ),
                child: Text(
                  '${alternatives.length}',
                  style: TextStyle(
                    color: isDark ? Colors.green[300] : Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: isSmallScreen ? 12 : 16),

        // Alternative crops in grid or horizontal layout
        if (isSmallScreen)
          _buildHorizontalAlternatives(context, alternatives, padding)
        else
          _buildGridAlternatives(context, alternatives, padding),
      ],
    );
  }

  Widget _buildHorizontalAlternatives(
    BuildContext context,
    List<dynamic> alternatives,
    double padding,
  ) {
    return SizedBox(
      height: 200.0, // Reduced height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: padding),
        itemCount: alternatives.length,
        itemBuilder: (context, index) {
          final alt = alternatives[index];
          return Container(
            width: 180, // Reduced width
            margin: EdgeInsets.only(
                right: index < alternatives.length - 1 ? 12 : 0),
            child: AlternativeCropCard(
              cropName: alt.crop,
              confidence: alt.confidence,
              reason: alt.reason,
              imageUrl: alt.imageUrl,
              isSmallScreen: true,
              index: index,
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridAlternatives(
    BuildContext context,
    List<dynamic> alternatives,
    double padding,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4, // More square aspect ratio
        ),
        itemCount: alternatives.length,
        itemBuilder: (context, index) {
          final alt = alternatives[index];
          return AlternativeCropCard(
            cropName: alt.crop,
            confidence: alt.confidence,
            reason: alt.reason,
            imageUrl: alt.imageUrl,
            isSmallScreen: false,
            index: index,
          );
        },
      ),
    );
  }
}

class AlternativeCropCard extends StatelessWidget {
  final String cropName;
  final double confidence;
  final String reason;
  final String? imageUrl;
  final bool isSmallScreen;
  final int index;

  const AlternativeCropCard({
    super.key,
    required this.cropName,
    required this.confidence,
    required this.reason,
    this.imageUrl,
    required this.isSmallScreen,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confidenceColor = SuitabilityHelpers.getConfidenceColor(confidence);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardTheme.color,
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Better space distribution
          children: [
            // Rank badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.green[900]!.withOpacity(0.3)
                    : Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#${index + 1}',
                style: TextStyle(
                  color: isDark ? Colors.green[300] : Colors.green[700],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Crop name and confidence
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cropName,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[200] : Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reason,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: confidenceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: confidenceColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Compact image
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.landscape,
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                                size: 24,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.landscape,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                            size: 24,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}