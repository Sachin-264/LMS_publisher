import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/StudentPannel/MySubject/chapter_Detail_Screen.dart';
import 'package:lms_publisher/StudentPannel/Service/student_subject_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:provider/provider.dart';

class SubjectChaptersScreen extends StatefulWidget {
  final SubjectModel subject;
  final Color subjectColor;
  final String studentId;

  const SubjectChaptersScreen({
    super.key,
    required this.subject,
    required this.subjectColor,
    required this.studentId,
  });

  @override
  State createState() => _SubjectChaptersScreenState();
}

class _SubjectChaptersScreenState extends State<SubjectChaptersScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  ChaptersResponse? _chaptersData;
  late bool _isParent; // ✅ ADD THIS

  @override
  void initState() {
    super.initState();
    // ✅ Initialize isParent once
    _isParent = Provider.of<UserProvider>(context, listen: false).isParent;
    print('👨‍👩‍👧 SubjectChaptersScreen - isParent: $_isParent');
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

  // ✅ UPDATED Header with Parent View Indicator
  Widget _buildHeader() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final studentName = userProvider.selectedStudentName ?? 'Student';

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

        // Main header row
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
                      // ✅ Parent badge on side
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

  // ✅ UPDATED Chapter Card with Parent Styling
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
              isParent: userProvider.isParent, // ✅ PASS isParent HERE
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
                      // ✅ Parent monitoring badge
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
              color: _isParent ? widget.subjectColor : widget.subjectColor,
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
