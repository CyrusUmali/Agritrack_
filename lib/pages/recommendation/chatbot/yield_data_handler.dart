// yield_data_handler.dart - IMPROVED VERSION
import 'dart:convert';

class YieldDataHandler {
  // MGA VARIABLES
  List<dynamic>? _availableYieldData;
  List<Map<String, dynamic>> _recentYieldDataCache = [];
  bool _hasYieldData = false;
  DateTime? _lastYieldDataUpdate;
  Map<String, int> _yieldKeywordFrequency = {};
  
  // Configuration - Adjusted thresholds for better accuracy
  double _keywordConfidenceThreshold = 0.15; // Lower threshold for more sensitivity
  int _maxYieldRecordsToAttach = 20;
  
  // SCORING SYSTEM - Different weights per category
  final Map<String, double> _categoryWeights = {
    'primary': 3.0,      // Highest weight - direct yield questions
    'analysis': 2.5,     // High weight - needs data analysis
    'comparison': 2.0,   // Medium-high - comparing data
    'volume': 1.5,       // Medium - quantity questions
    'value': 1.5,        // Medium - financial questions
    'area': 1.2,         // Medium-low - area-related
    'time': 1.2,         // Medium-low - time-related
    'product': 1.0,      // Low - just mentions product
    'location': 0.8,     // Low - just location
    'status': 0.8,       // Low - just status
  };
  
  // PRIMARY KEYWORDS - Direktang yield-related (HIGHEST PRIORITY)
  final List<String> _primaryYieldKeywords = [
    'ani', 'anihan', 'yield', 'produksyon', 
    'kita', 'tanggap', 'bunga', 'harvest',
    'huli ng ani', 'production', 'naani',
    'nakuha', 'naproduce', 'naging ani'
  ];
  
  // ANALYSIS KEYWORDS - Needs data (VERY HIGH PRIORITY)
  final List<String> _analysisKeywords = [
    'analysis', 'pagsusuri', 'analyze', 'suriin',
    'buod', 'summary', 'report', 'ulat',
    'data', 'records', 'talaan', 'statistics',
    'stats', 'tingnan', 'ipakita', 'show',
    'ano ang', 'magkano ang', 'ilan ang',
    'paano ang', 'kumusta ang', 'tignan',
    'ibigay', 'provide', 'display'
  ];
  
  // COMPARISON KEYWORDS (HIGH PRIORITY)
  final List<String> _comparisonKeywords = [
    'ikumpara', 'compare', 'paghahambing',
    'mas mataas', 'mas mababa', 'pinakamataas',
    'pinakamababa', 'highest', 'lowest',
    'best', 'worst', 'pinakamaganda', 'pinakamasama',
    'rank', 'ranking', 'top', 'bottom',
    'kaysa sa', 'versus', 'vs', 'laban sa'
  ];
  
  // QUESTION INDICATORS - Shows user is asking about data
  final List<String> _questionIndicators = [
    'ano', 'ilan', 'magkano', 'saan', 'kailan',
    'paano', 'what', 'how much', 'how many',
    'when', 'where', 'which', 'alin', 'sino',
    'gaano', 'may', 'mayroon', 'is there', 'are there'
  ];
  
  // VOLUME-RELATED KEYWORDS
  final List<String> _volumeKeywords = [
    'dami', 'volume', 'kantidad', 'bilang',
    'magkano', 'ilan', 'gaano karami',
    'kung ilan', 'quantity', 'total',
    'kabuuan', 'overall', 'lahat'
  ];
  
  // VALUE-RELATED KEYWORDS
  final List<String> _valueKeywords = [
    'halaga', 'value', 'worth', 'presyo',
    'kita', 'profit', 'tubo', 'ginastos',
    'cost', 'benepisyo', 'benefit', 'earning',
    'income', 'revenue', 'sales', 'benta'
  ];
  
  // AREA-RELATED KEYWORDS
  final List<String> _areaKeywords = [
    'hektarya', 'hectare', 'lupa', 'sukat',
    'area', 'farm', 'bukid', 'sakahan',
    'taniman', 'lawak', 'lugar', 'space'
  ];
  
  // PRODUCT-RELATED KEYWORDS
  final List<String> _productKeywords = [
    'produkto', 'product', 'pananim', 'crop',
    'gulay', 'prutas', 'palay', 'bigas',
    'corn', 'mais', 'niyog', 'tubo',
    'sugarcane', 'coconut', 'vegetable'
  ];
  
