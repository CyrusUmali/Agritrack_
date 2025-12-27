import 'package:flareline/pages/recommendation/suitability/widgets/alt_cards.dart';
import 'package:flareline/pages/recommendation/suitability/widgets/param_analysis.dart';
import 'package:flareline/pages/recommendation/suitability/widgets/result_header.dart';
import 'package:flareline/pages/recommendation/suitability/widgets/suggestions.dart';
import 'package:flutter/material.dart';
import 'package:flareline/services/lanugage_extension.dart';
 

class SuitabilityResults extends StatelessWidget {
  final Map<String, dynamic> suitabilityResult;
  final Function() onGetSuggestions;
  final bool isLoadingSuggestions;

  const SuitabilityResults({
    super.key,
    required this.suitabilityResult,
    required this.onGetSuggestions,
    required this.isLoadingSuggestions,
  });

  @override
  Widget build(BuildContext context) {
    final isSuitable = suitabilityResult['is_suitable'] as bool? ?? false;
    final parametersAnalysis =
        suitabilityResult['parameters_analysis'] as Map<String, dynamic>? ?? {};
    
    final deficientParams = parametersAnalysis.entries
        .where((e) => e.value['status'] != 'optimal')
        .toList();
    
    // Get confidence values (support both old and new API response format)
    final finalConfidence = suitabilityResult['final_confidence'] as double? ?? 
                            suitabilityResult['confidence'] as double? ?? 0.0;
    final paramConfidence = suitabilityResult['parameter_confidence'] as double? ?? finalConfidence;
    final mlConfidence = suitabilityResult['ml_confidence'] as Map<String, dynamic>?;
    
    // Get alternatives (if available)
    final alternatives = suitabilityResult['parsed_alternatives'] as List? ?? [];
    
    // Process suggestions
    final suggestions = _processSuggestions(suitabilityResult['suggestions']);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final padding = isSmallScreen ? 16.0 : 24.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎯 Main Result Header Card
            ResultHeaderCard(
              suitabilityResult: suitabilityResult,
              isSuitable: isSuitable,
              finalConfidence: finalConfidence,
              paramConfidence: paramConfidence,
              mlConfidence: mlConfidence,
              isSmallScreen: isSmallScreen,
              padding: padding,
            ),

            SizedBox(height: isSmallScreen ? 20 : 28),

            // 📊 Parameter Analysis Section
            ParameterAnalysisCard(
              parametersAnalysis: parametersAnalysis,
               parameterConfidence: paramConfidence,
              isSmallScreen: isSmallScreen,
              padding: padding,
            ),



               // 💡 Suggestions Section
            if (deficientParams.isNotEmpty) ...[
              SizedBox(height: isSmallScreen ? 20 : 28),
              SuggestionsCard(
                suggestions: suggestions,
                deficientParamsCount: deficientParams.length,
                isSmallScreen: isSmallScreen,
                padding: padding,
                onGetSuggestions: onGetSuggestions,
                isLoadingSuggestions: isLoadingSuggestions,
              ),
            ],

            // 🌱 Alternative Crops Section (if available)
            if (alternatives.isNotEmpty) ...[
              SizedBox(height: isSmallScreen ? 20 : 28),
              AlternativesCard(
                alternatives: alternatives,
                isSmallScreen: isSmallScreen,
                padding: padding,
                
              ),
            ],

         

            SizedBox(height: isSmallScreen ? 16 : 20),

            // 📝 Disclaimer
            DisclaimerWidget(
              disclaimer: suitabilityResult['disclaimer'],
              isSmallScreen: isSmallScreen,
              padding: padding,
            ),
          ],
        );
      },
    );
  }

  // Helper method to process suggestions
  List<String> _processSuggestions(dynamic suggestions) {
    if (suggestions == null) return [];
    if (suggestions is List) return suggestions.whereType<String>().toList();
    if (suggestions is String) return [suggestions];
    return [suggestions.toString()];
  }
}