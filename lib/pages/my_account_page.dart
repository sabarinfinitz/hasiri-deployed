import 'package:flutter/material.dart';
import '../theme/colors.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});
  
  @override
  MyAccountPageState createState() => MyAccountPageState();
}

class MyAccountPageState extends State<MyAccountPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [KissanColors.primary, KissanColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: KissanColors.primary,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Sakthivel',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Wheat and Rice Farmer',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildProfileStat('Land', '5 Acres'),
                      _buildProfileStat('Location', 'Punjab'),
                      _buildProfileStat('Experience', '15 Years'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Farm Details
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSectionTitle('Farm Details'),
                _buildDetailCard(
                  'Active Crops',
                  [
                    {'crop': 'Wheat', 'area': '3 Acres', 'status': 'Growing'},
                    {'crop': 'Rice', 'area': '2 Acres', 'status': 'Harvested'},
                  ],
                ),
                SizedBox(height: 20),

                _buildSectionTitle('Active Schemes'),
                _buildSchemeCard(
                  'PM-KISAN',
                  'Next installment due in 15 days',
                  Icons.calendar_today,
                  KissanColors.success,
                ),
                _buildSchemeCard(
                  'Crop Insurance',
                  'Coverage active till December 2025',
                  Icons.security,
                  KissanColors.primary,
                ),
                SizedBox(height: 20),

                _buildSectionTitle('Documents'),
                _buildDocumentsList(),
                SizedBox(height: 20),

                _buildSectionTitle('Settings'),
                _buildSettingsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: KissanColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Map<String, String>> items) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((item) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['crop']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: KissanColors.textPrimary,
                        ),
                      ),
                      Text(
                        item['area']!,
                        style: TextStyle(
                          color: KissanColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: item['status'] == 'Growing'
                          ? KissanColors.success.withValues(alpha: 0.1)
                          : KissanColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['status']!,
                      style: TextStyle(
                        color: item['status'] == 'Growing'
                            ? KissanColors.success
                            : KissanColors.warning,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSchemeCard(String title, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildDocumentsList() {
    final documents = [
      {'name': 'Aadhaar Card', 'verified': true},
      {'name': 'Land Records', 'verified': true},
      {'name': 'Bank Details', 'verified': true},
      {'name': 'KYC Documents', 'verified': false},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: documents.map((doc) {
          return ListTile(
            leading: Icon(Icons.description),
            title: Text(doc['name'] as String),
            trailing: Icon(
              doc['verified'] as bool ? Icons.verified : Icons.warning,
              color: doc['verified'] as bool ? KissanColors.success : KissanColors.warning,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.language),
            title: Text('Language'),
            trailing: Text('English'),
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeColor: KissanColors.primary,
            ),
          ),
          ListTile(
            leading: Icon(Icons.security),
            title: Text('Privacy Settings'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help & Support'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
