import 'dart:async';
import 'dart:io';

import 'package:flareline/pages/map/map_widget/polygon_manager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';

import 'package:flareline/pages/map/map_widget/farm_service.dart';
import 'package:flareline/pages/map/map_widget/map_panel/farm_weather/weather_model.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'weather_modal_content.dart'; 

class WeatherChip extends StatefulWidget {
  final LatLng location;
  final String apiKey;
  final double left;
   final double width;
  final VoidCallback? onWeatherTap;
  final PolygonData? polygonData;
  final FarmService farmService; 
  final bool showModalOnTap;

  const WeatherChip({
    super.key,
    required this.location,
    this.polygonData,
    required this.apiKey,
    required this.farmService,
    this.onWeatherTap,
    this.showModalOnTap = true,
     required this.left,
      required this.width,
  });

  @override
  State<WeatherChip> createState() => _WeatherChipState();
}

class _WeatherChipState extends State<WeatherChip> {

  WeatherData? _weatherData;
  AirQualityData? _airQualityData;
  List<ForecastItem>? _forecastData;
  List<DailyForecast>? _dailyForecast;
  bool _isLoadingWeather = false;
  bool _isLoadingAirQuality = false;
  bool _isLoadingForecast = false;
  String? _weatherError;
  String? _airQualityError;
  String? _forecastError;

  // Add these new fields
  String? _reporterSummary;
  bool _isLoadingSummary = false;
  String? _summaryError;
  bool _isSummaryReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.apiKey.isNotEmpty) {
      _fetchWeatherData();
      _fetchAirQualityData();
      _fetchForecastData();
    }
  }





Future<void> _generateReporterSummary() async {
  // print('🎯 [_generateReporterSummary] Method called');
  
  if (_weatherData == null) {
    // print('❌ No weather data available');
    if (mounted) {
      setState(() {
        _summaryError = 'Weather data not available yet';
        _isLoadingSummary = false;
      });
    }
    return;
  }

  // print('✅ Weather data available');
  
  // Reset previous state
  if (mounted) {
    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
      _reporterSummary = null;
    });
  }
  
  try {
    final farmService = widget.farmService;
    
    final weatherMap = {
      'temperature': _weatherData!.temperature,
      'feelsLike': _weatherData!.feelsLike,
      'description': _weatherData!.description,
      'humidity': _weatherData!.humidity,
      'windSpeed': _weatherData!.windSpeed,
      'visibility': _weatherData!.visibility,
      'clouds': _weatherData!.clouds,
      'rain1h': _weatherData!.rain1h,
    };

    List<Map<String, dynamic>>? forecastMap;
    if (_dailyForecast != null && _dailyForecast!.isNotEmpty) {
      forecastMap = _dailyForecast!
          .take(2)
          .map((f) => ({
                'tempMax': f.tempMax,
                'tempMin': f.tempMin,
                'description': f.description,
              }))
          .toList();
    }

    Map<String, dynamic>? airQualityMap;
    if (_airQualityData != null) {
      airQualityMap = {
        'quality': _airQualityData!.quality,
        'aqi': _airQualityData!.aqi,
      };
    }

    // print('🚀 Calling farmService.generateWeatherSummary...');
    final startTime = DateTime.now();
    
    final result = await farmService.generateWeatherSummary(
      weatherData: weatherMap,
      forecastData: forecastMap,
      airQualityData: airQualityMap,
      products: widget.polygonData?.products, 
    );

    final duration = DateTime.now().difference(startTime);
    // print('✅ Completed in ${duration.inMilliseconds}ms');

    if (result['success'] == true) {
      // print('🎉 Summary generation successful');
      final summary = result['summary'] as String?;
      
      if (summary != null && summary.isNotEmpty) {
        // print('📄 Summary length: ${summary.length} characters');
        
        if (mounted) {
          setState(() {
            _reporterSummary = summary;
            _isLoadingSummary = false;
            _summaryError = null;
          });
        }
      } else {
        // print('⚠️ Empty summary received');
        throw Exception('Received empty summary from server');
      }
    } else {
      final error = result['error'] ?? 'Unknown error';
      // print('❌ Summary generation failed: $error');
      throw Exception(error);
    }
  } catch (e, stackTrace) {
    // print('💥 Exception: $e');
    // print('📄 Stack trace: $stackTrace');
    
    String errorMessage;
    if (e is SocketException || e is TimeoutException || e is http.ClientException) {
      errorMessage = 'Network error: ${e.toString()}';
    } else if (e.toString().contains('Failed to generate summary')) {
      errorMessage = e.toString();
    } else {
      errorMessage = 'Failed to generate summary. Please try again.';
    }
    
    if (mounted) {
      setState(() {
        _summaryError = errorMessage;
        _isLoadingSummary = false;
        _reporterSummary = null;
      });
    }
  }
  
  print('🏁 Method completed');
  print('📊 Final state:');
  print('  - isLoadingSummary: $_isLoadingSummary');
  print('  - hasSummary: ${_reporterSummary != null}');
  print('  - hasError: ${_summaryError != null}');
}








