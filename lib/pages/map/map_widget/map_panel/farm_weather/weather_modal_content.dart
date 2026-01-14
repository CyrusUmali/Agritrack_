import 'package:flutter/material.dart';
import 'package:flareline/pages/map/map_widget/map_panel/farm_weather/weather_model.dart'; 

enum WeatherContentType {
  current,
  forecast,
}

class WeatherModalContent extends StatefulWidget {
  final WeatherData? weatherData;
  final AirQualityData? airQualityData;
  final List<DailyForecast>? dailyForecast;
  final String? reporterSummary;
  final bool isLoadingWeather;
  final bool isLoadingForecast;
  final bool isLoadingSummary;
  final String? weatherError;
  final String? forecastError;
  final String? summaryError;
  final bool isSummaryReady;
  final VoidCallback? onGenerateSummary;
  final bool hasMinimalWeatherData;

  const WeatherModalContent({
    super.key,
    required this.weatherData,
    required this.airQualityData,
    required this.dailyForecast,
    required this.reporterSummary,
    required this.isLoadingWeather,
    required this.isLoadingForecast,
    required this.isLoadingSummary,
    required this.weatherError,
    required this.forecastError,
    required this.summaryError,
    required this.isSummaryReady,
    this.onGenerateSummary,
    this.hasMinimalWeatherData = false,
  });

  @override
  State<WeatherModalContent> createState() => _WeatherModalContentState();
}

class _WeatherModalContentState extends State<WeatherModalContent> {
  WeatherContentType _contentType = WeatherContentType.current;

  @override 
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Content Type Toggle
        _buildContentTypeToggle(context),
        const SizedBox(height: 16),
        
        // Content Area
        SizedBox(
          height: 560,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentContent() {
    switch (_contentType) {
      case WeatherContentType.current:
        return _buildCurrentWeatherTab(context);
      case WeatherContentType.forecast:
        return _buildForecastTab(context);
    }
  }

  Widget _buildContentTypeToggle(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
        color: theme.brightness == Brightness.dark
            ? theme.primaryColor.withOpacity(0.1)
            : Colors.grey.shade50,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildContentTypeToggleButton(
            icon: Icons.info_outline,
            label: 'Current',
            isSelected: _contentType == WeatherContentType.current,
            onTap: () {
              setState(() {
                _contentType = WeatherContentType.current;
              });
            },
            theme: theme,
          ),
          Container(
            width: 1,
            height: 32,
            color: theme.dividerColor,
          ),
          _buildContentTypeToggleButton(
            icon: Icons.calendar_today,
            label: 'Forecast',
            isSelected: _contentType == WeatherContentType.forecast,
            onTap: () {
              setState(() {
                _contentType = WeatherContentType.forecast;
              });
            },
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildContentTypeToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? theme.primaryColor.withOpacity(0.2)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? theme.primaryColor
                    : theme.iconTheme.color?.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? theme.primaryColor
                      : theme.iconTheme.color?.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }




  Widget _buildCurrentWeatherTab(BuildContext context) {
    if (widget.isLoadingWeather) {
      return WeatherUIHelpers.buildLoadingIndicator('Loading weather data...');
    } else if (widget.weatherError != null) {
      return WeatherUIHelpers.buildErrorIndicator(widget.weatherError!);
    } else if (widget.weatherData != null) {
      return ListView(
        key: const ValueKey('current'),
        padding: const EdgeInsets.all(16),
        children: [
          _buildWeatherContent(context, widget.weatherData!),
          if (widget.airQualityData != null) ...[
            const SizedBox(height: 16),
            _buildAirQualitySection(context, widget.airQualityData!),
          ],
          const SizedBox(height: 16),
          _buildReporterSummary(context),
        ],
      );
    }
    return const Center(child: Text('No weather data available'));
  }

  Widget _buildForecastTab(BuildContext context) {
    if (widget.isLoadingForecast) {
      return WeatherUIHelpers.buildLoadingIndicator('Loading forecast data...');
    } else if (widget.forecastError != null) {
      return WeatherUIHelpers.buildErrorIndicator(widget.forecastError!);
    } else if (widget.dailyForecast != null && widget.dailyForecast!.isNotEmpty) {
      return ListView(
        key: const ValueKey('forecast'),
        padding: const EdgeInsets.all(16),
        children: [
          _buildForecastHeader(),
          const SizedBox(height: 16),
          ...widget.dailyForecast!
              .map((daily) => _buildDailyForecastCard(context, daily))
              .toList(),
        ],
      );
    }
    return const Center(child: Text('No forecast data available'));
  }

  Widget _buildForecastHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '5-Day Forecast',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${widget.dailyForecast?.length ?? 0} days',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  // Keep all the existing helper methods (_buildReporterSummary, 
  // _buildDailyForecastCard, _getWeatherConditionColor, 
  // _buildWeatherContent, etc.) exactly as they were in your original code
  // ...






Widget _buildReporterSummary(BuildContext context) {
  final theme = Theme.of(context);

  // 1. First check for errors
  if (widget.summaryError != null) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
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
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.summaryError!,
            style: TextStyle(
              fontSize: 13,
              color: Colors.red[700],
            ),
          ),
          if (widget.onGenerateSummary != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: widget.onGenerateSummary,
              icon: Icon(Icons.refresh, size: 16 , color: Colors.white),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 2. Check for loading state
  if (widget.isLoadingSummary) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
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
          ),
        ],
      ),
    );
  }

  // 3. Check if we have a summary
  if (widget.reporterSummary != null && widget.reporterSummary!.isNotEmpty) {
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
              const Spacer(),
              if (widget.onGenerateSummary != null)
                IconButton(
                  onPressed: widget.onGenerateSummary,
                  icon: Icon(Icons.refresh, size: 16),
                  color: Colors.blue,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.reporterSummary!,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          // if (onGenerateSummary != null)
          //   Align(
          //     alignment: Alignment.centerRight,
          //     child: TextButton(
          //       onPressed: onGenerateSummary,
          //       child: Text(
          //         'Regenerate',
          //         style: TextStyle(fontSize: 12),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }

  // 4. Show manual generation button if we have minimal weather data
  if (widget.hasMinimalWeatherData && widget.onGenerateSummary != null) {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get weather analysis based on current conditions.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
             TextButton.icon(
            onPressed: widget.onGenerateSummary,
            icon: Icon(Icons.auto_awesome, size: 16),
            label: Text('Generate Summary'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
            ),)
            ],
          ),
        ],
      ),
    );
  }

  // 5. Default fallback - show nothing or a minimal state
  return const SizedBox.shrink();
}