  // TIME-RELATED KEYWORDS
  final List<String> _timeKeywords = [
    'petsa', 'date', 'kailan', 'panahon',
    'season', 'recent', 'latest', 'pinakabago',
    'bagong', 'nakaraan', 'lumang', 'taon',
    'buwan', 'araw', 'ngayon', 'today',
    'last month', 'last year', 'this year'
  ];
  
  // LOCATION-RELATED KEYWORDS
  final List<String> _locationKeywords = [
    'lugar', 'location', 'barangay', 'municipality',
    'munisipyo', 'probinsya', 'province', 'rehiyon',
    'region', 'sector', 'sektor', 'address', 'saan'
  ];
  
  // STATUS-RELATED KEYWORDS
  final List<String> _statusKeywords = [
    'status', 'kalagayan', 'kondisyon', 'state',
    'naani', 'hindi pa', 'natapos', 'in progress',
    'completed', 'tapos na', 'ginagawa pa'
  ];
  
  // NEGATIVE INDICATORS - These suggest yield data is NOT needed
  final List<String> _negativeIndicators = [
    'paano mag', 'how to', 'tutorial', 'gabay',
    'guide', 'instructions', 'hakbang', 'steps',
    'define', 'kahulugan', 'meaning', 'ibig sabihin',
    'ano ang ibig sabihin', 'what is', 'what does',
    'hello', 'hi', 'kumusta', 'help', 'tulong',
    'salamat', 'thank you', 'okay', 'sige'
  ];
  
  // MGA GETTERS
  List<dynamic>? get availableYieldData => _availableYieldData;
  bool get hasYieldData => _hasYieldData;
  List<Map<String, dynamic>> get recentYieldDataCache => _recentYieldDataCache;
  DateTime? get lastYieldDataUpdate => _lastYieldDataUpdate;
  double get keywordConfidenceThreshold => _keywordConfidenceThreshold;
  int get maxYieldRecordsToAttach => _maxYieldRecordsToAttach;
  
  // MGA SETTERS
  void setYieldData(List<dynamic>? yieldData) {
    _availableYieldData = yieldData;
    _hasYieldData = yieldData != null && yieldData.isNotEmpty;
    _lastYieldDataUpdate = DateTime.now();
    
    if (yieldData != null && yieldData.isNotEmpty) {
      _recentYieldDataCache = _condenseYieldData(yieldData, _getBasicRequiredFields());
    }
  }
  
  void updateKeywordConfidence(double threshold) {
    _keywordConfidenceThreshold = threshold.clamp(0.0, 1.0);
  }
  
  void updateMaxRecords(int maxRecords) {
    _maxYieldRecordsToAttach = maxRecords.clamp(1, 100);
  }
  
  // IMPROVED: Enhanced prompt with better scoring
  String enhancePromptWithYieldData(String userMessage) {
    if (!_hasYieldData) return userMessage;
    
    // NEW: Use improved scoring system
    final needsData = shouldAttachYieldData(userMessage);
    
    if (!needsData) {
      return userMessage;
    }
    
    final requiredFields = _extractRequiredFieldsFromPrompt(userMessage);
    final condensedData = _condenseYieldData(
      _availableYieldData!, 
      requiredFields,
      limit: _maxYieldRecordsToAttach
    );
    
    if (condensedData.isEmpty) {
      return userMessage;
    }
    
    final jsonData = jsonEncode(condensedData);
    
    return '''$userMessage

YIELD DATA PARA SA PAGSUSURI:
$jsonData

PAKISURI ANG DATA NA ITO AT MAGBIGAY NG DETALYADONG SAGOT SA TAGALOG.
Mga importante dapat isama:
1. Buod ng data
2. Mga patterns o trends
3. Rekomendasyon kung mayroon
4. Specific na halimbawa mula sa data
''';
  }
  
