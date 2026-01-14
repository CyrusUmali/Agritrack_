// result_guide_content.dart
import 'package:flutter/material.dart';
 
class ResultGuideDialog {
  static void show(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Result Guide',
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
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Material(
                    type: MaterialType.transparency,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? screenWidth * 0.92 : 650,
                        maxHeight: MediaQuery.of(context).size.height * 0.85,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color ?? Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const ResultGuideContent(),
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










class ResultGuideContent extends StatefulWidget {
  const ResultGuideContent({super.key});

  @override
  State<ResultGuideContent> createState() => _ResultGuideContentState();
}

class _ResultGuideContentState extends State<ResultGuideContent> {
  int _currentPage = 0;
  final PageController _pageController = PageController();





final List<Map<String, dynamic>> _guidePages = [
  {
    'title': 'Final Confidence Score',
    'icon': Icons.score,
    'color': Color(0xFF3B82F6),
    'description': 'Paano basahin ang overall score',
    'explanation': 'Ang final confidence score ay combination ng dalawang factors:\n\n'
        '• Soil Parameter Score (70%) – Kung gaano ka-compatible ang soil conditions sa ideal ng crop\n'
        '• AI Model Score (30%) – Prediction mula sa crop-specific binary ML model\n\n'
        'Score ranges:\n'
        '• 90-100%: Sobrang ganda ng conditions!\n'
        '• 75-89%: Excellent, highly recommended\n'
        '• 60-74%: Good, pwede na magtanim\n'
        '• 50-59%: Marginal, kailangan ng improvements\n'
        '• Below 50%: Hindi recommended',
    'analogy': 'Parang weather forecast: 90% chance of sunshine → siguradong maganda ang araw. 60% → may konting risk. Below 40% → mas mabuti magpaliban.',
    'tips': '💡 Tip: Mas mataas ang weight ng soil parameters (70%) kaysa sa AI score. Siguraduhing compatible ang lupa bago magtanim.',
    'gradient': [Color(0xFF3B82F6), Color(0xFF2563EB)],
  },
  {
    'title': 'Soil Parameters Analysis',
    'icon': Icons.tune,
    'color': Color(0xFF10B981),
    'description': 'Detalyadong breakdown ng bawat soil parameter',
    'explanation': 'Sinusuri ng system ang 6 critical soil parameters:\n'
        '• Soil pH – Acidity/alkalinity\n'
        '• Fertility (EC) – Nutrient richness\n'
        '• Humidity – Kahalumigmigan ng hangin\n'
        '• Sunlight – Oras ng sikat ng araw\n'
        '• Soil Temperature – Init ng lupa\n'
        '• Soil Moisture – Tubig content ng lupa\n\n'
        'Bawat parameter ay may ideal range at importance weight. Ang final Soil Parameter Score ay batay sa compatibility ng lahat ng parameters.',
    'analogy': 'Parang pag-bake ng cake: bawat ingredient kailangan tama ang sukat. Kahit konti lang ang deviation, maaapektuhan ang resulta.',
    'tips': '⚠️ Important: Kung may parameter na sobrang layo sa ideal range, kailangan i-adjust muna bago magtanim.',
    'gradient': [Color(0xFF10B981), Color(0xFF059669)],
  },
  {
    'title': 'ML Model Confidence',
    'icon': Icons.psychology,
    'color': Color(0xFF8B5CF6),
    'description': 'AI prediction para sa crop suitability',
    'explanation': 'Ang ML (Machine Learning) confidence ay prediction ng crop-specific binary model base sa data ng real farms. '
        'Bawat crop ay sinusuri ng sariling model, at ang score ay combined sa Soil Parameter Score para sa final recommendation.',
    'analogy': 'Imagine may 5 farmers na tinanong tungkol sa crop. Bawat isa ay may sariling opinion. Kapag majority ay nagsabi "Oo, pwede," mas mataas ang confidence. Ganun din ang model, pero isinasaalang-alang rin ang quality ng soil parameters.',
    'tips': '🤖 Technical note: Kahit mataas ang ML score, kung low ang parameter matching, bababa pa rin ang final score. Kaya 70% weight sa soil parameters, 30% sa ML prediction.',
    'gradient': [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
  },
  {
    'title': 'Action Plan Based on Score',
    'icon': Icons.playlist_add_check,
    'color': Color(0xFFEC4899),
    'description': 'Ano ang dapat gawin next',
    'explanation': '🌟 High Score (75-100%)\n'
        '✅ Mag-proceed sa planting\n'
        '✅ Prepare usual farming practices\n'
        '✅ May mataas na chance of good harvest\n\n'
        '⚠️ Medium Score (60-74%)\n'
        '📋 Review parameters with issues\n'
        '🧪 Consider soil testing\n'
        '💰 Plan budget for soil amendments\n'
        '👥 Consult agricultural experts\n\n'
        '❌ Low Score (Below 60%)\n'
        '🛑 DO NOT plant yet\n'
        '🔧 Focus on soil improvement first\n'
        '📚 Research proper soil amendments\n'
        '🌱 Consider alternative crops\n'
        '⏱️ Retest after improvements',
    'analogy': 'Parang traffic light: Green → go; Yellow → prepare/adjust; Red → stop at check-point.',
    'tips': '🎯 Pro Tip: Huwag madaliin ang planting kung low score. Investment sa soil improvement = better harvest later.',
    'gradient': [Color(0xFFEC4899), Color(0xFFDB2777)],
  },
];






  void _nextPage() {
    if (_currentPage < _guidePages.length - 1) {
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
                child: const Icon(Icons.help_outline, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paano Basahin ang Resulta',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                          ),
                    ),
                    Text(
                      'Alamin kung ano ang ibig sabihin ng iyong crop suitability results',
                     
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
            itemCount: _guidePages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final page = _guidePages[index];
              return _buildGuidePage(context, page, isDark);
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
                children: List.generate(_guidePages.length, (index) {
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
                              colors: _guidePages[_currentPage]['gradient'],
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
                  // Previous button
                  SizedBox(
                    width: 100,
                    child: _currentPage > 0
                        ? TextButton(
                            onPressed: _previousPage,
                            style: TextButton.styleFrom(
                              foregroundColor: isDark ? Colors.grey[300] : Colors.grey[700],
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chevron_left, size: 18 ),
                           
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Page counter
                  Text(
                    '${_currentPage + 1} / ${_guidePages.length}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                  ),

                  // Next/Close button
                  SizedBox(
                    width: 100,
                    child: _currentPage == _guidePages.length - 1
                        ? ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Isara'),
                          )
                        : ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                             
                                Icon(Icons.chevron_right, size: 18 , color: Colors.white,),
                              ],
                            ),
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

Widget _buildGuidePage(BuildContext context, Map<String, dynamic> page, bool isDark) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Guide header with icon
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: page['gradient'],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: page['color'].withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  page['icon'],
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                page['title'],
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
                      page['color'].withOpacity(0.15),
                      page['color'].withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  page['description'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: page['color'],
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
        Container(
          padding: const EdgeInsets.all(18),
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
                      color: page['color'].withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.lightbulb_outline, size: 18, color: page['color']),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Paliwanag',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                page['explanation'],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      fontSize: 14.5,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Analogy section
        Container(
          padding: const EdgeInsets.all(18),
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
                      color: page['color'].withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.emoji_objects, size: 18, color: page['color']),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Simpleng Analogy',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                page['analogy'],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      fontSize: 14.5,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20), // Add spacing

        // Tips section - ADD THIS
        Container(
          padding: const EdgeInsets.all(18),
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
                      color: page['color'].withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.tips_and_updates, size: 18, color: page['color']),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Tips at Rekomendasyon',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                page['tips'], // This uses the 'tips' field from your data
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      fontSize: 14.5,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}



}