// Helper function to get minimum of two values
int min(int a, int b) => a < b ? a : b;




  @override
  void didUpdateWidget(WeatherChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.location != oldWidget.location ||
        widget.apiKey != oldWidget.apiKey) {
      _fetchWeatherData();
      _fetchAirQualityData();
      _fetchForecastData();

      // Reset summary when location changes
      if (mounted) {
        setState(() {
          _reporterSummary = null;
          _summaryError = null;
        });
      }
    }
  }



Future<void> _fetchWeatherData() async {
  if (widget.apiKey.isEmpty || !mounted) return;

  if (mounted) {
    setState(() {
      _isLoadingWeather = true;
      _weatherError = null;
    });
  }

  try {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${widget.location.latitude}&lon=${widget.location.longitude}&units=metric&appid=${widget.apiKey}');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (mounted) {
        setState(() {
          _weatherData = WeatherData.fromJson(data);
          _isLoadingWeather = false;
        });
        
        // Fetch UV Index after weather data is loaded
        _fetchUVIndex();
      }
    } else {
      if (mounted) {
        setState(() {
          _weatherError = 'Failed to load weather';
          _isLoadingWeather = false;
        });
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _weatherError = 'Error: $e';
        _isLoadingWeather = false;
      });
    }
  }
}


  Future<void> _fetchAirQualityData() async {
    if (widget.apiKey.isEmpty || !mounted) return;

    if (mounted) {
      setState(() {
        _isLoadingAirQuality = true;
        _airQualityError = null;
      });
    }

    try {
      final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/air_pollution?lat=${widget.location.latitude}&lon=${widget.location.longitude}&appid=${widget.apiKey}');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (mounted) {
          setState(() {
            _airQualityData = AirQualityData.fromJson(data);
            _isLoadingAirQuality = false;
          });
        }

        // Check if we should trigger summary generation now
        // if (mounted && _weatherData != null && _forecastData != null) {
        //   _generateReporterSummary();
        // }
      } else {
        if (mounted) {
          setState(() {
            _airQualityError = 'Failed to load air quality';
            _isLoadingAirQuality = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _airQualityError = 'Error: $e';
          _isLoadingAirQuality = false;
        });
      }
    }
  }




Future<void> _fetchUVIndex() async {
  if (widget.apiKey.isEmpty || !mounted || _weatherData == null) return;

  try {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/uvi?lat=${widget.location.latitude}&lon=${widget.location.longitude}&appid=${widget.apiKey}');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final uvIndex = data['value']?.toDouble();

      if (mounted && uvIndex != null) {
        setState(() {
          // Update the existing weather data with UV index
          if (_weatherData != null) {
            _weatherData = WeatherData(
              temperature: _weatherData!.temperature,
              feelsLike: _weatherData!.feelsLike,
              condition: _weatherData!.condition,
              description: _weatherData!.description,
              humidity: _weatherData!.humidity,
              windSpeed: _weatherData!.windSpeed,
              windDeg: _weatherData!.windDeg,
              pressure: _weatherData!.pressure,
              clouds: _weatherData!.clouds,
              rain1h: _weatherData!.rain1h,
              rain3h: _weatherData!.rain3h,
              visibility: _weatherData!.visibility,
              icon: _weatherData!.icon,
              uvi: uvIndex, // Add UV index here
              sunrise: _weatherData!.sunrise,
              sunset: _weatherData!.sunset,
            );
          }
        });
      }
    }
  } catch (e) {
    print('Error fetching UV Index: $e');
    // Don't show error to user, UV index is optional
  }
}



