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

class MySubjectsScreen extends StatefulWidget {
  const MySubjectsScreen({super.key});

  @override
  State createState() => _MySubjectsScreenState();
}

class _MySubjectsScreenState extends State<MySubjectsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  List<SubjectModel> _subjects = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late bool _isParent; // ✅ ADD THIS

  @override
  void initState() {
    super.initState();

    // ✅ Initialize isParent once
    _isParent = Provider.of<UserProvider>(context, listen: false).isParent;
    print('👨‍👩‍👧 MySubjectsScreen - isParent: $_isParent');

    // Setup fade animation
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
            if (!_isLoading && _subjects.isNotEmpty) ...[
              const SizedBox(height: 32),
            ],
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

  // ========== PAGE HEADER with Parent Indicator ==========
  Widget _buildPageHeader() {
    final userProvider = Provider.of<UserProvider>(context);
    final firstName =
        userProvider.userName?.split(' ').first ?? 'Student';
    final studentName = userProvider.selectedStudentName ?? firstName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Parent indicator badge
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

        // Main header row
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
                      // ✅ Parent badge on side
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

            // ✅ Refresh button (enhanced for parent)
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

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isPrimary = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isPrimary
            ? AppTheme.primaryGreen.withOpacity(0.1)
            : Colors.white,
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
              color: isPrimary ? AppTheme.primaryGreen : AppTheme.bodyText,
              size: 20,
            ),
          ),
        ),
      ),
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
            .map((entry) => TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (entry.key * 100)),
          tween: Tween<double>(begin: 0.0, end: 1.0),
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
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0.0, end: 1.0),
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
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0.0, end: 1.0),
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
              padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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

// ========== SUBJECT CARD WIDGET ==========
class _SubjectCard extends StatefulWidget {
  final SubjectModel subject;
  final bool isParent; // ✅ ADD THIS

  const _SubjectCard({
    required this.subject,
    required this.isParent, // ✅ ADD THIS
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
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEF4444), // Red
      const Color(0xFF14B8A6), // Teal
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectChaptersScreen(
          subject: widget.subject,
          subjectColor: _subjectColor,
          studentId: studentId,
        ),
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
                    ? _subjectColor.withOpacity(0.03)
                    : Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered
                  ? _subjectColor.withOpacity(widget.isParent ? 0.5 : 0.4)
                  : AppTheme.borderGrey.withOpacity(0.12),
              width: _isHovered ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? _subjectColor.withOpacity(widget.isParent ? 0.3 : 0.25)
                    : Colors.black.withOpacity(0.03),
                blurRadius: _isHovered ? 32 : 12,
                offset: Offset(0, _isHovered ? 16 : 8),
                spreadRadius: _isHovered ? 0 : -2,
              ),
              if (_isHovered)
                BoxShadow(
                  color: _subjectColor.withOpacity(widget.isParent ? 0.15 : 0.1),
                  blurRadius: 60,
                  offset: const Offset(0, 24),
                  spreadRadius: -8,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background gradient accent
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _subjectColor.withOpacity(0.08),
                          _subjectColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // ✅ Parent monitoring overlay
                if (widget.isParent)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Iconsax.eye,
                            size: 12,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Monitoring',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Main content
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardHeader(subject),
                      const SizedBox(height: 24),
                      if (subject.currentChapterName != null)
                        _buildCurrentChapterSection(subject),
                      if (subject.currentChapterName != null)
                        const SizedBox(height: 24),
                      _buildProgressSection(subject),
                      const SizedBox(height: 18),
                      _buildStatsRow(subject),
                      const SizedBox(height: 24),
                      _buildActionButton(context),
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
    );
  }

  Widget _buildCardHeader(SubjectModel subject) {
    return Row(
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          tween: Tween<double>(begin: 0.0, end: _isHovered ? 1.0 : 0.0),
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value * 0.1,
              child: Transform.scale(
                scale: 1.0 + (value * 0.08),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _subjectColor,
                        _subjectColor.withOpacity(0.75),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _subjectColor.withOpacity(0.35),
                        blurRadius: 16 + (value * 8),
                        offset: Offset(0, 6 + (value * 4)),
                      ),
                      BoxShadow(
                        color: _subjectColor.withOpacity(0.15),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Iconsax.book_1,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject.displaySubjectName,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkText,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subject.teacherNames != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _subjectColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Iconsax.teacher,
                        size: 14,
                        color: _subjectColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subject.teacherNames!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color:
                          AppTheme.bodyText.withOpacity(0.75),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
            _subjectColor.withOpacity(0.08),
            _subjectColor.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _subjectColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _subjectColor.withOpacity(0.2),
                  _subjectColor.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.document_text,
              size: 20,
              color: _subjectColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isParent ? 'CURRENT CHAPTER' : 'CONTINUE READING',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: _subjectColor.withOpacity(0.75),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subject.currentChapterName!,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Iconsax.arrow_right_3,
            size: 18,
            color: _subjectColor.withOpacity(0.6),
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
              widget.isParent
                  ? 'Student Progress'
                  : 'Overall Progress',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.bodyText.withOpacity(0.75),
                letterSpacing: 0.3,
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _subjectColor.withOpacity(0.15),
                    _subjectColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _subjectColor.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Text(
                '${subject.progressPercentage.toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _subjectColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Stack(
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: _subjectColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              widthFactor: subject.progressPercentage / 100,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _subjectColor,
                      _subjectColor.withOpacity(0.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _subjectColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
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
            value:
            '${subject.completedChapters}/${subject.totalChapters}',
            color: _subjectColor,
          ),
        ),
        const SizedBox(width: 14),
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
            color.withOpacity(0.06),
            color.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.bodyText.withOpacity(0.65),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
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
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isParent
                    ? Iconsax.eye
                    : Iconsax.play_circle,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                widget.isParent ? 'Review Chapters' : 'Continue Learning',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Iconsax.arrow_right_3, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastStudiedInfo(SubjectModel subject) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.bodyText.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.clock,
                size: 13,
                color: AppTheme.bodyText.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                widget.isParent
                    ? 'Last studied ${subject.lastStudiedDisplay}'
                    : 'Last studied ${subject.lastStudiedDisplay}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.bodyText.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
