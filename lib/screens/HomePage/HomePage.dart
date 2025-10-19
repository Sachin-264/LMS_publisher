import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/screens/HomePage/dashboard_bloc.dart';
import 'package:lms_publisher/screens/School/School_manage.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      activeScreen: AppScreen.dashboard,
      child: DashboardView(),
    );
  }
}

// =================================================================== //
//                         DASHBOARD CONTENT                           //
// =================================================================== //

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardBloc>().add(FetchDashboardData());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return Center(
            child: BeautifulLoader(
              type: LoaderType.spinner,
              message: 'Loading dashboard...',
              color: AppTheme.primaryGreen,
              size: 60,
            ),
          );
        }
        if (state is DashboardLoadFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.red.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.error,
                  style: GoogleFonts.inter(color: AppTheme.bodyText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<DashboardBloc>().add(FetchDashboardData());
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.defaultBorderRadius,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        if (state is DashboardLoadSuccess) {
          final data = state.data['data'] as Map<String, dynamic>;

          final String totalSchools =
              data['TotalSchools']?['TotalSchools']?.toString() ?? '0';

          final double totalRevenueValue = double.tryParse(
              data['TotalRevenue']?['TotalRevenue']?.toString() ?? '0.0') ??
              0.0;
          final String totalRevenue =
              '₹${(totalRevenueValue / 1000).toStringAsFixed(1)}k';

          final String activeSubscriptions =
              data['ActiveSubscriptions']?['ActiveSubscriptions']?.toString() ??
                  '0';

          final String upcomingExpiry =
              data['UpcomingExpiryCount']?['UpcomingExpiryCount']?.toString() ??
                  '0';

          final String topPlan =
              data['TopSubscriptionPlan']?['TopPlan']?.toString() ?? 'N/A';

          final String autoRenewals =
              "${data['AutoRenewalEnabled']?['AutoRenewalEnabled']?.toString() ?? '0'} schools";

          final String topState =
              data['TopStateBySchoolCount']?['TopState']?.toString() ?? 'N/A';

          final String newlyRegistered =
              "${data['NewlyRegisteredSchools']?['NewlyRegistered']?.toString() ?? '0'} this month";

          final List<dynamic> monthlyRevenueData =
              data['MonthlyRevenueTrend'] as List<dynamic>? ?? [];
          final List<dynamic> schoolsByTypeData =
              data['SchoolTypeDistribution'] as List<dynamic>? ?? [];
          final List<dynamic> materialsGrowthData =
              data['MonthlyContentGrowthMaterials'] as List<dynamic>? ?? [];
          final List<dynamic> chaptersGrowthData =
              data['MonthlyContentGrowthChapters'] as List<dynamic>? ?? [];

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DashboardBloc>().add(FetchDashboardData());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Consumer<UserProvider>(
                            builder: (context, userProvider, child) {
                              return Text(
                                'Publisher',
                                style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.darkText),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Text('Monitor sales and revenue streams.',
                              style: GoogleFonts.inter(
                                  color: AppTheme.bodyText)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.defaultPadding * 1.5),
                  _KpiSection(
                    totalSchools: totalSchools,
                    totalRevenue: totalRevenue,
                    activeSubscriptions: activeSubscriptions,
                    upcomingExpiry: upcomingExpiry,
                  ),
                  const SizedBox(height: AppTheme.defaultPadding * 1.5),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isWideScreen = constraints.maxWidth >= 1100;
                      if (isWideScreen) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  _SubscriptionInsightsCard(
                                    monthlyRevenueData: monthlyRevenueData,
                                    topPlan: topPlan,
                                    autoRenewals: autoRenewals,
                                  ),
                                  const SizedBox(
                                      height: AppTheme.defaultPadding * 1.5),
                                  _AcademicInsightsCard(
                                    materialsData: materialsGrowthData,
                                    chaptersData: chaptersGrowthData,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                                width: AppTheme.defaultPadding * 1.5),
                            Expanded(
                              flex: 2,
                              child: _SchoolInsightsCard(
                                schoolsByTypeData: schoolsByTypeData,
                                totalSchools: totalSchools,
                                topState: topState,
                                newlyRegistered: newlyRegistered,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SubscriptionInsightsCard(
                              monthlyRevenueData: monthlyRevenueData,
                              topPlan: topPlan,
                              autoRenewals: autoRenewals,
                            ),
                            const SizedBox(
                                height: AppTheme.defaultPadding * 1.5),
                            _SchoolInsightsCard(
                              schoolsByTypeData: schoolsByTypeData,
                              totalSchools: totalSchools,
                              topState: topState,
                              newlyRegistered: newlyRegistered,
                            ),
                            const SizedBox(
                                height: AppTheme.defaultPadding * 1.5),
                            _AcademicInsightsCard(
                              materialsData: materialsGrowthData,
                              chaptersData: chaptersGrowthData,
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// =================================================================== //
//                         REUSABLE WIDGETS                            //
// =================================================================== //

class _StyledContainer extends StatelessWidget {
  final Widget child;
  const _StyledContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.defaultPadding * 1.5),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: AppTheme.defaultBorderRadius,
        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.03),
              spreadRadius: 1,
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: child,
    );
  }
}

// MARK: - Header with Functional Notification Panel
class _Header extends StatefulWidget {
  const _Header();

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  final GlobalKey _notificationIconKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  void _toggleNotificationPanel() {
    if (_overlayEntry == null) {
      _showNotificationPanel();
    } else {
      _hideNotificationPanel();
    }
  }

  void _showNotificationPanel() {
    final renderBox = _notificationIconKey.currentContext!.findRenderObject()
    as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideNotificationPanel,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          Positioned(
            top: offset.dy + size.height + 10,
            right:
            MediaQuery.of(context).size.width - offset.dx - size.width,
            width: 360,
            child: Material(
              elevation: 8.0,
              borderRadius: AppTheme.defaultBorderRadius,
              child: const _AlertsAndRemindersCard(),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideNotificationPanel() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideNotificationPanel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: AppTheme.defaultBorderRadius,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 10)
                    ]),
                child: TextField(
                  decoration: InputDecoration(
                      hintText: 'Search anything...',
                      hintStyle: GoogleFonts.inter(color: AppTheme.bodyText),
                      prefixIcon: const Icon(Iconsax.search_normal_1,
                          color: AppTheme.bodyText, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15)),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.defaultPadding),
            Stack(
              children: [
                IconButton(
                  key: _notificationIconKey,
                  onPressed: _toggleNotificationPanel,
                  icon: const Icon(Iconsax.notification,
                      color: AppTheme.bodyText),
                  tooltip: 'View notifications',
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: Text('3',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
            const SizedBox(width: AppTheme.defaultPadding / 2),
            Row(
              children: [
                const CircleAvatar(
                    backgroundImage:
                    NetworkImage('https://picsum.photos/id/237/200/200'),
                    radius: 22),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userProvider.userName ?? 'Admin User',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkText)),
                    Text(userProvider.userID ?? 'admin@mackcleo.com',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppTheme.bodyText)),
                  ],
                )
              ],
            ),
          ],
        );
      },
    );
  }
}

