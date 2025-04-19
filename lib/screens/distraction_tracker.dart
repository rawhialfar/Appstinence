import 'dart:async'; // for base64
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:app_usage/app_usage.dart';
import 'package:appcheck/appcheck.dart';

Map<String, AppInfo> appInfoMap = {};

class DistractionTrackerScreen extends StatefulWidget {
  const DistractionTrackerScreen({super.key});
  
  @override
  State<DistractionTrackerScreen> createState() =>
      _DistractionTrackerScreenState();
}

class _DistractionTrackerScreenState extends State<DistractionTrackerScreen> {
  final Map<String, double> distractionCounts = {};
  final List<String> excludedApps = [
    "com.google.android.apps.nexuslauncher",
    "com.google.android.sdksetup",
  ];
  final Map<String, double> weeklyUsageMap = {
    'Mon': 0,
    'Tue': 0,
    'Wed': 0,
    'Thu': 0,
    'Fri': 0,
    'Sat': 0,
    'Sun': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchAppUsageStats();
  }

  Future<void> _fetchAppUsageStats() async {
    try {
      DateTime now = DateTime.now();
      final tempMap = {
        'Mon': 0.0,
        'Tue': 0.0,
        'Wed': 0.0,
        'Thu': 0.0,
        'Fri': 0.0,
        'Sat': 0.0,
        'Sun': 0.0,
      };

      distractionCounts.clear();
      appInfoMap.clear();

      final allInstalledApps = await AppCheck().getInstalledApps() ?? [];

      for (int i = 0; i < 7; i++) {
        DateTime dayStart = DateTime(now.year, now.month, now.day - i);
        DateTime dayEnd = dayStart.add(const Duration(days: 1));

        List<AppUsageInfo> infoList = await AppUsage().getAppUsage(dayStart, dayEnd);

        double dailyTotalMinutes = 0.0;

        for (var info in infoList) {
          if (excludedApps.contains(info.packageName)) continue;
          if (info.usage.inSeconds < 30) continue;

          double usageInMinutes = info.usage.inMinutes.toDouble();

          // Update usage map
          distractionCounts.update(info.appName, (v) => v + usageInMinutes, ifAbsent: () => usageInMinutes);
          dailyTotalMinutes += usageInMinutes;

          // Match app info and save icon
          final matchedApp = allInstalledApps.firstWhere(
            (app) => app.appName?.toLowerCase() == info.appName.toLowerCase(),
            orElse: () => AppInfo(appName: info.appName, packageName: '', icon: null),
          );

          if (matchedApp.icon != null) {
            appInfoMap[info.appName] = matchedApp;
          }
        }

        String weekday = _getWeekdayLabel(dayStart.weekday);
        tempMap[weekday] = dailyTotalMinutes / 60;
      }

      setState(() {
        weeklyUsageMap.clear();
        weeklyUsageMap.addAll(tempMap);
      });
    } catch (e) {
      print('Error fetching usage or apps: $e');
      setState(() {
        distractionCounts.clear();
        weeklyUsageMap.clear();
      });
    }
  }



  String _getWeekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }


  String generateInsight() {
    if (distractionCounts.isEmpty) return "No app usage data available.";

    final sortedEntries = distractionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topDistraction = sortedEntries.first.key;
    final topCount = sortedEntries.first.value;

    if (topCount > 60) {
      return "Your most common distraction is '$topDistraction'. Try strategies like:\n"
          "- Scheduling focused blocks\n"
          "- Noise-canceling headphones\n"
          "- 'Do Not Disturb' mode";
    } else {
      return "You're managing distractions well! Keep it up.";
    }
  }

  List<PieChartSectionData> getPieChartData() {
    return distractionCounts.entries
        .map((entry) => PieChartSectionData(
              value: entry.value,
              title: '${entry.key} (${entry.value.toInt()} mins)',
              color: _getRandomColor(entry.key),
              radius: 60,
              titleStyle: const TextStyle(color: Colors.white),
            ))
        .toList();
  }

  Color _getRandomColor(String category) {
    final hash = category.hashCode;
    return Color((hash & 0xFFFFFF) | 0xFF000000).withOpacity(0.8);
  }
  String formatHourMin(double minutes) {
    final total = minutes.round();
    final h = total ~/ 60;
    final m = total % 60;
    return '${h}h ${m}m';
  }
  String formatHourMinute(double hours) {
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')} h ${m.toString().padLeft(2, '0')} m';
  }

  @override
  Widget build(BuildContext context) {
    final totalUsageMinutes = distractionCounts.values.fold(0.0, (a, b) => a + b);
    final totalMinutesInDay = 24 * 60;
    final offlineMinutes = (totalMinutesInDay - totalUsageMinutes).clamp(0, totalMinutesInDay).toDouble();
    double totalWeekHours = weeklyUsageMap.values.fold(0.0, (a, b) => a + b);
    double avgDailyHours = totalWeekHours / 7;
    final sortedApps = distractionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topApps = sortedApps.take(3).toList();
    

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Time Analysis'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: const Color(0xFFFFD700),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAppUsageStats, 
            tooltip: 'Refresh',
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Image.asset('assets/Hourglass.png', width: 300, height: 200),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildMostUsedIcons(topApps)),
                  _buildAverageScreenTime(avgDailyHours),
                ],
              ),


              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Weekly Screen Time",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              _buildActivityBarChart(),

              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Time Breakdown",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),

              _buildUsageTile(
                "Time Offline",
                _formatDuration(offlineMinutes),
                leadingIcon: Icons.cloud_outlined,
              ),


              for (var entry in topApps)
                _buildUsageTile(
                  entry.key,
                  _formatDuration(entry.value.toDouble()),
                  appInfo: appInfoMap[entry.key],
                ),


              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Insights & Recommendations",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                generateInsight(),
                style: const TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.left,
              ),


              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMostUsedIcons(List<MapEntry<String, double>> topApps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Most Used", style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 4),
        Row(
          children: topApps.map((entry) {
            final appName = entry.key;
            final usage = entry.value;
            final appInfo = appInfoMap[appName];

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white12,
                    backgroundImage: appInfo?.icon != null
                        ? MemoryImage(appInfo!.icon!)
                        : null,
                    child: appInfo?.icon == null
                        ? const Icon(Icons.apps, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatHourMin(usage),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),

                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }



  Widget _buildAverageScreenTime(double avgHours) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          "Avg. Daily Screen Time",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          formatHourMinute(avgHours), 
          style: const TextStyle(color: Colors.yellow, fontSize: 20),
        ),
      ],
    );
  }



  Widget _buildUsageTile(String label, String time, {
    AppInfo? appInfo,
    IconData? leadingIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (appInfo?.icon != null)
                CircleAvatar(
                  radius: 14,
                  backgroundImage: MemoryImage(appInfo!.icon!),
                  backgroundColor: Colors.white10,
                )
              else if (leadingIcon != null)
                Icon(leadingIcon, color: Colors.white70, size: 28), // 👈 Bigger cloud here

              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          Text(time, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }




  Widget _buildActivityBarChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 24,
          minY: 0,
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= days.length) return const SizedBox.shrink();
                  return Text(days[index], style: const TextStyle(color: Colors.white));
                },
                reservedSize: 32,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}h',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                reservedSize: 36,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) {
            final day = days[index];
            final usageHours = weeklyUsageMap[day] ?? 0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: usageHours,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.blueAccent,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }



  String _formatDuration(double minutes) {
    final h = minutes ~/ 60;
    final m = (minutes % 60).toInt();
    return "${h}h ${m}m";
  }



  @override
  void dispose() {
    super.dispose();
  }
}