Widget _buildDailyForecastCard(BuildContext context, DailyForecast forecast) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final isToday = WeatherUIHelpers.isToday(forecast.date);
  final isTomorrow = WeatherUIHelpers.isTomorrow(forecast.date);

  String dayLabel;
  if (isToday) {
    dayLabel = 'Today';
  } else if (isTomorrow) {
    dayLabel = 'Tomorrow';
  } else {
    dayLabel = WeatherUIHelpers.formatDayOfWeek(forecast.date);
  }

  // Get dynamic color based on weather condition
  final conditionColor = _getWeatherConditionColor(forecast.condition);

  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: isToday 
        ? LinearGradient(
            colors: isDark
              ? [Colors.blue.shade900.withOpacity(0.3), Colors.blue.shade800.withOpacity(0.2)]
              : [Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null,
      color: isToday ? null : theme.cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isToday 
          ? (isDark ? Colors.blue.shade700.withOpacity(0.4) : Colors.blue.shade200)
          : theme.colorScheme.outline.withOpacity(0.1),
        width: isToday ? 1.5 : 1,
      ),
      boxShadow: isToday ? [
        BoxShadow(
          color: Colors.blue.withOpacity(isDark ? 0.1 : 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ] : null,
    ),
    child: Row(
      children: [
        // Date Section
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    dayLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isToday 
                        ? (isDark ? Colors.blue.shade200 : Colors.blue.shade900)
                        : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'NOW',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                WeatherUIHelpers.formatDate(forecast.date),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),

        // Weather Icon Section
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: conditionColor.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            WeatherUIHelpers.getWeatherIcon(forecast.condition),
            size: 32,
            color: conditionColor,
          ),
        ),

        const SizedBox(width: 16),

        // Temperature Section
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${forecast.tempMax.toStringAsFixed(0)}°',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '${forecast.tempMin.toStringAsFixed(0)}°',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                forecast.description,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}



Color _getWeatherConditionColor(String condition) {
  final lower = condition.toLowerCase();
  if (lower.contains('rain') || lower.contains('drizzle')) {
    return Colors.blue.shade600;
  } else if (lower.contains('cloud')) {
    return Colors.grey.shade600;
  } else if (lower.contains('clear') || lower.contains('sun')) {
    return Colors.orange.shade600;
  } else if (lower.contains('snow')) {
    return Colors.lightBlue.shade400;
  } else if (lower.contains('thunder') || lower.contains('storm')) {
    return Colors.deepPurple.shade600;
  } else if (lower.contains('fog') || lower.contains('mist')) {
    return Colors.blueGrey.shade500;
  }
  return Colors.blue.shade600;
}




Widget _buildWeatherContent(BuildContext context, WeatherData weatherData) {
  final theme = Theme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    
    

    Row(
  children: [
    Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        WeatherUIHelpers.getWeatherIcon(weatherData.condition),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side - Current temperature
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weatherData.temperature.toStringAsFixed(1)}°C',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    'Feels like ${weatherData.feelsLike.toStringAsFixed(1)}°',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              
              // Right side - UV Index badge
              if (weatherData.uvi != null)
                _buildUVIndexBadge(weatherData.uvi!),
            ],
          ),
          const SizedBox(height: 4),
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




LayoutBuilder(
  builder: (context, constraints) {
    // Use mobile layout for screens less than 600px wide
    if (constraints.maxWidth < 600) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceEvenly,
        children: [
          _buildWeatherDetail(
            context: context,
            icon: Icons.water_drop,
            label: 'Humidity',
            value: '${weatherData.humidity}%',
          ),
          _buildWeatherDetail(
            context: context,
            icon: Icons.air,
            label: 'Wind',
            value: '${weatherData.windSpeed.toStringAsFixed(1)} m/s',
          ),
          _buildWeatherDetail(
            context: context,
            icon: Icons.compress,
            label: 'Pressure',
            value: '${weatherData.pressure} hPa',
          ),
          _buildWeatherDetail(
            context: context,
            icon: Icons.cloud,
            label: 'Clouds',
            value: '${weatherData.clouds}%',
          ),
          _buildWeatherDetail(
            context: context,
            icon: Icons.umbrella,
            label: 'Rain (1h)',
            value: weatherData.rain1h != null 
                ? '${weatherData.rain1h!.toStringAsFixed(1)} mm'
                : 'No rain',
          ),
          _buildWeatherDetail(
            context: context,
            icon: Icons.visibility,
            label: 'Visibility',
            value: '${(weatherData.visibility / 1000).toStringAsFixed(1)} km',
          ),
        ],
      );
    }
    
    // Use desktop/tablet layout for larger screens
    return Column(
      children: [
        // First row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildWeatherDetail(
              context: context,
              icon: Icons.water_drop,
              label: 'Humidity',
              value: '${weatherData.humidity}%',
            ),
            _buildWeatherDetail(
              context: context,
              icon: Icons.air,
              label: 'Wind',
              value: '${weatherData.windSpeed.toStringAsFixed(1)} m/s',
            ),
            _buildWeatherDetail(
              context: context,
              icon: Icons.compress,
              label: 'Pressure',
              value: '${weatherData.pressure} hPa',
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Second row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildWeatherDetail(
              context: context,
              icon: Icons.cloud,
              label: 'Clouds',
              value: '${weatherData.clouds}%',
            ),
            _buildWeatherDetail(
              context: context,
              icon: Icons.umbrella,
              label: 'Rain (1h)',
              value: weatherData.rain1h != null 
                  ? '${weatherData.rain1h!.toStringAsFixed(1)} mm'
                  : 'No rain',
            ),
            _buildWeatherDetail(
              context: context,
              icon: Icons.visibility,
              label: 'Visibility',
              value: '${(weatherData.visibility / 1000).toStringAsFixed(1)} km',
            ),
          ],
        ),
      ],
    );
  },
),


      
      // Sunrise/Sunset
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSunInfo(
            context: context,
            icon: Icons.wb_sunny,
            label: 'Sunrise',
            time: WeatherUIHelpers.formatTime(weatherData.sunrise),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey[300],
          ),
          _buildSunInfo(
            context: context,
            icon: Icons.nights_stay,
            label: 'Sunset',
            time: WeatherUIHelpers.formatTime(weatherData.sunset),
          ),
        ],
      ),
    ],
  );
}


  Widget _buildAirQualitySection(BuildContext context, AirQualityData airQualityData) {
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
                context: context,
                label: 'PM2.5',
                value: '${airQualityData.pm2_5.toStringAsFixed(1)} μg/m³',
              ),
              _buildAirQualityDetail(
                context: context,
                label: 'PM10',
                value: '${airQualityData.pm10.toStringAsFixed(1)} μg/m³',
              ),
              _buildAirQualityDetail(
                context: context,
                label: 'NO₂',
                value: '${airQualityData.no2.toStringAsFixed(1)} μg/m³',
              ),
              _buildAirQualityDetail(
                context: context,
                label: 'O₃',
                value: '${airQualityData.o3.toStringAsFixed(1)} μg/m³',
              ),
            ],
          ),
        ],
      ),
    );
  }

 

  Widget _buildWeatherDetail({
    required BuildContext context,
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
    required BuildContext context,
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

  Widget _buildAirQualityDetail({
    required BuildContext context,
    required String label,
    required String value,
  }) {
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




 


 Widget _buildUVIndexBadge(double uvIndex) {
  final uvColor = _getUVIndexColor(uvIndex);
  final uvLabel = _getUVIndexLabel(uvIndex);
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: uvColor.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: uvColor.withOpacity(0.3),
        width: 1.5,
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // UV Index number with sun icon
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wb_sunny,
              size: 16,
              color: uvColor,
            ),
            const SizedBox(width: 4),
            Text(
              'UV ${uvIndex.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: uvColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // Risk level label
        Text(
          uvLabel,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: uvColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

// UV Index color helper (add to your class)
Color _getUVIndexColor(double uvi) {
  if (uvi <= 2) {
    return Colors.green; // Low
  } else if (uvi <= 5) {
    return Colors.yellow.shade700; // Moderate
  } else if (uvi <= 7) {
    return Colors.orange; // High
  } else if (uvi <= 10) {
    return Colors.red; // Very High
  } else {
    return Colors.purple; // Extreme
  }
}

// UV Index label helper (add to your class)
String _getUVIndexLabel(double uvi) {
  if (uvi <= 2) {
    return 'LOW';
  } else if (uvi <= 5) {
    return 'MODERATE';
  } else if (uvi <= 7) {
    return 'HIGH';
  } else if (uvi <= 10) {
    return 'VERY HIGH';
  } else {
    return 'EXTREME';
  }
}

}