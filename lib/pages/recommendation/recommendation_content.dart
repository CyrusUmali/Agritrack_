import 'package:flareline/pages/recommendation/ai_models_info_widget.dart';
import 'package:flareline/pages/recommendation/chatbot/chatbot_page.dart';
import 'package:flareline/pages/recommendation/requirement_page.dart';
import 'package:flareline/pages/recommendation/suitability/suitability_page.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'recommendation_inputs.dart';
import 'recommendation_results.dart';
import 'recommendation_model.dart';
import 'package:flareline/services/lanugage_extension.dart';

class RecommendationContent extends StatefulWidget {
  const RecommendationContent({super.key});

  @override
  RecommendationContentState createState() => RecommendationContentState();
}

class RecommendationContentState extends State<RecommendationContent> {
  final RecommendationModel model = RecommendationModel();
  final GlobalKey _navigationMenuKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isTablet = MediaQuery.of(context).size.width < 900;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 0 : 24,
        vertical: isMobile ? 8 : 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: isMobile ? double.infinity : 800),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Responsive Header
                _buildResponsiveHeader(isMobile, isTablet),

                const SizedBox(height: 24),

                // Model selection card
                _buildModelSelectionCard(),

                const SizedBox(height: 24),

                // Input parameters card
                _buildInputParametersCard(isMobile),

                // Results
                if (model.predictionResult != null &&
                    model.predictionResult!['recommendations'] != null &&
                    model.predictionResult!['recommendations'].isNotEmpty) ...[
                  const SizedBox(height: 24),
                  RecommendationResults(
                      predictionResult: model.predictionResult!),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveHeader(bool isMobile, bool isTablet) {
    // Navigation function
    void _navigateToRequirements() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RequirementPage(),
        ),
      );
    }

    void _showAiModelsInfo() {
      AiModelsInfoWidget.show(context: context);
    }
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;
    // For desktop view (when neither mobile nor tablet)
    if (!isMobile && !isTablet) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title Text on left
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.translate('Crop Recommendation'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                      // color: const Color.fromARGB(255, 1, 1, 1),
                    ),
              ),
              const SizedBox(height: 4),
              Tooltip(
                message: context.translate('Crop Suitability'),
                child: IconButton(
                  key: _navigationMenuKey,
                  icon: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..scale(-1.0, 1.0), // Flip horizontally (mirror effect)
                    child: const Icon(
                      Icons.keyboard_return,
                      size: 22,
                      color: Colors.grey,
                    ),
                  ),
                  onPressed: () {
                    // _showNavigationMenu();

                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //       builder: (context) => const SuitabilityPage()),
                    // );

                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const SuitabilityPage(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return child;
                        },
                        transitionDuration: Duration.zero,
                      ),
                    );
                  },
                  splashRadius: 16, // Smaller splash effect
                  padding: EdgeInsets.zero, // Remove extra padding
                ),
              )
            ],
          ),

          Row(
            children: [
              // AI Models Info Button (Question Mark)
              Tooltip(
                message: context.translate('Learn about AI Models'),
                child: InkWell(
                  onTap: _showAiModelsInfo,
                  borderRadius: BorderRadius.circular(50),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  child: Container(
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey[500]!,
                        width: 2,
                      ),
                      color: Theme.of(context).cardTheme.color,
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      size: 24,
                      // color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
           if (!isFarmer)
              // Requirements Button
              Tooltip(
                message: context.translate('View Requirements'),
                child: InkWell(
                  onTap: _navigateToRequirements,
                  borderRadius: BorderRadius.circular(50),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  child: Container(
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey[500]!,
                        width: 2,
                      ),
                      color: Colors.white,
                    ),
                    child: Icon(
                      Icons.menu_book_outlined,
                      size: 24,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.translate('Crop Recommendation'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 24 : 28,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Flipped Return Icon
                Tooltip(
                  message: context.translate('Crop Suitability'),
                  child: IconButton(
                    key: _navigationMenuKey,
                    icon: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..scale(-1.0, 1.0),
                      child: const Icon(
                        Icons.keyboard_return,
                        size: 22,
                        color: Colors.grey,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SuitabilityPage()),
                      );
                    },
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                  ),
                ),

                // Right side buttons for mobile
                Row(
                  children: [
                    // AI Models Info Button (Question Mark)
                    Tooltip(
                      message: context.translate('Learn about AI Models'),
                      child: InkWell(
                        onTap: _showAiModelsInfo,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 25,
                          height: 25,
                          padding: const EdgeInsets.all(0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey[500]!,
                              width: 1,
                            ),
                            color: Theme.of(context).cardTheme.color,
                          ),
                          child: Icon(
                            Icons.lightbulb_outline,
                            size: 15,
                            // color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                  if (!isFarmer)
                    // Requirements Button
                    Tooltip(
                      message: context.translate('View Requirements'),
                      child: InkWell(
                        onTap: _navigateToRequirements,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 25,
                          height: 25,
                          padding: const EdgeInsets.all(0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey[500]!,
                              width: 1,
                            ),
                            color: Colors.white,
                          ),
                          child: Icon(
                            Icons.menu_book_outlined,
                            size: 15,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModelSelectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.translate('Select Model'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: model.selectedModel,
              items: model.models.keys.map((String modelName) {
                return DropdownMenuItem<String>(
                  value: modelName,
                  child: Text(
                    modelName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  model.selectedModel = newValue!;
                  model.modelAccuracy =
                      'Accuracy: ${(model.models[newValue]!['accuracy']! * 100).toStringAsFixed(2)}%';
                });
              },
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Theme.of(context).cardTheme.surfaceTintColor ??
                          Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Theme.of(context).cardTheme.surfaceTintColor ??
                          Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue, width: 0.5),
                ),
                filled: true,
                fillColor:
                    Theme.of(context).cardTheme.color, // Background color here
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
              ),
              dropdownColor: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              elevation: 2,
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
              iconSize: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputParametersCard(bool isMobile) {
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Center(
            child: Text(
              context.translate('Enter Environmental Parameters'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 20 : 24,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          RecommendationInputs(
            model: model,
            isMobile: isMobile,
            onChanged: () => setState(() {}), // Add this callback
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                setState(() {
                  model.isLoading =
                      true; // Manually set loading state before prediction
                });

                await model.predictCrop();

                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  letterSpacing: 0.1,
                ),
                minimumSize: const Size(64, 48),
              ),
              child: model.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      context.translate('Predict'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ));
  }
}
