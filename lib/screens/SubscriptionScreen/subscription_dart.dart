import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Service/Subscription_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/screens/SubscriptionScreen/plan_detail_dialog.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:ui';
import 'package:lms_publisher/screens/SubscriptionScreen/subscription_model.dart';
import 'package:intl/intl.dart';
import 'package:lms_publisher/screens/SubscriptionScreen/add_edit_plan_dialog.dart';
import 'package:provider/provider.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';


class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      activeScreen: AppScreen.subscriptions,
      child: SubscriptionsView(),
    );
  }
}

enum SubscriptionViewType { dashboard, plans }

class SubscriptionsView extends StatefulWidget {
  const SubscriptionsView({super.key});

  @override
  _SubscriptionsViewState createState() => _SubscriptionsViewState();
}

class _SubscriptionsViewState extends State<SubscriptionsView> {
  SubscriptionViewType _currentView = SubscriptionViewType.dashboard;
  static const double mobileBreakpoint = 850;

  @override
  Widget build(BuildContext context) {
    // --- ADDED THIS WRAPPER ---
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < mobileBreakpoint;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // --- ADDED THIS LINE ---
            mainAxisSize: MainAxisSize.min,
            children: [
              isMobile
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderTitle(),
                  const SizedBox(height: 16),
                  _ViewSwitcher(
                    currentView: _currentView,
                    onViewChanged: (view) =>
                        setState(() => _currentView = view),
                  ),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildHeaderTitle()),
                  _ViewSwitcher(
                    currentView: _currentView,
                    onViewChanged: (view) =>
                        setState(() => _currentView = view),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.defaultPadding * 1.5),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _buildCurrentView(),
              ),
            ],
          );
        },
      ),
    );
    // --- AND CLOSED IT HERE ---
  }

  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subscriptions',
            style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText)),
        const SizedBox(height: 4),
        Text('Monitor plans, revenue, and subscriber activity.',
            style: GoogleFonts.inter(color: AppTheme.bodyText)),
      ],
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case SubscriptionViewType.dashboard:
        return const SubscriptionDashboard(key: ValueKey('dashboard'));
      case SubscriptionViewType.plans:
        return const SubscriptionPlans(key: ValueKey('plans'));
    }
  }
}

class SubscriptionDashboard extends StatefulWidget {
  const SubscriptionDashboard({super.key});

  @override
  _SubscriptionDashboardState createState() => _SubscriptionDashboardState();
}

class _SubscriptionDashboardState extends State<SubscriptionDashboard> {
  late Future<DashboardData> _dashboardDataFuture;
  final SubscriptionApiService _apiService = SubscriptionApiService();

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _apiService.fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardData>(
      future: _dashboardDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(64.0),
              child: BeautifulLoader(
                type: LoaderType.spinner,
                message: 'Loading dashboard...',
                color: AppTheme.primaryGreen,
                size: 60,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No data available.'));
        }

        final dashboardData = snapshot.data!;
        print('🔥 Dashboard Data Loaded:');
        print('Monthly Revenue items: ${dashboardData.monthlyRevenue.length}');
        for (var item in dashboardData.monthlyRevenue) {
          print('  Month: ${item.x}, Value: ${item.y}');
        }

        return Column(
          children: [
            _KpiSection(kpis: dashboardData.kpis),
            const SizedBox(height: AppTheme.defaultPadding * 1.5),
            LayoutBuilder(builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 950;
              return isWide
                  ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 3,
                      child:
                      _buildMRRCard(dashboardData.monthlyRevenue)),
                  const SizedBox(width: AppTheme.defaultPadding * 1.5),
                  Expanded(
                      flex: 2,
                      child: _buildSideBar(
                          dashboardData.planPopularity,
                          dashboardData.recentActivities)),
                ],
              )
                  : Column(
                children: [
                  _buildMRRCard(dashboardData.monthlyRevenue),
                  const SizedBox(
                      height: AppTheme.defaultPadding * 1.5),
                  _buildSideBar(dashboardData.planPopularity,
                      dashboardData.recentActivities),
                ],
              );
            })
          ],
        );
      },
    );
  }

  Widget _buildMRRCard(List<ChartData> mrrData) {
    return _StyledContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Recurring Revenue (MRR)',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          SizedBox(height: 300, child: MRRChart(chartData: mrrData)),
        ],
      ),
    );
  }

  Widget _buildSideBar(
      List<ChartData> planPopularityData, List<Activity> recentActivities) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StyledContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan Popularity',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(
                  height: 240,
                  child: _PlanPopularityChart(pieData: planPopularityData)),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.defaultPadding * 1.5),
        _RecentActivityCard(activities: recentActivities),
      ],
    );
  }
}

