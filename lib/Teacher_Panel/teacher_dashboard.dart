import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Teacher_Panel/MyClass/teacher_classes_screen.dart';
import 'package:lms_publisher/Teacher_Panel/teacher_panel_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardData;

  static const String _imageBaseUrl = "https://storage.googleapis.com/upload-images-34/images/LMS/";

  String _selectedAcademicYear = '2025-26';
  final List<String> _academicYears = ['2024-25', '2025-26', '2026-27'];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _loadDashboard();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final teacherCode = userProvider.userCode;

      if (teacherCode == null) {
        throw Exception('Teacher code not found');
      }

      final data = await TeacherPanelService.getDashboardSummary(
        teacherCode: teacherCode,
        academicYear: _selectedAcademicYear,
      );

      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });

      _fadeController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        CustomSnackbar.showError(
          context,
          'Failed to load dashboard: $e',
        );
      }
    }
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    return '$_imageBaseUrl$imagePath';
  }

  double _parseScore(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? 0;
    }
    if (value is num) return value.toInt();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      activeScreen: AppScreen.teacherDashboard,
      child: _isLoading
          ? const Center(child: BeautifulLoader())
          : _errorMessage != null
          ? _buildErrorView()
          : _buildDashboardContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.info_circle, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Error Loading Dashboard',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.bodyText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadDashboard,
            icon: const Icon(Iconsax.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    final teacherInfo = _dashboardData?['teacher_info'];
    final quickStats = _dashboardData?['quick_stats'];
    final todaysSchedule = _dashboardData?['todays_schedule'] ?? [];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(teacherInfo, isMobile),

                // School Info Card for Mobile (below header)
                if (isMobile) ...[
                  const SizedBox(height: 12),
                  _buildSchoolInfoCard(teacherInfo),
                ],

                SizedBox(height: isMobile ? 20 : 32),

                _buildQuickStatsGrid(quickStats, isMobile),
                SizedBox(height: isMobile ? 20 : 32),

                // Responsive Layout
                if (isMobile)
                  Column(
                    children: [
                      _buildTodaysSchedule(todaysSchedule, isMobile),
                      const SizedBox(height: 20),
                      _buildQuickActions(isMobile),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildTodaysSchedule(todaysSchedule, isMobile),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 4,
                        child: _buildQuickActions(isMobile),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileHeader(Map<String, dynamic>? teacherInfo, String teacherPhotoUrl, String schoolLogoUrl) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: teacherPhotoUrl.isNotEmpty
                ? Image.network(
              teacherPhotoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
            )
                : _buildDefaultAvatar(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back! 👋',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                teacherInfo?['Teacher_Name'] ?? 'Teacher',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.calendar_1, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAcademicYear,
                  dropdownColor: AppTheme.primaryGreen,
                  icon: const Icon(Iconsax.arrow_down_1, color: Colors.white, size: 14),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  items: _academicYears.map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedAcademicYear = value;
                        _fadeController.reset();
                      });
                      _loadDashboard();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

// NEW: School Info Card for Mobile
  Widget _buildSchoolInfoCard(Map<String, dynamic>? teacherInfo) {
    final schoolLogoUrl = _getImageUrl(teacherInfo?['School_Logo_Path']);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (schoolLogoUrl.isNotEmpty) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  schoolLogoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Iconsax.building,
                    size: 20,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacherInfo?['School_Name'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Iconsax.location,
                      size: 12,
                      color: AppTheme.bodyText.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Your Institution',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.bodyText.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Iconsax.building,
              size: 16,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHeader(Map<String, dynamic>? teacherInfo, bool isMobile) {
    final teacherPhotoUrl = _getImageUrl(teacherInfo?['Teacher_Photo_Path']);
    final schoolLogoUrl = _getImageUrl(teacherInfo?['School_Logo_Path']);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 28),
        child: isMobile
            ? _buildMobileHeader(teacherInfo, teacherPhotoUrl, schoolLogoUrl)
            : _buildWebHeader(teacherInfo, teacherPhotoUrl, schoolLogoUrl),
      ),
    );
  }



  Widget _buildWebHeader(Map<String, dynamic>? teacherInfo, String teacherPhotoUrl, String schoolLogoUrl) {
    return Row(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: teacherPhotoUrl.isNotEmpty
                ? Image.network(
              teacherPhotoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
            )
                : _buildDefaultAvatar(),
          ),
        ),
        const SizedBox(width: 24),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back! 👋',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                teacherInfo?['Teacher_Name'] ?? 'Teacher',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (schoolLogoUrl.isNotEmpty) ...[
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          schoolLogoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Iconsax.building, size: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      teacherInfo?['School_Name'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 24),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.calendar_1, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAcademicYear,
                  dropdownColor: AppTheme.primaryGreen,
                  icon: const Icon(Iconsax.arrow_down_1, color: Colors.white, size: 16),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  items: _academicYears.map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedAcademicYear = value;
                        _fadeController.reset();
                      });
                      _loadDashboard();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withOpacity(0.1),
            AppTheme.accentGreen.withOpacity(0.1),
          ],
        ),
      ),
      child: const Icon(
        Iconsax.teacher,
        size: 45,
        color: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildQuickStatsGrid(Map<String, dynamic>? stats, bool isMobile) {
    final totalStudents = _parseInt(stats?['Total_Students_Count']);
    final todayClasses = _parseInt(stats?['Todays_Classes_Count']);
    final pendingGrading = _parseInt(stats?['Pending_Grading_Count']);
    final avgScore = _parseScore(stats?['Overall_Average_Score']);

    final statItems = [
      {
        'icon': Iconsax.profile_2user,
        'title': 'Total Students',
        'value': '$totalStudents',
        'subtitle': 'Assigned to you',
      },
      {
        'icon': Iconsax.book,
        'title': "Today's Classes",
        'value': '$todayClasses',
        'subtitle': 'Scheduled today',
      },
      {
        'icon': Iconsax.document_text,
        'title': 'Pending to Grade',
        'value': '$pendingGrading',
        'subtitle': 'Needs attention',
      },
      {
        'icon': Iconsax.chart_21,
        'title': 'Avg Performance',
        'value': '${avgScore.toStringAsFixed(1)}%',
        'subtitle': 'Class average',
      },
    ];

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: isMobile ? 12 : 20,
        mainAxisSpacing: isMobile ? 12 : 20,
        childAspectRatio: isMobile ? 1.2 : 1.3,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: statItems.length,
      itemBuilder: (context, index) {
        final item = statItems[index];
        return _buildStatCard(
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          value: item['value'] as String,
          subtitle: item['subtitle'] as String,
          isMobile: isMobile,
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: isMobile ? 18 : 22),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          SizedBox(height: isMobile ? 2 : 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 11 : 13,
              color: AppTheme.bodyText,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isMobile ? 1 : 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 9 : 11,
              color: AppTheme.bodyText.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysSchedule(List<dynamic> schedule, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Row(
              children: [
                Icon(Iconsax.calendar, color: AppTheme.primaryGreen, size: isMobile ? 18 : 22),
                SizedBox(width: isMobile ? 8 : 12),
                Text(
                  "Today's Schedule",
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 10,
                    vertical: isMobile ? 4 : 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${schedule.length} ${schedule.length == 1 ? 'Class' : 'Classes'}',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 10 : 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          schedule.isEmpty
              ? Padding(
            padding: EdgeInsets.all(isMobile ? 24 : 40),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Iconsax.calendar_tick,
                    size: isMobile ? 40 : 56,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(height: isMobile ? 8 : 16),
                  Text(
                    'No classes scheduled for today',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 12 : 14,
                      color: AppTheme.bodyText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
              : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            itemCount: schedule.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: isMobile ? 8 : 12),
            itemBuilder: (context, index) {
              final classItem = schedule[index];
              return _buildScheduleCard(classItem, isMobile);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> classItem, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 3 : 4,
            height: isMobile ? 30 : 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classItem['Class_Name'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 13 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: isMobile ? 2 : 4),
                Text(
                  classItem['Subject_Name'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 11 : 13,
                    color: AppTheme.bodyText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12,
              vertical: isMobile ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              classItem['Start_Time'] ?? '',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 11 : 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isMobile) {
    final actions = [
      {
        'icon': Iconsax.book_square,
        'title': 'My Classes',
        'subtitle': 'View all classes',
        'onTap': () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TeacherClassesScreen()),
          );
        }
      },
      {
        'icon': Iconsax.people,
        'title': 'Students',
        'subtitle': 'Manage students',
        'onTap': () {
          // TODO: Navigate to students screen
          CustomSnackbar.showInfo(context, 'Students screen coming soon!');
        }
      },
      {
        'icon': Iconsax.chart,
        'title': 'Analytics',
        'subtitle': 'View performance',
        'onTap': () {
          // TODO: Navigate to analytics screen
          CustomSnackbar.showInfo(context, 'Analytics screen coming soon!');
        }
      },
      {
        'icon': Iconsax.folder_open,
        'title': 'Materials',
        'subtitle': 'Study resources',
        'onTap': () {
          // TODO: Navigate to materials screen
          CustomSnackbar.showInfo(context, 'Materials screen coming soon!');
        }
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Text(
              "Quick Actions",
              style: GoogleFonts.inter(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            itemCount: actions.length,
            separatorBuilder: (context, index) => SizedBox(height: isMobile ? 6 : 8),
            itemBuilder: (context, index) {
              final action = actions[index];
              return InkWell(
                onTap: action['onTap'] as VoidCallback,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 6 : 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          action['icon'] as IconData,
                          color: AppTheme.primaryGreen,
                          size: isMobile ? 16 : 20,
                        ),
                      ),
                      SizedBox(width: isMobile ? 10 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              action['title'] as String,
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 12 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              action['subtitle'] as String,
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 10 : 11,
                                color: AppTheme.bodyText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Iconsax.arrow_right_3,
                        size: isMobile ? 14 : 16,
                        color: AppTheme.bodyText.withOpacity(0.4),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
