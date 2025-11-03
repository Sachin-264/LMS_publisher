import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/StudentPannel/MySubject/chapter_Detail_Screen.dart';
import 'package:lms_publisher/StudentPannel/MySubject/my_subject_screen.dart';
import 'package:lms_publisher/StudentPannel/Service/student_subject_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:provider/provider.dart';

const String _imageBaseUrl = "https://storage.googleapis.com/upload-images-34/images/LMS/";

class SubjectChaptersScreen extends StatefulWidget {
  final SubjectModel subject;
  final Color subjectColor;
  final String studentId;

  // ✅ NEW: Teacher data
  final TeacherNavigationData selectedTeacher;
  final List<TeacherNavigationData> allTeachers;
  final List<TeacherNavigationData> otherTeachers;

  const SubjectChaptersScreen({
    super.key,
    required this.subject,
    required this.subjectColor,
    required this.studentId,
    required this.selectedTeacher,
    required this.allTeachers,
    required this.otherTeachers,
  });

  @override
  State<SubjectChaptersScreen> createState() => _SubjectChaptersScreenState();
}

class _SubjectChaptersScreenState extends State<SubjectChaptersScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  ChaptersResponse? _chaptersData;
  late bool _isParent;

  // ✅ NEW: Current teacher state
  late TeacherNavigationData _currentTeacher;

  @override
  void initState() {
    super.initState();
    _isParent = Provider.of<UserProvider>(context, listen: false).isParent;

    // ✅ Initialize current teacher
    _currentTeacher = widget.selectedTeacher;

    print('👨👩👧 SubjectChaptersScreen - isParent: $_isParent');
    print('📚 Received Teacher: ${_currentTeacher.teacherFullName}');
    print('   Code: ${_currentTeacher.teacherCode}');
    print('   All Teachers: ${widget.allTeachers.length}');

    _loadChapters();
  }

  Future<void> _loadChapters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await StudentSubjectService.getSubjectChapters(
        widget.studentId,
        widget.subject.subjectId,
      );

      if (mounted) {
        setState(() {
          _chaptersData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
        CustomSnackbar.showError(context, _errorMessage!, title: 'Error');
      }
    }
  }

  // ✅ NEW: Switch teacher method
  void _switchTeacher(TeacherNavigationData newTeacher) {
    setState(() {
      _currentTeacher = newTeacher;
    });

    print('🔄 Switched to teacher: ${newTeacher.teacherFullName}');
    print('   Code: ${newTeacher.teacherCode}');
  }

  // ✅ NEW: Show other teachers modal
  void _showOtherTeachers() {
    if (widget.otherTeachers.isEmpty) {
      CustomSnackbar.showInfo(context, 'No other teachers assigned');
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
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
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
                      'Other Teachers',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.otherTeachers.length} teacher${widget.otherTeachers.length > 1 ? 's' : ''} available',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...widget.otherTeachers.map((teacher) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildTeacherSwitchCard(teacher),
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

  Widget _buildTeacherSwitchCard(TeacherNavigationData teacher) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _switchTeacher(teacher);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.subjectColor.withOpacity(0.08),
              widget.subjectColor.withOpacity(0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.subjectColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            // Teacher photo
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.subjectColor.withOpacity(0.3),
                  width: 2,
                ),
                image: teacher.teacherPhoto != null
                    ? DecorationImage(
                  image: NetworkImage('$_imageBaseUrl${teacher.teacherPhoto}'),
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
                      widget.subjectColor,
                      widget.subjectColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Iconsax.teacher,
                    color: Colors.white,
                    size: 28,
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
                    teacher.teacherFullName,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    teacher.designation,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: widget.subjectColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Code: ${teacher.teacherCode}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              size: 18,
              color: widget.subjectColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
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
            _buildHeader(),
            const SizedBox(height: 16),
            // ✅ NEW: Teacher banner
            _buildTeacherBanner(),
            const SizedBox(height: 32),
            if (_isLoading)
              _buildLoadingState()
            else if (_errorMessage != null)
              _buildErrorState()
            else if (_chaptersData != null)
                _buildChaptersList(),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Teacher banner widget
  Widget _buildTeacherBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.subjectColor.withOpacity(0.12),
            widget.subjectColor.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.subjectColor.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.subjectColor.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Teacher photo
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.subjectColor.withOpacity(0.3),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.subjectColor.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              image: _currentTeacher.teacherPhoto != null
                  ? DecorationImage(
                image: NetworkImage(
                    '$_imageBaseUrl${_currentTeacher.teacherPhoto}'),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: _currentTeacher.teacherPhoto == null
                ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    widget.subjectColor,
                    widget.subjectColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Iconsax.teacher,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            )
                : null,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teacher',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: widget.subjectColor.withOpacity(0.7),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentTeacher.teacherFullName,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.darkText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: widget.subjectColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.subjectColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _currentTeacher.designation,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.subjectColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Switch teacher button
          if (widget.otherTeachers.isNotEmpty)
            GestureDetector(
              onTap: _showOtherTeachers,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.subjectColor.withOpacity(0.2),
                      widget.subjectColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.subjectColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Iconsax.arrow_down_1,
                  size: 20,
                  color: widget.subjectColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final studentName = userProvider.selectedStudentName ?? 'Student';

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
                    'Viewing $studentName\'s Chapters',
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
          children: [
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderGrey.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Iconsax.arrow_left, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.subject.displaySubjectName,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkText,
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
                            color: widget.subjectColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.subjectColor.withOpacity(0.3),
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
                    '${_chaptersData?.chapters.length ?? 0} Chapters Available',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: widget.subjectColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChaptersList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _chaptersData!.chapters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final chapter = _chaptersData!.chapters[index];
        return _buildChapterCard(chapter);
      },
    );
  }

  Widget _buildChapterCard(ChapterModel chapter) {
    return InkWell(
      onTap: () {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChapterDetailsScreen(
              chapter: chapter,
              subjectColor: widget.subjectColor,
              subjectName: widget.subject.displaySubjectName,
              subjectId: widget.subject.subjectId,
              isParent: userProvider.isParent,
              // ✅ PASS teacher data to next screen
              selectedTeacher: _currentTeacher,
              allTeachers: widget.allTeachers,
              otherTeachers: widget.otherTeachers, academicYear: '2025-26',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isParent
                ? widget.subjectColor.withOpacity(0.3)
                : widget.subjectColor.withOpacity(0.2),
            width: _isParent ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isParent
                  ? widget.subjectColor.withOpacity(0.15)
                  : widget.subjectColor.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.subjectColor.withOpacity(_isParent ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Iconsax.book_1,
                color: widget.subjectColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chapter.displayChapterName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkText,
                          ),
                        ),
                      ),
                      if (_isParent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Review',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${chapter.materialCount} materials • ${chapter.progressPercentage.toStringAsFixed(0)}% complete',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.bodyText.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              color: widget.subjectColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: BeautifulLoader(
        type: LoaderType.pulse,
        size: 70,
        color: widget.subjectColor,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        children: [
          Icon(Iconsax.danger, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_errorMessage'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadChapters,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