class SubscriptionPlans extends StatefulWidget {
  const SubscriptionPlans({super.key});
  @override
  _SubscriptionPlansState createState() => _SubscriptionPlansState();
}

class _SubscriptionPlansState extends State<SubscriptionPlans> {
  late Future<List<Plan>> _plansFuture;
  final SubscriptionApiService _apiService = SubscriptionApiService();

  @override
  void initState() {
    super.initState();
    _plansFuture = _apiService.fetchSubscriptionPlans();
  }

  void _refreshPlans() {
    setState(() {
      _plansFuture = _apiService.fetchSubscriptionPlans();
    });
  }

  void _showAddEditDialog({Plan? plan}) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddEditPlanDialog(plan: plan),
    );
    if (result == true) {
      _refreshPlans();
    }
  }

  void _showDetailsDialog(Plan plan) {
    showDialog(
      context: context,
      builder: (context) => PlanDetailsDialog(plan: plan),
    );
  }

  void _showDeleteConfirmationDialog(Plan plan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ImprovedDeleteConfirmationDialog(
        plan: plan,
        onDeleteConfirmed: (planToDelete) {
          _performDelete(planToDelete);
        },
      ),
    );
  }

  Future<void> _performDelete(Plan plan) async {
    try {
      final success = await _apiService.deletePlan(
        recNo: plan.recNo,
        deletedBy: 'Admin',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Iconsax.tick_circle : Iconsax.close_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    success
                        ? 'Plan deleted successfully!'
                        : 'Failed to delete plan.',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
        if (success) _refreshPlans();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.close_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'An error occurred: $e',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Check if user has add permission
        final canAdd = userProvider.hasPermission('M003', 'add');

        return FutureBuilder<List<Plan>>(
          future: _plansFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(64.0),
                  child: BeautifulLoader(
                    type: LoaderType.dots,
                    message: 'Loading subscription plans...',
                    color: AppTheme.primaryGreen,
                    size: 50,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                  child: Text("Failed to load plans: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _StyledContainer(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.document_text,
                          size: 64, color: AppTheme.bodyText.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        "No subscription plans found",
                        style:
                        GoogleFonts.inter(color: AppTheme.bodyText, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      // Only show Add button if user has add permission
                      if (canAdd)
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditDialog(),
                          icon: const Icon(Iconsax.add, size: 20),
                          label: const Text('Add New Plan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            elevation: 0,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            final plans = snapshot.data!;
            return _StyledContainer(
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 850;
                      return isMobile
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Pricing & Plans",
                              style: GoogleFonts.poppins(
                                  fontSize: 20, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          _buildPlanActions(isMobile: true, canAdd: canAdd),
                        ],
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Pricing & Plans",
                              style: GoogleFonts.poppins(
                                  fontSize: 20, fontWeight: FontWeight.w700)),
                          _buildPlanActions(isMobile: false, canAdd: canAdd),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 32),
                  _buildCardView(plans),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlanActions({required bool isMobile, required bool canAdd}) {
    // Only show the Add button if user has add permission
    if (!canAdd) return const SizedBox.shrink();

    final button = ElevatedButton.icon(
      onPressed: () => _showAddEditDialog(),
      icon: const Icon(Iconsax.add, size: 20),
      label: Text(isMobile ? 'New Plan' : 'Add New Plan'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(
            horizontal: 20, vertical: isMobile ? 12 : 16),
        elevation: 0,
      ),
    );

    return isMobile ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildCardView(List<Plan> plans) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Check if user has edit and delete permissions
        final canEdit = userProvider.hasPermission('M003', 'edit');
        final canDelete = userProvider.hasPermission('M003', 'delete');

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;
            final isTablet = constraints.maxWidth < 1000;

            if (isMobile) {
              // Mobile: One card per row
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: plans.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _CompactPlanCard(
                  plan: plans[index],
                  onViewDetails: () => _showDetailsDialog(plans[index]),
                  onEdit: canEdit ? () => _showAddEditDialog(plan: plans[index]) : null,
                  onDelete: canDelete ? () => _showDeleteConfirmationDialog(plans[index]) : null,
                ),
              );
            } else {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 2 : 3,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: plans.length,
                itemBuilder: (context, index) => _ImprovedPlanCard(
                  plan: plans[index],
                  onViewDetails: () => _showDetailsDialog(plans[index]),
                  onEdit: canEdit ? () => _showAddEditDialog(plan: plans[index]) : null,
                  onDelete: canDelete ? () => _showDeleteConfirmationDialog(plans[index]) : null,
                ),
              );
            }
          },
        );
      },
    );
  }
}