  // NEW: Improved decision making with weighted scoring
  bool shouldAttachYieldData(String message) {
    if (!_hasYieldData) return false;
    
    final lowerMessage = message.toLowerCase();
    
    // Check for negative indicators first
    if (_hasAnyKeyword(lowerMessage, _negativeIndicators)) {
      return false;
    }
    
    // Calculate weighted score
    double score = 0.0;
    
    // Primary keywords - highest weight
    if (_hasAnyKeyword(lowerMessage, _primaryYieldKeywords)) {
      score += _categoryWeights['primary']!;
    }
    
    // Analysis keywords - very high weight
    if (_hasAnyKeyword(lowerMessage, _analysisKeywords)) {
      score += _categoryWeights['analysis']!;
    }
    
    // Comparison keywords - high weight
    if (_hasAnyKeyword(lowerMessage, _comparisonKeywords)) {
      score += _categoryWeights['comparison']!;
    }
    
    // Question indicators - boost if present
    if (_hasAnyKeyword(lowerMessage, _questionIndicators)) {
      score += 0.5;
    }
    
    // Other categories with their respective weights
    if (_hasAnyKeyword(lowerMessage, _volumeKeywords)) {
      score += _categoryWeights['volume']!;
    }
    
    if (_hasAnyKeyword(lowerMessage, _valueKeywords)) {
      score += _categoryWeights['value']!;
    }
    
    if (_hasAnyKeyword(lowerMessage, _areaKeywords)) {
      score += _categoryWeights['area']!;
    }
    
    if (_hasAnyKeyword(lowerMessage, _timeKeywords)) {
      score += _categoryWeights['time']!;
    }
    
    if (_hasAnyKeyword(lowerMessage, _productKeywords)) {
      score += _categoryWeights['product']!;
    }
    
    if (_hasAnyKeyword(lowerMessage, _locationKeywords)) {
      score += _categoryWeights['location']!;
    }
    
    if (_hasAnyKeyword(lowerMessage, _statusKeywords)) {
      score += _categoryWeights['status']!;
    }
    
    // Normalize score (max possible ~11, threshold at ~1.5)
    final normalizedScore = score / 11.0;
    
    // Return true if score exceeds threshold
    return normalizedScore >= _keywordConfidenceThreshold;
  }
  
  // NEW: Get confidence level for debugging/UI
  Map<String, dynamic> getConfidenceAnalysis(String message) {
    final lowerMessage = message.toLowerCase();
    Map<String, bool> categoryMatches = {};
    double score = 0.0;
    
    categoryMatches['primary'] = _hasAnyKeyword(lowerMessage, _primaryYieldKeywords);
    if (categoryMatches['primary']!) score += _categoryWeights['primary']!;
    
    categoryMatches['analysis'] = _hasAnyKeyword(lowerMessage, _analysisKeywords);
    if (categoryMatches['analysis']!) score += _categoryWeights['analysis']!;
    
    categoryMatches['comparison'] = _hasAnyKeyword(lowerMessage, _comparisonKeywords);
    if (categoryMatches['comparison']!) score += _categoryWeights['comparison']!;
    
    categoryMatches['question'] = _hasAnyKeyword(lowerMessage, _questionIndicators);
    if (categoryMatches['question']!) score += 0.5;
    
    categoryMatches['volume'] = _hasAnyKeyword(lowerMessage, _volumeKeywords);
    if (categoryMatches['volume']!) score += _categoryWeights['volume']!;
    
    categoryMatches['value'] = _hasAnyKeyword(lowerMessage, _valueKeywords);
    if (categoryMatches['value']!) score += _categoryWeights['value']!;
    
    categoryMatches['hasNegative'] = _hasAnyKeyword(lowerMessage, _negativeIndicators);
    
    final normalizedScore = score / 11.0;
    final shouldAttach = normalizedScore >= _keywordConfidenceThreshold && !categoryMatches['hasNegative']!;
    
    return {
      'shouldAttach': shouldAttach,
      'rawScore': score,
      'normalizedScore': normalizedScore,
      'threshold': _keywordConfidenceThreshold,
      'categoryMatches': categoryMatches,
      'matchedKeywords': _getMatchedKeywords(lowerMessage),
    };
  }
  
  // Helper: Get actual matched keywords for debugging
  List<String> _getMatchedKeywords(String message) {
    List<String> matched = [];
    final allKeywords = [
      ..._primaryYieldKeywords,
      ..._analysisKeywords,
      ..._comparisonKeywords,
      ..._questionIndicators,
      ..._volumeKeywords,
      ..._valueKeywords,
    ];
    
    for (var keyword in allKeywords) {
      if (message.contains(keyword)) {
        matched.add(keyword);
      }
    }
    
    return matched.take(10).toList(); // Limit to 10 for clarity
  }
  
  // Helper: Check if any keyword from list is in message
  bool _hasAnyKeyword(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }
  
