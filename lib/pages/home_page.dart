import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import 'my_account_page.dart';
import 'weather_page.dart';
import 'subsidy_page.dart';
import 'market_price_page.dart';
import 'chatbot_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key}); 

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 2; // Start with Home tab
  late PageController _pageController;
  late AnimationController _animationController;

  // Updated navigation order as requested: Account > Chatbot > Home > Weather > Subsidy > Market
  late final List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 2);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _navItems = [
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Account',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        activeIcon: Icon(Icons.chat_bubble),
        label: 'Assistant',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.cloud_outlined),
        activeIcon: Icon(Icons.cloud),
        label: 'Weather',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.account_balance_outlined),
        activeIcon: Icon(Icons.account_balance),
        label: 'Subsidies',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.trending_up_outlined),
        activeIcon: Icon(Icons.trending_up),
        label: 'Market',
      ),
    ];

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildHomeContent() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: KissanColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                _buildHeader(),
                
                // Quick Actions
                _buildQuickActions(),
                
                // Farm Status Dashboard
                _buildFarmStatus(),
                
                // Recent Updates
                _buildRecentUpdates(),
                
                // Weather Summary
                _buildWeatherSummary(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: KissanColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: KissanColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Sakthivel',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  color: KissanColors.textSecondary,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No new notifications')),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: KissanColors.accentGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Harvest Goal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '85% Complete',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.agriculture, color: Colors.white, size: 32),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.chat, 'label': 'Ask HASIRI', 'color': KissanColors.primary, 'page': 1},
      {'icon': Icons.cloud, 'label': 'Weather', 'color': Colors.blue, 'page': 3},
      {'icon': Icons.trending_up, 'label': 'Prices', 'color': KissanColors.success, 'page': 5},
      {'icon': Icons.account_balance, 'label': 'Subsidies', 'color': KissanColors.warning, 'page': 4},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: actions.map((action) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: HasiriIconButton(
                    icon: action['icon'] as IconData,
                    label: action['label'] as String,
                    color: action['color'] as Color,
                    onTap: () => _onNavItemTapped(action['page'] as int),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmStatus() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: HasiriCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Farm Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: KissanColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Healthy',
                    style: TextStyle(
                      color: KissanColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatusItem('Crops', '12 Types', Icons.eco, KissanColors.success),
                _buildStatusItem('Area', '5.2 Acres', Icons.landscape, KissanColors.primary),
                _buildStatusItem('Season', 'Kharif', Icons.calendar_today, KissanColors.warning),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentUpdates() {
    final updates = [
      {
        'title': 'Pest Alert: Leaf Blight',
        'description': 'Detected in nearby farms. Take preventive measures.',
        'time': '2 hours ago',
        'icon': Icons.bug_report,
        'color': KissanColors.warning,
      },
      {
        'title': 'Market Price Rise',
        'description': 'Rice prices increased by 8% in local market.',
        'time': '5 hours ago',
        'icon': Icons.trending_up,
        'color': KissanColors.success,
      },
      {
        'title': 'Weather Update',
        'description': 'Light rain expected tomorrow evening.',
        'time': '1 day ago',
        'icon': Icons.cloud,
        'color': Colors.blue,
      },
    ];

    return Container(
      margin: const EdgeInsets.all(20),
      child: HasiriCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Updates',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...updates.map((update) => _buildUpdateItem(update)),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateItem(Map<String, dynamic> update) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: update['color'].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              update['icon'],
              color: update['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update['title'],
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  update['description'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            update['time'],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: KissanColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSummary() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: HasiriCard(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Today\'s Weather',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.wb_sunny, color: Colors.white, size: 32),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '28°C',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Partly Cloudy',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Humidity: 68% • Wind: 12 km/h',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatbotPage() {
    // Use the renamed chatbot
    return ChatbotPage();
  }

  @override
  Widget build(BuildContext context) {
    // Define pages here to access context
    final List<Widget> pages = [
      MyAccountPage(), // Account
      _buildChatbotPage(),   // Chatbot
      _buildHomeContent(), // Home Dashboard
      WeatherPage(),   // Weather
      SubsidyPage(),   // Subsidy
      MarketPricePage(), // Market
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: _navItems,
          currentIndex: _selectedIndex,
          onTap: _onNavItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: KissanColors.primary,
          unselectedItemColor: KissanColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }
}
