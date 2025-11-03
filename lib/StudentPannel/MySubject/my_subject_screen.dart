import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/StudentPannel/Service/student_subject_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:provider/provider.dart';
import 'subject_chapter_screen.dart';

const String _imageBaseUrl = "https://storage.googleapis.com/upload-images-34/images/LMS/";

class MySubjectsScreen extends StatefulWidget {
  const MySubjectsScreen({super.key});

  @override
  State<MySubjectsScreen> createState() => _MySubjectsScreenState();
}

class _MySubjectsScreenState extends State<MySubjectsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  List<SubjectModel> _subjects = [];
  ClassInfo? _classInfo;  // CHANGED from: Map<String, dynamic>? _classInfo;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;  // CHANGED from: late Animation _fadeAnimation;
  late bool _isParent;


  @override
  void initState() {
    super.initState();
    _isParent = Provider.of<UserProvider>(context, listen: false).isParent;
    print('👨👩👧 MySubjectsScreen - isParent: $_isParent');

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _loadSubjects();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
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

      final response =
      await StudentSubjectService.getStudentSubjects(studentId);

      if (mounted) {
        setState(() {
          _subjects = response.subjects;
          _classInfo = response.classInfo;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
        CustomSnackbar.showError(
          context,
          _errorMessage!,
          title: 'Failed to Load Subjects',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      activeScreen: AppScreen.mySubjects,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            if (!_isLoading && _classInfo != null) ...{
              const SizedBox(height: 24),
              _buildClassInfoSection(),
            },
            if (!_isLoading && _subjects.isNotEmpty) ...{
              const SizedBox(height: 32),
            },
            if (_isLoading)
              _buildLoadingState()
            else if (_errorMessage != null)
              _buildErrorState()
            else if (_subjects.isEmpty)
                _buildEmptyState()
              else
                _buildSubjectsGrid(),
          ],
        ),
      ),
    );
  }

  // ========== PAGE HEADER ==========
  Widget _buildPageHeader() {
    final userProvider = Provider.of<UserProvider>(context);
    final firstName = userProvider.userName?.split(' ').first ?? 'Student';
    final studentName = userProvider.selectedStudentName ?? firstName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isParent)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Iconsax.shield_security,
                    color: Colors.amber,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Monitoring $studentName\'s Learning',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isParent ? 'Subject Overview' : 'My Subjects',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkText,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      if (_isParent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Iconsax.eye,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Parent View',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isParent
                        ? 'Review ${studentName}\'s course progress'
                        : '${_subjects.length} subjects to explore',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.bodyText.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildActionButton(
              icon: Iconsax.refresh,
              onTap: () {
                _loadSubjects();
                CustomSnackbar.showInfo(
                  context,
                  _isParent
                      ? 'Refreshing student progress...'
                      : 'Refreshing subjects...',
                );
              },
              tooltip: 'Refresh',
              isPrimary: true,
            ),
          ],
        ),
      ],
    );
  }

  // ========== CLASS INFO SECTION (NEW) ==========
  Widget _buildClassInfoSection() {
    if (_classInfo == null) return const SizedBox.shrink();

    final className = _classInfo!.className;
    final classCode = _classInfo!.classCode;
    final sectionName = _classInfo!.sectionName;
    final academicYear = _classInfo!.academicYear;
    final teacherName = _classInfo!.classTeacherFullName;
    final teacherMobile = _classInfo!.classTeacherMobile;
    final teacherEmail = _classInfo!.classTeacherEmail ?? '';
    final teacherDesignation = _classInfo!.classTeacherDesignation;
    final teacherPhoto = _classInfo!.classTeacherPhoto;
    final teacherExperience = _classInfo!.classTeacherExperienceYears;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen.withOpacity(0.08),
            AppTheme.primaryGreen.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryGreen,
                                AppTheme.primaryGreen.withOpacity(0.75),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Iconsax.building_3,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              className,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkText,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Section $sectionName • $academicYear',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.bodyText.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  classCode,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Class Teacher Info
          _buildClassTeacherCard(
            teacherName: teacherName,
            teacherMobile: teacherMobile,
            teacherEmail: teacherEmail,
            teacherDesignation: teacherDesignation,
            teacherPhoto: teacherPhoto,
            teacherExperience: teacherExperience,
          ),
        ],
      ),
    );
  }

  // Class Teacher Card
  Widget _buildClassTeacherCard({
    required String teacherName,
    required String teacherMobile,
    required String teacherEmail,
    required String teacherDesignation,
    required String? teacherPhoto,
    required int teacherExperience,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderGrey.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Teacher Photo
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                width: 2,
              ),
              image: teacherPhoto != null
                  ? DecorationImage(
                image: NetworkImage('$_imageBaseUrl$teacherPhoto'),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: teacherPhoto == null
                ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen,
                    AppTheme.primaryGreen.withOpacity(0.7),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Iconsax.teacher,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Class Teacher',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.bodyText.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  teacherName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        teacherDesignation,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (teacherExperience > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$teacherExperience y exp',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showClassTeacherDetailsModal(
              teacherName: teacherName,
              teacherMobile: teacherMobile,
              teacherEmail: teacherEmail,
              teacherDesignation: teacherDesignation,
              teacherPhoto: teacherPhoto,
              teacherExperience: teacherExperience,
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Icon(
                Iconsax.info_circle,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Class Teacher Details Modal (NEW)
  void _showClassTeacherDetailsModal({
    required String teacherName,
    required String teacherMobile,
    required String teacherEmail,
    required String teacherDesignation,
    required String? teacherPhoto,
    required int teacherExperience,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle bar
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.bodyText.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Large teacher photo
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          width: 3,
                        ),
                        image: teacherPhoto != null
                            ? DecorationImage(
                          image: NetworkImage('$_imageBaseUrl$teacherPhoto'),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: teacherPhoto == null
                          ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryGreen,
                              AppTheme.primaryGreen.withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Iconsax.teacher,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(height: 20),
                    // Name
                    Text(
                      teacherName,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Designation
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        teacherDesignation,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Info Grid
                    Column(
                      children: [
                        _buildDetailRow(
                          icon: Iconsax.call,
                          label: 'Mobile',
                          value: teacherMobile.isNotEmpty
                              ? teacherMobile
                              : 'Not provided',
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          icon: Iconsax.sms,
                          label: 'Email',
                          value: teacherEmail.isNotEmpty
                              ? teacherEmail
                              : 'Not provided',
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          icon: Iconsax.award,
                          label: 'Experience',
                          value: '$teacherExperience years',
                          color: Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.bodyText.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========== SUBJECTS GRID ==========
  Widget _buildSubjectsGrid() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: _subjects
            .asMap()
            .entries
            .map((entry) => TweenAnimationBuilder(
          duration: Duration(milliseconds: 400 + (entry.key * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: _SubjectCard(
                  subject: entry.value,
                  isParent: _isParent,
                ),
              ),
            );
          },
        ))
            .toList(),
      ),
    );
  }

  // ========== ACTION BUTTON ==========
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isPrimary = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isPrimary ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isPrimary
                    ? AppTheme.primaryGreen.withOpacity(0.3)
                    : AppTheme.borderGrey.withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color:
              isPrimary ? AppTheme.primaryGreen : AppTheme.bodyText,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  // ========== LOADING STATE ==========
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 120),
          BeautifulLoader(
            type: LoaderType.pulse,
            size: 80,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 24),
          Text(
            _isParent
                ? 'Loading student progress...'
                : 'Loading your subjects...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.bodyText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait a moment',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.bodyText.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ========== ERROR STATE ==========
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 120),
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Iconsax.danger,
                    size: 72,
                    color: Colors.red,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          Text(
            'Oops! Something Went Wrong',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              _errorMessage ?? 'Unknown error occurred',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.bodyText.withOpacity(0.7),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadSubjects,
            icon: const Icon(Iconsax.refresh, size: 20),
            label: Text(
              'Try Again',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              shadowColor: AppTheme.primaryGreen.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  // ========== EMPTY STATE ==========
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 120),
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (value * 0.2),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Iconsax.book,
                      size: 80,
                      color: AppTheme.primaryGreen.withOpacity(0.5),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          Text(
            'No Subjects Found',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isParent
                ? 'No subjects available for this student yet.'
                : 'You haven\'t been enrolled in any subjects yet.\nPlease contact your administrator.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.bodyText.withOpacity(0.7),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _loadSubjects,
            icon: const Icon(Iconsax.refresh, size: 18),
            label: Text(
              'Refresh',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 14,
              ),
              side: BorderSide(
                color: AppTheme.primaryGreen.withOpacity(0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ CHUNK 2: IMPROVED SUBJECT CARD WIDGET ============

class _SubjectCard extends StatefulWidget {
  final SubjectModel subject;
  final bool isParent;

  const _SubjectCard({
    required this.subject,
    required this.isParent,
  });

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  Color get _subjectColor {
    final colors = [
      const Color(0xFF6366F1),    // Indigo
      const Color(0xFFEC4899),    // Pink
      const Color(0xFF10B981),    // Emerald
      const Color(0xFFF59E0B),    // Amber
      const Color(0xFF8B5CF6),    // Purple
      const Color(0xFF06B6D4),    // Cyan
      const Color(0xFFEF4444),    // Red
      const Color(0xFF14B8A6),    // Teal
    ];
    return colors[widget.subject.subjectId % colors.length];
  }

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

// ============================================
// UPDATED _navigateToChapters METHOD
// ============================================

  void _navigateToChapters(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final studentId = userProvider.userCode;

    if (studentId == null) {
      CustomSnackbar.showError(
        context,
        'Student ID not found. Please login again.',
        title: 'Authentication Error',
      );
      return;
    }

    try {
      // Get complete navigation data with teacher details
      final navigationData = widget.subject.getNavigationData(_subjectColor);

      print('📚 Navigation Data with Teacher Details:');
      print('   Subject: ${navigationData.subject.displaySubjectName}');
      print('   Selected Teacher: ${navigationData.selectedTeacher.teacherFullName}');
      print('   Teacher Code: ${navigationData.selectedTeacher.teacherCode}');
      print('   Teacher Photo: ${navigationData.selectedTeacher.teacherPhoto}');
      print('   All Teachers Count: ${navigationData.allTeachers.length}');
      print('   Other Teachers Count: ${navigationData.otherTeachers.length}');

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SubjectChaptersScreen(
                // Subject data
                  subject: navigationData.subject,
                  subjectColor: navigationData.subjectColor,
                  studentId: studentId,

                  // Selected Teacher (full details)
                  selectedTeacher: navigationData.selectedTeacher as dynamic,

                  // All Teachers (full details)
                  allTeachers: navigationData.allTeachers as dynamic,

                  // Other Teachers (full details)
                  otherTeachers: navigationData.otherTeachers as dynamic,
              ),
          ),
              );

    } catch (e) {
      CustomSnackbar.showError(
        context,
        e.toString(),
        title: 'Navigation Error',
      );
    }
  }


  void _showAllTeachersModal() {
    final teachers = widget.subject.teachers;

    if (teachers.isEmpty) {
      CustomSnackbar.showInfo(
        context,
        'No teachers assigned to this subject yet.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle bar
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.bodyText.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subject Teachers',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${teachers.length} teacher${teachers.length > 1 ? 's' : ''} assigned',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.bodyText.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...teachers.asMap().entries.map((entry) {
                      final teacher = entry.value;
                      final isLast = entry.key == teachers.length - 1;

                      return Column(
                        children: [
                          _buildEnhancedTeacherTile(teacher),
                          if (!isLast)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Divider(
                                color: AppTheme.borderGrey.withOpacity(0.1),
                                height: 1,
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTeacherTile(TeacherModel teacher) {
    final teacherName = teacher.teacherFullName;
    final teacherDesignation = teacher.designation ?? 'Teacher';
    final teacherPhone = teacher.mobileNumber;
    final teacherEmail = teacher.institutionalEmail ?? '';
    final teacherPhoto = teacher.teacherPhoto;
    final isCurrentTeacher = teacher.isCurrentTeacher;
    final teacherCode = teacher.teacherCode;
    final experience = teacher.experienceYears;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isCurrentTeacher
                ? _subjectColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.03),
            isCurrentTeacher
                ? _subjectColor.withOpacity(0.05)
                : Colors.grey.withOpacity(0.01),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrentTeacher
              ? _subjectColor.withOpacity(0.25)
              : AppTheme.borderGrey.withOpacity(0.15),
          width: isCurrentTeacher ? 2 : 1.5,
        ),
        boxShadow: [
          if (isCurrentTeacher)
            BoxShadow(
              color: _subjectColor.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Column(
        children: [
          // Main teacher info row
          Row(
            children: [
              // Teacher photo with badge
              Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _subjectColor.withOpacity(0.4),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _subjectColor.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      image: teacherPhoto != null
                          ? DecorationImage(
                        image: NetworkImage('$_imageBaseUrl$teacherPhoto'),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: teacherPhoto == null
                        ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            _subjectColor,
                            _subjectColor.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Iconsax.teacher,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    )
                        : null,
                  ),
                  // Current teacher badge
                  if (isCurrentTeacher)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Iconsax.check,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Teacher details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            teacherName,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentTeacher)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.withOpacity(0.2),
                                  Colors.green.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'Current',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.green.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _subjectColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _subjectColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            teacherDesignation,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: _subjectColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        if (experience > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '$experience yrs exp',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber.shade700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.call,
                                size: 13,
                                color: AppTheme.bodyText.withOpacity(0.5),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  teacherPhone.isNotEmpty
                                      ? teacherPhone
                                      : 'N/A',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color:
                                    AppTheme.bodyText.withOpacity(0.65),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Teacher code badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'Code: $teacherCode',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action button
              GestureDetector(
                onTap: () => _showTeacherDetailsModal(
                  teacher: teacher,
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _subjectColor.withOpacity(0.15),
                        _subjectColor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _subjectColor.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Iconsax.arrow_right_3,
                    size: 18,
                    color: _subjectColor,
                  ),
                ),
              ),
            ],
          ),
          // Email row if available
          if (teacherEmail.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.sms,
                    size: 14,
                    color: Colors.orange.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      teacherEmail,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showTeacherDetailsModal({
    required TeacherModel teacher,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle bar
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 24),
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.bodyText.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    // Large profile photo
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _subjectColor.withOpacity(0.4),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _subjectColor.withOpacity(0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        image: teacher.teacherPhoto != null
                            ? DecorationImage(
                          image: NetworkImage(
                              '$_imageBaseUrl${teacher.teacherPhoto}'),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: teacher.teacherPhoto == null
                          ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              _subjectColor,
                              _subjectColor.withOpacity(0.6),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Iconsax.teacher,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(height: 24),
                    // Teacher name
                    Text(
                      teacher.teacherFullName,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.darkText,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    // Teacher code and designation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.35),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'Code: ${teacher.teacherCode}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.blue.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _subjectColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _subjectColor.withOpacity(0.35),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            teacher.designation ?? 'Teacher',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _subjectColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Info cards grid
                    Column(
                      children: [
                        _buildInfoCard(
                          icon: Iconsax.emercoin_emc,
                          label: 'Employee Code',
                          value: teacher.employeeCode ?? 'N/A',
                          color: Colors.purple,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          icon: Iconsax.call,
                          label: 'Phone',
                          value: teacher.mobileNumber.isNotEmpty
                              ? teacher.mobileNumber
                              : 'Not provided',
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          icon: Iconsax.sms,
                          label: 'Email',
                          value: teacher.institutionalEmail ?? 'Not provided',
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          icon: Iconsax.building,
                          label: 'Department',
                          value: teacher.department ?? 'Not assigned',
                          color: Colors.teal,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          icon: Iconsax.award,
                          label: 'Experience',
                          value: '${teacher.experienceYears} years',
                          color: Colors.amber,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          icon: Iconsax.calendar,
                          label: 'Joined On',
                          value: teacher.dateOfJoining != null
                              ? '${teacher.dateOfJoining!.day}/${teacher.dateOfJoining!.month}/${teacher.dateOfJoining!.year}'
                              : 'N/A',
                          color: Colors.indigo,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _subjectColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          shadowColor: _subjectColor.withOpacity(0.4),
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.bodyText.withOpacity(0.65),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkText,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.subject;
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _scaleController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _scaleController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: () => _navigateToChapters(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: 400,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  _isHovered
                      ? _subjectColor.withOpacity(0.04)
                      : Colors.white,
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: _isHovered
                    ? _subjectColor.withOpacity(
                    widget.isParent ? 0.55 : 0.45)
                    : AppTheme.borderGrey.withOpacity(0.12),
                width: _isHovered ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? _subjectColor.withOpacity(
                      widget.isParent ? 0.35 : 0.28)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: _isHovered ? 36 : 14,
                  offset: Offset(0, _isHovered ? 18 : 10),
                  spreadRadius: _isHovered ? 2 : -2,
                ),
                if (_isHovered)
                  BoxShadow(
                    color: _subjectColor.withOpacity(
                        widget.isParent ? 0.18 : 0.12),
                    blurRadius: 70,
                    offset: const Offset(0, 28),
                    spreadRadius: -10,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                children: [
                  // Animated background orb
                  Positioned(
                    top: -120,
                    right: -120,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween(
                        begin: 0.0,
                        end: _isHovered ? 1.0 : 0.0,
                      ),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  _subjectColor.withOpacity(0.12),
                                  _subjectColor.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Parent monitor badge
                  if (widget.isParent)
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.withOpacity(0.15),
                              Colors.blue.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.25),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.eye,
                              size: 13,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Monitoring',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue.shade700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Card content
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCardHeader(subject),
                        const SizedBox(height: 26),
                        if (subject.currentChapterName != null)
                          _buildCurrentChapterSection(subject),
                        if (subject.currentChapterName != null)
                          const SizedBox(height: 26),
                        _buildProgressSection(subject),
                        const SizedBox(height: 20),
                        _buildStatsRow(subject),
                        const SizedBox(height: 28),
                        _buildActionButtons(context),
                        if (subject.lastStudiedDisplay != 'Never')
                          _buildLastStudiedInfo(subject),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(SubjectModel subject) {
    return Row(
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: _isHovered ? 1.0 : 0.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value * 0.15,
              child: Transform.scale(
                scale: 1.0 + (value * 0.12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _subjectColor,
                        _subjectColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _subjectColor.withOpacity(0.4),
                        blurRadius: 20 + (value * 12),
                        offset: Offset(0, 8 + (value * 6)),
                        spreadRadius: value * 2,
                      ),
                      BoxShadow(
                        color: _subjectColor.withOpacity(0.15),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Iconsax.book_1,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject.displaySubjectName,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.darkText,
                  letterSpacing: -0.7,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subject.teachers.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _subjectColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: _subjectColor.withOpacity(0.25),
                        ),
                      ),
                      child: Icon(
                        Iconsax.teacher,
                        size: 15,
                        color: _subjectColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subject.teachers[0].teacherFullName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.bodyText.withOpacity(0.75),
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (subject.teachers.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _subjectColor.withOpacity(0.18),
                              _subjectColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: _subjectColor.withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          '+${subject.teachers.length - 1}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: _subjectColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentChapterSection(SubjectModel subject) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _subjectColor.withOpacity(0.1),
            _subjectColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _subjectColor.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _subjectColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _subjectColor.withOpacity(0.25),
                  _subjectColor.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: _subjectColor.withOpacity(0.3),
              ),
            ),
            child: Icon(
              Iconsax.document_text,
              size: 22,
              color: _subjectColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isParent ? 'CURRENT CHAPTER' : 'CONTINUE READING',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: _subjectColor.withOpacity(0.8),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subject.currentChapterName!,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkText,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Iconsax.arrow_right_3,
            size: 20,
            color: _subjectColor.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(SubjectModel subject) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.isParent ? 'Student Progress' : 'Your Progress',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.bodyText.withOpacity(0.8),
                letterSpacing: 0.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _subjectColor.withOpacity(0.18),
                    _subjectColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: _subjectColor.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _subjectColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${subject.progressPercentage.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _subjectColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: _subjectColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _subjectColor.withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              widthFactor: subject.progressPercentage / 100,
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      _subjectColor,
                      _subjectColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _subjectColor.withOpacity(0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(SubjectModel subject) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Iconsax.book_square,
            label: 'Chapters',
            value: '${subject.completedChapters}/${subject.totalChapters}',
            color: _subjectColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            icon: Iconsax.clock,
            label: 'Study Time',
            value:
            '${subject.totalTimeSpentMinutes ~/ 60}h ${subject.totalTimeSpentMinutes % 60}m',
            color: _subjectColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: color.withOpacity(0.25),
              ),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.bodyText.withOpacity(0.7),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppTheme.darkText,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final teachers = widget.subject.teachers;

    return Column(
      children: [
        // Main action button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _navigateToChapters(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: _subjectColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ).copyWith(
              overlayColor: WidgetStateProperty.all(
                Colors.white.withOpacity(0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isParent ? Iconsax.eye : Iconsax.play_circle,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.isParent ? 'Review Chapters' : 'Continue Learning',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (teachers.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAllTeachersModal,
              icon: const Icon(Iconsax.people, size: 20),
              label: Text(
                '${teachers.length} Teacher${teachers.length > 1 ? 's' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _subjectColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: _subjectColor.withOpacity(0.35),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLastStudiedInfo(SubjectModel subject) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.bodyText.withOpacity(0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.bodyText.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.clock,
                size: 13,
                color: AppTheme.bodyText.withOpacity(0.5),
              ),
              const SizedBox(width: 7),
              Text(
                'Last studied ${subject.lastStudiedDisplay}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.bodyText.withOpacity(0.65),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ CHUNK 1: NEW MODEL FOR NAVIGATION ============
// Add this to your models file (student_subject_service.dart or models.dart)

// ============================================
// CHUNK 1: NEW TEACHER DATA MODEL FOR NAVIGATION
// ============================================

class TeacherNavigationData {
  final String teacherCode;
  final String teacherFullName;
  final String? teacherPhoto;
  final String designation;
  final String department;
  final String mobileNumber;
  final String? institutionalEmail;
  final int experienceYears;
  final String? employeeCode;
  final bool isCurrentTeacher;
  final DateTime? dateOfJoining;
  final String employeeStatus;

  TeacherNavigationData({
    required this.teacherCode,
    required this.teacherFullName,
    this.teacherPhoto,
    required this.designation,
    required this.department,
    required this.mobileNumber,
    this.institutionalEmail,
    required this.experienceYears,
    this.employeeCode,
    required this.isCurrentTeacher,
    this.dateOfJoining,
    required this.employeeStatus,
  });

  factory TeacherNavigationData.fromTeacherModel(TeacherModel teacher) {
    return TeacherNavigationData(
      teacherCode: teacher.teacherCode,
      teacherFullName: teacher.teacherFullName,
      teacherPhoto: teacher.teacherPhoto,
      designation: teacher.designation ?? 'Teacher',
      department: teacher.department ?? 'Not Assigned',
      mobileNumber: teacher.mobileNumber,
      institutionalEmail: teacher.institutionalEmail,
      experienceYears: teacher.experienceYears,
      employeeCode: teacher.employeeCode,
      isCurrentTeacher: teacher.isCurrentTeacher,
      dateOfJoining: teacher.dateOfJoining,
      employeeStatus: teacher.employeeStatus ?? 'Active',
    );
  }
}

// ============================================
// CHUNK 2: ENHANCED NAVIGATION DATA MODEL
// ============================================

class SubjectNavigationDataWithTeachers {
  final SubjectModel subject;
  final TeacherNavigationData selectedTeacher;
  final List<TeacherNavigationData> allTeachers;
  final List<TeacherNavigationData> otherTeachers;
  final Color subjectColor;

  SubjectNavigationDataWithTeachers({
    required this.subject,
    required this.selectedTeacher,
    required this.allTeachers,
    required this.otherTeachers,
    required this.subjectColor,
  });
}

// ============================================
// CHUNK 3: EXTENSION METHODS FOR EASY ACCESS
// ============================================

extension SubjectModelTeacherExtension on SubjectModel {
  /// Get selected teacher with full details
  TeacherNavigationData? getSelectedTeacherData() {
    if (teachers.isEmpty) return null;

    final currentTeacher = teachers.firstWhere(
          (t) => t.isCurrentTeacher,
      orElse: () => teachers.first,
    );

    return TeacherNavigationData.fromTeacherModel(currentTeacher);
  }

  /// Get all teachers with full details
  List<TeacherNavigationData> getAllTeachersData() {
    return teachers
        .map((t) => TeacherNavigationData.fromTeacherModel(t))
        .toList();
  }

  /// Get other teachers (not selected) with full details
  List<TeacherNavigationData> getOtherTeachersData() {
    final selected = getSelectedTeacherData();
    return teachers
        .where((t) => t.teacherCode != selected?.teacherCode)
        .map((t) => TeacherNavigationData.fromTeacherModel(t))
        .toList();
  }

  /// Get complete navigation data
  SubjectNavigationDataWithTeachers getNavigationData(Color color) {
    final selectedTeacher = getSelectedTeacherData();

    if (selectedTeacher == null && teachers.isEmpty) {
      throw Exception('No teachers found for this subject');
    }

    return SubjectNavigationDataWithTeachers(
      subject: this,
      selectedTeacher: selectedTeacher ?? getAllTeachersData().first,
      allTeachers: getAllTeachersData(),
      otherTeachers: getOtherTeachersData(),
      subjectColor: color,
    );
  }
}


extension SubjectModelExtension on SubjectModel {
  String getSelectedTeacherCode() {
    if (teachers.isEmpty) return '';
    final currentTeacher = teachers.firstWhere(
          (t) => t.isCurrentTeacher,
      orElse: () => teachers.first,
    );
    return currentTeacher.teacherCode ?? '';
  }

  /// Get all teacher codes
  List<String> getAllTeacherCodes() {
    return teachers.map((t) => t.teacherCode).toList();
  }

  /// Get selected teacher code and others
  Map<String, List<String>> getTeacherCodesByType() {
    final selected = getSelectedTeacherCode();
    final others = getAllTeacherCodes()
        .where((code) => code != selected)
        .toList();

    return {
      'selected': [selected],
      'others': others,
    };
  }
}


