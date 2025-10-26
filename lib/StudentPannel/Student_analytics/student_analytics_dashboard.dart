import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/StudentPannel/Service/student_analytics_dashboard_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart' as gauges;
import 'dart:math' as math;
import 'dart:ui';

class StudentAnalyticsDashboard extends StatefulWidget {
  const StudentAnalyticsDashboard({super.key});

  @override
  State<StudentAnalyticsDashboard> createState() => _StudentAnalyticsDashboardState();
}

class _StudentAnalyticsDashboardState extends State<StudentAnalyticsDashboard>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedTimeRange = 'This Week';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Data from API
  Map<String, dynamic> _analyticsData = {};
  List<Map<String, dynamic>> _subjectsData = [];
  List<Map<String, dynamic>> _weeklyData = [];
  List<Map<String, dynamic>> _heatmapData = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _loadDashboardData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final studentId = userProvider.userCode;

      if (studentId == null) {
        throw Exception('Student ID not found. Please login again.');
      }

      String timeRange;
      if (_selectedTimeRange == 'This Week') {
        timeRange = 'THIS_WEEK';
      } else if (_selectedTimeRange == 'This Month') {
        timeRange = 'THIS_MONTH';
      } else {
        timeRange = 'ALL_TIME';
      }

      final data = await StudentAnalyticsDashboardService.getDashboardData(
        studentId: studentId,
        timeRange: timeRange,
      );

      if (mounted) {
        setState(() {
          _analyticsData = {
            'student_id': data['overview']['Student_ID'] ?? '',
            'student_name': data['overview']['Student_Name'] ?? 'Student',
            'student_photo': StudentAnalyticsDashboardService.getStudentPhotoUrl(
                data['overview']['Student_Photo_Path']
            ),
            'school_name': data['overview']['School_Name'] ?? 'School',
            'school_logo': data['overview']['School_Logo_Full_URL'] ?? '',
            'class': data['overview']['Class_Name'] ?? 'Class',
            'section': data['overview']['Section_Division'] ?? '',
            'overall_progress': (data['overview']['Overall_Progress'] ?? 0.0).toDouble(),
            'weekly_progress': (data['overview']['Weekly_Progress'] ?? 0.0).toDouble(),
            'total_study_hours': (data['overview']['Total_Study_Hours'] ?? 0.0).toDouble(),
            'weekly_study_hours': (data['overview']['Weekly_Study_Hours'] ?? 0.0).toDouble(),
            'subjects_enrolled': data['overview']['Subjects_Enrolled'] ?? 0,
            'completed_chapters': data['overview']['Completed_Chapters'] ?? 0,
            'total_chapters': data['overview']['Total_Chapters_Started'] ?? 0,
            'average_score': (data['overview']['Average_Score'] ?? 0.0).toDouble(),
            'streak_days': data['overview']['Max_Streak'] ?? 0,
            'monthly_active_days': data['overview']['Current_Month_Active_Days'] ?? 0,
          };

          _subjectsData = (data['subjects'] as List?)?.map((subject) {
            return {
              'name': subject['SubjectName'] ?? '',
              'score': (subject['Average_Score'] ?? 0.0).toDouble(),
              'completed': subject['Chapters_Completed'] ?? 0,
              'total': subject['Total_Chapters'] ?? 1,
              'progress': (subject['Average_Progress'] ?? 0.0).toDouble(),
              'color': _getSubjectColor(subject['SubjectID'] ?? 0),
            };
          }).toList() ?? [];

          _weeklyData = (data['weekly_study'] as List?)?.map((day) {
            return {
              'day': _getShortDayName(day['Day_Name'] ?? ''),
              'hours': (day['Study_Minutes'] ?? 0) / 60.0,
              'score': (day['Performance_Score'] ?? 0.0).toDouble(),
            };
          }).toList() ?? [];

          _heatmapData = (data['activity_heatmap'] as List?)?.map((day) {
            return {
              'date': day['Day_Date'] ?? '',
              'day': day['Day_Number'] ?? 0,
              'intensity': (day['Activity_Score'] ?? 0.0) / 100.0,
              'hours': (day['Study_Minutes'] ?? 0) / 60.0,
              'chapters': day['Chapters_Studied'] ?? 0,
              'is_active': day['Is_Active'] == 1 || day['Is_Active'] == true,
            };
          }).toList() ?? [];

          _isLoading = false;
          _fadeController.forward();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
        CustomSnackbar.showError(context, _errorMessage!, title: 'Failed to Load Dashboard');
      }
    }
  }

  Color _getSubjectColor(int subjectId) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
    ];
    return colors[subjectId % colors.length];
  }

  String _getShortDayName(String fullName) {
    const dayMap = {
      'Monday': 'Mon',
      'Tuesday': 'Tue',
      'Wednesday': 'Wed',
      'Thursday': 'Thu',
      'Friday': 'Fri',
      'Saturday': 'Sat',
      'Sunday': 'Sun',
    };
    return dayMap[fullName] ?? fullName.substring(0, math.min(3, fullName.length));
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      activeScreen: AppScreen.analytics,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF8FAFC),
              const Color(0xFFE0E7FF).withOpacity(0.3),
            ],
          ),
        ),
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
            ? _buildErrorState()
            : _buildDashboardContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BeautifulLoader(
            type: LoaderType.pulse,
            size: 80,
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your analytics...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.bodyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.danger, size: 72, color: Colors.red),
          ),
          const SizedBox(height: 28),
          Text(
            'Failed to Load Analytics',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.bodyText.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadDashboardData,
            icon: const Icon(Iconsax.refresh, size: 20),
            label: Text('Try Again', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPremiumHeader(),
            const SizedBox(height: 32),
            _buildMetricsRow(),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildChartsColumn()),
                const SizedBox(width: 24),
                Expanded(child: _buildStatsColumn()),
              ],
            ),
            const SizedBox(height: 32),
            _buildSubjectsSection(),
            const SizedBox(height: 32),
            _buildActivityHeatmap(),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1),
            const Color(0xFF8B5CF6),
            const Color(0xFF06B6D4),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Row(
        children: [
          // School Logo Section
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: (_analyticsData['school_logo'] != null &&
                        _analyticsData['school_logo'].toString().isNotEmpty)
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        _analyticsData['school_logo'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Iconsax.building,
                            color: Colors.white,
                            size: 36,
                          );
                        },
                      ),
                    )
                        : const Icon(
                      Iconsax.building,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  'School Logo',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 24),

          // Student Info Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _analyticsData['school_name'] ?? 'School Name',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome back, ${_analyticsData['student_name'] ?? 'Student'}!',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip('${_analyticsData['class']} • ${_analyticsData['section']}'),
                    const SizedBox(width: 12),
                    if ((_analyticsData['streak_days'] ?? 0) > 0)
                      _buildInfoChip('🔥 ${_analyticsData['streak_days']} Days Streak'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // Student Photo Section
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: (_analyticsData['student_photo'] != null &&
                        _analyticsData['student_photo'].toString().isNotEmpty)
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        _analyticsData['student_photo'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Iconsax.user,
                            color: Colors.white,
                            size: 36,
                          );
                        },
                      ),
                    )
                        : const Icon(
                      Iconsax.user,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  'Student Photo',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 24),

          // Controls
          Column(
            children: [
              _buildGlassSelector(),
              const SizedBox(height: 12),
              _buildGlassButton(Iconsax.refresh, _loadDashboardData),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildGlassSelector() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTimeRange,
              dropdownColor: const Color(0xFF6366F1),
              icon: const Icon(Iconsax.arrow_down_1, color: Colors.white, size: 18),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              items: ['This Week', 'This Month', 'All Time']
                  .map((range) => DropdownMenuItem(value: range, child: Text(range)))
                  .toList(),
              onChanged: (value) {
                if (value != null && value != _selectedTimeRange) {
                  setState(() => _selectedTimeRange = value);
                  _loadDashboardData();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton(IconData icon, VoidCallback onTap) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withOpacity(0.2),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Iconsax.chart_21,
            title: 'Overall Progress',
            value: '${(_analyticsData['overall_progress'] ?? 0.0).toStringAsFixed(1)}%',
            subtitle: '+${(_analyticsData['weekly_progress'] ?? 0.0).toStringAsFixed(1)}% this week',
            colors: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildMetricCard(
            icon: Iconsax.clock,
            title: 'Study Time',
            value: '${(_analyticsData['total_study_hours'] ?? 0.0).toStringAsFixed(0)}h',
            subtitle: '+${(_analyticsData['weekly_study_hours'] ?? 0.0).toStringAsFixed(0)}h this week',
            colors: [const Color(0xFFEC4899), const Color(0xFFDB2777)],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildMetricCard(
            icon: Iconsax.medal_star,
            title: 'Average Score',
            value: '${(_analyticsData['average_score'] ?? 0.0).toStringAsFixed(1)}%',
            subtitle: 'Excellent performance!',
            colors: [const Color(0xFF10B981), const Color(0xFF059669)],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildMetricCard(
            icon: Iconsax.book_1,
            title: 'Chapters',
            value: '${_analyticsData['completed_chapters']}/${_analyticsData['total_chapters']}',
            subtitle: '${_analyticsData['subjects_enrolled']} subjects',
            colors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required List<Color> colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsColumn() {
    return _buildGlassCard(
      title: 'Weekly Performance',
      child: SizedBox(height: 320, child: _buildWeeklyChart()),
    );
  }

  Widget _buildStatsColumn() {
    return _buildGlassCard(
      title: 'Overall Progress',
      child: SizedBox(height: 320, child: _buildCircularGauge()),
    );
  }

  Widget _buildGlassCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_weeklyData.isEmpty) {
      return Center(
        child: Text(
          'No weekly data available',
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.bodyText.withOpacity(0.6)),
        ),
      );
    }

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.bodyText.withOpacity(0.6)),
      ),
      primaryYAxis: NumericAxis(
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        labelStyle: GoogleFonts.inter(fontSize: 11, color: AppTheme.bodyText.withOpacity(0.6)),
        title: AxisTitle(
          text: 'Study Hours',
          textStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.bodyText.withOpacity(0.7),
          ),
        ),
      ),
      series: <CartesianSeries<Map<String, dynamic>, String>>[
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: _weeklyData,
          xValueMapper: (data, _) => data['day'] as String,
          yValueMapper: (data, _) => data['hours'] as double,
          name: 'Study Hours',
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ],
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        textStyle: GoogleFonts.inter(fontSize: 12),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
    );
  }

  Widget _buildCircularGauge() {
    final progress = (_analyticsData['overall_progress'] ?? 0.0).toDouble();
    final completed = _analyticsData['completed_chapters'] ?? 0;
    final total = _analyticsData['total_chapters'] ?? 1;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 220,
          child: gauges.SfRadialGauge(
            axes: <gauges.RadialAxis>[
              gauges.RadialAxis(
                minimum: 0,
                maximum: 100,
                showLabels: false,
                showTicks: false,
                startAngle: 270,
                endAngle: 270,
                radiusFactor: 0.8,
                axisLineStyle: gauges.AxisLineStyle(
                  thickness: 0.2,
                  color: Colors.grey.shade200,
                  thicknessUnit: gauges.GaugeSizeUnit.factor,
                ),
                pointers: <gauges.GaugePointer>[
                  gauges.RangePointer(
                    value: progress,
                    width: 0.2,
                    sizeUnit: gauges.GaugeSizeUnit.factor,
                    gradient: const SweepGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFF8B5CF6)],
                    ),
                    cornerStyle: gauges.CornerStyle.bothCurve,
                  ),
                ],
                annotations: <gauges.GaugeAnnotation>[
                  gauges.GaugeAnnotation(
                    widget: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${progress.toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                              ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                          ),
                        ),
                        Text(
                          'Complete',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.bodyText.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    angle: 270,
                    positionFactor: 0.1,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildProgressStat('Completed', '$completed', const Color(0xFF10B981)),
            const SizedBox(width: 40),
            _buildProgressStat('Remaining', '${total - completed}', const Color(0xFF6366F1)),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.bodyText.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsSection() {
    if (_subjectsData.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject Performance',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: _subjectsData.map((subject) {
            return _buildSubjectCard(subject);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: subject['color'].withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [subject['color'], subject['color'].withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Iconsax.book_1, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject['name'],
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${subject['completed']} / ${subject['total']} chapters',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.bodyText.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: subject['color'].withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${subject['score'].toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: subject['color'],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: subject['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: subject['progress'] / 100,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [subject['color'], subject['color'].withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityHeatmap() {
    if (_heatmapData.isEmpty) return const SizedBox.shrink();

    return _buildGlassCard(
      title: 'Activity Heatmap (Last 31 Days)',
      child: Column(
        children: [
          _buildHeatmapGrid(),
          const SizedBox(height: 20),
          _buildHeatmapLegend(),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    final weeks = <List<Map<String, dynamic>>>[];
    List<Map<String, dynamic>> currentWeek = [];

    for (var day in _heatmapData) {
      currentWeek.add(day);
      if (currentWeek.length == 7) {
        weeks.add(List.from(currentWeek));
        currentWeek.clear();
      }
    }
    if (currentWeek.isNotEmpty) weeks.add(currentWeek);

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 40),
            ...['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
              return Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.bodyText.withOpacity(0.5),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
        const SizedBox(height: 12),
        ...weeks.asMap().entries.map((entry) {
          final weekIndex = entry.key;
          final week = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    'W${weekIndex + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.bodyText.withOpacity(0.5),
                    ),
                  ),
                ),
                ...week.map((day) {
                  final intensity = day['intensity'] as double;

                  return Expanded(
                    child: Container(
                      height: 40,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _getHeatmapColor(intensity),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: intensity > 0.5 ? [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Center(
                        child: Text(
                          day['day'].toString(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: intensity > 0.5
                                ? Colors.white
                                : AppTheme.darkText.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _getHeatmapColor(double intensity) {
    if (intensity == 0) return Colors.grey.shade100;
    if (intensity < 0.25) return const Color(0xFF6366F1).withOpacity(0.2);
    if (intensity < 0.5) return const Color(0xFF6366F1).withOpacity(0.4);
    if (intensity < 0.75) return const Color(0xFF6366F1).withOpacity(0.7);
    return const Color(0xFF6366F1);
  }

  Widget _buildHeatmapLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Less', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.bodyText.withOpacity(0.5))),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          return Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _getHeatmapColor(index / 4),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text('More', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.bodyText.withOpacity(0.5))),
      ],
    );
  }
}
