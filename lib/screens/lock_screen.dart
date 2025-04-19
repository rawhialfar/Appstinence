import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class LockScreen extends StatefulWidget {
  final String packageName;
  const LockScreen({super.key, required this.packageName});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String? savedPassword;
  static const platform = MethodChannel('com.example.appstinence/native');

  @override
  void initState() {
    super.initState();
    _getSavedPassword();
  }

  Future<void> _getSavedPassword() async {
    try {
      final password = await platform.invokeMethod('getPassword');
      setState(() {
        savedPassword = password;
      });
    } catch (e) {
      print("Error getting password: $e");
    }
  }

  void _validatePassword() {
    if (_passwordController.text == savedPassword) {
      // Close the overlay and return to home screen
      FlutterOverlayWindow.closeOverlay();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 50, color: Color(0xFFFFD700)),
            const SizedBox(height: 20),
            const Text(
              "App Locked",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 10),
            Text(
              "Enter password to unlock ${widget.packageName}",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Password",
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _validatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Unlock", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}