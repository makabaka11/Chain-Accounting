import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chain_provider.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChainProvider>(
      builder: (context, provider, _) {
        final monthlyData = provider.getMonthlyData();
        final labels = monthlyData.keys.toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: '总资产',
                      amount: provider.totalBalance,
                      color: const Color(0xFF1565C0),
                      icon: Icons.account_balance_wallet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: '净收入',
                      amount: provider.totalIncome - provider.totalExpense,
                      color: const Color(0xFF2E7D32),
                      icon: Icons.trending_up,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Bar chart
              if (labels.isNotEmpty && provider.transactions.isNotEmpty) ...[
                const Text(
                  '月度收支',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxY(monthlyData),
                        minY: 0,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final label =
                                  rodIndex == 0 ? '收入' : '支出';
                              return BarTooltipItem(
                                '$label\n¥${rod.toY.toStringAsFixed(0)}',
                                TextStyle(
                                  color: rodIndex == 0
                                      ? const Color(0xFF43A047)
                                      : const Color(0xFFE53935),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 48,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const Text('0');
                                if (value >= 10000) {
                                  return Text(
                                    '${(value / 10000).toStringAsFixed(1)}w',
                                    style: const TextStyle(fontSize: 11),
                                  );
                                }
                                return Text(
                                  value.toStringAsFixed(0),
                                  style: const TextStyle(fontSize: 11),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx >= 0 && idx < labels.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      labels[idx],
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(labels.length, (i) {
                          final data = monthlyData[labels[i]]!;
                          return BarChartGroupData(x: i, barRods: [
                            BarChartRodData(
                              toY: data['income']!.clamp(0, double.infinity),
                              color: const Color(0xFF43A047),
                              width: 12,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: data['expense']!.clamp(0, double.infinity),
                              color: const Color(0xFFE53935),
                              width: 12,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ]);
                        }),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendItem(color: const Color(0xFF43A047), label: '收入'),
                    const SizedBox(width: 24),
                    _LegendItem(color: const Color(0xFFE53935), label: '支出'),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              // Pie chart - account distribution
              if (provider.accounts.isNotEmpty) ...[
                const Text(
                  '账户分布',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _buildPieSections(provider),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...provider.accounts.map((acc) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getAccountColor(
                                  provider.accounts.indexOf(acc)),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(acc.name),
                          const Spacer(),
                          Text(
                            '¥${acc.balance.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
              ],
              // Account income/expense details
              const Text(
                '各账户收支详情',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...provider.accounts.map((acc) {
                final income = provider.getAccountIncome(acc.id);
                final expense = provider.getAccountExpense(acc.id);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          acc.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _IncomeExpenseBar(
                                label: '收入',
                                amount: income,
                                color: const Color(0xFF43A047),
                                total: income + expense,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _IncomeExpenseBar(
                                label: '支出',
                                amount: expense,
                                color: const Color(0xFFE53935),
                                total: income + expense,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  double _getMaxY(Map<String, Map<String, double>> data) {
    double max = 0;
    for (final d in data.values) {
      if (d['income']! > max) max = d['income']!;
      if (d['expense']! > max) max = d['expense']!;
    }
    return max == 0 ? 1000 : max * 1.2;
  }

  List<PieChartSectionData> _buildPieSections(ChainProvider provider) {
    return List.generate(provider.accounts.length, (i) {
      final acc = provider.accounts[i];
      final pct = provider.totalBalance > 0
          ? (acc.balance / provider.totalBalance * 100)
          : 0.0;
      return PieChartSectionData(
        value: acc.balance.clamp(0.1, double.infinity),
        color: _getAccountColor(i),
        title: '${pct.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });
  }

  Color _getAccountColor(int index) {
    const colors = [
      Color(0xFF1565C0),
      Color(0xFF2E7D32),
      Color(0xFFE65100),
      Color(0xFF6A1B9A),
      Color(0xFF00838F),
      Color(0xFFAD1457),
      Color(0xFF4527A0),
      Color(0xFFEF6C00),
    ];
    return colors[index % colors.length];
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: color, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '¥${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _IncomeExpenseBar extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final double total;

  const _IncomeExpenseBar({
    required this.label,
    required this.amount,
    required this.color,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (amount / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          '¥${amount.toStringAsFixed(2)}',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