// MARK: - KPI Section with Hover Effect
class _KpiSection extends StatelessWidget {
  final String totalSchools, totalRevenue, activeSubscriptions, upcomingExpiry;

  const _KpiSection(
      {required this.totalSchools,
        required this.totalRevenue,
        required this.activeSubscriptions,
        required this.upcomingExpiry});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.defaultPadding,
      runSpacing: AppTheme.defaultPadding,
      children: [
        _KpiCard(value: totalSchools, label: 'Total Schools', isPrimary: true),
        _KpiCard(value: totalRevenue, label: 'Total Revenue'),
        _KpiCard(value: activeSubscriptions, label: 'Active Subscriptions'),
        _KpiCard(value: upcomingExpiry, label: 'Upcoming Expiry (30d)'),
      ],
    );
  }
}

class _KpiCard extends StatefulWidget {
  final String value, label;
  final bool isPrimary;

  const _KpiCard(
      {required this.value, required this.label, this.isPrimary = false});

  @override
  _KpiCardState createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: LayoutBuilder(builder: (context, constraints) {
          double cardWidth =
              (constraints.maxWidth - (AppTheme.defaultPadding * 3)) / 4;
          if (MediaQuery.of(context).size.width < 1200)
            cardWidth = (constraints.maxWidth - AppTheme.defaultPadding) / 2;
          if (MediaQuery.of(context).size.width < 600)
            cardWidth = constraints.maxWidth;
          return SizedBox(
            width: cardWidth,
            child: Container(
              padding: const EdgeInsets.all(AppTheme.defaultPadding * 1.25),
              decoration: BoxDecoration(
                color: widget.isPrimary
                    ? AppTheme.primaryGreen
                    : AppTheme.background,
                gradient: widget.isPrimary ? AppTheme.primaryGradient : null,
                borderRadius: AppTheme.defaultBorderRadius,
                border: Border.all(color: AppTheme.borderGrey.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: widget.isPrimary
                        ? AppTheme.primaryGreen
                        .withOpacity(_isHovered ? 0.4 : 0.2)
                        : Colors.grey.withOpacity(_isHovered ? 0.08 : 0.04),
                    spreadRadius: 2,
                    blurRadius: 20,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label,
                      style: GoogleFonts.inter(
                          color: widget.isPrimary
                              ? Colors.white70
                              : AppTheme.bodyText)),
                  const SizedBox(height: 8),
                  Text(widget.value,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 32,
                          color: widget.isPrimary
                              ? Colors.white
                              : AppTheme.darkText)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// MARK: - Card Sections with Modernized Syncfusion Charts
class _SubscriptionInsightsCard extends StatelessWidget {
  final List monthlyRevenueData;
  final String topPlan, autoRenewals;

  const _SubscriptionInsightsCard({
    required this.monthlyRevenueData,
    required this.topPlan,
    required this.autoRenewals,
  });

  @override
  Widget build(BuildContext context) {
    return _StyledContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Revenue',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText)),
            const SizedBox(height: AppTheme.defaultPadding),
            SizedBox(
                height: 200,
                child: MonthlyRevenueChart(chartData: monthlyRevenueData)),
            const Divider(height: 32, color: AppTheme.borderGrey),
            _InsightRow(
                icon: Iconsax.crown,
                iconColor: Colors.amber,
                title: 'Top Plan',
                value: topPlan),
            _InsightRow(
                icon: Iconsax.repeat,
                iconColor: Colors.green,
                title: 'Auto-Renewal Enabled',
                value: autoRenewals),
          ],
        ));
  }
}

class _SchoolInsightsCard extends StatefulWidget {
  final List schoolsByTypeData;
  final String totalSchools, topState, newlyRegistered;

  const _SchoolInsightsCard({
    required this.schoolsByTypeData,
    required this.totalSchools,
    required this.topState,
    required this.newlyRegistered,
  });

  @override
  State<_SchoolInsightsCard> createState() => _SchoolInsightsCardState();
}

class _SchoolInsightsCardState extends State<_SchoolInsightsCard> {
  int explodedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return _StyledContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Schools by Type',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText)),
          const SizedBox(height: AppTheme.defaultPadding),
          SizedBox(
            height: 200,
            child: SchoolsPieChart(
                pieData: widget.schoolsByTypeData,
                totalSchools: widget.totalSchools,
                explodedIndex: explodedIndex,
                onPointTap: (index) {
                  setState(() {
                    explodedIndex = (explodedIndex == index) ? -1 : index;
                  });
                }),
          ),
          const Divider(height: 32, color: AppTheme.borderGrey),
          _InsightRow(
              icon: Iconsax.location,
              iconColor: AppTheme.mackColor,
              title: 'Top State',
              value: widget.topState),
          _InsightRow(
              icon: Iconsax.add,
              iconColor: Colors.green,
              title: 'Newly Registered',
              value: widget.newlyRegistered),
        ],
      ),
    );
  }
}