Future<void> _fetchForecastData() async {
  if (widget.apiKey.isEmpty || !mounted) return;

  if (mounted) {
    setState(() {
      _isLoadingForecast = true;
      _forecastError = null;
    });
  }

  try {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=${widget.location.latitude}&lon=${widget.location.longitude}&units=metric&appid=${widget.apiKey}');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final List<dynamic> forecastList = data['list'];
      final forecasts =
          forecastList.map((item) => ForecastItem.fromJson(item)).toList();
      final daily = _processDailyForecast(forecasts);

      if (mounted) {
        setState(() {
          _forecastData = forecasts;
          _dailyForecast = daily;
          _isLoadingForecast = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _forecastError = 'Failed to load forecast';
          _isLoadingForecast = false;
        });
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _forecastError = 'Error: $e';
        _isLoadingForecast = false;
      });
    }
  }
}



  List<DailyForecast> _processDailyForecast(List<ForecastItem> forecasts) {
    final Map<String, List<ForecastItem>> groupedByDay = {};

    for (final forecast in forecasts) {
      final dateKey =
          '${forecast.dateTime.year}-${forecast.dateTime.month}-${forecast.dateTime.day}';
      groupedByDay.putIfAbsent(dateKey, () => []).add(forecast);
    }

    final dailyForecasts = <DailyForecast>[];

    groupedByDay.forEach((dateKey, dayForecasts) {
      final date = dayForecasts.first.dateTime;
      final tempMin =
          dayForecasts.map((f) => f.tempMin).reduce((a, b) => a < b ? a : b);
      final tempMax =
          dayForecasts.map((f) => f.tempMax).reduce((a, b) => a > b ? a : b);
      final avgHumidity =
          dayForecasts.map((f) => f.humidity).reduce((a, b) => a + b) /
              dayForecasts.length;
      final avgWindSpeed =
          dayForecasts.map((f) => f.windSpeed).reduce((a, b) => a + b) /
              dayForecasts.length;

      // Use midday forecast for condition/description/icon
      final middayForecast = dayForecasts.firstWhere(
        (f) => f.dateTime.hour >= 12 && f.dateTime.hour <= 15,
        orElse: () => dayForecasts[dayForecasts.length ~/ 2],
      );

      dailyForecasts.add(DailyForecast(
        date: date,
        tempMin: tempMin,
        tempMax: tempMax,
        condition: middayForecast.condition,
        description: middayForecast.description,
        avgHumidity: avgHumidity,
        avgWindSpeed: avgWindSpeed,
        icon: middayForecast.icon,
      ));
    });

    return dailyForecasts.take(5).toList();
  }

  void _showWeatherModal(BuildContext context) {
    // Check if summary is ready before opening modal
    if (!_isSummaryReady && _isLoadingSummary) {
      return; // Don't open modal
    }

    // If summary failed to generate but we have weather data, still allow opening
    if (_summaryError != null && _weatherData != null) {}

    if (widget.onWeatherTap != null) {
      widget.onWeatherTap!();
    }

 
 final screenWidth = MediaQuery.of(context).size.width;
final modalWidth = screenWidth < 600 ? screenWidth * 0.8 : screenWidth * 0.4;

// final modalWidth = widget.width < 600 ? widget.width * 0.8 : widget.width * 0.4;

// Then calculate the left position to center it within the map widget
final leftPosition = widget.left + (widget.width - modalWidth) / 2;
  

ModalDialog.show(
  context: context,
  title: 'Weather Information',
  showTitle: true,
  showCancel: false,
  showFooter: false,
  // Use conditional position - provide a centered position for mobile
  // position: MediaQuery.of(context).size.width >= 600 
  //     ? ModalPosition(
  //         left: leftPosition,
  //         top: 100,
  //       )
  //     : ModalPosition.center(), // Assuming there's a centered constructor
  
  modalType: MediaQuery.of(context).size.width < 600 
      ? ModalType.large 
      : ModalType.medium,
  child: WeatherModalContent(
    weatherData: _weatherData,
    airQualityData: _airQualityData,
    dailyForecast: _dailyForecast,
    reporterSummary: _reporterSummary,
    isLoadingWeather: _isLoadingWeather,
    isLoadingForecast: _isLoadingForecast,
    isLoadingSummary: _isLoadingSummary,
    weatherError: _weatherError,
    forecastError: _forecastError,
    summaryError: _summaryError,
    isSummaryReady: _isSummaryReady,
    onGenerateSummary: () async {
      await _generateReporterSummary();
      Navigator.of(context).pop();
      _showWeatherModal(context);
    },
    hasMinimalWeatherData: _weatherData != null,
  ),
  onSaveTap: () {
    Navigator.of(context).pop();
  },
);
  
  }

  @override
  Widget build(BuildContext context) {
    return WeatherChipUI(
      weatherData: _weatherData,
      showModalOnTap: widget.showModalOnTap,
      onTap: widget.showModalOnTap ? () => _showWeatherModal(context) : null,
      isLoadingWeather: _isLoadingWeather,
      isLoadingAirQuality: _isLoadingAirQuality,
      isLoadingForecast: _isLoadingForecast,
      isLoadingSummary: _isLoadingSummary,
    );
  }
}





 
class WeatherChipUI extends StatelessWidget {
  final WeatherData? weatherData;
  final bool showModalOnTap;
  final VoidCallback? onTap;
  final bool isLoadingWeather;
  final bool isLoadingAirQuality;
  final bool isLoadingForecast;
  final bool isLoadingSummary;

