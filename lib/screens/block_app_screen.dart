import 'dart:async';
import 'dart:convert';
import 'package:appstinence/screens/block_time_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appcheck/appcheck.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_usage/app_usage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

const platform = MethodChannel('com.example.appstinence/native');

class ScheduledBlock {
  final String name;
  final TimeOfDay start;
  final TimeOfDay end;

  ScheduledBlock({required this.name, required this.start, required this.end});
}

Timer? globalTicker;

final Map<String, int> remainingTimeMs = {};
int timeElapsed = 0;

class BlockAppScreen extends StatefulWidget {
  const BlockAppScreen({super.key});

  @override
  State<BlockAppScreen> createState() => _BlockAppScreenState();
}

class _BlockAppScreenState extends State<BlockAppScreen> {
  final Set<String> blockedApps = {};
  final Map<String, Duration> appUsageDurations = {};
  List<String> availableApps = [];
  final appsCheck = AppCheck();
  List<AppInfo> installedApps = [];
  List<AppInfo> filteredApps = [];
  List<AppInfo>? apps = [];
  final List<String> excludedApps = [
    "com.android.settings",
    "com.google.android.apps.nexuslauncher",
    "com.google.android.sdksetup",
    "com.example.appstinence",
  ];
  // Add this instead:
  final Map<String, String> perAppPasswords = {};
  bool _permissionsGranted = false;
  Map<String, int?> appBlockDurations = {};
  final Map<String, TextEditingController> _durationControllers = {};
  final List<Map<String, dynamic>> scheduledBlocks = [];
  bool showUpcoming = false;
  final Set<String> activelyBlockedApps = {};
  final Map<String, TextEditingController> _passwordControllers = {};
  final Set<String> manuallyUnblockedApps = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _fetchAvailableApps();
    _loadManuallyUnblockedApps();
    _loadSavedSettings();
    startGlobalTicker();
    Timer.periodic(const Duration(seconds: 10), (_) => checkScheduledBlocks());
  }

  @override
  void dispose() {
    for (final controller in _passwordControllers.values) {
      controller.dispose();
    }
    for (final controller in _durationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSavedSettings() async {
    try {
      final savedAppsString = await platform.invokeMethod<String>(
        'getBlockedApps',
      );
      final savedPassword = await platform.invokeMethod<String>('getPassword');

      if (savedAppsString != null && savedAppsString.isNotEmpty) {
        final apps = savedAppsString.split(',').where((e) => e.isNotEmpty);
        setState(() {
          blockedApps.addAll(apps);
        });

        setState(() {
          activelyBlockedApps.clear();
          activelyBlockedApps.addAll(apps); // Mark them as truly active
        });

        for (final app in apps) {
          final minutes = appBlockDurations[app];
          if (minutes != null && minutes > 0) {
            remainingTimeMs[app] = minutes * 60000;
          }
        }
        startGlobalTicker();
      }
    } catch (e) {
      print("Error loading saved settings: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    final scheduledJson = prefs.getString('scheduled_blocks');

    if (scheduledJson != null) {
      final List decoded = const JsonDecoder().convert(scheduledJson);
      scheduledBlocks.addAll(
        decoded.map(
          (b) => {
            'app': b['app'],
            'password': b['password'],
            'start': TimeOfDay(hour: b['startHour'], minute: b['startMinute']),
            'end': TimeOfDay(hour: b['endHour'], minute: b['endMinute']),
          },
        ),
      );
    }
  }

  Future<void> _saveManuallyUnblockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'manually_unblocked_apps',
      manuallyUnblockedApps.toList(),
    );
  }

  Future<void> _loadManuallyUnblockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('manually_unblocked_apps') ?? [];
    manuallyUnblockedApps.clear();
    manuallyUnblockedApps.addAll(list);
  }

  void startGlobalTicker() {
    if (remainingTimeMs.isEmpty) return; // already running
    globalTicker?.cancel();
    final blockTimeService = Provider.of<BlockTimeService>(
      context,
      listen: false,
    );
    globalTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      checkScheduledBlocks();
      if (blockedApps.isNotEmpty) {
        timeElapsed = timeElapsed + 1;
      }
      final expiredApps = <String>[];

      for (var app in remainingTimeMs.keys) {
        remainingTimeMs[app] = (remainingTimeMs[app] ?? 0) - 1000;
        if ((remainingTimeMs[app] ?? 0) <= 0) {
          expiredApps.add(app);
          blockedApps.remove(app);
        }
      }

      blockTimeService.updateDuration(Duration(seconds: timeElapsed));

      for (var app in expiredApps) {
        unblockApp(app);
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _saveScheduledBlocks() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        scheduledBlocks
            .map(
              (block) => {
                'app': block['app'],
                'password': block['password'],
                'startHour': (block['start'] as TimeOfDay).hour,
                'startMinute': (block['start'] as TimeOfDay).minute,
                'endHour': (block['end'] as TimeOfDay).hour,
                'endMinute': (block['end'] as TimeOfDay).minute,
              },
            )
            .toList();

    await prefs.setString(
      'scheduled_blocks',
      const JsonEncoder().convert(encoded),
    );
  }

  void _openScheduleSessionDialog() {
    TimeOfDay? start;
    TimeOfDay? end;
    String? selectedApp;
    final TextEditingController pwdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text(
                "Schedule Session",
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedApp,
                    hint: const Text(
                      "Select App",
                      style: TextStyle(color: Colors.white70),
                    ),
                    dropdownColor: const Color(0xFF2A2A2A),
                    items:
                        filteredApps.map((app) {
                          return DropdownMenuItem(
                            value: app.packageName,
                            child: Text(
                              app.appName ?? app.packageName,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                    onChanged: (val) => setState(() => selectedApp = val),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pwdController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: "Password",
                      hintStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) setState(() => start = picked);
                        },
                        child: Text(
                          start == null ? "Start Time" : start!.format(context),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) setState(() => end = picked);
                        },
                        child: Text(
                          end == null ? "End Time" : end!.format(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (start != null &&
                        end != null &&
                        selectedApp != null &&
                        pwdController.text.isNotEmpty) {
                      Navigator.pop(context);
                      // move this setState outside the dialog using a post-frame callback
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          scheduledBlocks.add({
                            'app': selectedApp!,
                            'start': start!,
                            'end': end!,
                            'password': pwdController.text,
                          });
                          showUpcoming = true; // open the expansion tile
                          _saveScheduledBlocks();
                        });
                      });
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void checkScheduledBlocks() async {
    final now = TimeOfDay.now();

    for (var block in scheduledBlocks) {
      final isNow =
          now.hour > block['start'].hour ||
          (now.hour == block['start'].hour &&
              now.minute >= block['start'].minute);

      final isBeforeEnd =
          now.hour < block['end'].hour ||
          (now.hour == block['end'].hour && now.minute < block['end'].minute);

      if (isNow && isBeforeEnd) {
        final appToBlock = block['app'];
        final pwd = block['password'];

        final isAfterEnd =
            now.hour > block['end'].hour ||
            (now.hour == block['end'].hour &&
                now.minute >= block['end'].minute);

        if (isAfterEnd) {
          manuallyUnblockedApps.remove(
            appToBlock,
          ); // remove override if time is past
        }

        if (!blockedApps.contains(appToBlock) &&
            !manuallyUnblockedApps.contains(appToBlock)) {
          blockedApps.add(appToBlock);
          activelyBlockedApps.add(appToBlock);
          final start = block['start'] as TimeOfDay;
          final end = block['end'] as TimeOfDay;
          final now = TimeOfDay.now();
          final endMinutes = end.hour * 60 + end.minute;
          final nowMinutes = now.hour * 60 + now.minute;
          final durationMs = (endMinutes - nowMinutes) * 60000;

          remainingTimeMs[appToBlock] = durationMs;
          appBlockDurations[appToBlock] = (durationMs / 60000).round();
          startGlobalTicker();
          try {
            await platform.invokeMethod('setPasswordForApp', {
              "package": appToBlock,
              "password": pwd,
            });
            await platform.invokeMethod(
              'updateBlockedApps',
              blockedApps.toList(),
            );
            await platform.invokeMethod(
              'startService',
            ); // <--- THIS IS MISSING!
          } catch (e) {
            print("Error updating native blocked apps: $e");
          }
          //startGlobalTicker();
          if (mounted) {
            setState(() {});
          }
        }
      }
    }
  }

  Future<void> _checkPermissions() async {
    bool overlayGranted = await platform.invokeMethod('checkOverlayPermission');
    bool usageStatsGranted = await platform.invokeMethod(
      'checkUsageStatsPermission',
    );

    if (!overlayGranted) {
      await platform.invokeMethod('requestOverlayPermission');
    }
    if (!usageStatsGranted) {
      await platform.invokeMethod('requestUsageStatsPermission');
    }

    overlayGranted = await platform.invokeMethod('checkOverlayPermission');
    usageStatsGranted = await platform.invokeMethod(
      'checkUsageStatsPermission',
    );

    setState(() {
      _permissionsGranted = overlayGranted && usageStatsGranted;
    });

    if (!_permissionsGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please grant overlay and usage stats permissions to continue",
          ),
        ),
      );
    }
  }

  Future<void> _fetchAvailableApps() async {
    try {
      apps = await appsCheck.getInstalledApps();
      installedApps =
          apps!
              .where((app) => !excludedApps.contains(app.packageName))
              .toList();
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(days: 7));

      final appUsage = AppUsage();
      List<AppUsageInfo> usageInfo = await appUsage.getAppUsage(
        startDate,
        endDate,
      );
      final Set<String> appNames = {};

      for (var info in usageInfo) {
        appNames.add(info.packageName);
        appUsageDurations[info.packageName] = info.usage;
      }
      setState(() {
        availableApps = appNames.toList();
      });
      filteredApps =
          installedApps
              .where((app) => appNames.contains(app.packageName))
              .toList();
      filteredApps.sort((a, b) => (a.appName ?? '').compareTo(b.appName ?? ''));
    } catch (e) {
      print("Error fetching apps: $e");
    }
  }

  void toggleBlock(String packageName, bool block) async {
    setState(() {
      if (block) {
        blockedApps.add(packageName);
        activelyBlockedApps.add(packageName);
        manuallyUnblockedApps.remove(packageName);
      } else {
        blockedApps.remove(packageName);
        activelyBlockedApps.remove(packageName);
        remainingTimeMs.remove(packageName);
        appBlockDurations.remove(packageName);
        manuallyUnblockedApps.add(packageName);
      }
    });

    await _saveManuallyUnblockedApps();
    try {
      await platform.invokeMethod('updateBlockedApps', blockedApps.toList());
    } catch (e) {
      print("Error updating blocked apps: $e");
    }
  }

  void startBlocking() async {
    if (!_permissionsGranted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Permissions not granted")));
      return;
    }

    // Optional: You can check if all blocked apps have a password set
    for (final app in blockedApps) {
      if ((perAppPasswords[app] ?? "").isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please set a password for ${app.split('.').last}"),
          ),
        );
        return;
      }
    }

    try {
      for (final app in blockedApps) {
        final pwd = perAppPasswords[app] ?? "";
        await platform.invokeMethod('setPasswordForApp', {
          "package": app,
          "password": pwd,
        });
      }
      await platform.invokeMethod('updateBlockedApps', blockedApps.toList());
      await platform.invokeMethod('startService');

      activelyBlockedApps.clear(); // reset
      activelyBlockedApps.addAll(
        blockedApps,
      ); // only now are they truly blocked

      for (var app in blockedApps) {
        final durationMin = appBlockDurations[app];
        if (durationMin != null && durationMin > 0) {
          remainingTimeMs[app] = durationMin * 60000;
        }
      }
      startGlobalTicker();

      if (mounted) {
        setState(() {});
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Blocking started!")));
    } catch (e) {
      print("Error in startBlocking: $e");
    }
  }

  Future<void> unblockApp(String packageName) async {
    blockedApps.remove(packageName);
    activelyBlockedApps.remove(packageName);
    remainingTimeMs.remove(packageName);
    appBlockDurations.remove(packageName);

    try {
      await platform.invokeMethod('updateBlockedApps', blockedApps.toList());
    } catch (e) {
      print("Error updating native unblocked apps: $e");
    }

    if (mounted) {
      setState(() {});
    }
  }

  void resetBlocking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Reset All Settings"),
            content: const Text(
              "Are you sure you want to clear all blocked apps and password?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Reset"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        for (String app in List.from(blockedApps)) {
          await unblockApp(app);
        }

        globalTicker?.cancel();
        for (final app in perAppPasswords.keys) {
          timeElapsed = 0;
          await platform.invokeMethod('setPasswordForApp', {
            'package': app,
            'password': '',
          });
        }

        setState(() {
          blockedApps.clear();
          perAppPasswords.clear();
          appBlockDurations.clear();
          _durationControllers.clear();
          manuallyUnblockedApps.clear();
        });

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("All settings reset!")));
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('scheduled_blocks');
        await _saveManuallyUnblockedApps();
      } catch (e) {
        print("Reset error: $e");
      }
    }
  }

  List<Map<String, dynamic>> getUpcomingBlocks() {
    final now = TimeOfDay.now();
    return scheduledBlocks.where((block) {
      final start = block['start'] as TimeOfDay;
      return now.hour < start.hour ||
          (now.hour == start.hour && now.minute < start.minute);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('App Blocking'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: const Color(0xFFFFD700),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset All',
            onPressed: resetBlocking,
          ),
        ],
      ),
      body: Column(
        children: [
          ExpansionTile(
            initiallyExpanded: showUpcoming,
            onExpansionChanged: (val) => setState(() => showUpcoming = val),
            title: const Text(
              "Upcoming Scheduled Blocks",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            children:
                getUpcomingBlocks().isEmpty
                    ? [
                      const ListTile(
                        title: Text(
                          "No scheduled blocks",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ]
                    : getUpcomingBlocks().map((block) {
                      final appName =
                          filteredApps
                              .firstWhere(
                                (a) => a.packageName == block['app'],
                                orElse:
                                    () => AppInfo(
                                      appName: block['app'],
                                      packageName: block['app'],
                                    ),
                              )
                              .appName;

                      return ListTile(
                        title: Text(
                          appName ?? block['app'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "${block['start'].format(context)} - ${block['end'].format(context)}",
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: const Icon(
                          Icons.schedule,
                          color: Colors.orangeAccent,
                        ),
                      );
                    }).toList(),
          ),
          Expanded(
            child:
                filteredApps.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: filteredApps.length,
                      itemBuilder: (context, index) {
                        final app = filteredApps[index];
                        final packageName = app.packageName;
                        final usage =
                            appUsageDurations[packageName]?.inMinutes ?? 0;
                        final durationController = _durationControllers
                            .putIfAbsent(
                              packageName,
                              () => TextEditingController(),
                            );

                        return Card(
                          color: const Color(0xFF1A1A1A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading:
                                      app.icon != null
                                          ? CircleAvatar(
                                            backgroundImage: MemoryImage(
                                              app.icon!,
                                            ),
                                            radius: 22,
                                          )
                                          : const Icon(
                                            Icons.apps,
                                            color: Colors.white,
                                          ),
                                  title: Text(
                                    app.appName ?? '',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Used $usage min in last 7 days',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),

                                      // Status & Time display ONLY if blocking is active
                                      if (activelyBlockedApps.contains(
                                        packageName,
                                      ))
                                        Text(
                                          "Status: Blocked",
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      else
                                        Text(
                                          "Status: Not Blocked",
                                          style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                      if (remainingTimeMs.containsKey(
                                        packageName,
                                      ))
                                        Text(
                                          "Remaining: ${_formatTime(remainingTimeMs[packageName] ?? 0)}",
                                          style: const TextStyle(
                                            color: Colors.orangeAccent,
                                            fontSize: 12,
                                          ),
                                        )
                                      else if (blockedApps.contains(
                                        packageName,
                                      ))
                                        Text(
                                          "Remaining: Unlimited",
                                          style: const TextStyle(
                                            color: Colors.orangeAccent,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Switch(
                                    activeColor: const Color(0xFFFFD700),
                                    value: blockedApps.contains(packageName),
                                    onChanged:
                                        (val) => toggleBlock(packageName, val),
                                  ),
                                ),
                                if (blockedApps.contains(packageName))
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                      bottom: 8,
                                    ),
                                    child: TextField(
                                      controller: durationController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: "Block duration (minutes)",
                                        labelStyle: TextStyle(
                                          color: Colors.white70,
                                        ),
                                        filled: true,
                                        fillColor: Color(0xFF2A2A2A),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(8),
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        final minutes =
                                            int.tryParse(value) ?? 0;
                                        appBlockDurations[packageName] =
                                            minutes;
                                      },
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    bottom: 8,
                                  ),
                                  child: TextField(
                                    controller: _passwordControllers
                                        .putIfAbsent(
                                          packageName,
                                          () => TextEditingController(),
                                        ),
                                    obscureText: true,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: "App Password",
                                      labelStyle: TextStyle(
                                        color: Colors.white70,
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFF2A2A2A),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8),
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      perAppPasswords[packageName] = value;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: startBlocking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Start Blocking",
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _openScheduleSessionDialog(); // You will create this below
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2A2A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.schedule),
                label: const Text("Schedule Session"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(int milliseconds) {
  final minutes = (milliseconds ~/ 60000);
  final seconds = ((milliseconds % 60000) ~/ 1000);
  return '$minutes min ${seconds.toString().padLeft(2, '0')} sec';
}