class _AcademicInsightsCard extends StatelessWidget {
  final List materialsData, chaptersData;

  const _AcademicInsightsCard(
      {required this.materialsData, required this.chaptersData});

  @override
  Widget build(BuildContext context) {
    return _StyledContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Content Growth',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText)),
          const SizedBox(height: AppTheme.defaultPadding),
          SizedBox(
              height: 250,
              child: AcademicContentChart(
                  materialsData: materialsData, chaptersData: chaptersData))
        ],
      ),
    );
  }
}

// MARK: - Modernized Syncfusion Chart Widgets
class _ChartData {
  _ChartData(this.x, this.y, [this.y2]);
  final String x;
  final double y;
  final double? y2;
}

class MonthlyRevenueChart extends StatelessWidget {
  final List chartData;
  const MonthlyRevenueChart({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.inter(color: AppTheme.bodyText),
        ),
      );
    }

    final List<_ChartData> transformedData = chartData.map((item) {
      final month = item['Month']?.substring(5) ?? 'N/A';
      final revenue =
          double.tryParse(item['Revenue']?.toString() ?? '0') ?? 0;
      return _ChartData(month, revenue / 1000);
    }).toList();

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
          labelStyle: GoogleFonts.inter(color: AppTheme.bodyText)),
      primaryYAxis: const NumericAxis(isVisible: false),
      plotAreaBorderWidth: 0,
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        tooltipSettings: InteractiveTooltip(
            enable: true,
            color: AppTheme.darkText,
            textStyle: GoogleFonts.inter(color: Colors.white)),
        lineType: TrackballLineType.vertical,
      ),
      series: <CartesianSeries<_ChartData, String>>[
        ColumnSeries<_ChartData, String>(
          dataSource: transformedData,
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.y,
          name: 'Revenue',
          width: 0.6,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8), topRight: Radius.circular(8)),
          gradient: AppTheme.primaryGradient,
        ),
      ],
    );
  }
}

