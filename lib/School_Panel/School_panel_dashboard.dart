import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/School_Panel/school_panel_dashboard_bloc.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../Theme/apptheme.dart';
import '../screens/main_layout.dart';
import 'dart:ui';

// ============================================================================
// MAIN DASHBOARD SCREEN
// ============================================================================
class SchoolPanelDashboard extends StatelessWidget {
  const SchoolPanelDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔥 Get schoolRecNo from UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final schoolRecNo = int.tryParse(userProvider.userCode ?? '0') ?? 0;

    print("🔍 [SchoolPanelDashboard] UserCode from Provider: ${userProvider.userCode}");
    print("🔍 [SchoolPanelDashboard] Parsed School_RecNo: $schoolRecNo");

    return BlocProvider(
      create: (context) => SchoolPanelBloc()
        ..add(LoadDashboardData(
          schoolRecNo: schoolRecNo, // 🔥 Use from provider
          academicYear: '2025-26',
        )),
      child: const MainLayout(
        activeScreen: AppScreen.schoolPanel,
        child: SchoolDashboardView(),
      ),
    );
  }
}

// ============================================================================
// DASHBOARD VIEW
// ============================================================================
class SchoolDashboardView extends StatelessWidget {
  const SchoolDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SchoolPanelBloc, SchoolPanelState>(
      builder: (context, state) {
        if (state is SchoolPanelLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.accentGreen,
            ),
          );
        }

