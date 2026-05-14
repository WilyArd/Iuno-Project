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

          Obx(() {
            final sensors = controller.devices.where((d) => d.type == 'sensor').toList();
            if (sensors.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No sensors detected yet.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: sensors.map((sensor) {
                // Determine colors based on name or arbitrary logic
                final isTemp = sensor.name.toLowerCase().contains('temp') || sensor.name.toLowerCase().contains('suhu');
                final isHumid = sensor.name.toLowerCase().contains('hum') || sensor.name.toLowerCase().contains('kelembaban');
                
                final title = sensor.name.toUpperCase() + (sensor.unit.isNotEmpty ? ' (${sensor.unit})' : '');
                final icon = isTemp ? Icons.thermostat : (isHumid ? Icons.water_drop : Icons.sensors);
                final accentColor = isTemp ? const Color(0xFFFFE600) : (isHumid ? const Color(0xFF2E5BFF) : const Color(0xFF00E676));
                final iconColor = isTemp ? const Color(0xFFDEC800) : (isHumid ? const Color(0xFF0040E0) : const Color(0xFF00C853));
                final lineColor = isTemp ? const Color(0xFFBA1A1A) : (isHumid ? const Color(0xFF0040E0) : const Color(0xFF000000));
                final isLightAccent = !isHumid;

                // Adjust min/max based on known sensor types or history data
                double minY = 0;
                double maxY = 100;
                if (isTemp) {
                  minY = 15;
                  maxY = 45;
                }
                
                if (!isTemp && !isHumid && sensor.history.isNotEmpty) {
                  // auto scale
                  double min = sensor.history.first.y;
                  double max = sensor.history.first.y;
                  for (var spot in sensor.history) {
                    if (spot.y < min) min = spot.y;
                    if (spot.y > max) max = spot.y;
                  }
                  minY = (min - 10).clamp(0, double.infinity);
                  maxY = max + 10;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: _buildChartCard(
                    title: title,
                    icon: icon,
                    iconColor: iconColor,
                    accentColor: accentColor,
                    lineColor: lineColor,
                    historyData: sensor.history,
                    minY: minY,
                    maxY: maxY,
                    isLightAccent: isLightAccent,
                  ),
                );
              }).toList(),
            );
          }),

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