class SchoolsPieChart extends StatelessWidget {
  final List pieData;
  final String totalSchools;
  final int explodedIndex;
  final Function(int) onPointTap;
  const SchoolsPieChart(
      {super.key,
        required this.pieData,
        required this.totalSchools,
        required this.explodedIndex,
        required this.onPointTap});

  @override
  Widget build(BuildContext context) {
    if (pieData.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.inter(color: AppTheme.bodyText),
        ),
      );
    }

    final List<_ChartData> transformedData = pieData.map((item) {
      final type = item['School_Type'] as String? ?? 'Other';
      final count = double.tryParse(item['Count']?.toString() ?? '0') ?? 0.0;
      return _ChartData(type, count);
    }).toList();

    return SfCircularChart(
      tooltipBehavior:
      TooltipBehavior(enable: true, textStyle: GoogleFonts.inter()),
      annotations: <CircularChartAnnotation>[
        CircularChartAnnotation(
            widget: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(totalSchools,
                    style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText)),
                const SizedBox(height: 4),
                Text('Total Schools',
                    style:
                    GoogleFonts.inter(fontSize: 13, color: AppTheme.bodyText)),
              ],
            ))
      ],
      series: <CircularSeries>[
        DoughnutSeries<_ChartData, String>(
          dataSource: transformedData,
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.y,
          innerRadius: '70%',
          pointColorMapper: (_ChartData data, index) {
            final colors = [
              AppTheme.primaryGreen,
              AppTheme.accentGreen,
              AppTheme.mackColor,
              AppTheme.cleoColor
            ];
            return colors[index % colors.length];
          },
          dataLabelSettings: DataLabelSettings(
              isVisible: true,
              textStyle: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          explode: true,
          explodeIndex: explodedIndex,
          onPointTap: (ChartPointDetails details) =>
              onPointTap(details.pointIndex ?? -1),
        ),
      ],
    );
  }
}

class AcademicContentChart extends StatelessWidget {
  final List materialsData, chaptersData;
  const AcademicContentChart(
      {super.key, required this.materialsData, required this.chaptersData});

