import 'package:flareline/pages/map/map_widget/farm_service.dart';
import 'package:flareline/pages/map/map_widget/map_panel/farm_weather/weather_model.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';

class WeatherChip extends StatefulWidget {
  final LatLng location;
  final String apiKey;
  final VoidCallback? onWeatherTap;
  final FarmService farmService;
  final bool showModalOnTap;

  const WeatherChip({
    super.key,
    required this.location,
    required this.apiKey,
    required this.farmService,
    this.onWeatherTap,
    this.showModalOnTap = true,
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
 

    // First check if we're mounted
    if (!mounted) {
      
      return;
    }

    // Check if we have minimal required data
    if (_weatherData == null) {
    
      if (mounted) {
        setState(() {
          _summaryError = 'Weather data not available yet';
          _isLoadingSummary = false;
        });
      }
      return;
    }
 

    if (mounted) {
      setState(() {
        _isSummaryReady = false;
        _isLoadingSummary = true;
        _summaryError = null;
      });
    }
    try {
      final farmService = widget.farmService;

    

      // Prepare weather data
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

 

      // Prepare forecast data (can be null)
      List<Map<String, dynamic>>? forecastMap;
      if (_dailyForecast != null && _dailyForecast!.isNotEmpty) {
        forecastMap = _dailyForecast!
            .take(2)
            .map((f) => {
                  'tempMax': f.tempMax,
                  'tempMin': f.tempMin,
                  'description': f.description,
                })
            .toList();
      } else {
      }

      // Prepare air quality data (can be null)
      Map<String, dynamic>? airQualityMap;
      if (_airQualityData != null) {
        airQualityMap = {
          'quality': _airQualityData!.quality,
          'aqi': _airQualityData!.aqi,
        };
      } else {
      }

      final result = await farmService.generateWeatherSummary(
        weatherData: weatherMap,
        forecastData: forecastMap,
        airQualityData: airQualityMap,
      );


      if (!mounted) {
        return;
      }

      if (result['success']) {
        setState(() {
          _reporterSummary = result['summary'];
          _isLoadingSummary = false;
          _isSummaryReady = true; // SET READY STATE
        });
      } else {
        setState(() {
          _summaryError = 'Failed to generate summary: ${result['error']}';
          _isLoadingSummary = false;
          _isSummaryReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _summaryError = 'Failed to generate summary: ${e.toString()}';
          _isLoadingSummary = false;
        });
      }
    }
  }




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
        }

        // Debug prints to see what data we have

        // Auto-generate summary after all data is loaded
        if (mounted && _forecastData != null && _airQualityData != null) {
           _generateReporterSummary();
        } else {
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

        if (mounted && _weatherData != null && _forecastData != null) {
           _generateReporterSummary();
        }
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

        // Check if we should trigger summary generation now

        if (mounted && _weatherData != null && _airQualityData != null) {
           _generateReporterSummary();
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

    ModalDialog.show(
      context: context,
      title: 'Weather Information',
      showTitle: true,
      showCancel: false,
      showFooter: false,
      modalType: ModalType.medium,
      child: _buildWeatherModalContent(),
      onSaveTap: () {
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildWeatherModalContent() {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Current'),
              Tab(text: 'Forecast'),
            ],
          ),
          SizedBox(
            height: 500,
            child: TabBarView(
              children: [
                _buildCurrentWeatherTab(),
                _buildForecastTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherTab() {
    if (_isLoadingWeather) {
      return _buildLoadingIndicator();
    } else if (_weatherError != null) {
      return _buildErrorIndicator(_weatherError!);
    } else if (_weatherData != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWeatherContent(_weatherData!),
          if (_airQualityData != null) ...[
            const SizedBox(height: 16),
            _buildAirQualitySection(_airQualityData!),
          ],

          const SizedBox(height: 16),
          // Add AI-generated summary at the top
          _buildReporterSummary(),
        ],
      );
    }
    return const Center(child: Text('No weather data available'));
  }



Widget _buildReporterSummary() {
  final theme = Theme.of(context);

  // Don't show anything if summary failed to generate
  if (_summaryError != null ||_reporterSummary == null  ) {
    return const SizedBox.shrink(); // Hide the entire section
  }

  // Only show if we have a summary or are loading/generating one
  if (_reporterSummary == null && !_isLoadingSummary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
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
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Weather Report',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              _generateReporterSummary();
            },
            icon: Icon(Icons.auto_awesome, size: 16),
            label: Text('Generate AI Summary'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // Show the summary section when we have content or are loading
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.blue.withOpacity(0.1),
          Colors.purple.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.blue.withOpacity(0.3),
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
                color: Colors.blue,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Weather Report',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingSummary)
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                'Generating weather report...',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          )
        else if (_reporterSummary != null)
          Text(
            _reporterSummary!,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
      ],
    ),
  );
}



  Widget _buildForecastTab() {
    if (_isLoadingForecast) {
      return _buildLoadingIndicator();
    } else if (_forecastError != null) {
      return _buildErrorIndicator(_forecastError!);
    } else if (_dailyForecast != null && _dailyForecast!.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '5-Day Forecast',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._dailyForecast!
              .map((daily) => _buildDailyForecastCard(daily))
              ,
        ],
      );
    }
    return const Center(child: Text('No forecast data available'));
  }

