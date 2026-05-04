import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../dashboard/controllers/dashboard_controller.dart';

class AnalyticsView extends StatelessWidget {
  AnalyticsView({super.key});

  // Reusing the same DashboardController to access real-time history
  final DashboardController controller = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            margin: const EdgeInsets.only(bottom: 32),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Analytics',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE600),
                    border: Border.all(color: Colors.black, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    'LIVE TRENDS',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Suhu Chart Card
          _buildChartCard(
            title: 'SUHU (°C)',
            icon: Icons.thermostat,
            iconColor: const Color(0xFFDEC800),
            accentColor: const Color(0xFFFFE600),
            lineColor: const Color(0xFFBA1A1A),
            historyData: controller.temperatureHistory,
            minY: 15,
            maxY: 45,
          ),

          const SizedBox(height: 24),

          // Kelembaban Chart Card
          _buildChartCard(
            title: 'KELEMBABAN (%)',
            icon: Icons.water_drop,
            iconColor: const Color(0xFF0040E0),
            accentColor: const Color(0xFF2E5BFF),
            lineColor: const Color(0xFF0040E0),
            historyData: controller.humidityHistory,
            minY: 0,
            maxY: 100,
            isLightAccent: false,
          ),

          const SizedBox(height: 80), // Padding for Bottom Navigation
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color accentColor,
    required Color lineColor,
    required RxList<FlSpot> historyData,
    required double minY,
    required double maxY,
    bool isLightAccent = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor,
              border: const Border(
                bottom: BorderSide(color: Colors.black, width: 3),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: isLightAccent ? Colors.black : Colors.white),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isLightAccent ? Colors.black : Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Chart Body
          Container(
            height: 200,
            padding: const EdgeInsets.only(
              right: 24,
              left: 12,
              top: 24,
              bottom: 12,
            ),
            child: Obx(() {
              if (historyData.isEmpty) {
                return Center(
                  child: Text(
                    'Waiting for data...',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              }

              return LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  minX: historyData.first.x,
                  maxX: historyData.last.x > historyData.first.x
                      ? historyData.last.x
                      : historyData.first.x + 1,
                  lineTouchData: const LineTouchData(enabled: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: (maxY - minY) / 4,
                    verticalInterval: 10,
                    getDrawingHorizontalLine: (value) {
                      return const FlLine(
                        color: Colors.black,
                        strokeWidth: 2,
                        dashArray: [4, 4],
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return const FlLine(
                        color: Colors.black,
                        strokeWidth: 2,
                        dashArray: [4, 4],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 10,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: (maxY - minY) / 4,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: historyData.toList(),
                      isCurved: false,
                      color: lineColor,
                      barWidth: 5,
                      isStrokeCapRound: false,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: lineColor.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 0),
              );
            }),
          ),
        ],
      ),
    );
  }
}
