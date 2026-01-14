 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
 

// NASA POWER Soil Data Model
class NasaSoilData {
  final Map<String, List<double>> soilMoisture;
  final Map<String, List<double>> soilTemperature;
  final Map<String, List<double>> precipitation;
  final Map<String, List<double>> evapotranspiration;
  final Map<String, List<double>> solarRadiation;
  final List<String> dates;

  NasaSoilData({
    required this.soilMoisture,
    required this.soilTemperature,
    required this.precipitation,
    required this.evapotranspiration,
    required this.solarRadiation,
    required this.dates,
  });

 



factory NasaSoilData.fromJson(Map<String, dynamic> json) {
  final parameters = json['properties']['parameter'];
  
  // Get all dates from the API response
  final firstParam = parameters.values.first as Map<String, dynamic>;
  final allDates = firstParam.keys.toList()..sort();
  
  // Find dates where ALL parameters have valid data (not -999)
  final validDates = allDates.where((date) {
    return parameters.values.every((paramData) {
      if (paramData is Map<String, dynamic>) {
        final value = paramData[date];
        if (value is num) {
          final doubleVal = value.toDouble();
          return doubleVal != -999 && doubleVal != -999.0 && doubleVal != -9999;
        }
      }
      return false;
    });
  }).toList();
   
  // Extract values only for valid dates
  return NasaSoilData(
    soilMoisture: _extractParameterForDates(parameters, 'GWETROOT', validDates),
    soilTemperature: _extractParameterForDates(parameters, 'TS', validDates),
    precipitation: _extractParameterForDates(parameters, 'PRECTOTCORR', validDates),
    evapotranspiration: _extractParameterForDates(parameters, 'EVPTRNS', validDates),
    solarRadiation: _extractParameterForDates(parameters, 'ALLSKY_SFC_SW_DWN', validDates),
    dates: validDates,
  );
}

static Map<String, List<double>> _extractParameterForDates(
  Map<String, dynamic> parameters,
  String key,
  List<String> validDates,
) {
  if (!parameters.containsKey(key)) {
    return {key: []};
  }
  
  final paramData = parameters[key] as Map<String, dynamic>;
  final values = validDates.map((date) {
    final value = paramData[date];
    return value is num ? value.toDouble() : 0.0;
  }).toList();
  
  return {key: values};
}



  // Helper methods to get latest values
  double get latestSoilMoisture => soilMoisture.values.first.isNotEmpty 
      ? soilMoisture.values.first.last : 0.0;
  
  double get latestSoilTemperature => soilTemperature.values.first.isNotEmpty 
      ? soilTemperature.values.first.last : 0.0;
  
  double get latestPrecipitation => precipitation.values.first.isNotEmpty 
      ? precipitation.values.first.last : 0.0;
  
  double get latestEvapotranspiration => evapotranspiration.values.first.isNotEmpty 
      ? evapotranspiration.values.first.last : 0.0;
  
  double get latestSolarRadiation => solarRadiation.values.first.isNotEmpty 
      ? solarRadiation.values.first.last : 0.0;

  // Calculate averages for the period
  double get avgSoilMoisture => _calculateAverage(soilMoisture.values.first);
  double get avgSoilTemperature => _calculateAverage(soilTemperature.values.first);
  double get totalPrecipitation => _calculateSum(precipitation.values.first);
  
  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }
  
  double _calculateSum(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b);
  }
}

// Main Soil Chip Widget
class SoilDataChip extends StatefulWidget {
  final LatLng location;
  final VoidCallback? onSoilTap;
  final bool showModalOnTap;

  const SoilDataChip({
    super.key,
    required this.location,
    this.onSoilTap,
    this.showModalOnTap = true,
  });

  @override
  State<SoilDataChip> createState() => _SoilDataChipState();
}

class _SoilDataChipState extends State<SoilDataChip> {
  NasaSoilData? _soilData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
        
    _fetchSoilData();
  }

  @override
  void didUpdateWidget(SoilDataChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.location != oldWidget.location) {
 
      _fetchSoilData();
    }
  }





