import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Welcome Heading
              const Center(
                child: Text(
                  'Welcome to Appstinence',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Center(
                child: Text(
                  'Take control of your time and boost your productivity!',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 30),

              // Core Feature Cards
              _buildFeatureCard(
                icon: Icons.block,
                title: 'Block Apps',
                description: 'Stay focused by limiting access to distracting apps.',
              ),
              _buildFeatureCard(
                icon: Icons.timer,
                title: 'Focus Mode',
                description: 'Powerful focus sessions with custom timers.',
              ),
              _buildFeatureCard(
                icon: Icons.flag,
                title: 'Productivity Challenges',
                description: 'Fun challenges to improve your focus habits.',
              ),

              const SizedBox(height: 30),

              // Permissions Section
              const Text(
                'This app requires some permissions:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              _buildPermissionRow(
                icon: Icons.notifications,
                title: 'Notification Access',
                description: 'For focus session alerts & reminders.',
              ),
              _buildPermissionRow(
                icon: Icons.lock,
                title: 'App Blocking Control',
                description: 'To block distracting apps when needed.',
              ),

              const SizedBox(height: 30),

              // Continue Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                  child: const Text('Continue'),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Feature Card
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0),
            blurRadius: 10,
            spreadRadius: 2, 
            offset: const Offset(0, 0), 
          )
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFFFD700), size: 32),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(description, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }

  // Permission Row
  Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFFD700)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      subtitle: Text(description, style: const TextStyle(color: Colors.white70)),
    );
  }
}
