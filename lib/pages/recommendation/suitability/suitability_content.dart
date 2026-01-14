import 'package:flareline/pages/recommendation/ai_models_info_widget.dart'; 
import 'package:flareline/pages/recommendation/recommendation_page.dart';
import 'package:flareline/pages/recommendation/requirement_page.dart'; 
import 'package:flareline/pages/recommendation/suitability/suitabilty_model.dart';
import 'package:flareline/pages/recommendation/suitability/widgets/result_guide_content.dart';
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flareline/providers/language_provider.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'suitability_inputs.dart';
import 'suitability_results.dart'; 
import 'package:flareline/services/lanugage_extension.dart';

class SuitabilityContent extends StatefulWidget {
  const SuitabilityContent({super.key});

  @override
  SuitabilityContentState createState() => SuitabilityContentState();
}

class SuitabilityContentState extends State<SuitabilityContent> {
  final GlobalKey _navigationMenuKey = GlobalKey();
  SuitabilityModel? model;

  final List<String> availableCrops = [
    "Ampalaya",
    "Avocado",
    "Banana",
    "Bamboo",
    "Black Pepper",
    "Cacao",
    "Calamansi",
    "Cassava",
    "Coconut",
    "Coffee",
    "Eggplant",
    "Forage Grass",
    "Gabi",
    "Ginger",
    "Ipil Ipil",
    "Jackfruit",
    "Katuray",
    "Kulo",
    "Lanzones",
    "Lipote",
    "Maize",
    "Mango",
    "Orchid",
    "Papaya",
    "Pechay",
    "Pineapple",
    "Rambutan",
    "Rice",
    "Sili Labuyo",
    "Squash",
    "String Bean",
    "Sweet Potato",
    "Sweet Sorghum",
    "Ube",
    "Upo",
  ];

