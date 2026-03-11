import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class RevenueChartWidget extends StatelessWidget {
  final Map<String, dynamic> analytics;
  final String selectedTimeRange;
  final Function(String) onTimeRangeChanged;

  const RevenueChartWidget({
    super.key,
    required this.analytics,
    required this.selectedTimeRange,
    required this.onTimeRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — responsive: row on wide screens, column on narrow
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final titleWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Analytics',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your business performance',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              );
              // Time Range Selector
              final dropdownWidget = Container(
                width: 140,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedTimeRange,
                    isExpanded: true,
                    items: ['This Week', 'This Month', 'Last 3 Months', 'This Year']
                        .map((range) => DropdownMenuItem(
                              value: range,
                              child: Text(
                                range,
                                style: GoogleFonts.inter(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) onTimeRangeChanged(value);
                    },
                  ),
                ),
              );
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titleWidget, const SizedBox(height: 12), dropdownWidget],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Expanded(child: titleWidget), const SizedBox(width: 12), dropdownWidget],
              );
            },
          ),
          const SizedBox(height: 24),
          
          // Chart
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        Widget text;
                        switch (value.toInt()) {
                          case 1:
                            text = const Text('Week 1', style: style);
                            break;
                          case 2:
                            text = const Text('Week 2', style: style);
                            break;
                          case 3:
                            text = const Text('Week 3', style: style);
                            break;
                          case 4:
                            text = const Text('Week 4', style: style);
                            break;
                          default:
                            text = const Text('', style: style);
                            break;
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: text,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5000,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '₹${(value / 1000).toInt()}K',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: 25000,
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateRevenueSpots(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2E7D32),
                        const Color(0xFF2E7D32).withOpacity(0.3),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF2E7D32),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2E7D32).withOpacity(0.2),
                          const Color(0xFF2E7D32).withOpacity(0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Summary Stats
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Revenue',
                  '₹${(analytics['totalRevenue'] ?? 12500).toStringAsFixed(0)}',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Growth Rate',
                  '+${(analytics['revenueGrowth'] ?? 12.5).toStringAsFixed(1)}%',
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Avg. Order',
                  '₹${(analytics['avgOrderValue'] ?? 0.0).toStringAsFixed(0)}',
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateRevenueSpots() {
    // Generate sample revenue data based on analytics
    final baseRevenue = (analytics['totalRevenue'] ?? 15000).toDouble();
    return [
      FlSpot(0, 0),
      FlSpot(1, baseRevenue * 0.6),
      FlSpot(2, baseRevenue * 0.8),
      FlSpot(3, baseRevenue * 0.95),
      FlSpot(4, baseRevenue),
    ];
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}