import 'package:flareline/pages/recommendation/suitability/widgets/suitabillity_helper.dart';
import 'package:flutter/material.dart';
import 'package:flareline/services/lanugage_extension.dart'; 

class ResultHeaderCard extends StatelessWidget {
  final Map<String, dynamic> suitabilityResult;
  final bool isSuitable;
  final double finalConfidence;
  final double paramConfidence;
  final Map<String, dynamic>? mlConfidence;
  final bool isSmallScreen;
  final double padding;

  const ResultHeaderCard({
    super.key,
    required this.suitabilityResult,
    required this.isSuitable,
    required this.finalConfidence,
    required this.paramConfidence,
    required this.mlConfidence,
    required this.isSmallScreen,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final mainColor = isSuitable ? Colors.green : Colors.orange;
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
            // Status Badge Row
            _buildStatusBadgeRow(context, mainColor, isDark),
            
            SizedBox(height: isSmallScreen ? 16 : 20),

            // Combined Confidence Display
            _buildCombinedConfidenceDisplay(context, mainColor, isDark),
            
            // ML Model Confidences (if multiple models used)
            if (mlConfidence != null && mlConfidence!.length > 1) ...[
              SizedBox(height: isSmallScreen ? 16 : 20),
              _buildMLConfidenceSection(context, isDark),
            ],

            SizedBox(height: isSmallScreen ? 16 : 20),

            // Models Used Section
            _buildModelsUsedSection(context, isDark),

            // Crop Image (if available)
            if (suitabilityResult['image_url'] != null) ...[
              SizedBox(height: isSmallScreen ? 16 : 20),
              _buildImageSection(context, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadgeRow(BuildContext context, Color mainColor, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: mainColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuitable ? Icons.verified : Icons.warning_amber_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                isSuitable
                    ? context.translate('SUITABLE')
                    : context.translate('NOT_SUITABLE'),
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
        if (!isSuitable) _buildWarningBadge(context, isDark),
      ],
    );
  }

  Widget _buildWarningBadge(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.orange[900]!.withOpacity(0.3) : Colors.orange[50],
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
            context.translate('Needs Attention'),
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

  Widget _buildCombinedConfidenceDisplay(BuildContext context, Color mainColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.analytics, color: mainColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confidence Breakdown',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 15 : 17,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Final confidence based on multiple factors',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Main progress bar with segments
          Column(
            children: [
              // Labels above the bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildConfidenceLabel('Parameters', paramConfidence, Colors.blue),
                  _buildConfidenceLabel('Final', finalConfidence, mainColor),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Combined progress bar
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Stack(
                  children: [
                    // Parameter confidence (left segment)
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: paramConfidence,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(5),
                              bottomLeft: const Radius.circular(5),
                              topRight: Radius.circular(paramConfidence >= 1.0 ? 5 : 0),
                              bottomRight: Radius.circular(paramConfidence >= 1.0 ? 5 : 0),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${(paramConfidence * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Final confidence (right segment, overlapping)
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: finalConfidence,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                mainColor.withOpacity(0.8),
                                mainColor,
                              ],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(5),
                              bottomLeft: const Radius.circular(5),
                              topRight: Radius.circular(finalConfidence >= 1.0 ? 5 : 0),
                              bottomRight: Radius.circular(finalConfidence >= 1.0 ? 5 : 0),
                            ),
                            border: Border.all(
                              color: Colors.white,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Percentage values below
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Parameter Match: ${(paramConfidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    'Final Confidence: ${(finalConfidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.bold,
                      color: mainColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Optional: Show ML confidence if available
          if (mlConfidence != null && mlConfidence!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              height: 1,
            ),
            const SizedBox(height: 12),
            Text(
              'ML Model Votes',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isSmallScreen ? 13 : 14,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            ...mlConfidence!.entries.map((entry) {
              final confidence = (entry.value as num).toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: confidence,
                          child: Container(
                            decoration: BoxDecoration(
                              color: SuitabilityHelpers.getConfidenceColor(confidence),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${(confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          fontWeight: FontWeight.bold,
                          color: SuitabilityHelpers.getConfidenceColor(confidence),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceLabel(String text, double confidence, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMLConfidenceSection(BuildContext context, bool isDark) {
    // This is now integrated into the combined display
    return const SizedBox.shrink();
  }

  Widget _buildModelsUsedSection(BuildContext context, bool isDark) {
    final models = suitabilityResult['model_used'] as List? ?? [];
    if (models.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.memory,
                color: isDark ? Colors.blue[300] : Colors.blue[600],
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                context.translate('AI Models Used'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 14 : 16,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: models.map((model) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blue[900]!.withOpacity(0.3)
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? Colors.blue[700]! : Colors.blue[100]!,
                  ),
                ),
                child: Text(
                  model.toString(),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: isDark ? Colors.blue[300] : Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context, bool isDark) {
    return Container(
      height: isSmallScreen ? 180 : 220,
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
        child: Image.network(
          suitabilityResult['image_url'],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              child: Icon(
                Icons.landscape,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                size: 48,
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
    );
  }
}