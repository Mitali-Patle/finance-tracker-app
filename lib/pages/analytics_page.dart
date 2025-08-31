import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import '../models/friend.dart';
//import '../widgets/helpers.dart';

class AnalyticsPage extends StatelessWidget {
  final List<Expense> expenses;
  final List<Friend> friends;
  const AnalyticsPage({super.key, required this.expenses, required this.friends});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final monthExpenses = expenses
        .where((e) => e.date.isAfter(monthStart.subtract(const Duration(milliseconds: 1))) && e.date.isBefore(monthEnd))
        .toList();

    // Category totals for pie
    final Map<String, double> byCategory = {};
    for (final e in monthExpenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }

    // Daily totals for bar chart
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final List<double> byDay = List.filled(daysInMonth, 0);
    for (final e in monthExpenses) {
      final day = e.date.day;
      byDay[day - 1] += e.amount;
    }

    return monthExpenses.isEmpty
        ? const Center(child: Text('No data for this month'))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category Split (This Month)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 1.2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: byCategory.entries.map((e) {
                        final total = byCategory.values.fold<double>(0, (p, v) => p + v);
                        final pc = total == 0 ? 0 : (e.value / total) * 100;
                        return PieChartSectionData(
                          value: e.value,
                          title: '${e.key}\n${pc.toStringAsFixed(0)}%',
                          radius: 70,
                          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Spending Trend (Daily)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 1.7,
                  child: BarChart(
                    BarChartData(
                      barGroups: [
                        for (int i = 0; i < byDay.length; i++)
                          BarChartGroupData(x: i + 1, barRods: [BarChartRodData(toY: byDay[i])]),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 3,
                            getTitlesWidget: (v, meta) {
                              final d = v.toInt();
                              if (d < 1 || d > daysInMonth) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(d.toString(), style: const TextStyle(fontSize: 9)),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: true),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Who Owes What (This Month)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildWhoOwesWhat(monthExpenses, friends),
              ],
            ),
          );
  }

  Widget _buildWhoOwesWhat(List<Expense> exps, List<Friend> friends) {
    // Sum owed per friend id
    final Map<int, double> owed = {};
    for (final e in exps) {
      e.shares.forEach((fid, amount) {
        owed[fid] = (owed[fid] ?? 0) + amount;
      });
    }
    if (owed.isEmpty) {
      return const Text('No splits this month');
    }
    return Column(
      children: owed.entries.map((entry) {
        final friend = friends.firstWhere((f) => f.id == entry.key, orElse: () => Friend(id: -1, name: 'Unknown'));
        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(friend.name),
          trailing: Text('₹${entry.value.toStringAsFixed(2)}'),
        );
      }).toList(),
    );
  }
}