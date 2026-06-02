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
          // Elegant Analytics Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0A1F30), // Brand Navy
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Real-time metrics and data streams',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
              // Glowing Live Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0D9488), // Teal
                      Color(0xFF0EA5E9), // Cyan
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.circle,
                      color: Colors.white,
                      size: 6,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE TRENDS',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Obx(() {
            final sensors = controller.devices.where((d) => d.type == 'sensor').toList();
            if (sensors.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: Color(0xFF94A3B8),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No sensors detected yet',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0A1F30),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Once nodes are connected, live telemetry graphs will show here.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: sensors.map((sensor) {
                final n = sensor.name.toLowerCase();
                
                final title = sensor.name.toUpperCase();
                IconData icon;
                Color accentColor;
                Color iconBgColor;
                
                if (n.contains('temp') || n.contains('suhu')) {
                  icon = Icons.thermostat_rounded;
                  accentColor = const Color(0xFFFF6B35);
                  iconBgColor = const Color(0xFFFFF4EF);
                } else if (n.contains('hum') || n.contains('kelembaban') && !n.contains('tanah')) {
                  icon = Icons.water_drop_rounded;
                  accentColor = const Color(0xFF0284C7);
                  iconBgColor = const Color(0xFFF0F9FF);
                } else if (n.contains('light') || n.contains('ldr') || n.contains('cahaya')) {
                  icon = Icons.wb_sunny_rounded;
                  accentColor = const Color(0xFFF59E0B);
                  iconBgColor = const Color(0xFFFFFBEB);
                } else if (n.contains('dist') || n.contains('jarak')) {
                  icon = Icons.straighten_rounded;
                  accentColor = const Color(0xFF0D9488);
                  iconBgColor = const Color(0xFFF0FDFA);
                } else if (n.contains('soil') || n.contains('tanah')) {
                  icon = Icons.grass_rounded;
                  accentColor = const Color(0xFF8B5CF6);
                  iconBgColor = const Color(0xFFF5F3FF);
                } else {
                  icon = Icons.sensors_rounded;
                  accentColor = const Color(0xFF10B981);
                  iconBgColor = const Color(0xFFECFDF5);
                }

                // Adjust min/max based on known sensor types or history data
                double minY = 0;
                double maxY = 100;
                
                if (n.contains('temp') || n.contains('suhu')) {
                  minY = 15;
                  maxY = 40;
                } else if (n.contains('hum') || n.contains('kelembaban') && !n.contains('tanah')) {
                  minY = 30;
                  maxY = 90;
                } else if (n.contains('soil') || n.contains('tanah')) {
                  minY = 20;
                  maxY = 80;
                } else if (n.contains('dist') || n.contains('jarak')) {
                  minY = 0;
                  maxY = 80;
                } else if (n.contains('light') || n.contains('cahaya')) {
                  minY = 0;
                  maxY = 1000;
                } else if (sensor.history.isNotEmpty) {
                  // auto scale
                  double min = sensor.history.first.y;
                  double max = sensor.history.first.y;
                  for (var spot in sensor.history) {
                    if (spot.y < min) min = spot.y;
                    if (spot.y > max) max = spot.y;
                  }
                  minY = (min - 10).clamp(0.0, double.infinity);
                  maxY = max + 10;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: _buildChartCard(
                    title: title,
                    unit: sensor.unit,
                    icon: icon,
                    iconBgColor: iconBgColor,
                    accentColor: accentColor,
                    historyData: sensor.history,
                    minY: minY,
                    maxY: maxY,
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
    required String unit,
    required IconData icon,
    required Color iconBgColor,
    required Color accentColor,
    required RxList<FlSpot> historyData,
    required double minY,
    required double maxY,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title + (unit.isNotEmpty ? ' ($unit)' : ''),
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0A1F30),
                      ),
                    ),
                  ),
                  // Pulse dot for live data
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Chart Body
            Container(
              height: 200,
              padding: const EdgeInsets.fromLTRB(12, 16, 24, 12),
              child: Obx(() {
                if (historyData.isEmpty) {
                  return Center(
                    child: Text(
                      'Waiting for stream telemetry…',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFBBBBBB),
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
                          color: Color(0xFFF1F5F9),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return const FlLine(
                          color: Color(0xFFF1F5F9),
                          strokeWidth: 1,
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
                          reservedSize: 24,
                          interval: 10,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                value.toInt().toString(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: (maxY - minY) / 4,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: Text(
                                value.toInt().toString(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF94A3B8),
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
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                        left: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                        top: BorderSide.none,
                        right: BorderSide.none,
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: historyData.toList(),
                        isCurved: true,
                        color: accentColor,
                        barWidth: 3.5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: accentColor.withValues(alpha: 0.08),
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
      ),
    );
  }
}
