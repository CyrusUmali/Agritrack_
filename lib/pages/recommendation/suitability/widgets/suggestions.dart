import 'package:flutter/material.dart';
import 'package:flareline/services/lanugage_extension.dart';

// ============================================================
// SUGGESTIONS CARD WIDGET
// ============================================================

class SuggestionsCard extends StatelessWidget {
  final List<String> suggestions;
  final int deficientParamsCount;
  final bool isSmallScreen;
  final double padding;
  final Function() onGetSuggestions;
  final bool isLoadingSuggestions;

  const SuggestionsCard({
    super.key,
    required this.suggestions,
    required this.deficientParamsCount,
    required this.isSmallScreen,
    required this.padding,
    required this.onGetSuggestions,
    required this.isLoadingSuggestions,
  });

  @override
  Widget build(BuildContext context) {
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
            // Header
            Row(
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
                    Icons.auto_awesome,
                    color: isDark ? Colors.blue[300] : Colors.blue[600],
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.translate('Improvement Suggestions'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[200] : Colors.grey[800],
                        fontSize: isSmallScreen ? 18 : 20,
                      ),
                ),
                const Spacer(),
                if (deficientParamsCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.orange[900]!.withOpacity(0.3)
                          : Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isDark ? Colors.orange[700]! : Colors.orange[200]!,
                      ),
                    ),
                    child: Text(
                      '$deficientParamsCount',
                      style: TextStyle(
                        color: isDark ? Colors.orange[300] : Colors.orange[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: isSmallScreen ? 16 : 20),

            Text(
              '${deficientParamsCount} ${context.translate('parameters need attention')}',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: isSmallScreen ? 16 : 20),

            // Content area
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: suggestions.isNotEmpty
                  ? _SuggestionsContent(
                      suggestions: suggestions,
                      isSmallScreen: isSmallScreen,
                    )
                  : _GetSuggestionsButton(
                      onGetSuggestions: onGetSuggestions,
                      isLoadingSuggestions: isLoadingSuggestions,
                      isSmallScreen: isSmallScreen,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SUGGESTIONS CONTENT WIDGET (Private)
// ============================================================

class _SuggestionsContent extends StatelessWidget {
  final List<String> suggestions;
  final bool isSmallScreen;

  const _SuggestionsContent({
    required this.suggestions,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No suggestions available',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 15,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[600]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Recommendations',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
          ),
          Text(
            suggestions.join('\n\n'),
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 15,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GET SUGGESTIONS BUTTON WIDGET (Private)
// ============================================================

class _GetSuggestionsButton extends StatelessWidget {
  final Function() onGetSuggestions;
  final bool isLoadingSuggestions;
  final bool isSmallScreen;

  const _GetSuggestionsButton({
    required this.onGetSuggestions,
    required this.isLoadingSuggestions,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 48 : 52,
      decoration: BoxDecoration(
        color: Colors.blue[600],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoadingSuggestions ? null : onGetSuggestions,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoadingSuggestions)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else ...[
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.translate('Get AI Suggestions'),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 15 : 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DISCLAIMER WIDGET
// ============================================================

class DisclaimerWidget extends StatelessWidget {
  final String? disclaimer;
  final bool isSmallScreen;
  final double padding;

  const DisclaimerWidget({
    super.key,
    required this.disclaimer,
    required this.isSmallScreen,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              disclaimer ?? context.translate('disclaimer_ai'),
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontStyle: FontStyle.italic,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}