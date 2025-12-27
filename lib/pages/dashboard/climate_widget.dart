import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ClimateInfoWidget extends StatefulWidget {
  const ClimateInfoWidget({super.key});

  @override
  State<ClimateInfoWidget> createState() => _ClimateInfoWidgetState();
}

class _ClimateInfoWidgetState extends State<ClimateInfoWidget> {
  WeatherData? _weatherData;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _usingDummyData = false;
  bool _isDisposed = false;

  // Add dummy weather data
  final WeatherData _dummyWeatherData = WeatherData(
    temp: 28.0,
    feelsLike: 30.0,
    tempMin: 26.0,
    tempMax: 32.0,
    description: 'partly cloudy',
    icon: '02d',
    humidity: 65,
    windSpeed: 12.0,
    pressure: 1012,
  );

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _fetchWeatherData() async {
    _safeSetState(() {
      _isLoading = true;
      _usingDummyData = false;
    });

    const apiKey = '0e0d32c1dcc47a3adc567ec7923c2508';
    const city = 'San Pablo City';
    const countryCode = 'PH';
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city,$countryCode&units=metric&appid=$apiKey');

    try {
      final response = await http.get(url);

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        _safeSetState(() {
          _weatherData = WeatherData.fromJson(json.decode(response.body));
          _isLoading = false;
        });
      } else {
        _safeSetState(() {
          _errorMessage =
              'Failed to load weather data (Error ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_isDisposed) return;

      _safeSetState(() {
        _errorMessage = 'Connection error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _loadDummyData() {
    _safeSetState(() {
      _weatherData = _dummyWeatherData;
      _usingDummyData = true;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_usingDummyData)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Showing demo data',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.amber[800],
                    ),
                  ),
                ],
              ),
            ),
          if (_usingDummyData) const SizedBox(height: 8),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
                  ? Column(
                      children: [
                        Text(_errorMessage),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadDummyData,
                          child: const Text('Show Demo Weather Data'),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LocationBadge(location: "San Pablo City, PH"),
                        const SizedBox(height: 16),
                        _DateAndWeather(weatherData: _weatherData!),
                        const SizedBox(height: 16),
                        _TemperatureDetails(weatherData: _weatherData!),
                        const SizedBox(height: 8),
                        _AdditionalWeatherInfo(weatherData: _weatherData!),
                      ],
                    ),
        ],
      ),
    );
  }
}

class WeatherData {
  final double temp;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final int pressure;

  WeatherData({
    required this.temp,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temp: json['main']['temp'].toDouble(),
      feelsLike: json['main']['feels_like'].toDouble(),
      tempMin: json['main']['temp_min'].toDouble(),
      tempMax: json['main']['temp_max'].toDouble(),
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      humidity: json['main']['humidity'],
      windSpeed: json['wind']['speed'].toDouble(),
      pressure: json['main']['pressure'],
    );
  }
}

class _LocationBadge extends StatelessWidget {
  final String location;

  const _LocationBadge({required this.location});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12,
        vertical: isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
     
    color: Theme.of(context).brightness == Brightness.dark
              ?  FlarelineColors.darkerBackground 
              :      theme.colorScheme.primaryContainer,

        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on,
              color: theme.colorScheme.onPrimaryContainer,
              size: isSmallScreen ? 14 : 16),
          SizedBox(width: isSmallScreen ? 4 : 6),
          Text(
            location,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
              fontSize: isSmallScreen ? 12 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateAndWeather extends StatelessWidget {
  final WeatherData weatherData;

  const _DateAndWeather({required this.weatherData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE').format(DateTime.now()),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 18 : 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('d MMM, yyyy').format(DateTime.now()),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: isSmallScreen ? 12 : 12,
              ),
            ),
          ],
        ),
        Image.network(
          'https://openweathermap.org/img/wn/${weatherData.icon}@2x.png',
          width: isSmallScreen ? 40 : 48,
          height: isSmallScreen ? 40 : 48,
        ),
      ],
    );
  }
}

class _TemperatureDetails extends StatelessWidget {
  final WeatherData weatherData;

  const _TemperatureDetails({required this.weatherData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${weatherData.temp.round()}°C",
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w300,
                fontSize: isSmallScreen ? 36 : 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "H: ${weatherData.tempMax.round()}° L: ${weatherData.tempMin.round()}°",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: isSmallScreen ? 12 : 12,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              weatherData.description
                  .split(' ')
                  .map((s) => s[0].toUpperCase() + s.substring(1))
                  .join(' '),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: isSmallScreen ? 14 : 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Feels like ${weatherData.feelsLike.round()}°",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: isSmallScreen ? 12 : 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdditionalWeatherInfo extends StatelessWidget {
  final WeatherData weatherData;

  const _AdditionalWeatherInfo({required this.weatherData});

  @override
  Widget build(BuildContext context) { 
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _WeatherStatItem(
          icon: Icons.water_drop,
          value: "${weatherData.humidity}%",
          label: "Humidity",
          isSmallScreen: isSmallScreen,
        ),
        _WeatherStatItem(
          icon: Icons.air,
          value: "${weatherData.windSpeed.round()} km/h",
          label: "Wind",
          isSmallScreen: isSmallScreen,
        ),
        _WeatherStatItem(
          icon: Icons.speed,
          value: "${weatherData.pressure} hPa",
          label: "Pressure",
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }
}

class _WeatherStatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isSmallScreen;

  const _WeatherStatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon,
            size: isSmallScreen ? 20 : 24,
            color: const Color.fromARGB(255, 92, 91, 91)),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            // fontWeight: FontWeight.w500,
            fontSize: isSmallScreen ? 12 : 12,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: isSmallScreen ? 10 : 10,
          ),
        ),
      ],
    );
  }
}