Future<void> _fetchSoilData() async {
  // Check if widget is still mounted before starting
  if (!mounted) return;
  
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    // Get date range (last 7 days)
    final endDate = DateTime.now().subtract(const Duration(days: 7));
    final startDate = endDate.subtract(const Duration(days: 7));
    final dateFormat = DateFormat('yyyyMMdd');
    // final endDate = DateTime.now();
    // final startDate = endDate.subtract(const Duration(days: 7));
    // final dateFormat = DateFormat('yyyyMMdd');
    
    final url = Uri.parse(
      'https://power.larc.nasa.gov/api/temporal/daily/point?'
      'parameters=GWETROOT,TS,PRECTOTCORR,EVPTRNS,ALLSKY_SFC_SW_DWN&'
      'community=AG&'
      'longitude=${widget.location.longitude}&'
      'latitude=${widget.location.latitude}&'
      'start=${dateFormat.format(startDate)}&'
      'end=${dateFormat.format(endDate)}&'
      'format=JSON'
    );

 

    final response = await http.get(url);

    // Check if widget is still mounted before updating state
    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('properties') && 
          data['properties'].containsKey('parameter')) {
        
        final parameters = data['properties']['parameter'];
        
        // Check each parameter for -999 values
        parameters.forEach((key, value) {
          if (value is Map) {
            // Check for -999 specifically
            final hasMissing = value.values.any((v) => v == -999 || v == -999.0);
            if (hasMissing) {
             
            }
          }
        });
      }
      
      setState(() {
        _soilData = NasaSoilData.fromJson(data);
        _isLoading = false;
      });
    } else { 
      
      if (mounted) {
        setState(() {
          _error = 'Failed to load soil data (${response.statusCode})';
          _isLoading = false;
        });
      }
    }
  } catch (e) { 
    
    // Check if widget is still mounted before updating state
    if (mounted) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }
}






  void _showSoilModal(BuildContext context) {
    if (widget.onSoilTap != null) {
      widget.onSoilTap!();
    }
    
    // Using the provided ModalDialog
    ModalDialog.show(
      context: context,
      title: 'Soil & Agricultural Data',
      showTitle: true,
      showCancel: true,
      showFooter: false,
        modalType: MediaQuery.of(context).size.width < 600 
      ? ModalType.large 
      : ModalType.medium, 
      child: _buildSoilModalContent(),
      onSaveTap: () {
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildSoilModalContent() {
    if (_isLoading) {
      return _buildLoadingIndicator();
    } else if (_error != null) {
      return _buildErrorIndicator(_error!);
    } else if (_soilData != null) {
      return _buildSoilDataContent(_soilData!);
    }
    return const Text('No soil data available');
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(), 
            
          ],
        ),
      ),
    );
  }

  Widget _buildErrorIndicator(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

  }















Widget _buildSoilDataContent(NasaSoilData soilData) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern Header with Gradient
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                ? [Colors.brown.shade800, Colors.brown.shade900]
                : [Colors.brown.shade600, Colors.brown.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.terrain,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agricultural Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NASA POWER • Last 7 days',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Key Metrics Grid
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.water_drop,
                label: 'Soil Moisture',
                value: '${(soilData.latestSoilMoisture * 100).toStringAsFixed(1)}%',
                color: Colors.blue,
                status: _getSoilMoistureStatus(soilData.latestSoilMoisture),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.thermostat,
                label: 'Temperature',
                value: '${soilData.latestSoilTemperature.toStringAsFixed(1)}°C',
                color: Colors.orange,
                status: _getSoilTemperatureStatus(soilData.latestSoilTemperature),
                isDark: isDark,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Detailed Metrics Section
        Text(
          'Detailed Metrics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        _buildModernDataRow(
          icon: Icons.water_drop_outlined,
          title: 'Root Zone Moisture',
          value: '${(soilData.latestSoilMoisture * 100).toStringAsFixed(1)}%',
          subtitle: 'Avg: ${(soilData.avgSoilMoisture * 100).toStringAsFixed(1)}%',
          color: Colors.blue,
          isDark: isDark,
        ),

        const SizedBox(height: 8),

        _buildModernDataRow(
          icon: Icons.umbrella,
          title: 'Precipitation',
          value: '${soilData.totalPrecipitation.toStringAsFixed(1)} mm',
          subtitle: 'Total over 7 days',
          color: Colors.cyan,
          isDark: isDark,
        ),

        const SizedBox(height: 8),

        _buildModernDataRow(
          icon: Icons.air,
          title: 'Evapotranspiration',
          value: '${soilData.latestEvapotranspiration.toStringAsFixed(2)} mm/day',
          subtitle: 'Water loss rate',
          color: Colors.teal,
          isDark: isDark,
        ),

        const SizedBox(height: 8),

        _buildModernDataRow(
          icon: Icons.wb_sunny,
          title: 'Solar Radiation',
          value: '${soilData.latestSolarRadiation.toStringAsFixed(1)} kWh/m²',
          subtitle: 'Daily average',
          color: Colors.amber,
          isDark: isDark,
        ),

        const SizedBox(height: 20),

        // Smart Recommendations
        _buildModernRecommendations(soilData, isDark),
      ],
    ),
  );
}

Widget _buildMetricCard({
  required IconData icon,
  required String label,
  required String value,
  required Color color,
  required String status,
  required bool isDark,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: color.withOpacity(isDark ? 0.3 : 0.2),
        width: 1,
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
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    ),
  );
}

