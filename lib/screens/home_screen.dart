import 'package:appstinence/screens/block_app_screen.dart';
import 'package:appstinence/screens/challenges_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'focus_screen.dart';
import 'distraction_tracker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.4);
  int currentIndex = 0;

  // Feature Cards
  final List<Map<String, dynamic>> featureCards = [
    {
      'icon': Icons.timer,
      'title': 'Focus Mode',
      'screen': const FocusScreen(),
    },
    // {
    //   'icon': Icons.block,
    //   'title': 'Blocks',
    //   'screen': Placeholder(),
    // },
    {
      'icon': Icons.add_circle_outline,
      'title': 'Block an App',
      'screen': const BlockAppScreen(),
    },
    {
      'icon': Icons.flag,
      'title': 'Challenges',
      'screen': const ChallengesScreen(),
    },
    {
      'icon': Icons.bar_chart,
      'title': 'Time Analysis',
      'screen': const DistractionTrackerScreen(),
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.jumpToPage(featureCards.length * 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Stylish Title with Fade-In Animation
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 800),
            child: const Text(
              'Appstinence',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700), // Gold
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  )
                ],
              ),
            ),
          ),
          const Text(
            'Take Control Of Your Time',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
              fontWeight: FontWeight.w300,
            ),
          ),

          const SizedBox(height: 30),

          // Feature Cards with Infinite Loop
          Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                if (event.scrollDelta.dy > 0) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                } else {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              }
            },
            child: SizedBox(
              height: 240,
              child: PageView.builder(
                controller: _pageController,
                itemBuilder: (context, index) {
                  final int effectiveIndex = index % featureCards.length;
                  final bool isMain = effectiveIndex == currentIndex;

                  return Transform.scale(
                    scale: isMain ? 1.0 : 0.8,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isMain ? 1.0 : 0.4,
                      child: _buildFeatureCard(
                        context,
                        icon: featureCards[effectiveIndex]['icon'],
                        title: featureCards[effectiveIndex]['title'],
                        screen: featureCards[effectiveIndex]['screen'],
                        isMain: isMain,
                      ),
                    ),
                  );
                },
                onPageChanged: (index) {
                  setState(() => currentIndex = index % featureCards.length);
                },
              ),
            ),
          ),

          const Spacer(),

          // Version Info
          const Text(
            'Version 1.0.0',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    ),
    );
  }

  // Custom Feature Card Widget
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget screen,
    required bool isMain,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Container(
      width: isMain ? 230 : 180,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20), 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF262626),
        boxShadow: [
          BoxShadow(
            color: isMain
                ? const Color(0xFFFFD700).withOpacity(0.5)
                : Colors.transparent,
            blurRadius: 20, // increased blur radius for a smoother glow
            spreadRadius: 2, // optional: gives a soft halo
            offset: const Offset(0, 0), // centralized shadow
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: const Color(0xFFFFD700)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
