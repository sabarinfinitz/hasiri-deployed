import 'package:flutter/material.dart';
import '../theme/colors.dart';

class MarketPricePage extends StatefulWidget {
  const MarketPricePage({super.key});
  
  @override
  MarketPricePageState createState() => MarketPricePageState();
}

class MarketPricePageState extends State<MarketPricePage> {
  String _selectedCrop = 'Rice';
  final List<String> _crops = ['Rice', 'Wheat', 'Sugarcane', 'Cotton', 'Tomato', 'Onion', 'Potato'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.trending_up, size: 32, color: Colors.white),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Market Price Trends',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Real-time price analysis',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Crop Selector
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCrop,
                        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        dropdownColor: KissanColors.primary,
                        items: _crops.map((String crop) {
                          return DropdownMenuItem<String>(
                            value: crop,
                            child: Text(crop),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCrop = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // Price Summary Cards
            Row(
              children: [
                Expanded(child: _buildPriceCard('Current Price', '₹2,450/quintal', Icons.currency_rupee, KissanColors.success)),
                SizedBox(width: 12),
                Expanded(child: _buildPriceCard('Trend', '+12%', Icons.trending_up, KissanColors.primary)),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildPriceCard('Min Price', '₹2,200/quintal', Icons.arrow_downward, KissanColors.warning)),
                SizedBox(width: 12),
                Expanded(child: _buildPriceCard('Max Price', '₹2,680/quintal', Icons.arrow_upward, KissanColors.accent)),
              ],
            ),
            SizedBox(height: 20),
            
            // Price Chart Placeholder
            Container(
              height: 200,
              padding: EdgeInsets.all(20),
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
                    'Price Chart - $_selectedCrop',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: KissanColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.insert_chart, size: 48, color: KissanColors.primary.withValues(alpha: 0.5)),
                          SizedBox(height: 8),
                          Text(
                            'Interactive Price Chart',
                            style: TextStyle(
                              fontSize: 16,
                              color: KissanColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Coming Soon',
                            style: TextStyle(
                              fontSize: 12,
                              color: KissanColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // Market Insights
            Container(
              padding: EdgeInsets.all(20),
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
                    'Market Insights',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: KissanColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16),
                  ..._buildInsightCards(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(String title, String value, IconData icon, Color color) {
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
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: KissanColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInsightCards() {
    final insights = [
      {
        'title': 'Market Outlook',
        'description': 'Prices expected to rise by 8-10% in the next month due to increased demand',
        'icon': Icons.visibility,
        'color': KissanColors.primary,
      },
      {
        'title': 'Best Selling Time',
        'description': 'Optimal selling window is in the next 2-3 weeks for maximum profit',
        'icon': Icons.schedule,
        'color': KissanColors.success,
      },
      {
        'title': 'Regional Comparison',
        'description': 'Local prices are 5% higher than national average',
        'icon': Icons.location_on,
        'color': KissanColors.warning,
      },
    ];

    return insights.map((insight) {
      return Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (insight['color'] as Color).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (insight['color'] as Color).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(insight['icon'] as IconData, color: insight['color'] as Color, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight['title'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KissanColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    insight['description'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: KissanColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