Widget _buildModernDataRow({
  required IconData icon,
  required String title,
  required String value,
  required String subtitle,
  required Color color,
  required bool isDark,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: isDark 
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.02),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark 
          ? Colors.white.withOpacity(0.08)
          : Colors.black.withOpacity(0.05),
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}

Widget _buildModernRecommendations(NasaSoilData soilData, bool isDark) {
  final recommendations = <Map<String, dynamic>>[];
  
  // Soil moisture recommendations
  if (soilData.latestSoilMoisture < 0.2) {
    recommendations.add({
      'icon': Icons.water_drop,
      'text': 'Low soil moisture - Consider irrigation',
      'type': 'warning',
    });
  } else if (soilData.latestSoilMoisture > 0.8) {
    recommendations.add({
      'icon': Icons.warning_amber,
      'text': 'High soil moisture - Monitor for waterlogging',
      'type': 'warning',
    });
  } else {
    recommendations.add({
      'icon': Icons.check_circle,
      'text': 'Soil moisture is optimal for most crops',
      'type': 'success',
    });
  }

  // Temperature recommendations
  if (soilData.latestSoilTemperature < 10) {
    recommendations.add({
      'icon': Icons.ac_unit,
      'text': 'Soil too cold - Wait for warming before planting',
      'type': 'info',
    });
  } else if (soilData.latestSoilTemperature > 35) {
    recommendations.add({
      'icon': Icons.local_fire_department,
      'text': 'High temperature - Consider mulching',
      'type': 'warning',
    });
  }

  // Precipitation recommendations
  if (soilData.totalPrecipitation > 50) {
    recommendations.add({
      'icon': Icons.umbrella,
      'text': 'Good rainfall - Reduce irrigation',
      'type': 'success',
    });
  } else if (soilData.totalPrecipitation < 10) {
    recommendations.add({
      'icon': Icons.wb_sunny,
      'text': 'Low rainfall - Increase irrigation frequency',
      'type': 'warning',
    });
  }

  if (recommendations.isEmpty) {
    recommendations.add({
      'icon': Icons.check_circle_outline,
      'text': 'All conditions within normal range',
      'type': 'success',
    });
  }

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isDark 
          ? [Colors.green.shade900.withOpacity(0.3), Colors.green.shade800.withOpacity(0.2)]
          : [Colors.green.shade50, Colors.green.shade100],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark ? Colors.green.shade700.withOpacity(0.3) : Colors.green.shade200,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.eco,
                size: 18,
                color: isDark ? Colors.green.shade300 : Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Smart Recommendations',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.green.shade200 : Colors.green.shade900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...recommendations.map((rec) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                rec['icon'],
                size: 18,
                color: _getRecommendationColor(rec['type'], isDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rec['text'],
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white.withOpacity(0.9) : Colors.green.shade900,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    ),
  );
}

