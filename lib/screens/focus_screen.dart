import 'dart:async';
import 'package:flutter/material.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  int selectedMinutes = 25;
  int remainingTime = 0;
  Timer? _timer;
  bool isRunning = false;
  int completedSessions = 0;
  bool isOnBreak = false;

  @override
  void initState() {
    super.initState();
    resetTimer();
  }

  void startTimer() {
    if (!isRunning) {
      remainingTime = selectedMinutes * 60;

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingTime > 0) {
          setState(() => remainingTime--);
        } else {
          timer.cancel();
          _showSessionCompleteDialog();
          setState(() {
            completedSessions++;
            isOnBreak = true;
            remainingTime = 5 * 60;
          });
        }
      });

      setState(() => isRunning = true);
    }
  }

  void pauseTimer() {
    _timer?.cancel();
    setState(() => isRunning = false);
  }

  void resetTimer() {
    _timer?.cancel();
    setState(() {
      remainingTime = selectedMinutes * 60;
      isRunning = false;
      isOnBreak = false;
    });
  }

  void _showSessionCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Session Complete!', style: TextStyle(color: Colors.white)),
        content: Text(
          isOnBreak
              ? 'Break complete! Ready for the next session?'
              : 'Great job staying focused! Take a 5-minute break.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFFFD700))),
          )
        ],
      ),
    );
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Focus Mode'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: const Color(0xFFFFD700),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isOnBreak ? 'Break Time' : 'Focus Session',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // Timer Display
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: CircularProgressIndicator(
                    value: remainingTime == 0
                        ? 1
                        : remainingTime / (isOnBreak ? 5 * 60 : selectedMinutes * 60),
                    strokeWidth: 10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isOnBreak ? Colors.greenAccent : const Color(0xFFFFD700)),
                    backgroundColor: Colors.white24,
                  ),
                ),
                Text(
                  formatTime(remainingTime),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Session Length Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Session Length:', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    border: Border.all(color: const Color(0xFFFFD700)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<int>(
                    dropdownColor: const Color(0xFF1A1A1A),
                    iconEnabledColor: const Color(0xFFFFD700),
                    value: selectedMinutes,
                    underline: const SizedBox(),
                    items: [15, 25, 30, 45, 60]
                        .map((time) => DropdownMenuItem(
                              value: time,
                              child: Text('$time min', style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => selectedMinutes = value!);
                      resetTimer();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: startTimer,
                  child: const Text('Start'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: pauseTimer,
                  child: const Text('Pause'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: resetTimer,
                  child: const Text('Reset'),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Text(
              'Completed Sessions: $completedSessions',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
