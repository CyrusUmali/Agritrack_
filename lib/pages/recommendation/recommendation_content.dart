import 'package:flareline/pages/recommendation/ai_models_info_widget.dart';
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
  void dispose() {
    model.dispose();
    super.dispose();
  }

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

                // Input parameters card
                _buildInputParametersCard(isMobile),

                // Error Message Display
                if (model.hasError && model.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorCard(),
                ],

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

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade700,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.translate('Error'),
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model.errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.red.shade700),
              onPressed: () {
                setState(() {
                  model.clearError();
                });
              },
              tooltip: context.translate('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }





  Widget _buildResponsiveHeader(bool isMobile, bool isTablet) {



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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.translate('Crop Recommendation'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
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
                      ..scale(-1.0, 1.0),
                    child: const Icon(
                      Icons.keyboard_return,
                      size: 22,
                      color: Colors.grey,
                    ),
                  ),
                  onPressed: () => _navigateToSuitability(),
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                ),
              )
            ],
          ),

          Row(
            children: [
              // AI Models Info Button (Question Mark)
              Tooltip(
                message: context.translate('Learn about the Model'),
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
                      color: Colors.white,
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      size: 24,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
          //  if (isFarmer)
          //     // Requirements Button
          //     Tooltip(
          //       message: context.translate('View Requirements'),
          //       child: InkWell(
          //         onTap: _navigateToRequirements,
          //         borderRadius: BorderRadius.circular(50),
          //         hoverColor: Colors.grey.withOpacity(0.1),
          //         child: Container(
          //           width: 50,
          //           height: 50,
          //           padding: const EdgeInsets.all(8),
          //           decoration: BoxDecoration(
          //             shape: BoxShape.circle,
          //             border: Border.all(
          //               color: Colors.grey[500]!,
          //               width: 2,
          //             ),
          //             color: Colors.white,
          //           ),
          //           child: Icon(
          //             Icons.menu_book_outlined,
          //             size: 24,
          //             color: Colors.grey[700],
          //           ),
          //         ),
          //       ),
          //     ),
        
        
        
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
                    onPressed: () => _navigateToSuitability(),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                  ),
                ),

                // Right side buttons for mobile
                Row(
                  children: [
                    // AI Models Info Button (Question Mark)
                    Tooltip(
                      message: context.translate('Learn about the Model'),
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
                            color: Colors.white,
                          ),
                          child: Icon(
                            Icons.lightbulb_outline,
                            size: 15,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                  // if (isFarmer)
                  //   // Requirements Button
                  //   Tooltip(
                  //     message: context.translate('View Requirements'),
                  //     child: InkWell(
                  //       onTap: _navigateToRequirements,
                  //       borderRadius: BorderRadius.circular(50),
                  //       child: Container(
                  //         width: 25,
                  //         height: 25,
                  //         padding: const EdgeInsets.all(0),
                  //         decoration: BoxDecoration(
                  //           shape: BoxShape.circle,
                  //           border: Border.all(
                  //             color: Colors.grey[500]!,
                  //             width: 1,
                  //           ),
                  //           color: Colors.white,
                  //         ),
                  //         child: Icon(
                  //           Icons.menu_book_outlined,
                  //           size: 15,
                  //           color: Colors.grey[700],
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                 
                 
                 
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToSuitability() {
    try {
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
    } catch (e) {
      debugPrint('Navigation error: $e');
   
    }
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
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: model.isLoading ? null : () => _handlePrediction(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.blue.shade300,
                  disabledForegroundColor: Colors.white70,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePrediction() async {
    // Clear previous errors
    model.clearError();

    try {
      // Show loading state immediately
      setState(() {});

      // Perform prediction with context for error toasts
      await model.predictCrop(context: context);

      // Update UI with results
      setState(() {});

  
    } catch (e) {
      // This catch block handles any errors not caught by the model
      debugPrint('Unexpected error in _handlePrediction: $e');
       
    } finally {
      // Ensure UI is updated even if there's an error
      if (mounted) {
        setState(() {});
      }
    }
  }
}