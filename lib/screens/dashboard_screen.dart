import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'record_mortality_screen.dart';
import 'record_eggs_screen.dart';
import 'feed_management_screen.dart';
import 'vaccination_screen.dart';
import 'marketplace_screen.dart';
import 'analytics_screen.dart';
import 'tips_screen.dart';
import 'feeding_programs_screen.dart';
import 'saved_tips_screen.dart';
import 'poultry_details_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'record_flock_screen.dart';
import 'mortality_list_screen.dart';
import '../theme/colors.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Sample carousel images (6 images)
  final List<String> carouselImages = const [
    'assets/images/poultry1.jpeg',
    'assets/images/poultry2.jpg',
    'assets/images/poultry3.jpg',
    'assets/images/poultry4.jpeg',
    'assets/images/poultry5.jpeg',
    'assets/images/poultry6.jpeg',
  ];

  late final PageController _pageController;
  Timer? _autoTimer;
  int _currentPage = 0; // will be set to a random start in initState
  // Animated welcome messages (built at runtime from profile)
  late List<String> _welcomeMessages;
  String _profileName = 'Farmer';
  int _messageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    // choose a random start image
    _currentPage = Random().nextInt(carouselImages.length);
    _pageController = PageController(initialPage: _currentPage, viewportFraction: 0.92);
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_pageController.hasClients) return;
      final next = (_currentPage + 1) % carouselImages.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
      );
    });
      // Load profile name for personalized greetings (safe fallback)
      try {
        if (Hive.isBoxOpen('profile')) {
          final box = Hive.box('profile');
          final name = box.get('name', defaultValue: 'Farmer') as String;
          _profileName = name.isNotEmpty ? name : 'Farmer';
        }
      } catch (_) {
        _profileName = 'Farmer';
      }

      // Build welcome messages now that we have the profile name
      _welcomeMessages = [
        'Welcome back, $_profileName! Check your farm status.',
        'Tip: Keep water clean for healthier birds.',
        'Reminder: Review vaccination schedule this week.',
      ];
    // cycle welcome messages
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (t) {
      if (!mounted) return;
      setState(() => _messageIndex = (_messageIndex + 1) % _welcomeMessages.length);
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          "Poultry App",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // Notifications icon with badge showing pending reminders count
          ValueListenableBuilder(
            valueListenable: Hive.box('notifications').listenable(),
            builder: (context, Box box, _) {
              final count = box.length;
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications, color: Colors.white),
                    if (count > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Center(
                            child: Text(
                              count > 99 ? '99+' : count.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Reduce bottom padding so content scrolls closer to quick actions
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewPadding.bottom + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated welcome message that reflects profile name changes
            SizedBox(
              height: 56,
              child: Center(
                child: ValueListenableBuilder(
                  valueListenable: Hive.box('profile').listenable(),
                  builder: (context, Box profileBox, _) {
                    final name = profileBox.get('name', defaultValue: _profileName) as String;
                    final messages = [
                      'Welcome back, ${name.isNotEmpty ? name : _profileName}! Check your farm status.',
                      'Tip: Keep water clean for healthier birds.',
                      'Reminder: Review vaccination schedule this week.',
                    ];
                    final idx = messages.isNotEmpty ? (_messageIndex % messages.length) : 0;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                      child: Container(
                        key: ValueKey<int>(_messageIndex),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, spreadRadius: 1)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.campaign, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                messages[idx],
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Simple PageView-based carousel (replaces carousel_slider)
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: carouselImages.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final imagePath = carouselImages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stack) {
                              // Show a placeholder if the asset is missing to avoid throwing.
                              return Container(
                                width: double.infinity,
                                color: AppColors.cardBackground,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.broken_image, size: 36, color: AppColors.primary),
                                    const SizedBox(height: 8),
                                    Text('Image not found', style: TextStyle(color: AppColors.textDark)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(carouselImages.length, (i) {
                        final active = i == _currentPage;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 10 : 8,
                          height: active ? 10 : 8,
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : Colors.white.withAlpha(120),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Greeting
            ValueListenableBuilder(
              valueListenable: Hive.box('profile').listenable(),
              builder: (context, Box profileBox, _) {
                final name = profileBox.get('name', defaultValue: _profileName) as String;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${name.isNotEmpty ? name : _profileName}!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your poultry farm efficiently',
                      style: TextStyle(color: AppColors.textDark.withAlpha((0.7 * 255).round())),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Quick Actions moved to bottomNavigationBar to avoid overflow

            // Quick Stats Cards (live data where available)
            ValueListenableBuilder(
              valueListenable: Hive.box('profile').listenable(),
              builder: (context, Box profileBox, _) {
                final flockSize = profileBox.get('flockSize');
                String totalBirds;
                if (Hive.isBoxOpen('flocks')) {
                  final f = Hive.box('flocks');
                  int sum = 0;
                  for (var i = 0; i < f.length; i++) {
                    final item = f.getAt(i) as Map?;
                    if (item == null) continue;
                    sum += (item['count'] as int?) ?? 0;
                  }
                  totalBirds = sum.toString();
                } else {
                  totalBirds = flockSize != null ? flockSize.toString() : '520';
                }
                final formatter = NumberFormat.decimalPattern();
                return Row(
                  children: [
                    Expanded(child: _buildStatCard("Total Birds", formatter.format(int.tryParse(totalBirds) ?? 0), Icons.egg)),
                    const SizedBox(width: 12),
                    // Mortality: if a 'mortality' box exists use its length, else fallback
                    Expanded(
                      child: Hive.isBoxOpen('mortality')
                          ? ValueListenableBuilder(
                              valueListenable: Hive.box('mortality').listenable(),
                              builder: (context, Box mortalityBox, _) {
                                final Set<String> deadFlocks = {};
                                int totalDeadBirds = 0;
                                for (var i = 0; i < mortalityBox.length; i++) {
                                  final item = mortalityBox.getAt(i) as Map?;
                                  if (item == null) continue;
                                  final f = (item['flock'] as String?)?.trim();
                                  if (f != null && f.isNotEmpty) deadFlocks.add(f);
                                  totalDeadBirds += (item['count'] as int?) ?? 0;
                                }
                                // Show total birds dead as the main value, include flock count and record count in subtitle, and make card tappable
                                final subtitle = "${deadFlocks.length} flocks · ${mortalityBox.length} records";
                                return _buildStatCard(
                                  "Mortality (${deadFlocks.length} flocks)",
                                  formatter.format(totalDeadBirds),
                                  Icons.warning_amber,
                                  subtitle: subtitle,
                                  tooltip: 'Tap to view mortality records',
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MortalityListScreen()));
                                  },
                                );
                              },
                            )
                          : _buildStatCard("Mortality", '0', Icons.warning_amber),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            // Eggs and Feed (eggs from optional 'eggs' box, feed from 'feed' box calculations)
            Row(
              children: [
                Expanded(
                  child: Builder(builder: (context) {
                    String eggsToday = '135';
                    if (Hive.isBoxOpen('eggs')) {
                      final box = Hive.box('eggs');
                      final today = DateTime.now();
                      int sum = 0;
                      for (var i = 0; i < box.length; i++) {
                        final item = box.getAt(i) as Map?;
                        if (item == null) continue;
                        try {
                          final date = DateTime.parse(item['date'] as String);
                          if (date.year == today.year && date.month == today.month && date.day == today.day) {
                            sum += (item['totalEggs'] as int?) ?? 0;
                          }
                        } catch (_) {}
                      }
                      eggsToday = sum.toString();
                    }
                    return _buildStatCard("Eggs Today", eggsToday, Icons.emoji_food_beverage);
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: Hive.box('feed').listenable(),
                    builder: (context, Box feedBox, _) {
                      double stockTotal = 0.0;
                      double consumptionTotal = 0.0;
                      for (var i = 0; i < feedBox.length; i++) {
                        final item = feedBox.getAt(i) as Map?;
                        if (item == null) continue;
                        final type = item['type'] as String?;
                        final amt = (item['amountKg'] as num?)?.toDouble() ?? 0.0;
                        if (type == 'stock') stockTotal += amt;
                        if (type == 'consumption') consumptionTotal += amt;
                      }
                      String display = 'N/A';
                      if (stockTotal > 0) {
                        final left = (stockTotal - consumptionTotal).clamp(0.0, stockTotal);
                        final pct = (left / stockTotal * 100).round();
                        display = '$pct%';
                      }
                      return _buildStatCard("Feed Left", display, Icons.inventory);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Section: Features
            Text(
              "Farm Tools",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 15),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildFeatureCard(
                  title: "Record Mortality",
                  icon: Icons.report,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RecordMortalityScreen()),
                    );
                  },
                ),
                _buildFeatureCard(
                  title: "Record Eggs",
                  icon: Icons.egg_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RecordEggsScreen()),
                    );
                  },
                ),
                _buildFeatureCard(
                  title: "Feed Management",
                  icon: Icons.inventory_2,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FeedManagementScreen()),
                    );
                  },
                ),
                _buildFeatureCard(
                  title: "Feeding Programs",
                  icon: Icons.note_alt,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedingProgramsScreen()));
                  },
                ),
                _buildFeatureCard(
                  title: "Manage Flocks",
                  icon: Icons.groups,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RecordFlockScreen()));
                  },
                ),
                _buildFeatureCard(
                  title: "Poultry Info",
                  icon: Icons.info_outline,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PoultryDetailsScreen()));
                  },
                ),
                _buildFeatureCard(
                  title: "Vaccination Schedule",
                  icon: Icons.event_available,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VaccinationScreen()),
                    );
                  },
                ),
                _buildFeatureCard(
                  title: "Marketplace",
                  icon: Icons.money,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MarketplaceScreen()),
                    );
                  },
                ),
                // Notifications card removed (accessible via quick actions / app bar)
                _buildFeatureCard(
                  title: "Growth Tracking",
                  icon: Icons.show_chart,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                    );
                  },
                ),
                _buildFeatureCard(
                  title: "Tips",
                  icon: Icons.lightbulb_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TipsScreen()),
                    );
                  },
                ),
                _buildFeatureCard(
                  title: "Saved Tips",
                  icon: Icons.bookmark_outline,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedTipsScreen()));
                  },
                ),
                _buildFeatureCard(
                  title: "Settings",
                  icon: Icons.settings_applications,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: _buildQuickActions(),
        ),
      ),
    );
  }

  // Quick Stats Card
  Widget _buildStatCard(String title, String value, IconData icon, {String? subtitle, VoidCallback? onTap, String? tooltip}) {
    Widget card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 28, color: AppColors.primary),
              if (tooltip != null) Icon(Icons.info_outline, size: 18, color: AppColors.textDark.withAlpha(180)),
            ],
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(fontSize: 13, color: AppColors.textDark.withAlpha((0.7 * 255).round())),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: AppColors.textDark.withAlpha((0.55 * 255).round())),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    if (tooltip != null) {
      card = Tooltip(message: tooltip, child: card);
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: SizedBox(height: 140, child: card));
    }

    // Ensure all stat cards have a consistent height so the Mortality card
    // matches the other quick-stat cards visually.
    return SizedBox(height: 140, child: card);
  }

  // Feature Card
  Widget _buildFeatureCard({required String title, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              spreadRadius: 1,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }

  // Quick Actions row
  Widget _buildQuickActions() {
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          const SizedBox(width: 4),
          _quickActionCard(
            title: 'Mortality',
            icon: Icons.report,
            color: AppColors.primary,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordMortalityScreen()));
            },
          ),
          const SizedBox(width: 12),
          _quickActionCard(
            title: 'Add Feed',
            icon: Icons.inventory_2,
            color: AppColors.primary,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedManagementScreen()));
            },
          ),
          const SizedBox(width: 12),
          _quickActionCard(
            title: 'Notifications',
            icon: Icons.notifications, 
            color: AppColors.primary,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
          ),
          const SizedBox(width: 12),
          const SizedBox(width: 12),
          _quickActionCard(
            title: 'Record Eggs',
            icon: Icons.egg_outlined,
            color: AppColors.accent,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordEggsScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _quickActionCard({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, spreadRadius: 1)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Icon(icon, color: Colors.white, size: 20)),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
