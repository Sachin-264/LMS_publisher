import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Teacher_Panel/MyClass/teachermaterialscreen.dart';
import 'package:lms_publisher/Teacher_Panel/teacher_material_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';

class TeacherSubjectChaptersScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final Color subjectColor;
  final String teacherCode;

  const TeacherSubjectChaptersScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.subjectColor,
    required this.teacherCode,
  });

  @override
  State<TeacherSubjectChaptersScreen> createState() => _TeacherSubjectChaptersScreenState();
}

class _TeacherSubjectChaptersScreenState extends State<TeacherSubjectChaptersScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _chapters = [];

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
      final chapters = await TeacherMaterialService.getChaptersBySubjectId(
        subjectId: widget.subjectId,
      );

      if (mounted) {
        setState(() {
          _chapters = chapters;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        CustomSnackbar.showError(context, _errorMessage!, title: 'Error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
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
            else
              _buildChaptersList(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left, color: AppTheme.darkText),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.subjectName,
        style: GoogleFonts.inter(
          color: AppTheme.darkText,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.subjectColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Iconsax.book_square, color: widget.subjectColor, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subjectName,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Iconsax.book_1, size: 16, color: widget.subjectColor),
                    const SizedBox(width: 6),
                    Text(
                      '${_chapters.length} Chapters',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: widget.subjectColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChaptersList() {
    if (_chapters.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _chapters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final chapter = _chapters[index];
        return _buildChapterCard(chapter);
      },
    );
  }

  Widget _buildChapterCard(Map<String, dynamic> chapter) {
    // Extract chapter data from the API response
    final chapterId = chapter['ChapterID'] ?? 0;
    final chapterName = chapter['ChapterName'] ?? 'Untitled Chapter';
    final chapterOrder = chapter['ChapterOrder'] ?? 0;
    final chapterDescription = chapter['ChapterDescription'] ?? '';
    final chapterCode = chapter['ChapterCode'] ?? '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherMaterialScreen(
              teacherCode: widget.teacherCode,
              chapterId: chapterId,
              chapterName: chapterName,
              subjectName: widget.subjectName,  // Added this line
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
          border: Border.all(color: widget.subjectColor.withOpacity(0.2), width: 1.5),
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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: widget.subjectColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '$chapterOrder',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: widget.subjectColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapterName,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (chapterDescription.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      chapterDescription,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.bodyText,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (chapterCode.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Iconsax.code, size: 14, color: AppTheme.bodyText),
                        const SizedBox(width: 6),
                        Text(
                          chapterCode,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.bodyText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Iconsax.arrow_right_3, color: widget.subjectColor, size: 22),
          ],
        ),
      ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Iconsax.book, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              'No Chapters Found',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no chapters available for this subject',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.bodyText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: BeautifulLoader(
          type: LoaderType.pulse,
          size: 70,
          color: widget.subjectColor,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Iconsax.danger, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 20),
            Text(
              'Error Loading Chapters',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
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
              onPressed: _loadChapters,
              icon: const Icon(Iconsax.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.subjectColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
