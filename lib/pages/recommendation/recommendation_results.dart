import 'package:flareline/pages/products/product_profile.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';

import 'package:flareline/services/lanugage_extension.dart';

class RecommendationResults extends StatelessWidget {
  final Map<String, dynamic> predictionResult;

  const RecommendationResults({
    super.key,
    required this.predictionResult,
  });

  @override
  Widget build(BuildContext context) {
    final recommendations = predictionResult['recommendations'] as List;
    final primaryRecommendation = recommendations[0];
    final secondaryRecommendations =
        recommendations.length > 1 ? recommendations.sublist(1) : <dynamic>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final padding = isSmallScreen ? 16.0 : 24.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 Primary Recommended Crop with enhanced design
            _buildPrimaryRecommendationCard(
              context,
              primaryRecommendation,
              isSmallScreen,
              padding,
            ),

            SizedBox(height: isSmallScreen ? 20 : 28),

            // 🔄 Alternative Crops with improved layout
            if (secondaryRecommendations.isNotEmpty)
              _buildAlternativeCropsSection(
                context,
                secondaryRecommendations,
                isSmallScreen,
                padding,
              ),

            SizedBox(height: isSmallScreen ? 16 : 20),

            // 📊 Enhanced Additional Information
            _buildAdditionalInfoCard(context, isSmallScreen, padding),
          ],
        );
      },
    );
  }

  Widget _buildPrimaryRecommendationCard(
    BuildContext context,
    dynamic recommendation,
    bool isSmallScreen,
    double padding,
  ) {
    final hasWarning = recommendation['warning'] == 'low_confidence';
    final confidence = recommendation['confidence'] as double;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.eco,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.translate('RECOMMENDED'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (hasWarning) _buildWarningBadge(context, isSmallScreen),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 16 : 20),

                // Crop name and confidence with enhanced styling
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        recommendation['crop'].toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 28 : 36,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.green[400] : Colors.green[800],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(confidence, isDark)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getConfidenceColor(confidence, isDark),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${(confidence * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: _getConfidenceColor(confidence, isDark),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 16 : 20),

                // Enhanced image container
                _buildImageContainer(
                  recommendation,
                  true, // isPrimary
                  isSmallScreen,
                  isDark,
                ),

                SizedBox(height: isSmallScreen ? 16 : 20),

                // Enhanced model votes section
                _buildModelVotesSection(
                  context,
                  recommendation,
                  isSmallScreen,
                  true, // isPrimary
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeCropsSection(
    BuildContext context,
    List<dynamic> alternatives,
    bool isSmallScreen,
    double padding,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blue[900]!.withOpacity(0.3)
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.compare_arrows,
                  color: isDark ? Colors.blue[300] : Colors.blue[600],
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                context.translate('Alternative Options'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[200] : Colors.grey[800],
                      fontSize: isSmallScreen ? 18 : 20,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
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
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: padding),
        itemCount: alternatives.length,
        itemBuilder: (context, index) {
          return Container(
            width: 220,
            margin: EdgeInsets.only(
                right: index < alternatives.length - 1 ? 16 : 0),
            child: _buildAlternativeCard(
              context,
              alternatives[index],
              true,
              index,
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
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: alternatives.length,
        itemBuilder: (context, index) {
          return _buildAlternativeCard(
              context, alternatives[index], false, index);
        },
      ),
    );
  }

  Widget _buildAlternativeCard(
    BuildContext context,
    dynamic recommendation,
    bool isSmallScreen,
    int index,
  ) {
    final hasWarning = recommendation['warning'] == 'low_confidence';
    final confidence = recommendation['confidence'] as double;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rank badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.blue[900]!.withOpacity(0.3)
                        : Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#${index + 2}',
                    style: TextStyle(
                      color: isDark ? Colors.blue[300] : Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                if (hasWarning) ...[
                  const SizedBox(height: 8),
                  _buildWarningBadge(context, true),
                ],

                const SizedBox(height: 12),

                // Crop name and confidence
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation['crop'].toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.blue[300] : Colors.blue[800],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getConfidenceColor(confidence, isDark)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(confidence * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getConfidenceColor(confidence, isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Compact image
                _buildImageContainer(
                  recommendation,
                  false, // isPrimary
                  isSmallScreen,
                  isDark,
                ),

                const SizedBox(height: 12),

                // Compact model votes
                _buildModelVotesSection(
                  context,
                  recommendation,
                  isSmallScreen,
                  false, // isPrimary
                ),
              ],
            ),
          ),

          // Floating detail button
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: isDark ? Colors.blue[300] : Colors.blue[600],
                  size: 18,
                ),
                tooltip: context.translate('View Details'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductProfile(product: recommendation),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContainer(
    dynamic recommendation,
    bool isPrimary,
    bool isSmallScreen,
    bool isDark,
  ) {
    final height =
        isPrimary ? (isSmallScreen ? 180 : 220) : (isSmallScreen ? 100 : 120);

    return Container(
      height: height.toDouble(),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              child: Image.network(
                recommendation['image_url'] ??
                    'https://via.placeholder.com/400',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: Icon(
                      Icons.image_not_supported,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                      size: isPrimary ? 48 : 32,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.green[600],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Gradient overlay for better text readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelVotesSection(
    BuildContext context,
    dynamic recommendation,
    bool isSmallScreen,
    bool isPrimary,
  ) {
    final models = recommendation['supporting_models'] as List;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.how_to_vote,
                size: isSmallScreen ? 14 : 16,
                color: isPrimary
                    ? (isDark ? Colors.green[400] : Colors.green[600])
                    : (isDark ? Colors.blue[400] : Colors.blue[600]),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.translate('Model Consensus'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                fontSize: isSmallScreen ? 14 : 15,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 8 : 10),

        // Enhanced model votes display
        ...List.generate(
          models.length,
          (index) {
            final model = models[index];
            final probability = model['probability'] as double;

            return Container(
              margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      model['model'],
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Probability bar
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: probability,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(probability, isDark),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(probability * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                      fontSize: isSmallScreen ? 12 : 13,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoCard(
    BuildContext context,
    bool isSmallScreen,
    double padding,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.amber[900]!.withOpacity(0.3)
                        : Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info,
                    size: isSmallScreen ? 16 : 18,
                    color: isDark ? Colors.amber[300] : Colors.amber[700],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.translate('Analysis Summary'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 16 : 18,
                        color: isDark ? Colors.grey[200] : Colors.grey[800],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    context,
                    context.translate('Crops Analyzed'),
                    predictionResult['total_crops_considered'].toString(),
                    Icons.analytics,
                    isSmallScreen: isSmallScreen,
                  ),
                  if (predictionResult['confidence_threshold'] != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      context.translate('Confidence Threshold'),
                      '${(predictionResult['confidence_threshold'] * 100).toStringAsFixed(0)}%',
                      Icons.speed,
                      isSmallScreen: isSmallScreen,
                    ),
                  ],
                ],
              ),
            ),
            if (predictionResult['note'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blue[900]!.withOpacity(0.3)
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.blue[700]! : Colors.blue[200]!,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: isDark ? Colors.blue[300] : Colors.blue[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        predictionResult['note'],
                        style: TextStyle(
                          color: isDark ? Colors.blue[200] : Colors.blue[800],
                          fontSize: isSmallScreen ? 14 : 15,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    required bool isSmallScreen,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          size: isSmallScreen ? 16 : 18,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: isSmallScreen ? 14 : 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.grey[200] : Colors.grey[800],
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 14 : 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningBadge(BuildContext context, bool isSmallScreen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.orange[900]!.withOpacity(0.3) : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.orange[700]! : Colors.orange[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: isDark ? Colors.orange[300] : Colors.orange[700],
          ),
          const SizedBox(width: 4),
          Text(
            context.translate('Low Confidence'),
            style: TextStyle(
              color: isDark ? Colors.orange[300] : Colors.orange[700],
              fontSize: isSmallScreen ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence, bool isDark) {
    if (confidence >= 0.8) {
      return isDark ? Colors.green[400]! : Colors.green[600]!;
    }
    if (confidence >= 0.6) {
      return isDark ? Colors.orange[400]! : Colors.orange[600]!;
    }
    return isDark ? Colors.red[400]! : Colors.red[600]!;
  }
}
