import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/StudentPannel/MySubject/chapter_Detail_Screen.dart';
import 'package:lms_publisher/StudentPannel/Service/student_subject_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';
import 'package:lms_publisher/screens/main_layout.dart';


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
  State<SubjectChaptersScreen> createState() => _SubjectChaptersScreenState();
}

class _SubjectChaptersScreenState extends State<SubjectChaptersScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  ChaptersResponse? _chaptersData;

  @override
  void initState() {
    super.initState();
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

  Widget _buildHeader() {
    return Row(
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
              Text(
                widget.subject.displaySubjectName,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 4),
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChapterDetailsScreen(
              chapter: chapter,
              subjectColor: widget.subjectColor,
              subjectName: widget.subject.displaySubjectName,
              // FIX: Pass the required subjectId
              subjectId: widget.subject.subjectId,
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
          border: Border.all(color: widget.subjectColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: widget.subjectColor.withOpacity(0.08),
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
                color: widget.subjectColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Iconsax.book_1, color: widget.subjectColor, size: 24),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.displayChapterName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkText,
                    ),
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

            Icon(Iconsax.arrow_right_3, color: widget.subjectColor, size: 20),
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