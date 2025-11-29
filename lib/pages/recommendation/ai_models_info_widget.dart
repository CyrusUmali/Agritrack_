// lib/pages/recommendation/ai_models_info_widget.dart

import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart'; 

class AiModelsInfoWidget {
  static void show({
    required BuildContext context,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Isara',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(screenWidth < 600 ? 16 : 24),
                  child: Material(
                    type: MaterialType.transparency,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: screenWidth < 600 ? screenWidth * 0.92 : 650,
                        maxHeight: MediaQuery.of(context).size.height * 0.85,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).cardTheme.color ?? Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const AiModelsInfoContent(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AiModelsInfoContent extends StatefulWidget {
  const AiModelsInfoContent({super.key});

  @override
  State<AiModelsInfoContent> createState() => _AiModelsInfoContentState();
}

class _AiModelsInfoContentState extends State<AiModelsInfoContent> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  List<Map<String, dynamic>> _getModels(BuildContext context) {
    return [
      {
        'title': 'Decision Tree',
        'icon': Icons.account_tree,
        'color': Color(0xFF10B981),
        'description': 'Parang puno ng desisyon',
        'explanation': 'Isipin mo na parang nag-tatanong ka sa sarili mo: "Maulan ba? Oo o Hindi?" Kung OO, tanong ulit: "Sandy ba ang lupa? Oo o Hindi?" Ganyan yung Decision Tree - sunod-sunod na tanong hanggang makuha ang tamang sagot kung anong pananim ang angkop.',
        'analogy': 'Parang ikaw na pumipili ng pananim: Una, tingnan mo kung maulan ba o mainit. Tapos, tignan mo kung sandy o clay ang lupa mo. Sunod-sunod na tanong hanggang makuha mo ang best na crop para sa iyong farm.',
        'bestFor': 'Maganda kung gusto mo maintindihan kung bakit ganito ang recommendation. Simple at madaling i-explain sa kapwa magsasaka.',
        'gradient': [Color(0xFF10B981), Color(0xFF059669)],
      },
      {
        'title': 'Random Forest',
        'icon': Icons.forest,
        'color': Color(0xFF3B82F6),
        'description': 'Maraming puno ng desisyon',
        'explanation': 'Hindi lang isang puno - maraming puno! Imagine, may 100 ka pong kapitbahay na magsasaka na may kanya-kanyang opinion. Tinatanong mo silang lahat: "Ano magandang itanim?" Tapos kukunin mo yung pinaka-common na sagot. Mas accurate kasi maraming opinion ang pinag-combined!',
        'analogy': 'Parang community meeting ng mga magsasaka. Hindi ka magtitiwala sa isang tao lang - tatanungin mo ang 50-100 na magsasaka, tapos yung pinakamaraming pumili ng isang crop, yun ang i-recommend mo. Mas matatag ang desisyon!',
        'bestFor': 'Pinaka-reliable para sa iba\'t ibang kondisyon ng lupa at weather. Kahit may pagka-komplikado ang situation, makakakuha pa rin ng magandang recommendation.',
        'gradient': [Color(0xFF3B82F6), Color(0xFF2563EB)],
      },
      {
        'title': 'Logistic Regression',
        'icon': Icons.trending_up,
        'color': Color(0xFFF59E0B),
        'description': 'Simple math para sa prediction',
        'explanation': 'Ito ay parang timbangan o weighing scale. Bawat factor (ulan, lupa, temperatura) ay may "bigat" o importance. I-add up lahat ng factors at kung lampas sa threshold, sasabihin "Oo, magtanim ng Palay!" Kung hindi umabot, "Hindi, magtanim ng iba."',
        'analogy': 'Parang points system sa palengke. Kung sobrang ulan (+30 points), clay soil (+20 points), at mainit (+15 points) = 65 points total. Kung 50 ang passing, edi magtanim ng Palay! Simple math lang.',
        'bestFor': 'Fast at simple. Okay kung ang tanong mo ay "Oo o Hindi" lang - magtatanim ba ng specific crop o hindi. Hindi masyadong kumplekado pero mabilis.',
        'gradient': [Color(0xFFF59E0B), Color(0xFFD97706)],
      },
      {
        'title': 'XGBoost',
        'icon': Icons.rocket_launch,
        'color': Color(0xFF8B5CF6),
        'description': 'Ang pinaka-matalino at mabilis',
        'explanation': 'Ito yung "expert mode" na parang si Tatay na marunong na magsaka ng 30 years. Hindi lang titingin sa obvious na bagay - pati yung maliliit na detalye na hindi mo napapansin, alam niya. Natututo pa siya from mistakes para mas gumaling pa.',
        'analogy': 'Imagine may team ka ng pinaka-expert na agricultural technicians. Yung una mag-check ng soil, yung pangalawa ng weather, yung pangatlo ng market price. Lahat ng opinion nila pinagsama-sama ng pinaka-wise na elder para makuha ang BEST recommendation. Yun ang XGBoost!',
        'bestFor': 'Para sa pinaka-accurate na prediction. Gamitin kung sobrang importante ang desisyon mo - like malaking investment o critical season. Ito yung pinaka-advanced naming AI.',
        'gradient': [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      },
    ];
  }

  void _nextPage() {
    if (_currentPage < _getModels(context).length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final models = _getModels(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with gradient
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF3B82F6).withOpacity(0.1),
                Color(0xFF8B5CF6).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.psychology, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paano Gumagana ang Aming AI',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                          ),
                    ),
                    Text(
                      'Alamin kung paano namin nirerekomenda ang tamang pananim',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Page View
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: models.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final model = models[index];
              return _buildModelPage(context, model, isDark);
            },
          ),
        ),

        // Footer with navigation
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[50],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(models.length, (index) {
                  final isActive = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: isActive
                          ? LinearGradient(
                              colors: models[index]['gradient'],
                            )
                          : null,
                      color: isActive
                          ? null
                          : (isDark ? Colors.grey[700] : Colors.grey[300]),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side - Previous button or empty space
                  SizedBox(
                    width: 100,
                    child: _currentPage > 0
                        ? ButtonWidget(
                            btnText: 'Balik',
                            onTap: _previousPage,
                            textColor: FlarelineColors.darkBlackText,
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Center - Page counter
                  Text(
                    '${_currentPage + 1} / ${models.length}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                  ),

                  // Right side - Next/Close button
                  SizedBox(
                    width: 100,
                    child: ButtonWidget(
                      btnText: _currentPage == models.length - 1 
                          ? 'Isara' 
                          : 'Susunod',
                      onTap: _currentPage == models.length - 1
                          ? () => Navigator.of(context).pop()
                          : _nextPage,
                      type: ButtonType.primary.type,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModelPage(
      BuildContext context, Map<String, dynamic> model, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Model header with icon and title
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: model['gradient'],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: model['color'].withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    model['icon'],
                    size: 44,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  model['title'],
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        model['color'].withOpacity(0.15),
                        model['color'].withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    model['description'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: model['color'],
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Explanation section
          _buildSection(
            context,
            'Paano Ito Gumagana?',
            Icons.lightbulb_outline,
            model['explanation'],
            model['color'],
            isDark,
          ),

          const SizedBox(height: 20),

          // Analogy section
          _buildSection(
            context,
            'Simpleng Halimbawa',
            Icons.emoji_objects,
            model['analogy'],
            model['color'],
            isDark,
          ),

          const SizedBox(height: 20),

          // Best for section
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  model['color'].withOpacity(0.1),
                  model['color'].withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: model['color'].withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: model['color'].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.star, color: model['color'], size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kailan Gamitin?',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: model['color'],
                                  fontSize: 15,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        model['bestFor'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[800],
                              fontSize: 15,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    String content,
    Color accentColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  fontSize: 14.5,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
          ),
        ],
      ),
    );
  }
}