  void _navigateToRequirements() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RequirementPage(),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    try {
      if (model == null) {
        final languageProvider =
            Provider.of<LanguageProvider>(context, listen: false);
        model = SuitabilityModel(languageProvider: languageProvider);
        model!.addListener(_onModelChanged);
      }
    } catch (e) {
      debugPrint('Error initializing model: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.translate('Failed to initialize. Please restart.')),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    model?.removeListener(_onModelChanged);
    model?.dispose();
    super.dispose();
  }

  void _onModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        if (model == null) {
          return const Center(child: CircularProgressIndicator());
        }

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
                    _buildResponsiveHeader(isMobile, isTablet),
                    const SizedBox(height: 24),
                    _buildCropSelectionDropdown(),
                    const SizedBox(height: 24),
                    _buildInputParametersCard(isMobile),
                    
                    // Error Display
                    if (model!.hasError && model!.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorCard(),
                    ],
                    
                    // Loading Indicator
                    if (model!.isLoading) ...[
                      const SizedBox(height: 24),
                      const Center(child: CircularProgressIndicator()),
                    ],
                    
                    // Results
                    if (model!.suitabilityResult != null &&
                        model!.suitabilityResult!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      SuitabilityResults(
                        suitabilityResult: model!.suitabilityResult!,
                        onGetSuggestions: () => _handleGetSuggestions(),
                        isLoadingSuggestions: model!.isStreamingSuggestions,
                      )
                    ]
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
                    model!.errorMessage!,
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
                  model!.clearError();
                });
              },
              tooltip: context.translate('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGetSuggestions() async {
    try {
      if (model!.suitabilityResult == null) {
        throw Exception('No suitability results available');
      }

      final paramAnalysis = model!.suitabilityResult!['parameters_analysis'];
      if (paramAnalysis == null || paramAnalysis is! Map) {
        throw Exception('Parameter analysis not available');
      }

      final deficientParams = paramAnalysis.entries
          .where((e) => e.value['status'] != 'optimal')
          .map((e) => e.key.toString())
          .toList();

      if (deficientParams.isEmpty) {
        ToastHelper.showErrorToast(
          context.translate('No deficient parameters to improve'),
          context,
        );
        return;
      }

      await model!.getSuggestionsStream(deficientParams);
      
    } catch (e) {
      debugPrint('Error getting suggestions: $e');
      if (mounted) {
        ToastHelper.showErrorToast(
          context.translate('Failed to get suggestions. Please try again.'),
          context,
        );
      }
    }
  }

  Widget _buildCropSelectionDropdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.translate('Select Crop'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return availableCrops;
                }
                return availableCrops.where((String option) {
                  return option
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                try {
                  setState(() {
                    model!.selectedCrop = selection;
                    model!.suitabilityResult = null;
                    model!.clearError();
                  });
                } catch (e) {
                  debugPrint('Error selecting crop: $e');
                }
              },
              fieldViewBuilder: (BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted) {
                if (model!.selectedCrop != null &&
                    textEditingController.text.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (textEditingController.text.isEmpty) {
                      textEditingController.text = model!.selectedCrop!;
                    }
                  });
                }

                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
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
                      borderSide: const BorderSide(color: Colors.blue, width: 1),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardTheme.color,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    hintText: context.translate('Type to search crops...'),
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    suffixIcon: model!.selectedCrop != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              try {
                                setState(() {
                                  model!.selectedCrop = null;
                                  model!.suitabilityResult = null;
                                  model!.clearError();
                                  textEditingController.clear();
                                });
                              } catch (e) {
                                debugPrint('Error clearing selection: $e');
                              }
                            },
                          )
                        : null,
                  ),
                );
              },
              optionsViewBuilder: (BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 64,
                      constraints: const BoxConstraints(maxWidth: 770),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return InkWell(
                              onTap: () {
                                onSelected(option);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardTheme.color,
                                ),
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
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
            Text(
              context.translate('Enter Environmental Parameters'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 20 : 24,
                  ),
            ),
            const SizedBox(height: 16),
            SuitabilityInputs(
              model: model!,
              isMobile: isMobile,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (model!.selectedCrop == null || model!.isLoading)
                    ? null
                    : () => _handleCheckSuitability(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: model!.selectedCrop == null 
                      ? Colors.grey 
                      : Colors.blue,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: model!.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        context.translate('Check Suitability'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            if (model!.suitabilityResult != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  try {
                    setState(() {
                      model!.suitabilityResult = null;
                      model!.clearError();
                    });
                  } catch (e) {
                    debugPrint('Error resetting results: $e');
                  }
                },
                child: Text(context.translate('Check Another Configuration')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleCheckSuitability() async {
    // Clear previous errors
    model!.clearError();

    try {
      setState(() {});

      await model!.checkSuitability();

 

      setState(() {});

    } catch (e) {
      debugPrint('Error in _handleCheckSuitability: $e');
      
      if (mounted) {
        ToastHelper.showErrorToast(
          context.translate('An error occurred. Please try again.'),
          context,
        );
      }
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Widget _buildResponsiveHeader(bool isMobile, bool isTablet) {
    void _showAiModelsInfo() {
      AiModelsInfoWidget.show(context: context);
    } final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;
    if (!isMobile && !isTablet) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.translate('Crop Suitability'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                    ),
              ),
              const SizedBox(height: 4),
              Tooltip(
                message: context.translate('Crop Recommendation'),
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
                  onPressed: () => _navigateToRecommendation(),
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                ),
              ),
         
         
            ],
          ),

          // Right side buttons
          Row(
            children: [
              // // AI Models Info Button (Question Mark)
              // Tooltip(
              //   message: context.translate('How to read your result'),
              //   child: InkWell(
              //     onTap: () => ResultGuideDialog.show(context),
              //     borderRadius: BorderRadius.circular(50),
              //     hoverColor: Colors.grey.withOpacity(0.1),
              //     child: Container(
              //       width: 50,
              //       height: 50,
              //       padding: const EdgeInsets.all(8),
              //       decoration: BoxDecoration(
              //         shape: BoxShape.circle,
              //         border: Border.all(
              //           color: Colors.grey[500]!,
              //           width: 2,
              //         ),
              //         color: Colors.white,
              //       ),
              //       child: Icon(
              //         Icons.lightbulb_outline,
              //         size: 24,
              //         color: Colors.grey[700],
              //       ),
              //     ),
              //   ),
              // ),
              // const SizedBox(width: 12),
if(isFarmer) 
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
              context.translate('Crop Suitability'),
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
                  message: context.translate('Crop Recommendation'),
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
                    onPressed: () => _navigateToRecommendation(),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                  ),
                ),
                Row(
                  children: [
   
              // Tooltip(
              //   message: context.translate('How to read your result'),
              //   child: InkWell(
              //     onTap: () => ResultGuideDialog.show(context),
              //           borderRadius: BorderRadius.circular(50),
              //           child: Container(
              //             width: 25,
              //             height: 25,
              //             padding: const EdgeInsets.all(0),
              //             decoration: BoxDecoration(
              //               shape: BoxShape.circle,
              //               border: Border.all(
              //                 color: Colors.grey[500]!,
              //                 width: 1,
              //               ),
              //               color: Colors.white,
              //             ),
              //             child: Icon(
              //               Icons.lightbulb_outline,
              //               size: 15,
              //               color: Colors.grey[700],
              //             ),
              //           ),
              //         ),
              //       ),

              //       const SizedBox(width: 8),

if(isFarmer) 
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

  void _navigateToRecommendation() {
    try {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const RecommendationPage(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return child;
          },
          transitionDuration: Duration.zero,
        ),
      );
    } catch (e) {
      debugPrint('Navigation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.translate('Navigation failed. Please try again.')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}