  @override
  Widget build(BuildContext context) {
    if (materialsData.isEmpty && chaptersData.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.inter(color: AppTheme.bodyText),
        ),
      );
    }

    final Map<String, _ChartData> combinedDataMap = {};

    for (var item in materialsData) {
      final month = item['Month'] as String? ?? 'N/A-M';
      final materials =
          double.tryParse(item['MaterialsUploaded']?.toString() ?? '0') ?? 0;
      final monthLabel = month.split('-').last;
      combinedDataMap[month] = _ChartData(monthLabel, materials, 0);
    }

    for (var item in chaptersData) {
      final month = item['Month'] as String? ?? 'N/A-C';
      final chapters =
          double.tryParse(item['ChaptersUploaded']?.toString() ?? '0') ?? 0;
      final monthLabel = month.split('-').last;

      if (combinedDataMap.containsKey(month)) {
        final existingData = combinedDataMap[month]!;
        combinedDataMap[month] =
            _ChartData(existingData.x, existingData.y, chapters);
      } else {
        combinedDataMap[month] = _ChartData(monthLabel, 0, chapters);
      }
    }

    final List<_ChartData> chartData = combinedDataMap.values.toList();
    chartData.sort((a, b) => a.x.compareTo(b.x));

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
          majorGridLines: const MajorGridLines(width: 0),
          labelStyle: GoogleFonts.inter(color: AppTheme.bodyText)),
      primaryYAxis: const NumericAxis(
          axisLine: AxisLine(width: 0),
          majorTickLines: MajorTickLines(size: 0)),
      plotAreaBorderWidth: 0,
      legend: Legend(
          isVisible: true,
          position: LegendPosition.top,
          textStyle: GoogleFonts.inter()),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
        tooltipSettings: InteractiveTooltip(
            enable: true,
            color: AppTheme.darkText,
            textStyle: GoogleFonts.inter()),
      ),
      series: <CartesianSeries>[
        SplineAreaSeries<_ChartData, String>(
          dataSource: chartData,
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.y,
          name: 'Materials',
          gradient: LinearGradient(
              colors: [
                AppTheme.primaryGreen.withOpacity(0.4),
                AppTheme.accentGreen.withOpacity(0.2)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
          borderColor: AppTheme.primaryGreen,
          borderWidth: 3,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
        SplineSeries<_ChartData, String>(
          dataSource: chartData,
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.y2,
          name: 'Chapters',
          color: AppTheme.mackColor,
          width: 3,
          dashArray: const <double>[5, 5],
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      ],
    );
  }
}

// MARK: - Sidebar and Other Helper Widgets
class _Sidebar extends StatelessWidget {
  final bool isCollapsed;
  const _Sidebar({required this.isCollapsed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: isCollapsed ? 100 : 250,
      color: AppTheme.background,
      child: Column(
        crossAxisAlignment:
        isCollapsed ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal:
                isCollapsed ? 0 : AppTheme.defaultPadding * 2,
                vertical: AppTheme.defaultPadding * 1.5),
            child: isCollapsed
                ? const Icon(Iconsax.bezier,
                color: AppTheme.primaryGreen, size: 30)
                : RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                    fontSize: 30, fontWeight: FontWeight.w800),
                children: const [
                  TextSpan(
                      text: 'MACK',
                      style: TextStyle(color: AppTheme.mackColor)),
                  TextSpan(
                      text: 'CLEO',
                      style: TextStyle(color: AppTheme.cleoColor)),
                ],
              ),
            ),
          ),
          Center(
            child: IconButton(
              onPressed: () =>
              isSidebarCollapsed.value = !isSidebarCollapsed.value,
              icon: Icon(
                  isCollapsed ? Iconsax.arrow_right_3 : Iconsax.arrow_left_2,
                  color: AppTheme.bodyText),
              tooltip: isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
            ),
          ),
          const SizedBox(height: AppTheme.defaultPadding),
          _SidebarMenuItem(
              icon: Iconsax.home,
              text: 'Dashboard',
              isActive: true,
              isCollapsed: isCollapsed),
          _SidebarMenuItem(
            icon: Iconsax.building_4,
            text: 'Schools',
            isCollapsed: isCollapsed,
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SchoolsScreen()),
              );
            },
          ),
          _SidebarMenuItem(
              icon: Iconsax.crown,
              text: 'Subscriptions',
              isCollapsed: isCollapsed),
          _SidebarMenuItem(
              icon: Iconsax.document_text,
              text: 'Study Materials',
              isCollapsed: isCollapsed),
          _SidebarMenuItem(
              icon: Iconsax.chart_2,
              text: 'Analytics',
              isCollapsed: isCollapsed),
          _SidebarMenuItem(
              icon: Iconsax.people, text: 'Users', isCollapsed: isCollapsed),
          const Spacer(),
          _SidebarMenuItem(
              icon: Iconsax.setting_2,
              text: 'Settings',
              isCollapsed: isCollapsed),
          _SidebarMenuItem(
              icon: Iconsax.logout, text: 'Logout', isCollapsed: isCollapsed),
        ],
      ),
    );
  }
}

