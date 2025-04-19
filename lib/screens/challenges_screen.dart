import 'package:appstinence/screens/block_time_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  // Update your challenges list to be mutable
  late List<Map<String, dynamic>> challenges;

  @override
  void initState() {
    super.initState();
    challenges = _createInitialChallenges();
    _loadCompletionStatus();
  }

  List<Map<String, dynamic>> _createInitialChallenges() {
    return [
      {
        'id': 'focus_30_min',
        'title': '30-Minute Focus Streak',
        'description': 'Stay focused for 30 minutes without distractions.',
        'completed': false,
        'timeBased': true, // Mark time-based challenges
        'requiredMinutes': 30,
      },
      {
        'id': 'deep_work_3hr',
        'title': '3-Hour Deep Work',
        'description': 'Spend 3 uninterrupted hours working on a task.',
        'completed': false,
        'timeBased': true,
        'requiredMinutes': 180,
      },
      {
        'id': 'tech_free_morning',
        'title': 'Tech-Free Morning',
        'description':
            'Avoid using your phone for the first hour after waking up.',
        'completed': false,
        'timeBased': false, // Manual completion only
      },
      {
        'id': 'mindful_breaks',
        'title': 'Mindful Breaks',
        'description': 'Take mindful breaks every hour for a day.',
        'completed': false,
        'timeBased': false,
      },
    ];
  }

  final Map<int, String> badgeMilestones = {
    1: 'Bronze Star',
    3: 'Silver Star',
    5: 'Gold Star',
    10: 'Platinum Star',
  };

  int completedChallenges = 0;

  final List<String> motivationalQuotes = [
    "Success is the sum of small efforts repeated daily. 🌟",
    "Your focus determines your reality. 💫",
    "Progress is progress, no matter how small. 🚀",
    "Discipline is choosing between what you want now and what you want most. 💪",
    "Small steps lead to big results. 🔥",
  ];

  Future<void> _loadCompletionStatus() async {
    // Challenge completion persistence even when exiting this screen
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var challenge in challenges) {
        final id = challenge['id'];
        challenge['completed'] = prefs.getBool(id) ?? false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Challenges'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: const Color(0xFFFFD700),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Daily Challenges!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              getRandomQuote(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white60),
            ),
            const SizedBox(height: 30),

            // Challenge List
            Selector<BlockTimeService, Duration>(
              selector: (_, service) => service.totalBlockedDuration,
              builder: (_, duration, __) {
                return Expanded(
                  // Added return statement here
                  child: ListView.builder(
                    itemCount: challenges.length,
                    itemBuilder: (context, index) {
                      return _buildChallengeCard(
                        challenges[index],
                        index,
                        duration,
                      );
                    },
                  ),
                );
              },
            ),
            _buildTimeDisplay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(BuildContext context) {
    return Selector<BlockTimeService, Duration>(
      selector: (_, service) => service.totalBlockedDuration,
      builder: (_, duration, __) {
        return Text(
          'Total Time Focused: ${_formatDuration(duration)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildChallengeCard(
    Map<String, dynamic> challenge,
    int index,
    Duration duration,
  ) {
    bool isTimeBased = challenge['timeBased'] == true;
    if (isTimeBased && duration.inMinutes == challenge['requiredMinutes']) {
      challenge['completed'] = true;
    }
    bool completed = challenge['completed'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(15.0),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF1A1A1A),
        boxShadow:
            completed
                ? [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.5),
                    // blurRadius: 20, // Reintroduce glow around items if desired, though it has been showing weird clipping bugs when scrolling.
                    // spreadRadius: 1,
                  ),
                ]
                : [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    // blurRadius: 15,
                    // spreadRadius: 1,
                  ),
                ],
        border: Border.all(
          color: completed ? Colors.greenAccent : const Color(0xFFFFD700),
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: Icon(
          completed ? Icons.check_circle : Icons.emoji_events,
          color: completed ? Colors.greenAccent : const Color(0xFFFFD700),
          size: 40,
        ),
        title: Text(
          challenge['title'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: completed ? Colors.greenAccent : Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge['description'],
              style: TextStyle(color: Colors.white70),
            ),
            if (isTimeBased && !completed)
              Text(
                'Progress: ${_formatProgress(challenge, duration)}',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing:
            completed
                ? const Icon(Icons.star, color: Colors.amber, size: 30)
                : const Icon(Icons.play_arrow, color: Color(0xFFFFD700)),
        // IconButton(
        //   icon: const Icon(Icons.play_arrow, color: Color(0xFFFFD700)),
        //   onPressed: () => toggleChallengeStatus(index),
        // ),
      ),
    );
  }

  void toggleChallengeStatus(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (!challenges[index]['completed']) {
        completedChallenges++;
        if (badgeMilestones.containsKey(completedChallenges)) {
          _showBadgeDialog(badgeMilestones[completedChallenges]!);
        }
      } else {
        completedChallenges = max(0, completedChallenges - 1);
      }
      challenges[index]['completed'] = !challenges[index]['completed'];
      prefs.setBool(
        challenges[index]['id'],
        challenges[index]['completed'],
      ); // Setting the bool in SharedPrefs to track completed challenges
    });
  }

  void _showBadgeDialog(String badgeName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              '🎖 Achievement Unlocked!',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'You earned the "$badgeName" badge for your progress!',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Awesome!',
                  style: TextStyle(color: Color(0xFFFFD700)),
                ),
              ),
            ],
          ),
    );
  }

  String getRandomQuote() {
    return motivationalQuotes[Random().nextInt(motivationalQuotes.length)];
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  String _formatProgress(Map<String, dynamic> challenge, Duration duration) {
    final required = challenge['requiredMinutes'] as int;
    final current = duration.inMinutes;
    final percent = (current / required * 100).clamp(0, 100).toInt();
    return '$percent% (${current}m/${required}m)';
  }
}
