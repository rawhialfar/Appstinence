import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayEntryWidget extends StatelessWidget {
  const OverlayEntryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.9),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, color: Color(0xFFFFD700), size: 80),
              const SizedBox(height: 20),
              const Text(
                "This app is currently blocked!",
                style: TextStyle(color: Colors.white, fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  FlutterOverlayWindow.closeOverlay();
                },
                child: const Text("Dismiss"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