  const WeatherChipUI({
    super.key,
    required this.weatherData,
    required this.showModalOnTap,
    this.onTap,
    required this.isLoadingWeather,
    required this.isLoadingAirQuality,
    required this.isLoadingForecast,
    required this.isLoadingSummary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).cardTheme.color
              : colorScheme.primaryContainer.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Consolidated loading indicator - check all loading states
            if (isLoadingWeather || isLoadingAirQuality || isLoadingForecast || isLoadingSummary)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              )
            else if (weatherData != null)
              Icon(
                WeatherUIHelpers.getWeatherIcon(weatherData!.condition),
                size: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : colorScheme.primary,
              )
            else
              Icon(
                Icons.cloud,
                size: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : colorScheme.onSurface.withOpacity(0.7),
              ),

            const SizedBox(width: 6),

            // Show temperature only when weather data is loaded and not loading anything
            if (!isLoadingWeather && 
                !isLoadingAirQuality && 
                !isLoadingForecast && 
                !isLoadingSummary && 
                weatherData != null)
              Text(
                '${weatherData!.temperature.toStringAsFixed(1)}°C',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              )
            // Show "Weather" text when no data but not loading
            else if (!isLoadingWeather && 
                     !isLoadingAirQuality && 
                     !isLoadingForecast && 
                     !isLoadingSummary)
              Text(
                'Weather',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : colorScheme.onSurface.withOpacity(0.8),
                  fontWeight: FontWeight.normal,
                ),
              )
            // When loading, show no text (just the spinner)
            else
              const SizedBox(width: 0),

            if (showModalOnTap) ...[
              const SizedBox(width: 4),
              // Info icon - only show when not loading
              if (!isLoadingWeather && 
                  !isLoadingAirQuality && 
                  !isLoadingForecast && 
                  !isLoadingSummary)
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : colorScheme.onSurface.withOpacity(0.8),
                )
              // When loading, show no icon
              else
                const SizedBox(width: 14, height: 14),
            ],
          ],
        ),
      ),
    );
  }
}