// --- REUSABLE WIDGETS ---

class _StyledContainer extends StatelessWidget {
  final Widget child;
  const _StyledContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.defaultPadding * 1.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.defaultBorderRadius,
        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              spreadRadius: 1,
              blurRadius: 15,
              offset: const Offset(0, 4))
        ],
      ),
      child: child,
    );
  }
}

class _KpiSection extends StatelessWidget {
  final KpiData kpis;
  const _KpiSection({required this.kpis});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final isTablet = constraints.maxWidth < 1200;

          return Wrap(
            spacing: AppTheme.defaultPadding,
            runSpacing: AppTheme.defaultPadding,
            children: [
              _KpiCard(
                  width: isMobile ? constraints.maxWidth : (isTablet ? (constraints.maxWidth - AppTheme.defaultPadding) / 2 : (constraints.maxWidth - AppTheme.defaultPadding * 3) / 4),
                  value: kpis.activePlans, label: 'Active Plans', isPrimary: false),
              _KpiCard(
                  width: isMobile ? constraints.maxWidth : (isTablet ? (constraints.maxWidth - AppTheme.defaultPadding) / 2 : (constraints.maxWidth - AppTheme.defaultPadding * 3) / 4),
                  value: kpis.totalRevenue, label: 'Total Revenue', isPrimary: true),
              _KpiCard(
                  width: isMobile ? constraints.maxWidth : (isTablet ? (constraints.maxWidth - AppTheme.defaultPadding) / 2 : (constraints.maxWidth - AppTheme.defaultPadding * 3) / 4),
                  value: kpis.subscribers, label: 'Subscribers'),
              _KpiCard(
                  width: isMobile ? constraints.maxWidth : (isTablet ? (constraints.maxWidth - AppTheme.defaultPadding) / 2 : (constraints.maxWidth - AppTheme.defaultPadding * 3) / 4),
                  value: kpis.expiringSoon, label: 'Expiring Soon'),
            ],
          );
        }
    );
  }
}

class _KpiCard extends StatefulWidget {
  final String value, label;
  final bool isPrimary;
  final double width;
  const _KpiCard(
      {required this.value, required this.label, this.isPrimary = false, required this.width});

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
        child: SizedBox(
          width: widget.width,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.defaultPadding * 1.25),
            decoration: BoxDecoration(
              color:
              widget.isPrimary ? AppTheme.primaryGreen : AppTheme.background,
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
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final List<Activity> activities;
  const _RecentActivityCard({required this.activities});

  @override
  Widget build(BuildContext context) {
    return _StyledContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Activity',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("No recent activity."),
            ))
          else
            ...activities
                .map((activity) => _ActivityItem(activity: activity))
                .toList()
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Activity activity;
  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          CircleAvatar(
              backgroundColor: activity.iconColor.withOpacity(0.1),
              radius: 20,
              child:
              Icon(activity.icon, color: activity.iconColor, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                Text(activity.subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.bodyText),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(activity.time,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.bodyText)),
        ],
      ),
    );
  }
}

class _ViewSwitcher extends StatelessWidget {
  final SubscriptionViewType currentView;
  final ValueChanged<SubscriptionViewType> onViewChanged;

  const _ViewSwitcher(
      {required this.currentView, required this.onViewChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: AppTheme.borderGrey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SwitcherButton(
              text: 'Dashboard',
              isActive: currentView == SubscriptionViewType.dashboard,
              onTap: () => onViewChanged(SubscriptionViewType.dashboard)),
          _SwitcherButton(
              text: 'Plans',
              isActive: currentView == SubscriptionViewType.plans,
              onTap: () => onViewChanged(SubscriptionViewType.plans)),
        ],
      ),
    );
  }
}

