import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/expense.dart';
import '../../../models/user.dart';
import '../../../theme/app_theme.dart';

class ExpenseChart extends StatefulWidget {
  final List<Expense> expenses;
  final List<User> members;

  const ExpenseChart({
    super.key,
    required this.expenses,
    required this.members,
  });

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    final spendingByUser = _calculateSpending();
    final totalSpending = widget.expenses.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    return AspectRatio(
      aspectRatio: 1.3,
      child: Row(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!
                            .touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: _showingSections(spendingByUser, totalSpending),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: spendingByUser.entries.map((entry) {
              final index = spendingByUser.keys.toList().indexOf(entry.key);
              final color =
                  AppTheme.chartColors[index % AppTheme.chartColors.length];
              final user = widget.members.firstWhere(
                (m) => m.id == entry.key,
                orElse: () => User(
                  id: entry.key,
                  name: entry.key == 'curr_user' ? 'You' : 'Unknown',
                  email: '',
                ),
              );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${entry.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Map<String, double> _calculateSpending() {
    final spending = <String, double>{};
    for (final expense in widget.expenses) {
      spending[expense.payerId] =
          (spending[expense.payerId] ?? 0) + expense.amount;
    }
    return spending;
  }

  List<PieChartSectionData> _showingSections(
    Map<String, double> spending,
    double total,
  ) {
    return List.generate(spending.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 14.0;
      final radius = isTouched ? 60.0 : 50.0;
      final key = spending.keys.elementAt(i);
      final value = spending[key]!;
      final percentage = (value / total * 100).toStringAsFixed(0);
      final color = AppTheme.chartColors[i % AppTheme.chartColors.length];

      return PieChartSectionData(
        color: color,
        value: value,
        title: '$percentage%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
      );
    });
  }
}