class _SidebarMenuItem extends StatefulWidget {
  final IconData icon;
  final String text;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback? onTap;

  const _SidebarMenuItem({
    required this.icon,
    required this.text,
    this.isActive = false,
    required this.isCollapsed,
    this.onTap,
  });

  @override
  _SidebarMenuItemState createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<_SidebarMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        decoration: BoxDecoration(
          color: widget.isActive
              ? AppTheme.primaryGreen.withOpacity(0.1)
              : (_isHovered
              ? AppTheme.borderGrey.withOpacity(0.5)
              : Colors.transparent),
          borderRadius: AppTheme.defaultBorderRadius,
        ),
        child: Tooltip(
          message: widget.isCollapsed ? widget.text : '',
          child: widget.isCollapsed
              ? SizedBox(
            width: double.infinity,
            child: IconButton(
                onPressed: widget.onTap,
                icon: Icon(widget.icon,
                    color: widget.isActive
                        ? AppTheme.primaryGreen
                        : AppTheme.bodyText)),
          )
              : ListTile(
            leading: Icon(widget.icon,
                color: widget.isActive
                    ? AppTheme.primaryGreen
                    : AppTheme.bodyText),
            title: Text(widget.text,
                style: GoogleFonts.inter(
                    color: widget.isActive
                        ? AppTheme.primaryGreen
                        : AppTheme.bodyText,
                    fontWeight: widget.isActive
                        ? FontWeight.w800
                        : FontWeight.w600)),
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  const _InsightRow(
      {required this.icon,
        required this.iconColor,
        required this.title,
        required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.defaultPadding * 0.75),
      child: Row(
        children: [
          CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.bodyText)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _AlertsAndRemindersCard extends StatelessWidget {
  const _AlertsAndRemindersCard();
  @override
  Widget build(BuildContext context) {
    return _StyledContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Alerts & Reminders',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText)),
              const Icon(Iconsax.warning_2, color: Colors.orange),
            ],
          ),
          const SizedBox(height: AppTheme.defaultPadding / 2),
          const _AlertTile(
              title: '45 Subs Expiring',
              subtitle: 'In the next 30 days',
              icon: Iconsax.calendar_remove,
              color: Colors.orange),
          const Divider(color: AppTheme.borderGrey),
          const _AlertTile(
              title: '21 Inactive Schools',
              subtitle: 'No login in 30 days',
              icon: Iconsax.moon,
              color: Colors.blueGrey),
          const Divider(color: AppTheme.borderGrey),
          const _AlertTile(
              title: '8 Low Engagement Schools',
              subtitle: '< 5 materials uploaded',
              icon: Iconsax.arrow_down,
              color: Colors.red),
          const SizedBox(height: AppTheme.defaultPadding / 2),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _AlertTile extends StatefulWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;

  const _AlertTile(
      {required this.title,
        required this.subtitle,
        required this.icon,
        required this.color});

  @override
  State<_AlertTile> createState() => _AlertTileState();
}

class _AlertTileState extends State<_AlertTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {},
        borderRadius: AppTheme.defaultBorderRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
          const EdgeInsets.symmetric(vertical: AppTheme.defaultPadding),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.borderGrey.withOpacity(0.5)
                : Colors.transparent,
            borderRadius: AppTheme.defaultBorderRadius,
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              CircleAvatar(
                  backgroundColor: widget.color.withOpacity(0.1),
                  child: Icon(widget.icon, color: widget.color, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    Text(widget.subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppTheme.bodyText),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
