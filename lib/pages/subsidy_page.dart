import 'package:flutter/material.dart';
import '../theme/colors.dart';

class SubsidyPage extends StatefulWidget {
  const SubsidyPage({super.key});
  
  @override
  SubsidyPageState createState() => SubsidyPageState();
}

class SubsidyPageState extends State<SubsidyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = ['All Schemes', 'Equipment', 'Seeds', 'Insurance', 'Training'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with Search
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search schemes...',
                    prefixIcon: Icon(Icons.search, color: KissanColors.textSecondary),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: KissanColors.primary,
                  unselectedLabelColor: KissanColors.textSecondary,
                  indicatorColor: KissanColors.primary,
                  tabs: _categories.map((category) => Tab(text: category)).toList(),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) => _buildSchemesList(category)).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement eligibility check
        },
        backgroundColor: KissanColors.primary,
        icon: Icon(Icons.check_circle_outline),
        label: Text('Check Eligibility'),
      ),
    );
  }

  Widget _buildSchemesList(String category) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        if (category == 'All Schemes' || category == 'Equipment')
          _buildSchemeCard(
            'Farm Mechanization Scheme',
            'Get up to 50% subsidy on purchase of new agricultural equipment and machinery',
            Icons.agriculture,
            '₹50,000',
            ['Tractors', 'Harvesters', 'Irrigation Equipment'],
          ),
        if (category == 'All Schemes' || category == 'Seeds')
          _buildSchemeCard(
            'Quality Seeds Program',
            'Subsidy on certified high-quality seeds for better yield',
            Icons.spa,
            '₹2,000/hectare',
            ['Wheat', 'Rice', 'Pulses'],
          ),
        if (category == 'All Schemes' || category == 'Insurance')
          _buildSchemeCard(
            'Crop Insurance Scheme',
            'Protect your crops against natural calamities and disasters',
            Icons.security,
            'Up to 80% coverage',
            ['All Major Crops', 'Weather Protection', 'Pest Coverage'],
          ),
        if (category == 'All Schemes' || category == 'Training')
          _buildSchemeCard(
            'Skill Development Initiative',
            'Free training programs for modern farming techniques',
            Icons.school,
            'Fully Sponsored',
            ['Organic Farming', 'Smart Irrigation', 'Pest Management'],
          ),
      ],
    );
  }

  Widget _buildSchemeCard(
    String title,
    String description,
    IconData icon,
    String benefit,
    List<String> tags,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KissanColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: KissanColors.primary),
                ),
                SizedBox(width: 16),
                Expanded(
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
                      SizedBox(height: 4),
                      Text(
                        benefit,
                        style: TextStyle(
                          fontSize: 14,
                          color: KissanColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: KissanColors.primary),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: KissanColors.textSecondary,
                  ),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) => _buildTag(tag)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: KissanColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: KissanColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
