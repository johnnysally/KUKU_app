import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/colors.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Prepare data from Hive boxes
    final eggsBoxOpen = Hive.isBoxOpen('eggs');
    final feedBoxOpen = Hive.isBoxOpen('feed');
    final mortalityBoxOpen = Hive.isBoxOpen('mortality');
    final vaccinationsOpen = Hive.isBoxOpen('vaccinations');
    final flocksOpen = Hive.isBoxOpen('flocks');

    // Egg production: last 6 months
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i), 1));
    final monthTotals = List.filled(6, 0);
    if (eggsBoxOpen) {
      final box = Hive.box('eggs');
      for (var i = 0; i < box.length; i++) {
        final item = box.getAt(i) as Map?;
        if (item == null) continue;
        try {
          final d = DateTime.parse(item['date'] as String);
          for (var m = 0; m < months.length; m++) {
            if (d.year == months[m].year && d.month == months[m].month) {
              monthTotals[m] += (item['totalEggs'] as int?) ?? 0;
            }
          }
        } catch (_) {}
      }
    }

    // Feed consumption: last 4 weeks (weekly totals)
    final weekTotals = List.filled(4, 0.0);
    if (feedBoxOpen) {
      final box = Hive.box('feed');
      final today = DateTime(now.year, now.month, now.day);
      for (var i = 0; i < box.length; i++) {
        final item = box.getAt(i) as Map?;
        if (item == null) continue;
        final type = item['type'] as String?;
        if (type != 'consumption') continue;
        try {
          final d = DateTime.parse(item['date'] as String);
          final diffDays = today.difference(DateTime(d.year, d.month, d.day)).inDays;
          if (diffDays >= 0 && diffDays < 28) {
            final weekIndex = (diffDays / 7).floor();
            final amt = (item['amountKg'] as num?)?.toDouble() ?? 0.0;
            // weekIndex 0 = today..6 days ago => put into weekTotals[0] as most recent
            if (weekIndex >= 0 && weekIndex < 4) {
              weekTotals[weekIndex] += amt;
            }
          }
        } catch (_) {}
      }
    }

    // Mortality and vaccination stats
    int totalDead = 0;
    if (mortalityBoxOpen) {
      final box = Hive.box('mortality');
      for (var i = 0; i < box.length; i++) {
        final item = box.getAt(i) as Map?;
        if (item == null) continue;
        totalDead += (item['count'] as int?) ?? 0;
      }
    }

    int totalSick = 0;
    if (Hive.isBoxOpen('analytics')) {
      final a = Hive.box('analytics');
      // optional: analytics box might contain 'sick' entries; sum them if present
      for (var i = 0; i < a.length; i++) {
        final item = a.getAt(i) as Map?;
        if (item == null) continue;
        totalSick += (item['sick'] as int?) ?? 0;
      }
    }

    double vaccinationPct = 0.0;
    if (vaccinationsOpen && flocksOpen) {
      final vbox = Hive.box('vaccinations');
      final fbox = Hive.box('flocks');
      final flocksCount = fbox.length > 0 ? fbox.length : 1;
      vaccinationPct = (vbox.length / flocksCount * 100).clamp(0, 100).toDouble();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Analytics",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Farm Analytics",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Egg Production Chart
            const Text("Egg Production (Monthly)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.cardBackground),
              child: LineChart(LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: true, getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1), getDrawingVerticalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                    final labels = months.map((m) => '${m.month}/${m.year % 100}').toList();
                    if (value.toInt() >= 0 && value.toInt() < labels.length) return Text(labels[value.toInt()]);
                    return const Text('');
                  })),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(monthTotals.length, (i) => FlSpot(i.toDouble(), monthTotals[i].toDouble())),
                    isCurved: true,
                    barWidth: 3,
                    color: AppColors.primary,
                    dotData: FlDotData(show: true),
                  ),
                ],
              )),
            ),
            const SizedBox(height: 20),

            // Feed Consumption Chart
            const Text("Feed Consumption (Weekly)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.cardBackground),
              child: BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (weekTotals.isNotEmpty ? weekTotals.reduce((a, b) => a > b ? a : b) : 50) + 10,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                    const weeks = ["This", "1w", "2w", "3w"];
                    if (value.toInt() >= 0 && value.toInt() < weeks.length) return Text(weeks[value.toInt()]);
                    return const Text('');
                  })),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(4, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: weekTotals.length > i ? weekTotals[i] : 0.0, color: AppColors.primaryLight)])),
              )),
            ),
            const SizedBox(height: 20),

            // Mortality / Health
            const Text("Mortality / Health Issues",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.accentLight),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Total Sick Birds: $totalSick", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text("Total Dead Birds: $totalDead", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text("Vaccination Completed: ${vaccinationPct.toStringAsFixed(0)}%", style: const TextStyle(fontSize: 16)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