        if (state is SchoolPanelError) {
          // 🔥 Get schoolRecNo for retry
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          final schoolRecNo = int.tryParse(userProvider.userCode ?? '0') ?? 0;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.danger,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    state.message,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.bodyText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                _HoverButton(
                  onPressed: () {
                    context.read<SchoolPanelBloc>().add(
                      RefreshDashboard(
                        schoolRecNo: schoolRecNo, // 🔥 Use from provider
                        academicYear: '2025-26',
                      ),
                    );
                  },
                  icon: Iconsax.refresh,
                  label: 'Retry',
                ),
              ],
            ),
          );
        }

        if (state is DashboardLoaded) {
          // 🔥 Get schoolRecNo for refresh
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          final schoolRecNo = int.tryParse(userProvider.userCode ?? '0') ?? 0;

          return RefreshIndicator(
            color: AppTheme.accentGreen,
            onRefresh: () async {
              context.read<SchoolPanelBloc>().add(
                RefreshDashboard(
                  schoolRecNo: schoolRecNo, // 🔥 Use from provider
                  academicYear: '2025-26',
                ),
              );
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(_getResponsivePadding(constraints.maxWidth)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, constraints.maxWidth),
                        SizedBox(height: _getResponsiveSpacing(constraints.maxWidth)),
                        _buildKpiCards(context, state.data.kpiSummary, constraints.maxWidth),
                        SizedBox(height: _getResponsiveSpacing(constraints.maxWidth)),
                        _buildChartsSection(context, state.data, constraints.maxWidth),
                        SizedBox(height: _getResponsiveSpacing(constraints.maxWidth)),
                        _buildBottomSection(context, state.data, constraints.maxWidth),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  double _getResponsivePadding(double width) {
    if (width > 1400) return 32.0;
    if (width > 1024) return 28.0;
    if (width > 768) return 24.0;
    if (width > 600) return 20.0;
    if (width > 480) return 16.0;
    return 12.0;
  }

  double _getResponsiveSpacing(double width) {
    if (width > 1400) return 32.0;
    if (width > 1024) return 28.0;
    if (width > 768) return 24.0;
    if (width > 600) return 20.0;
    if (width > 480) return 18.0;
    return 16.0;
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================
  Widget _buildHeader(BuildContext context, double screenWidth) {
    // 🔥 Get schoolRecNo for refresh button
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final schoolRecNo = int.tryParse(userProvider.userCode ?? '0') ?? 0;

    final isMobile = screenWidth < 600;
    return isMobile
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'School Dashboard',
          style: GoogleFonts.poppins(
            fontSize: screenWidth > 480 ? 24 : 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Academic Year 2025-26',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth > 480 ? 13 : 11,
                  color: AppTheme.bodyText,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _HoverButton(
              onPressed: () {
                context.read<SchoolPanelBloc>().add(
                  RefreshDashboard(
                    schoolRecNo: schoolRecNo, // 🔥 Use from provider
                    academicYear: '2025-26',
                  ),
                );
              },
              icon: Iconsax.refresh,
              label: 'Refresh',
              isCompact: true,
            ),
          ],
        ),
      ],
    )
        : Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'School Dashboard',
              style: GoogleFonts.poppins(
                fontSize: screenWidth > 1400 ? 32 : screenWidth > 1024 ? 30 : 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Academic Year 2025-26',
              style: GoogleFonts.poppins(
                fontSize: screenWidth > 1024 ? 14 : 13,
                color: AppTheme.bodyText,
              ),
            ),
          ],
        ),
        _HoverButton(
          onPressed: () {
            context.read<SchoolPanelBloc>().add(
              RefreshDashboard(
                schoolRecNo: schoolRecNo, // 🔥 Use from provider
                academicYear: '2025-26',
              ),
            );
          },
          icon: Iconsax.refresh,
          label: 'Refresh',
        ),
      ],
    );
  }

  // ==========================================================================
  // KPI CARDS - FULLY RESPONSIVE
  // ==========================================================================
  Widget _buildKpiCards(BuildContext context, KpiSummary kpi, double screenWidth) {
    final crossAxisCount = _getGridColumns(screenWidth);
    final childAspectRatio = _getCardAspectRatio(screenWidth);
    final mainAxisSpacing = _getCardSpacing(screenWidth);
    final crossAxisSpacing = _getCardSpacing(screenWidth);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
      children: [
        _AnimatedKpiCard(
          title: 'Total Students',
          value: kpi.totalStudents.toString(),
          icon: Iconsax.people,
          gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
          isPositive: true,
          screenWidth: screenWidth,
        ),
        _AnimatedKpiCard(
          title: 'Total Teachers',
          value: kpi.totalTeachers.toString(),
          icon: Iconsax.teacher,
          gradientColors: [AppTheme.accentGreen, AppTheme.primaryGreen],
          isPositive: true,
          screenWidth: screenWidth,
        ),
        _AnimatedKpiCard(
          title: 'Active Subjects',
          value: kpi.totalSubjects.toString(),
          icon: Iconsax.book,
          gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
          isPositive: true,
          screenWidth: screenWidth,
        ),
        _AnimatedKpiCard(
          title: 'Classes',
          value: kpi.totalClasses.toString(),
          icon: Iconsax.category,
          gradientColors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          isPositive: true,
          screenWidth: screenWidth,
        ),
        _AnimatedKpiCard(
          title: 'Teacher-Student Ratio',
          value: '${kpi.teacherStudentRatio.toStringAsFixed(1)}:1',
          icon: Iconsax.chart_1,
          gradientColors: [Color(0xFFfa709a), Color(0xFFfee140)],
          isPositive: false,
          screenWidth: screenWidth,
        ),
      ],
    );
  }

  int _getGridColumns(double width) {
    if (width >= 1024) return 5;
    if (width >= 768) return 3;
    if (width >= 480) return 2;
    return 2;
  }

  double _getCardAspectRatio(double width) {
    if (width >= 1400) return 1.5;
    if (width >= 1024) return 1.4;
    if (width >= 768) return 1.6;
    if (width >= 600) return 1.8;
    if (width >= 480) return 1.7;
    return 1.5;
  }

  double _getCardSpacing(double width) {
    if (width >= 1024) return 16.0;
    if (width >= 768) return 14.0;
    if (width >= 480) return 12.0;
    return 10.0;
  }

  // ==========================================================================
  // CHARTS SECTION
  // ==========================================================================
  Widget _buildChartsSection(BuildContext context, DashboardData data, double screenWidth) {
    final isMobile = screenWidth < 768;

    if (isMobile) {
      return Column(
        children: [
          _buildEnrollmentChart(context, data.enrollmentTrend, screenWidth),
          SizedBox(height: _getCardSpacing(screenWidth)),
          _buildGenderChart(context, data.genderDistribution, screenWidth),
          SizedBox(height: _getCardSpacing(screenWidth)),
          _buildClassDistributionChart(context, data.classDistribution, screenWidth),
          SizedBox(height: _getCardSpacing(screenWidth)),
          _buildTeacherWorkloadChart(context, data.teacherWorkload, screenWidth),
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildEnrollmentChart(context, data.enrollmentTrend, screenWidth),
            ),
            SizedBox(width: screenWidth > 1024 ? 24 : 16),
            Expanded(
              child: _buildGenderChart(context, data.genderDistribution, screenWidth),
            ),
          ],
        ),
        SizedBox(height: screenWidth > 1024 ? 24 : 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildClassDistributionChart(context, data.classDistribution, screenWidth),
            ),
            SizedBox(width: screenWidth > 1024 ? 24 : 16),
            Expanded(
              child: _buildTeacherWorkloadChart(context, data.teacherWorkload, screenWidth),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================================
  // ENROLLMENT TREND CHART
  // ==========================================================================
  Widget _buildEnrollmentChart(BuildContext context, List<EnrollmentData> data, double screenWidth) {
    return _HoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Student Enrollment Trend',
                  style: GoogleFonts.poppins(
                    fontSize: _getChartTitleSize(screenWidth),
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(screenWidth > 480 ? 8 : 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Iconsax.chart_21,
                  color: AppTheme.accentGreen,
                  size: screenWidth > 480 ? 20 : 18,
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth > 768 ? 20 : 16),
          SizedBox(
            height: _getChartHeight(screenWidth),
            child: data.isEmpty
                ? Center(
              child: Text(
                'No enrollment data available',
                style: GoogleFonts.poppins(
                  color: AppTheme.bodyText,
                  fontSize: _getChartLabelSize(screenWidth),
                ),
              ),
            )
                : SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: GoogleFonts.poppins(
                  fontSize: _getChartLabelSize(screenWidth),
                  color: AppTheme.bodyText,
                ),
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: GoogleFonts.poppins(
                  fontSize: _getChartLabelSize(screenWidth),
                  color: AppTheme.bodyText,
                ),
                minimum: 0,
                majorGridLines: MajorGridLines(
                  width: 1,
                  color: AppTheme.borderGrey,
                ),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                color: AppTheme.primaryGreen,
                textStyle: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                ),
                format: 'Month: point.x\nStudents: point.y',
              ),
              series: <CartesianSeries<EnrollmentData, String>>[
                SplineAreaSeries<EnrollmentData, String>(
                  dataSource: data,
                  xValueMapper: (EnrollmentData data, _) => data.month,
                  yValueMapper: (EnrollmentData data, _) => data.count,
                  color: AppTheme.accentGreen.withOpacity(0.2),
                  borderColor: AppTheme.accentGreen,
                  borderWidth: 3,
                  markerSettings: MarkerSettings(
                    isVisible: true,
                    height: screenWidth > 480 ? 8 : 6,
                    width: screenWidth > 480 ? 8 : 6,
                    color: Colors.white,
                    borderWidth: 2,
                    borderColor: AppTheme.accentGreen,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentGreen.withOpacity(0.4),
                      AppTheme.accentGreen.withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // GENDER DISTRIBUTION CHART
  // ==========================================================================
  Widget _buildGenderChart(BuildContext context, List<GenderData> data, double screenWidth) {
    return _HoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Gender Distribution',
                  style: GoogleFonts.poppins(
                    fontSize: _getChartTitleSize(screenWidth),
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(screenWidth > 480 ? 8 : 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Iconsax.chart,
                  color: AppTheme.primaryGreen,
                  size: screenWidth > 480 ? 20 : 18,
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth > 768 ? 20 : 16),
          SizedBox(
            height: _getChartHeight(screenWidth),
            child: data.isEmpty
                ? Center(
              child: Text(
                'No gender data available',
                style: GoogleFonts.poppins(
                  color: AppTheme.bodyText,
                  fontSize: _getChartLabelSize(screenWidth),
                ),
              ),
            )
                : SfCircularChart(
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                textStyle: GoogleFonts.poppins(
                  fontSize: _getChartLabelSize(screenWidth),
                  color: AppTheme.bodyText,
                ),
                overflowMode: LegendItemOverflowMode.wrap,
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                color: AppTheme.primaryGreen,
                textStyle: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                ),
                format: 'Gender: point.x\nStudents: point.y (point.text)',
              ),
              series: <CircularSeries<GenderData, String>>[
                DoughnutSeries<GenderData, String>(
                  dataSource: data,
                  xValueMapper: (GenderData data, _) => data.gender,
                  yValueMapper: (GenderData data, _) => data.count,
                  dataLabelMapper: (GenderData data, _) =>
                  '${data.percentage.toStringAsFixed(1)}%',
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    textStyle: GoogleFonts.poppins(
                      fontSize: _getChartLabelSize(screenWidth),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  pointColorMapper: (GenderData data, _) {
                    if (data.gender.toLowerCase() == 'male') {
                      return AppTheme.accentGreen;
                    } else if (data.gender.toLowerCase() == 'female') {
                      return AppTheme.primaryGreen;
                    } else {
                      return const Color(0xFF1A5F3F);
                    }
                  },
                  innerRadius: '60%',
                  explode: true,
                  explodeOffset: '5%',
                  explodeGesture: ActivationMode.singleTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // CLASS DISTRIBUTION CHART (TOP 10)
  // ==========================================================================
  Widget _buildClassDistributionChart(BuildContext context, List<ClassDistribution> data, double screenWidth) {
    final filteredData = data
        .where((item) => item.studentCount > 0)
        .toList()
      ..sort((a, b) => b.studentCount.compareTo(a.studentCount));

    final top10Classes = filteredData.take(10).toList();

    return _HoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class Distribution',
                      style: GoogleFonts.poppins(
                        fontSize: _getChartTitleSize(screenWidth),
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                    if (top10Classes.length < data.length)
                      Text(
                        'Top ${top10Classes.length}',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth > 480 ? 11 : 9,
                          color: AppTheme.bodyText.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(screenWidth > 480 ? 8 : 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Iconsax.diagram,
                  color: AppTheme.accentGreen,
                  size: screenWidth > 480 ? 20 : 18,
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth > 768 ? 20 : 16),
          SizedBox(
            height: _getChartHeight(screenWidth),
            child: top10Classes.isEmpty
                ? Center(
              child: Text(
                'No students in any class yet',
                style: GoogleFonts.poppins(
                  color: AppTheme.bodyText,
                  fontSize: _getChartLabelSize(screenWidth),
                ),
              ),
            )
                : SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: GoogleFonts.poppins(
                  fontSize: _getChartLabelSize(screenWidth) - 1,
                  color: AppTheme.bodyText,
                ),
                labelRotation: -45,
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: GoogleFonts.poppins(
                  fontSize: _getChartLabelSize(screenWidth),
                  color: AppTheme.bodyText,
                ),
                minimum: 0,
                majorGridLines: MajorGridLines(
                  width: 1,
                  color: AppTheme.borderGrey,
                ),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                color: AppTheme.primaryGreen,
                textStyle: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                ),
                format: 'Class: point.x\nStudents: point.y',
              ),
              series: <CartesianSeries<ClassDistribution, String>>[
                ColumnSeries<ClassDistribution, String>(
                  dataSource: top10Classes,
                  xValueMapper: (ClassDistribution data, _) => data.className,
                  yValueMapper: (ClassDistribution data, _) => data.studentCount,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentGreen,
                      AppTheme.primaryGreen,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  dataLabelSettings: DataLabelSettings(
                    isVisible: screenWidth > 480,
                    textStyle: GoogleFonts.poppins(
                      fontSize: _getChartLabelSize(screenWidth),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  spacing: 0.2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TEACHER WORKLOAD CHART (TOP 6)
  // ==========================================================================
  Widget _buildTeacherWorkloadChart(BuildContext context, List<TeacherWorkload> data, double screenWidth) {
    final filteredData = data
        .where((teacher) => teacher.totalAllotments > 0)
        .toList()
      ..sort((a, b) => b.totalAllotments.compareTo(a.totalAllotments));

    final top6Teachers = filteredData.take(6).toList();

    return _HoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teacher Workload',
                      style: GoogleFonts.poppins(
                        fontSize: _getChartTitleSize(screenWidth),
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                    if (top6Teachers.length < filteredData.length)
                      Text(
                        'Top ${top6Teachers.length}',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth > 480 ? 11 : 9,
                          color: AppTheme.bodyText.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(screenWidth > 480 ? 8 : 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Iconsax.teacher,
                  color: AppTheme.primaryGreen,
                  size: screenWidth > 480 ? 20 : 18,
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth > 768 ? 20 : 16),
          SizedBox(
            height: _getChartHeight(screenWidth),
            child: top6Teachers.isEmpty
                ? Center(
              child: Text(
                'No teacher workload data available',
                style: GoogleFonts.poppins(
                  color: AppTheme.bodyText,
                  fontSize: _getChartLabelSize(screenWidth),
                ),
              ),
            )
                : SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: GoogleFonts.poppins(
                  fontSize: _getChartLabelSize(screenWidth) - 1,
                  color: AppTheme.bodyText,
                ),
                labelRotation: -45,
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: GoogleFonts.poppins(
                  fontSize: _getChartLabelSize(screenWidth),
                  color: AppTheme.bodyText,
                ),
                minimum: 0,
                majorGridLines: MajorGridLines(
                  width: 1,
                  color: AppTheme.borderGrey,
                ),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                color: AppTheme.primaryGreen,
                textStyle: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                ),
                format: 'Teacher: point.x\npoint.y subjects allotted',
              ),
              series: <CartesianSeries<TeacherWorkload, String>>[
                BarSeries<TeacherWorkload, String>(
                  dataSource: top6Teachers,
                  xValueMapper: (TeacherWorkload data, _) => data.teacherName,
                  yValueMapper: (TeacherWorkload data, _) => data.totalAllotments,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryGreen,
                      AppTheme.accentGreen,
                    ],
                  ),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(8),
                  ),
                  dataLabelSettings: DataLabelSettings(
                    isVisible: screenWidth > 480,
                    textStyle: GoogleFonts.poppins(
                      fontSize: _getChartLabelSize(screenWidth),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  spacing: 0.3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for responsive chart sizing
  double _getChartTitleSize(double width) {
    if (width >= 768) return 18;
    if (width >= 480) return 16;
    return 14;
  }

  double _getChartLabelSize(double width) {
    if (width >= 768) return 11;
    if (width >= 480) return 10;
    return 8;
  }

  double _getChartHeight(double width) {
    if (width >= 1024) return 280;
    if (width >= 768) return 250;
    if (width >= 480) return 220;
    return 200;
  }

  // ==========================================================================
  // BOTTOM SECTION
  // ==========================================================================
  Widget _buildBottomSection(BuildContext context, DashboardData data, double screenWidth) {
    final isMobile = screenWidth < 768;

    if (isMobile) {
      return Column(
        children: [
          _buildRecentActivities(context, data.recentActivities, screenWidth),
          SizedBox(height: _getCardSpacing(screenWidth)),
          _buildYearComparison(context, data.yearComparison, screenWidth),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildRecentActivities(context, data.recentActivities, screenWidth),
        ),
        SizedBox(width: screenWidth > 1024 ? 24 : 16),
        Expanded(
          child: _buildYearComparison(context, data.yearComparison, screenWidth),
        ),
      ],
    );
  }

  // ==========================================================================
  // RECENT ACTIVITIES
  // ==========================================================================
  Widget _buildRecentActivities(BuildContext context, List<ActivityItem> activities, double screenWidth) {
    return _HoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Recent Activities',
                  style: GoogleFonts.poppins(
                    fontSize: _getChartTitleSize(screenWidth),
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(screenWidth > 480 ? 8 : 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Iconsax.clock,
                  color: AppTheme.accentGreen,
                  size: screenWidth > 480 ? 20 : 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          activities.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'No recent activities',
                style: GoogleFonts.poppins(
                  color: AppTheme.bodyText,
                  fontSize: _getChartLabelSize(screenWidth),
                ),
              ),
            ),
          )
              : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length > 5 ? 5 : activities.length,
            separatorBuilder: (context, index) => Divider(
              height: 24,
              color: AppTheme.borderGrey,
            ),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _ActivityItem(activity: activity, screenWidth: screenWidth);
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // YEAR COMPARISON
  // ==========================================================================
  Widget _buildYearComparison(BuildContext context, List<YearComparison> data, double screenWidth) {
    return _HoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Year Comparison',
                  style: GoogleFonts.poppins(
                    fontSize: _getChartTitleSize(screenWidth),
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(screenWidth > 480 ? 8 : 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Iconsax.trend_up,
                  color: AppTheme.primaryGreen,
                  size: screenWidth > 480 ? 20 : 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...data.map((item) {
            final isPrevious = item.period.contains('Previous');
            final maxCount = data.map((e) => e.studentCount).reduce((a, b) => a > b ? a : b);
            final progress = maxCount > 0 ? item.studentCount / maxCount : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          item.period,
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth > 768 ? 14 : 13,
                            color: AppTheme.bodyText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        item.studentCount.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth > 768 ? 22 : screenWidth > 480 ? 20 : 18,
                          fontWeight: FontWeight.w700,
                          color: isPrevious ? AppTheme.bodyText : AppTheme.accentGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: progress),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: screenWidth > 480 ? 10 : 8,
                          backgroundColor: AppTheme.lightGrey,
                          color: isPrevious ? AppTheme.bodyText.withOpacity(0.5) : AppTheme.accentGreen,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================================
// ANIMATED KPI CARD - RESPONSIVE
// ============================================================================
class _AnimatedKpiCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isPositive;
  final double screenWidth;

  const _AnimatedKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradientColors,
    required this.isPositive,
    required this.screenWidth,
  });

  @override
  State<_AnimatedKpiCard> createState() => _AnimatedKpiCardState();
}

class _AnimatedKpiCardState extends State<_AnimatedKpiCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final padding = widget.screenWidth >= 768 ? 16.0 : widget.screenWidth >= 480 ? 14.0 : 12.0;
    final iconSize = widget.screenWidth >= 768 ? 20.0 : widget.screenWidth >= 480 ? 18.0 : 16.0;
    final valueSize = widget.screenWidth >= 768 ? 24.0 : widget.screenWidth >= 480 ? 20.0 : 18.0;
    final titleSize = widget.screenWidth >= 768 ? 12.0 : widget.screenWidth >= 480 ? 11.0 : 10.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.gradientColors[0].withOpacity(0.4)
                  : widget.gradientColors[0].withOpacity(0.2),
              blurRadius: _isHovered ? 20 : 10,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(_isHovered ? padding * 0.625 : padding * 0.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: _isHovered ? iconSize + 2 : iconSize,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.screenWidth >= 480 ? 8 : 6,
                      vertical: widget.screenWidth >= 480 ? 4 : 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isPositive ? Iconsax.arrow_up_3 : Iconsax.arrow_down,
                          size: widget.screenWidth >= 480 ? 12 : 10,
                          color: Colors.white,
                        ),
                        SizedBox(width: widget.screenWidth >= 480 ? 4 : 2),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Text(
                          widget.value,
                          style: GoogleFonts.poppins(
                            fontSize: valueSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontSize: titleSize,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HOVER CARD
// ============================================================================
class _HoverCard extends StatefulWidget {
  final Widget child;

  const _HoverCard({required this.child});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0),
        padding: EdgeInsets.all(MediaQuery.of(context).size.width > 480 ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? AppTheme.accentGreen.withOpacity(0.3) : Colors.transparent,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? AppTheme.accentGreen.withOpacity(0.15)
                  : AppTheme.borderGrey.withOpacity(0.3),
              blurRadius: _isHovered ? 20 : 10,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

// ============================================================================
// HOVER BUTTON
// ============================================================================
class _HoverButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isCompact;

  const _HoverButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isCompact = false,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
        child: ElevatedButton.icon(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isHovered ? AppTheme.primaryGreen : AppTheme.accentGreen,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 16 : 24,
              vertical: widget.isCompact ? 12 : 16,
            ),
            elevation: _isHovered ? 8 : 2,
            shadowColor: AppTheme.accentGreen.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(widget.icon, size: widget.isCompact ? 18 : 20),
          label: Text(
            widget.label,
            style: GoogleFonts.poppins(
              fontSize: widget.isCompact ? 13 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ACTIVITY ITEM
// ============================================================================
class _ActivityItem extends StatefulWidget {
  final ActivityItem activity;
  final double screenWidth;

  const _ActivityItem({
    required this.activity,
    required this.screenWidth,
  });

  @override
  State<_ActivityItem> createState() => _ActivityItemState();
}

class _ActivityItemState extends State<_ActivityItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (widget.activity.type.toLowerCase()) {
      case 'student':
        icon = Iconsax.user;
        color = AppTheme.accentGreen;
        break;
      case 'teacher':
        icon = Iconsax.teacher;
        color = AppTheme.primaryGreen;
        break;
      case 'allotment':
        icon = Iconsax.book;
        color = const Color(0xFF1E8E3E);
        break;
      case 'content':
        icon = Iconsax.document;
        color = AppTheme.accentGreen;
        break;
      default:
        icon = Iconsax.info_circle;
        color = AppTheme.bodyText;
    }

    final iconPadding = widget.screenWidth > 480 ? 10.0 : 8.0;
    final titleSize = widget.screenWidth > 768 ? 14.0 : widget.screenWidth > 480 ? 13.0 : 12.0;
    final descSize = widget.screenWidth > 768 ? 13.0 : widget.screenWidth > 480 ? 12.0 : 11.0;
    final timeSize = widget.screenWidth > 768 ? 11.0 : widget.screenWidth > 480 ? 10.0 : 9.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(_isHovered ? 12 : 8),
        decoration: BoxDecoration(
          color: _isHovered ? color.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(_isHovered ? iconPadding + 2 : iconPadding),
              decoration: BoxDecoration(
                color: color.withOpacity(_isHovered ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: widget.screenWidth > 480 ? 20 : 18),
            ),
            SizedBox(width: widget.screenWidth > 480 ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.activity.title,
                    style: GoogleFonts.poppins(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.activity.description,
                    style: GoogleFonts.poppins(
                      fontSize: descSize,
                      color: AppTheme.bodyText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(widget.activity.time),
                    style: GoogleFonts.poppins(
                      fontSize: timeSize,
                      color: AppTheme.bodyText.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return dateTimeStr;
    }
  }
}
