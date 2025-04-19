import 'package:appstinence/screens/block_time_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // This listens for events triggered from Kotlin
  FlutterOverlayWindow.overlayListener.listen((event) async {
    debugPrint("[OverlayListener] Received event: $event");
    if (event is Map && event['packageName'] != null) {
      final packageName = event['packageName'] as String;

      // Show overlay — no entryPoint
      await FlutterOverlayWindow.showOverlay(
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
        alignment: OverlayAlignment.center,
        flag: OverlayFlag.focusPointer, // allows typing
        enableDrag: false,
        overlayTitle: "Appstinence Lock",
        overlayContent: "App $packageName is blocked",
      );
    }
  });

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => BlockTimeService())],
      child: AppstinenceApp(),
    ),
  );
}

class AppstinenceApp extends StatelessWidget {
  const AppstinenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Appstinence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      ),
      initialRoute: '/onboarding',
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
        '/focus': (context) => const FocusScreen(),
      },
    );
  }
}

// Called by flutter_overlay_window via AndroidManifest meta-data
@pragma('vm:entry-point')
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  const platform = MethodChannel('com.example.appstinence/native');

  String? packageName;
  try {
    packageName = await platform.invokeMethod<String>('getLastBlockedApp');
    debugPrint("[overlayMain] Received package: $packageName");
  } catch (e) {
    debugPrint("Error in overlayMain: $e");
  }

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home:
          packageName != null
              ? LockScreen(packageName: packageName!)
              : const Scaffold(
                body: Center(child: Text("Failed to get blocked app")),
              ),
    ),
  );
}
