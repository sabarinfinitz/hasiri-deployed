import 'package:flutter/material.dart';
import '../theme/colors.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});
  
  @override
  WeatherPageState createState() => WeatherPageState();
}

class WeatherPageState extends State<WeatherPage> {
  String _selectedLocation = 'Current Location';
  final List<String> _locations = ['Current Location', 'Delhi', 'Mumbai', 'Bangalore', 'Chennai'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with Location Selector
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [KissanColors.primary, KissanColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: KissanColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLocation,
                            icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                            style: TextStyle(color: Colors.white, fontSize: 16),
                            dropdownColor: KissanColors.primary,
                            items: _locations.map((String location) {
                              return DropdownMenuItem<String>(
                                value: location,
                                child: Text(location),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedLocation = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Current Weather
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '32°C',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Partly Cloudy',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.cloud, color: Colors.white, size: 64),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Weather Details Cards
            Row(
              children: [
                Expanded(child: _buildWeatherDetailCard('Humidity', '65%', Icons.water_drop)),
                SizedBox(width: 12),
                Expanded(child: _buildWeatherDetailCard('Wind', '12 km/h', Icons.air)),
                SizedBox(width: 12),
                Expanded(child: _buildWeatherDetailCard('Rain', '20%', Icons.umbrella)),
              ],
            ),
            SizedBox(height: 20),

            // Hourly Forecast
            _buildForecastSection('Hourly Forecast', _buildHourlyForecast()),
            SizedBox(height: 20),

            // 7-Day Forecast
            _buildForecastSection('7-Day Forecast', _buildWeeklyForecast()),
            SizedBox(height: 20),

            // Farming Advisory
            _buildFarmingAdvisory(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetailCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: KissanColors.primary, size: 24),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: KissanColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: KissanColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSection(String title, Widget content) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: KissanColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildHourlyForecast() {
    final hours = ['Now', '1 PM', '2 PM', '3 PM', '4 PM', '5 PM', '6 PM', '7 PM'];
    final temps = ['32°', '33°', '33°', '32°', '31°', '30°', '29°', '28°'];
    final icons = [
      Icons.cloud,
      Icons.cloud_queue,
      Icons.wb_sunny,
      Icons.wb_sunny,
      Icons.cloud,
      Icons.cloud,
      Icons.nights_stay,
      Icons.nights_stay,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          hours.length,
          (index) => Container(
            margin: EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Text(
                  hours[index],
                  style: TextStyle(
                    fontSize: 12,
                    color: KissanColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Icon(icons[index], color: KissanColors.primary),
                SizedBox(height: 8),
                Text(
                  temps[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: KissanColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyForecast() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxTemps = ['33°', '32°', '34°', '31°', '30°', '31°', '32°'];
    final minTemps = ['24°', '23°', '25°', '22°', '21°', '22°', '23°'];
    final icons = [
      Icons.wb_sunny,
      Icons.cloud,
      Icons.wb_sunny,
      Icons.cloud_queue,
      Icons.umbrella,
      Icons.cloud,
      Icons.wb_sunny,
    ];

    return Column(
      children: List.generate(
        days.length,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  days[index],
                  style: TextStyle(color: KissanColors.textSecondary),
                ),
              ),
              Icon(icons[index], color: KissanColors.primary),
              Text(
                '${maxTemps[index]} / ${minTemps[index]}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: KissanColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmingAdvisory() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KissanColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KissanColors.warning.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: KissanColors.warning),
              SizedBox(width: 8),
              Text(
                'Weather Advisory',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: KissanColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Light rain expected in the next 24 hours. Consider postponing pesticide application. Ideal conditions for rice transplantation.',
            style: TextStyle(
              fontSize: 14,
              color: KissanColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