class _SwitcherButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;
  const _SwitcherButton(
      {required this.text, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5)
          ]
              : [],
        ),
        child: Text(text,
            style: GoogleFonts.inter(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppTheme.primaryGreen : AppTheme.bodyText)),
      ),
    );
  }
}

// IMPROVED PLAN CARD FOR DESKTOP/TABLET
class _ImprovedPlanCard extends StatefulWidget {
  final Plan plan;
  final VoidCallback onViewDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ImprovedPlanCard({
    required this.plan,
    required this.onViewDetails,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_ImprovedPlanCard> createState() => _ImprovedPlanCardState();
}

class _ImprovedPlanCardState extends State<_ImprovedPlanCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    bool isPopular = widget.plan.isPopular;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isPopular
              ? AppTheme.primaryGreen.withOpacity(0.05)
              : Colors.white,
          borderRadius: AppTheme.defaultBorderRadius,
          border: Border.all(
              color: isPopular
                  ? AppTheme.primaryGreen
                  : AppTheme.borderGrey.withOpacity(0.7),
              width: _isHovered ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.03),
              blurRadius: _isHovered ? 15 : 10,
              offset: Offset(0, _isHovered ? 6 : 4),
            )
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isPopular
                        ? AppTheme.primaryGreen.withOpacity(0.05)
                        : AppTheme.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.plan.name,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            _StatusBadge(isActive: widget.plan.isActive),
                          ],
                        ),
                      ),
                      // Only show action buttons if user has permissions
                      if (widget.onEdit != null || widget.onDelete != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.onEdit != null)
                              IconButton(
                                icon: const Icon(Iconsax.edit_2, size: 18),
                                onPressed: widget.onEdit,
                                tooltip: 'Edit Plan',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primaryGreen,
                                  padding: const EdgeInsets.all(8),
                                ),
                              ),
                            if (widget.onEdit != null && widget.onDelete != null)
                              const SizedBox(width: 8),
                            if (widget.onDelete != null)
                              IconButton(
                                icon: const Icon(Iconsax.trash, size: 18),
                                onPressed: widget.onDelete,
                                tooltip: 'Delete Plan',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                  foregroundColor: Colors.red.shade600,
                                  padding: const EdgeInsets.all(8),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.plan.description,
                          style: GoogleFonts.inter(
                            color: AppTheme.bodyText,
                            height: 1.5,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹${widget.plan.price.toInt()}',
                              style: GoogleFonts.poppins(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkText,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '/ ${widget.plan.billingCycle}',
                              style: GoogleFonts.inter(
                                color: AppTheme.bodyText,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'FEATURES',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.bodyText,
                            letterSpacing: 0.8,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.plan.features.length > 4
                                ? 4
                                : widget.plan.features.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Iconsax.tick_circle,
                                      color: AppTheme.primaryGreen,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        widget.plan.features[index],
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        if (widget.plan.features.length > 4)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '+${widget.plan.features.length - 4} more features',
                              style: GoogleFonts.inter(
                                color: AppTheme.primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Footer
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onViewDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPopular
                            ? AppTheme.primaryGreen
                            : Colors.white,
                        foregroundColor: isPopular
                            ? Colors.white
                            : AppTheme.primaryGreen,
                        side: BorderSide(
                          color: AppTheme.primaryGreen,
                          width: isPopular ? 0 : 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'View Full Details',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (isPopular)
              Positioned(
                top: 0,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(
                    color: AppTheme.mackColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    'POPULAR',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// COMPACT PLAN CARD FOR MOBILE
class _CompactPlanCard extends StatefulWidget {
  final Plan plan;
  final VoidCallback onViewDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CompactPlanCard({
    required this.plan,
    required this.onViewDetails,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_CompactPlanCard> createState() => _CompactPlanCardState();
}

class _CompactPlanCardState extends State<_CompactPlanCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    bool isPopular = widget.plan.isPopular;

    return Container(
      decoration: BoxDecoration(
        color: isPopular
            ? AppTheme.primaryGreen.withOpacity(0.05)
            : Colors.white,
        borderRadius: AppTheme.defaultBorderRadius,
        border: Border.all(
          color: isPopular
              ? AppTheme.primaryGreen
              : AppTheme.borderGrey.withOpacity(0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compact Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPopular
                  ? AppTheme.primaryGreen.withOpacity(0.05)
                  : AppTheme.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isPopular)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.mackColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'POPULAR',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          Text(
                            widget.plan.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          _StatusBadge(isActive: widget.plan.isActive),
                        ],
                      ),
                    ),
                    // Only show action buttons if user has permissions
                    if (widget.onEdit != null || widget.onDelete != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onEdit != null)
                            IconButton(
                              icon: const Icon(Iconsax.edit_2, size: 16),
                              onPressed: widget.onEdit,
                              tooltip: 'Edit',
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryGreen,
                              ),
                            ),
                          if (widget.onEdit != null && widget.onDelete != null)
                            const SizedBox(width: 6),
                          if (widget.onDelete != null)
                            IconButton(
                              icon: const Icon(Iconsax.trash, size: 16),
                              onPressed: widget.onDelete,
                              tooltip: 'Delete',
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: Colors.red.shade600,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹${widget.plan.price.toInt()}',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ ${widget.plan.billingCycle}',
                      style: GoogleFonts.inter(
                        color: AppTheme.bodyText,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Compact Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.plan.description,
                  style: GoogleFonts.inter(
                    color: AppTheme.bodyText,
                    height: 1.4,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Show first 3 features
                ...widget.plan.features.take(3).map(
                      (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Iconsax.tick_circle,
                          color: AppTheme.primaryGreen,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: GoogleFonts.inter(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.plan.features.length > 3)
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text(
                            _isExpanded
                                ? 'Show less'
                                : '+${widget.plan.features.length - 3} more features',
                            style: GoogleFonts.inter(
                              color: AppTheme.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            _isExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                            size: 14,
                            color: AppTheme.primaryGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                // Expanded features
                if (_isExpanded && widget.plan.features.length > 3)
                  ...widget.plan.features.skip(3).map(
                        (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Iconsax.tick_circle,
                            color: AppTheme.primaryGreen,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                // View Details Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onViewDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular
                          ? AppTheme.primaryGreen
                          : Colors.white,
                      foregroundColor: isPopular
                          ? Colors.white
                          : AppTheme.primaryGreen,
                      side: BorderSide(
                        color: AppTheme.primaryGreen,
                        width: isPopular ? 0 : 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'View Full Details',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isActive ? Colors.green : Colors.grey).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? Colors.green.shade600 : Colors.grey.shade600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: GoogleFonts.inter(
              color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// IMPROVED REVENUE CHART WIDGET - WITH DEBUG PRINTS
class MRRChart extends StatelessWidget {
  final List<ChartData> chartData;

  const MRRChart({required this.chartData});

  String formatCurrency(double value) {
    // Print raw value for debugging
    print('Raw value to format: $value');
    if (value >= 10000000) {
      // 1 Crore and above
      final formatted = '${(value / 10000000).toStringAsFixed(1)}Cr';
      print('Formatted as Crore: $formatted');
      return formatted;
    } else if (value >= 100000) {
      // 1 Lakh and above
      final formatted = '${(value / 100000).toStringAsFixed(1)}L';
      print('Formatted as Lakh: $formatted');
      return formatted;
    } else if (value >= 1000) {
      // 1 Thousand and above
      final formatted = '${(value / 1000).toStringAsFixed(1)}K';
      print('Formatted as Thousand: $formatted');
      return formatted;
    } else {
      // Less than 1000
      final formatted = value.toStringAsFixed(0);
      print('Formatted as plain: $formatted');
      return formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Print all chart data for debugging
    print('=== MRR Chart Data ===');
    print('Total items: ${chartData.length}');
    for (var i = 0; i < chartData.length; i++) {
      print('$i: x=${chartData[i].x}, y=${chartData[i].y} (type: ${chartData[i].y.runtimeType})');
    }

    final tooltip = TooltipBehavior(
      enable: true,
      header: '',
      format: 'point.x: ₹point.y',
      color: AppTheme.darkText,
      textStyle: GoogleFonts.inter(color: Colors.white),
    );

    // Calculate max value for better y-axis scaling
    double maxValue = chartData.isEmpty
        ? 100
        : chartData.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    print('Max value in chart: $maxValue');

    // Add 20% padding and ensure minimum threshold
    double yAxisMax = maxValue * 1.2;

    // Ensure minimum axis range to prevent zero/negative intervals
    if (yAxisMax < 10) {
      yAxisMax = 10;
    }

    yAxisMax = yAxisMax.ceilToDouble();
    print('Y-axis max with 20% padding: $yAxisMax');

    // Calculate interval - ensure it's always greater than 0
    double calculatedInterval = yAxisMax / 5;

    // Ensure interval is at least 1
    double finalInterval = calculatedInterval < 1 ? 1 : calculatedInterval;

    print('Calculated interval: $calculatedInterval');
    print('Final interval (minimum 1): $finalInterval');

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0),
        labelStyle: GoogleFonts.inter(
          color: AppTheme.bodyText,
          fontSize: 12,
        ),
      ),
      primaryYAxis: NumericAxis(
        isVisible: true,
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(
          width: 1,
          color: AppTheme.borderGrey.withOpacity(0.3),
          dashArray: <double>[5, 5],
        ),
        labelStyle: GoogleFonts.inter(
          color: AppTheme.bodyText,
          fontSize: 11,
        ),
        minimum: 0,
        maximum: yAxisMax,
        interval: finalInterval,  // Use the validated interval
        numberFormat: NumberFormat.currency(
          locale: 'en_IN',
          symbol: '₹',
          decimalDigits: 0,
        ),
      ),
      plotAreaBorderWidth: 0,
      tooltipBehavior: tooltip,
      series: <CartesianSeries>[
        ColumnSeries<ChartData, String>(
          dataSource: chartData,
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) {
            print('Y-value mapping: ${data.x} -> ${data.y}');
            return data.y;
          },
          gradient: AppTheme.primaryGradient,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          spacing: 0.3,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 10,
              color: AppTheme.darkText,
            ),
            labelAlignment: ChartDataLabelAlignment.top,
            builder: (dynamic data, dynamic point, dynamic series,
                int pointIndex, int seriesIndex) {
              print('Data label builder - Point index: $pointIndex');
              print('Data object: $data');
              print('Data.y value: ${data.y}');
              print('Point object: $point');
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  formatCurrency(data.y),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}



class _PlanPopularityChart extends StatelessWidget {
  final List<ChartData> pieData;
  const _PlanPopularityChart({required this.pieData});

  @override
  Widget build(BuildContext context) {
    return SfCircularChart(
      series: <CircularSeries>[
        DoughnutSeries<ChartData, String>(
          dataSource: pieData,
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          innerRadius: '65%',
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          pointColorMapper: (ChartData data, index) {
            final colors = [
              AppTheme.primaryGreen,
              AppTheme.accentGreen,
              AppTheme.mackColor,
              Colors.orange,
              Colors.blue,
            ];
            return colors[index % colors.length];
          },
        )
      ],
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        overflowMode: LegendItemOverflowMode.wrap,
        textStyle: GoogleFonts.inter(fontSize: 12),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.x: point.y subscribers',
        textStyle: GoogleFonts.inter(color: Colors.white),
      ),
    );
  }
}

class _ImprovedDeleteConfirmationDialog extends StatefulWidget {
  final Plan plan;
  final Function(Plan) onDeleteConfirmed;

  const _ImprovedDeleteConfirmationDialog({
    required this.plan,
    required this.onDeleteConfirmed,
  });

  @override
  State<_ImprovedDeleteConfirmationDialog> createState() =>
      _ImprovedDeleteConfirmationDialogState();
}

class _ImprovedDeleteConfirmationDialogState
    extends State<_ImprovedDeleteConfirmationDialog> {
  final TextEditingController _confirmController = TextEditingController();
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() {
      setState(() {
        _canDelete = _confirmController.text == 'DELETE';
      });
    });
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.warning_2, color: Colors.white, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Confirm Deletion',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          color: AppTheme.bodyText,
                          height: 1.6,
                          fontSize: 15,
                        ),
                        children: <TextSpan>[
                          const TextSpan(
                              text:
                              'This is a permanent action and cannot be undone. This will permanently delete the plan: '),
                          TextSpan(
                            text: widget.plan.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkText),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Iconsax.info_circle, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Please type "DELETE" to confirm.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _confirmController,
                      autocorrect: false,
                      decoration: InputDecoration(
                        hintText: 'Type DELETE here',
                        filled: true,
                        fillColor: AppTheme.lightGrey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          BorderSide(color: Colors.red.shade700, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppTheme.borderGrey),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppTheme.bodyText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: !_canDelete
                          ? null
                          : () {
                        widget.onDeleteConfirmed(widget.plan);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Iconsax.trash, size: 18),
                      label: Text(
                        'Delete',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
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
}