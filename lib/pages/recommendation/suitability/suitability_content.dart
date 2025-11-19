import 'package:flareline/pages/recommendation/ai_models_info_widget.dart';
import 'package:flareline/pages/recommendation/chatbot/chatbot_page.dart';
import 'package:flareline/pages/recommendation/recommendation_page.dart';
import 'package:flareline/pages/recommendation/requirement_page.dart';
import 'package:flareline/pages/recommendation/suitability/suitabilty_model.dart';
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flareline/providers/language_provider.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this import
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

  // Remove the local languageProvider and model declarations
  SuitabilityModel? model;

  final List<String> availableCrops = [
    "ampalaya",
    "apple",
    "banana",
    "cacao",
    "calamansi",
    "cassava",
    "coconut",
    "durian",
    "eggplant",
    "gabi",
    "ginger",
    "grapes",
    "guyabano",
    "jackfruit",
    "lanzones",
    "maize",
    "mango",
    "mungbean",
    "mustard",
    "okra",
    "onion",
    "orange",
    "oyster mushroom",
    "papaya",
    "patola",
    "pechay",
    "pineapple",
    "radish",
    "rambutan",
    "rice",
    "sigarilyas",
    "sili panigang",
    "sili tingala",
    "snap bean",
    "squash",
    "string bean",
    "sweet potato",
    "tomato",
    "ube",
    "upo",
    "watermelon",
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

    // Initialize model with the provider from context
    if (model == null) {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      model = SuitabilityModel(languageProvider: languageProvider);
      model!.addListener(_onModelChanged);
    }
  }

  @override
  void dispose() {
    model?.removeListener(_onModelChanged);
    super.dispose();
  }

  void _onModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

 
  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to language changes
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        if (model == null)
          return const Center(child: CircularProgressIndicator());

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
                    const SizedBox(height: 10),
                    _buildModelSelectionCard(),
                    const SizedBox(height: 24),
                    _buildInputParametersCard(isMobile),
                    if (model!.isLoading) ...[
                      const SizedBox(height: 24),
                      const Center(child: CircularProgressIndicator()),
                    ],
                    if (model!.suitabilityResult != null &&
                        model!.suitabilityResult!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      SuitabilityResults(
                        suitabilityResult: model!.suitabilityResult!,
                        onGetSuggestions: () async {
                          try {
                            // Convert to List<String> explicitly
                            final deficientParams = (model!.suitabilityResult![
                                    'parameters_analysis'] as Map)
                                .entries
                                .where((e) => e.value['status'] != 'optimal')
                                .map((e) => e.key.toString())
                                .toList();

                            await model!.getSuggestionsStream(
                              deficientParams,
                              languageCode: languageProvider
                                  .currentLanguageCode, // This will now get the updated value
                            );
                          } catch (e) {
                            ToastHelper.showErrorToast(
                              'Error: ${e.toString()}',
                              context,
                            );
                          }
                        },
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
              setState(() {
                model!.selectedCrop = selection;
                model!.suitabilityResult = null;
              });
            },
            fieldViewBuilder: (BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted) {
              // Set initial value if a crop is already selected
              if (model!.selectedCrop != null &&
                  textEditingController.text.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  textEditingController.text = model!.selectedCrop!;
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
                    borderSide: BorderSide(color: Colors.blue, width: 1),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardTheme.color,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  hintText: 'Type to search crops...',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  suffixIcon: model!.selectedCrop != null
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() {
                              model!.selectedCrop = null;
                              model!.suitabilityResult = null;
                              textEditingController.clear();
                            });
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
                    width: MediaQuery.of(context).size.width - 64, // Matches input field width
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
              value: model!.selectedModel,
              items: model!.models.keys.map((String modelName) {
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
                  model!.selectedModel = newValue!;
                  model!.modelAccuracy = newValue == 'All Models'
                      ? 'Ensemble average will be calculated'
                      : 'Accuracy: ${(model!.models[newValue]!['accuracy']! * 100).toStringAsFixed(2)}%';
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
                  borderSide: BorderSide(color: Colors.blue, width: 1),
                ),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
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
            Text(
              // 'Enter Environmental Parameters',
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
                onPressed: model!.selectedCrop == null
                    ? null
                    : () async {
                        try {
                          setState(() {
                            model!.isLoading = true;
                          });

                          await model!.checkSuitability();
                        } catch (e) {
                          ToastHelper.showErrorToast(
                            'Error: $e',
                            context,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      model!.selectedCrop == null ? Colors.grey : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.translate('Check Suitability'),
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            if (model!.suitabilityResult != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    model!.suitabilityResult = null;
                  });
                },
                child: Text(context.translate('Check Another Configuration')),
              ),
            ],
          ],
        ),
      ),
    );
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
                message:     context.translate('Crop Recommendation'),  
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
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const RecommendationPage(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
    transitionDuration: Duration.zero,
  ),
);

                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //       builder: (context) => const RecommendationPage()),
                    // );
                  },
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                ),
              ),
         
         
            ],
          ),

          // Right side buttons
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
if(!isFarmer) 
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
              // 'Crop Suitability ',

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
                  message:   context.translate('Crop Recommendation'), 
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
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //       builder: (context) => const RecommendationPage()),
                      // );


Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const RecommendationPage(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
    transitionDuration: Duration.zero,
  ),
);


                    },
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                  ),
                ),
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

if(!isFarmer) 
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
}