  // IMPROVED: Get relevant quick options based on message
  List<String> getRelevantQuickOptions(String userMessage) {
    if (!_hasYieldData) return [];
    
    final lowerMessage = userMessage.toLowerCase();
    final List<String> options = [];
    
    if (_hasAnyKeyword(lowerMessage, _analysisKeywords)) {
      options.addAll(['Buod ng Ani', 'Detalyadong Report']);
    }
    
    if (_hasAnyKeyword(lowerMessage, _comparisonKeywords)) {
      options.addAll(['Ikumpara ang mga ani', 'Ranking ng produkto']);
    }
    
    if (_hasAnyKeyword(lowerMessage, _timeKeywords)) {
      options.addAll(['Bagong Ani', 'Buwan ng datos']);
    }
    
    if (_hasAnyKeyword(lowerMessage, _valueKeywords)) {
      options.addAll(['Halaga ng Ani', 'Profit Analysis']);
    }
    
    if (_hasAnyKeyword(lowerMessage, _volumeKeywords)) {
      options.addAll(['Total Volume', 'Average per Hectare']);
    }
    
    return options.take(4).toList(); // Limit to 4 options
  }
  
  // HELPER METHODS (Same as before but optimized)
  
  List<String> _getBasicRequiredFields() {
    return ['id', 'productName', 'harvestDate', 'volume', 'hectare'];
  }
  
  List<Map<String, dynamic>> _condenseYieldData(
    List<dynamic> yieldData, 
    List<String> requiredFields,
    {int? limit}
  ) {
    if (yieldData.isEmpty) return [];
    
    final dataToUse = limit != null 
        ? yieldData.take(limit).toList()
        : yieldData;
    
    return dataToUse.map((yield) {
      return _extractYieldFields(yield, requiredFields);
    }).toList();
  }
  
  Map<String, dynamic> _extractYieldFields(dynamic yield, List<String> requiredFields) {
    final Map<String, dynamic> extracted = {};
    
    for (var field in requiredFields) {
      switch (field) {
        case 'id':
          extracted['id'] = yield.id;
          break;
        case 'volume':
          extracted['volume'] = yield.volume;
          break;
        case 'farmerName':
          extracted['farmerName'] = yield.farmerName;
          break;
        case 'productName':
          extracted['productName'] = yield.productName;
          break;
        case 'value':
          extracted['value'] = yield.value;
          break;
        case 'harvestDate':
          extracted['harvestDate'] = yield.harvestDate?.toIso8601String();
          break;
        case 'status':
          extracted['status'] = yield.status;
          break;
        case 'farmName':
          extracted['farmName'] = yield.farmName;
          break;
        case 'hectare':
          extracted['hectare'] = yield.hectare;
          break;
        case 'areaHarvested':
          extracted['areaHarvested'] = yield.areaHarvested;
          break;
        case 'sector':
          extracted['sector'] = yield.sector;
          break;
        case 'barangay':
          extracted['barangay'] = yield.barangay;
          break;
        default:
          extracted[field] = null;
      }
    }
    
    return extracted;
  }
  
  List<String> _extractRequiredFieldsFromPrompt(String message) {
    final lowerMessage = message.toLowerCase();
    final requiredFields = <String>{'id', 'productName', 'harvestDate'};
    
    if (_hasAnyKeyword(lowerMessage, _volumeKeywords)) {
      requiredFields.addAll(['volume', 'hectare']);
    }
    
    if (_hasAnyKeyword(lowerMessage, _areaKeywords)) {
      requiredFields.addAll(['hectare', 'areaHarvested']);
    }
    
    if (_hasAnyKeyword(lowerMessage, _valueKeywords)) {
      requiredFields.add('value');
    }
    
    if (_hasAnyKeyword(lowerMessage, _statusKeywords)) {
      requiredFields.add('status');
    }
    
    if (_hasAnyKeyword(lowerMessage, _locationKeywords)) {
      requiredFields.addAll(['farmName', 'barangay', 'sector']);
    }
    
    if (_hasAnyKeyword(lowerMessage, ['farmer', 'magsasaka'])) {
      requiredFields.add('farmerName');
    }
    
    return requiredFields.toList();
  }
  
  // IMPROVED: Better debug info
  Map<String, dynamic> getDebugInfo() {
    return {
      'hasYieldData': _hasYieldData,
      'dataCount': _availableYieldData?.length ?? 0,
      'cachedRecords': _recentYieldDataCache.length,
      'lastUpdate': _lastYieldDataUpdate?.toIso8601String(),
      'confidenceThreshold': _keywordConfidenceThreshold,
      'maxRecords': _maxYieldRecordsToAttach,
      'keywordFrequency': _yieldKeywordFrequency,
      'categoryWeights': _categoryWeights,
    };
  }
}