Color _getRecommendationColor(String type, bool isDark) {
  switch (type) {
    case 'warning':
      return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
    case 'success':
      return isDark ? Colors.green.shade300 : Colors.green.shade700;
    case 'info':
      return isDark ? Colors.blue.shade300 : Colors.blue.shade700;
    default:
      return isDark ? Colors.white70 : Colors.black54;
  }
}



















  String _getSoilMoistureStatus(double moisture) {
    if (moisture < 0.2) return 'Dry';
    if (moisture < 0.4) return 'Low';
    if (moisture < 0.7) return 'Good';
    if (moisture < 0.9) return 'High';
    return 'Wet';
  }

  String _getSoilTemperatureStatus(double temp) {
    if (temp < 10) return 'Cold';
    if (temp < 20) return 'Cool';
    if (temp < 30) return 'Optimal';
    if (temp < 35) return 'Warm';
    return 'Hot';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'dry':
      case 'cold':
      case 'hot':
        return Colors.red.shade600;
      case 'low':
      case 'cool':
      case 'warm':
        return Colors.orange.shade600;
      case 'good':
      case 'optimal':
        return Colors.green.shade600;
      case 'high':
      case 'wet':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
void dispose() {
  // Clean up any resources if needed
  // Note: The http package doesn't have request cancellation in this simple form
  // If you need cancellation, consider using a package like Dio which supports cancellation
  super.dispose();
}




@override
Widget build(BuildContext context) {
  

  return GestureDetector(
    onTap: () {
      if (widget.showModalOnTap) {
        _showSoilModal(context);
      }
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),  
      decoration: BoxDecoration(
        // Match WeatherChip styling with brown theme 
        color:  Theme.of(context).brightness == Brightness.dark
            ?  Theme.of(context).cardTheme.color  :     Colors.brown.shade50.withOpacity(0.9)   , 
        borderRadius: BorderRadius.circular(20), // Pill shape like WeatherChip
        border: Border.all(
          color:
          
          
           Colors.brown.shade300.withOpacity(0.2), // Subtle border
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: _buildChipContent(),
    ),
  );
}

Widget _buildChipContent() {
  final theme = Theme.of(context);
  

  if (_isLoading) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).brightness == Brightness.dark ? Colors.white:  Colors.brown.shade700),
          ),
        ),
        const SizedBox(width: 6), // Match WeatherChip spacing
       
      ],
    );
  }

  if (_error != null) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 16, color: Colors.red),
        const SizedBox(width: 6), // Match WeatherChip spacing
        Text(
          'Error',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  if (_soilData == null) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.terrain,
          size: 16,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white: Colors.brown.shade700.withOpacity(0.7)    ,
        ),
        const SizedBox(width: 6),
        Text(
          'Soil',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white: Colors.brown.shade700.withOpacity(0.8),
            fontWeight: FontWeight.normal,
          ),
        ),
        if (widget.showModalOnTap) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.info_outline,
            size: 14,
            color:Theme.of(context).brightness == Brightness.dark ? Colors.white:  Colors.brown.shade700.withOpacity(0.5),
          ),
        ],
      ],
    );
  }

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Simple icon like WeatherChip (no container)
      Icon(
        Icons.terrain,
        size: 16,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white: Colors.brown.shade700,
      ),
      const SizedBox(width: 6),
      // Simplified display - just moisture like WeatherChip shows temperature
      Text(
        '${(_soilData!.latestSoilMoisture * 100).toStringAsFixed(0)}%',
        style: theme.textTheme.labelSmall?.copyWith(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white: Colors.brown.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
      if (widget.showModalOnTap) ...[
        const SizedBox(width: 4),
        Icon(
          Icons.info_outline,
          size: 14,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white:  Colors.brown.shade700.withOpacity(0.7),
        ),
      ],
    ],
  );
}

 

}

 


 
// ModalDialog class (copied from your provided code)
enum ModalType { small, medium, large }

class ModalDialog {
  static show({
    required BuildContext context,
    String? title,
    bool? showTitle = false,
    bool? showTitleDivider = false,
    Alignment? titleAlign = Alignment.center,
    Widget? child,
    Widget? footer,
    bool? showFooter = false,
    bool? showCancel = true,
    ModalType modalType = ModalType.large,
    double? width,
    double? maxHeight,
    GestureTapCallback? onCancelTap,
    GestureTapCallback? onSaveTap,
  }) {
    // Get screen dimensions
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Set default max height if not provided (70% of screen height)
    maxHeight ??= screenHeight * 0.7;

    // Adjust modal width for mobile devices
    if (width == null) {
      if (modalType == ModalType.large) {
        width = screenWidth < 600 ? screenWidth * 0.9 : screenWidth * 0.6;
      } else if (modalType == ModalType.medium) {
        width = screenWidth < 600 ? screenWidth * 0.8 : screenWidth * 0.4;
      } else if (modalType == ModalType.small) {
        width = screenWidth < 600 ? screenWidth * 0.7 : screenWidth * 0.28;
      }
    }

    return showDialog(
      context: context,
      builder: (context) { 
        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(screenWidth < 600 ? 10 : 20),
              child: Material(
                type: MaterialType.transparency,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: width!,
                    maxHeight: maxHeight!,
                  ),
                  child: Container(
                    
                    decoration: BoxDecoration(
                      color:     Theme.of(context).cardTheme.color,  
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showTitle ?? false)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth < 600 ? 10 : 20,
                            ),
                            alignment: Alignment.center,
                            height: 50,
                            child: Stack(
                              children: [
                                if (title != null)
                                  Align(
                                    alignment: titleAlign!,
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: screenWidth < 600 ? 14 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: InkWell(
                                    child: const Icon(Icons.close),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (showTitleDivider ?? false)
                          const Divider(
                            thickness: 0,
                            height: 0.2,
                          ),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding:
                                  EdgeInsets.all(screenWidth < 600 ? 10 : 20),
                              child: child,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (showFooter ?? true)
                          if (footer != null)
                            footer
                          else
                            Container(
                              margin: EdgeInsets.only(
                                left: screenWidth < 600 ? 10 : 20,
                                right: screenWidth < 600 ? 10 : 20,
                                bottom: screenWidth < 600 ? 10 : 20,
                              ),
                              child: Row(
                                children: [
                                  if (showCancel!) const Spacer(),
                                  if (showCancel)
                                    SizedBox(
                                      width: 120,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          if (onCancelTap != null) {
                                            onCancelTap();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.black,
                                          elevation: 0,
                                        ),
                                        child: const Text('Close'),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                      ],
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