  Widget _buildDailyForecastCard(DailyForecast forecast) {
    final theme = Theme.of(context);
    final isToday = _isToday(forecast.date);
    final isTomorrow = _isTomorrow(forecast.date);

    String dayLabel;
    if (isToday) {
      dayLabel = 'Today';
    } else if (isTomorrow) {
      dayLabel = 'Tomorrow';
    } else {
      dayLabel = _formatDayOfWeek(forecast.date);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _formatDate(forecast.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            _getWeatherIcon(forecast.condition),
            size: 32,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${forecast.tempMax.toStringAsFixed(0)}°',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' / ${forecast.tempMin.toStringAsFixed(0)}°',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                Text(
                  forecast.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  String _formatDayOfWeek(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Loading weather data...'),
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
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(WeatherData weatherData) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main weather info
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getWeatherIcon(weatherData.condition),
                size: 32,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${weatherData.temperature.toStringAsFixed(1)}°C',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Feels like ${weatherData.feelsLike.toStringAsFixed(1)}°',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    weatherData.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),

        // Weather details grid
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildWeatherDetail(
              icon: Icons.water_drop,
              label: 'Humidity',
              value: '${weatherData.humidity}%',
            ),
            _buildWeatherDetail(
              icon: Icons.air,
              label: 'Wind',
              value: '${weatherData.windSpeed.toStringAsFixed(1)} m/s',
            ),
            _buildWeatherDetail(
              icon: Icons.compress,
              label: 'Pressure',
              value: '${weatherData.pressure} hPa',
            ),
            _buildWeatherDetail(
              icon: Icons.cloud,
              label: 'Clouds',
              value: '${weatherData.clouds}%',
            ),
            if (weatherData.rain1h != null)
              _buildWeatherDetail(
                icon: Icons.umbrella,
                label: 'Rain (1h)',
                value: '${weatherData.rain1h!.toStringAsFixed(1)} mm',
              ),
            _buildWeatherDetail(
              icon: Icons.visibility,
              label: 'Visibility',
              value: '${(weatherData.visibility / 1000).toStringAsFixed(1)} km',
            ),
          ],
        ),

        // Sunrise/Sunset
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSunInfo(
              icon: Icons.wb_sunny,
              label: 'Sunrise',
              time: _formatTime(weatherData.sunrise),
            ),
            Container(
              width: 1,
              height: 30,
              color: Colors.grey[300],
            ),
            _buildSunInfo(
              icon: Icons.nights_stay,
              label: 'Sunset',
              time: _formatTime(weatherData.sunset),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAirQualitySection(AirQualityData airQualityData) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: airQualityData.getColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: airQualityData.getColor().withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.air,
                size: 20,
                color: airQualityData.getColor(),
              ),
              const SizedBox(width: 8),
              Text(
                'Air Quality: ${airQualityData.quality}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: airQualityData.getColor(),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: airQualityData.getColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'AQI ${airQualityData.aqi}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildAirQualityDetail(
                  'PM2.5', '${airQualityData.pm2_5.toStringAsFixed(1)} μg/m³'),
              _buildAirQualityDetail(
                  'PM10', '${airQualityData.pm10.toStringAsFixed(1)} μg/m³'),
              _buildAirQualityDetail(
                  'NO₂', '${airQualityData.no2.toStringAsFixed(1)} μg/m³'),
              _buildAirQualityDetail(
                  'O₃', '${airQualityData.o3.toStringAsFixed(1)} μg/m³'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.blue.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSunInfo({
    required IconData icon,
    required String label,
    required String time,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.orange,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAirQualityDetail(String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }



@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return GestureDetector(
    onTap: () {
      if (widget.showModalOnTap) {
        _showWeatherModal(context);
      }
    },
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
          if (_isLoadingWeather || _isLoadingAirQuality || _isLoadingForecast || _isLoadingSummary)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          else if (_weatherData != null)
            Icon(
              _getWeatherIcon(_weatherData!.condition),
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
          if (!_isLoadingWeather && 
              !_isLoadingAirQuality && 
              !_isLoadingForecast && 
              !_isLoadingSummary && 
              _weatherData != null)
            Text(
              '${_weatherData!.temperature.toStringAsFixed(1)}°C',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            )
          // Show "Weather" text when no data but not loading
          else if (!_isLoadingWeather && 
                   !_isLoadingAirQuality && 
                   !_isLoadingForecast && 
                   !_isLoadingSummary)
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

          if (widget.showModalOnTap) ...[
            const SizedBox(width: 4),
            // Info icon - only show when not loading
            if (!_isLoadingWeather && 
                !_isLoadingAirQuality && 
                !_isLoadingForecast && 
                !_isLoadingSummary)
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

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
        return Icons.umbrella;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.blur_on;
      default:
        return Icons.wb_cloudy;
    }
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
