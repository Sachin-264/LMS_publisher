import 'package:flutter/material.dart';
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
  State<TeacherSubjectChaptersScreen> createState() =>
      _TeacherSubjectChaptersScreenState();
}

class _TeacherSubjectChaptersScreenState
    extends State<TeacherSubjectChaptersScreen> {
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
      backgroundColor: AppTheme.lightGrey, // Use theme background
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.defaultPadding * 1.5), // 24.0
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
      backgroundColor: AppTheme.background, // Use theme background
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left, color: AppTheme.darkText),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.subjectName,
        style: AppTheme.labelText.copyWith(
          fontSize: 18,
          color: AppTheme.darkText,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppTheme.borderGrey, // Use theme border color
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.background, // Use theme background
        borderRadius: AppTheme.defaultBorderRadius * 1.5, // 18.0
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor, // Use theme shadow
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
              gradient: LinearGradient(
                colors: [
                  widget.subjectColor,
                  widget.subjectColor.withOpacity(0.7)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppTheme.defaultBorderRadius, // 12.0
              boxShadow: [
                BoxShadow(
                  color: widget.subjectColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(Iconsax.book_square, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subjectName,
                  style: AppTheme.headline1.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Iconsax.book_1, size: 16, color: widget.subjectColor),
                    const SizedBox(width: 6),
                    Text(
                      _isLoading
                          ? 'Loading...'
                          : '${_chapters.length} Chapters',
                      style: AppTheme.labelText.copyWith(
                        color: widget.subjectColor,
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
              subjectName: widget.subjectName,
            ),
          ),
        );
      },
      borderRadius: AppTheme.defaultBorderRadius * 1.5, // 18.0
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: AppTheme.defaultBorderRadius * 1.5, // 18.0
          border: Border.all(color: AppTheme.borderGrey, width: 1.5),
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
                gradient: LinearGradient(
                  colors: [
                    widget.subjectColor,
                    widget.subjectColor.withOpacity(0.7)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppTheme.defaultBorderRadius, // 12.0
              ),
              child: Center(
                child: Text(
                  '$chapterOrder',
                  style: AppTheme.headline2.copyWith(fontSize: 24),
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
                    style: AppTheme.labelText.copyWith(
                      fontSize: 17,
                      color: AppTheme.darkText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (chapterDescription.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      chapterDescription,
                      style: AppTheme.bodyText1.copyWith(
                        fontSize: 13,
                        color: AppTheme.bodyText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (chapterCode.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Iconsax.code,
                            size: 14, color: AppTheme.bodyText),
                        const SizedBox(width: 6),
                        Text(
                          chapterCode,
                          style: AppTheme.bodyText1.copyWith(
                            fontSize: 12,
                            color: AppTheme.bodyText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Iconsax.arrow_right_3,
                color: widget.subjectColor, size: 22),
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
            Icon(Iconsax.book,
                size: 64, color: widget.subjectColor.withOpacity(0.3)),
            const SizedBox(height: 20),
            Text(
              'No Chapters Found',
              style: AppTheme.headline1.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no chapters available for this subject',
              style: AppTheme.bodyText1,
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
          message: 'Loading chapters...',
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
            Icon(Iconsax.danger, size: 64, color: AppTheme.mackColor),
            const SizedBox(height: 20),
            Text(
              'Error Loading Chapters',
              style: AppTheme.headline1.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: AppTheme.bodyText1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadChapters,
              icon: const Icon(Iconsax.refresh, size: 18),
              label:
              Text('Retry', style: AppTheme.buttonText.copyWith(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.subjectColor,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.defaultBorderRadius),
              ),
            ),
          ],
        ),
      ),
    );
  }
}