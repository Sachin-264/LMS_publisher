import 'package:lms_publisher/StudentPannel/MySubject/my_subject_screen.dart';
import 'package:lms_publisher/StudentPannel/MySubject/teacher_material_screen.dart';
import 'package:lms_publisher/StudentPannel/Service/student_daily_activity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/StudentPannel/Service/analytics_subject.dart';
import 'package:lms_publisher/StudentPannel/Service/student_subject_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

const String _imageBaseUrl = "https://storage.googleapis.com/upload-images-34/images/LMS/";

class ChapterDetailsScreen extends StatefulWidget {
  final ChapterModel chapter;
  final Color subjectColor;
  final String subjectName;
  final int subjectId;
  final bool isParent;

  // ✅ Teacher data parameters
  final TeacherNavigationData selectedTeacher;
  final List<TeacherNavigationData> allTeachers;
  final List<TeacherNavigationData> otherTeachers;
  final String academicYear;

  const ChapterDetailsScreen({
    super.key,
    required this.chapter,
    required this.subjectColor,
    required this.subjectName,
    required this.subjectId,
    this.isParent = false,
    required this.selectedTeacher,
    required this.allTeachers,
    required this.otherTeachers,
    required this.academicYear,
  });

  @override
  State<ChapterDetailsScreen> createState() => _ChapterDetailsScreenState();
}

class _ChapterDetailsScreenState extends State<ChapterDetailsScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  MaterialsResponse? _materialsData;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String? _userCode;
  final Stopwatch _stopwatch = Stopwatch();
  bool _isFavorite = false;
  late AnimationController _favoriteController;
  late Animation<double> _favoriteScaleAnimation;
  Map<String, Map<int, bool>> _fileCompletionStatus = {};
  double _overallCompletionPercentage = 0.0;
  Map<String, Map<int, VideoWatchProgress>> _videoWatchProgress = {};
  DateTime? _sessionStartTime;
  Timer? _dailyActivitySyncTimer;
  int _lastSyncedMinutes = 0;

  final Map<String, MaterialTypeConfig> materialTypeConfigs = {
    'Video': MaterialTypeConfig(
      icon: Iconsax.video_play,
      title: 'Videos',
      color: const Color(0xFFEF4444),
      key: 'Video',
    ),
    'Worksheet': MaterialTypeConfig(
      icon: Iconsax.document_text,
      title: 'Worksheets',
      color: const Color(0xFF6366F1),
      key: 'Worksheet',
    ),
    'ExtraQuestions': MaterialTypeConfig(
      icon: Iconsax.clipboard_text,
      title: 'Extra Questions',
      color: const Color(0xFF10B981),
      key: 'ExtraQuestions',
    ),
    'SolvedQuestions': MaterialTypeConfig(
      icon: Iconsax.tick_circle,
      title: 'Solved Questions',
      color: const Color(0xFFF59E0B),
      key: 'SolvedQuestions',
    ),
    'RevisionNotes': MaterialTypeConfig(
      icon: Iconsax.note,
      title: 'Revision Notes',
      color: const Color(0xFFEC4899),
      key: 'RevisionNotes',
    ),
    'LessonPlans': MaterialTypeConfig(
      icon: Iconsax.book,
      title: 'Lesson Plans',
      color: const Color(0xFF14B8A6),
      key: 'LessonPlans',
    ),
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _favoriteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _favoriteScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_favoriteController);

    _userCode = Provider.of<UserProvider>(context, listen: false).userCode;
    _isFavorite = widget.chapter.isFavorite ?? false;

    // ✅ Only start stopwatch if NOT a parent
    if (!widget.isParent) {
      _stopwatch.start();
      _sessionStartTime = DateTime.now();
      print('📖 Chapter session started at: $_sessionStartTime');

      _dailyActivitySyncTimer = Timer.periodic(
        const Duration(minutes: 2),
            (timer) {
          print('⏰ Auto-sync triggered (2-minute interval)');
          _syncDailyActivity();
        },
      );
    }

    _loadMaterials();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _favoriteController.dispose();

    // ✅ Only sync if NOT parent
    if (!widget.isParent) {
      _dailyActivitySyncTimer?.cancel();
      print('⏹️ Auto-sync timer cancelled');
      print('\n🏁 Final sync before leaving chapter...');
      _syncDailyActivity();
      _stopwatch.stop();
      _syncChapterProgressOnExit();
    }

    super.dispose();
  }

  // ✅ NEW: Navigation to TeacherMaterialsScreen
  void _navigateToTeacherMaterials() {
    print('📚 Navigating to TeacherMaterialsScreen');
    print('   Chapter: ${widget.chapter.chapterName}');
    print('   Teacher: ${widget.selectedTeacher.teacherFullName}');
    print('   Academic Year: ${widget.academicYear}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherMaterialsScreen(
          chapter: widget.chapter,
          subjectName: widget.subjectName,
          subjectId: widget.subjectId,
          subjectColor: widget.subjectColor,
          studentId: _userCode ?? '',
          isParent: widget.isParent,
          selectedTeacher: widget.selectedTeacher,
          allTeachers: widget.allTeachers,
          otherTeachers: widget.otherTeachers,
          academicYear: widget.academicYear,
        ),
      ),
    );
  }

  // ✅ NEW: Teacher action button
  Widget _buildTeacherActionButton() {
    return GestureDetector(
      onTap: _navigateToTeacherMaterials,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.subjectColor.withOpacity(0.15),
              widget.subjectColor.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.subjectColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.subjectColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.arrow_right_3,
              size: 16,
              color: widget.subjectColor,
            ),
            const SizedBox(width: 6),
            Text(
              'View Teacher Materials',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: widget.subjectColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getTotalStudyMinutes() {
    if (_sessionStartTime == null) return 0;
    final minutes = DateTime.now().difference(_sessionStartTime!).inMinutes;
    print('⏱️ Total study time: $minutes minutes');
    return minutes;
  }

  int _getVideosWatchedCount() {
    int count = 0;
    _videoWatchProgress.forEach((type, videos) {
      videos.forEach((index, progress) {
        if (progress.watchedPercentage >= 90) {
          count++;
        }
      });
    });
    print('🎥 Videos watched (90%+): $count');
    return count;
  }

  int _getDocumentsReadCount() {
    int count = 0;
    _fileCompletionStatus.forEach((type, files) {
      if (type != 'Video') {
        files.forEach((index, completed) {
          if (completed) count++;
        });
      }
    });
    print('📝 Documents read: $count');
    return count;
  }

  int _getTotalMaterialsViewed() {
    int count = 0;
    _fileCompletionStatus.forEach((type, files) {
      count += files.values.where((c) => c).length;
    });
    print('📄 Total materials viewed: $count');
    return count;
  }

  Future<void> _syncDailyActivity() async {
    if (_userCode == null || widget.isParent) {
      print('⚠️ Cannot sync: userCode is null or isParent is true');
      return;
    }

    final studyMinutes = _getTotalStudyMinutes();
    if (studyMinutes <= _lastSyncedMinutes) {
      print('⏭️ Skipping sync: No new minutes ($studyMinutes <= $_lastSyncedMinutes)');
      return;
    }

    final minutesToSync = studyMinutes - _lastSyncedMinutes;
    print('\n🔄 Syncing daily activity...');
    print('   New minutes to sync: $minutesToSync');

    try {
      final success = await StudentDailyActivityService.recordDailyActivity(
        studentId: _userCode!,
        studyMinutes: minutesToSync,
        chaptersStudied: 1,
        materialsViewed: _getTotalMaterialsViewed(),
        videosWatched: _getVideosWatchedCount(),
        documentsRead: _getDocumentsReadCount(),
      );

      if (success) {
        _lastSyncedMinutes = studyMinutes;
        print('✅ Sync successful! Total synced: $_lastSyncedMinutes minutes');
      } else {
        print('❌ Sync failed - will retry on next interval');
      }
    } catch (e) {
      print('❌ Error syncing daily activity: $e');
    }
  }

  Future<void> _loadMaterials() async {
    print("🔄 Loading materials for Chapter ID: ${widget.chapter.chapterId}");
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_userCode == null) throw Exception('Student ID not found');

      final response = await StudentSubjectService.getChapterMaterials(
        _userCode!,
        widget.chapter.chapterId,
      );

      await _syncChapterProgressOnEntry();

      if (mounted) {
        setState(() {
          _materialsData = response;
          _isLoading = false;
        });
        initializeTrackingData();
        _fadeController.forward();
        print("✅ Materials loaded successfully.");
      }
    } catch (e) {
      if (mounted) {
        print("❌ Error loading materials: $e");
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
        CustomSnackbar.showError(context, _errorMessage!,
            title: 'Failed to Load Materials');
      }
    }
  }

  void initializeTrackingData() {
    if (_materialsData == null) return;
    print('🛠️ Initializing tracking data from API response...');
    _fileCompletionStatus.clear();
    _videoWatchProgress.clear();

    _materialsData!.materials.forEach((materialKey, materialValue) {
      if (materialValue is Map &&
          materialValue['available'] == true &&
          materialValue['files'] != null) {
        final files = (materialValue['files'] as List)
            .map((f) => MaterialFile.fromJson(f))
            .toList();

        _fileCompletionStatus[materialKey] = {};
        if (materialKey == 'Video') {
          _videoWatchProgress[materialKey] = {};
        }

        for (int i = 0; i < files.length; i++) {
          final file = files[i];
          final fileCompleted = file.completed ?? false;
          final fileProgress = file.progress ?? 0.0;
          final fileLastPosition = file.lastPosition ?? 0;

          _fileCompletionStatus[materialKey]![i] = fileCompleted;

          print(
            ' - Initializing file \'${file.name}\' with [index: $i]. '
                'Completed = $fileCompleted, Progress = ${fileProgress.toStringAsFixed(1)}%',
          );

          if (materialKey == 'Video') {
            _videoWatchProgress[materialKey]![i] = VideoWatchProgress(
              watchedPercentage: fileProgress,
              lastPositionSeconds: fileLastPosition,
              totalDurationSeconds: 0,
            );
          }
        }
      }
    });

    _calculateOverallCompletion();
  }

  Future<void> _toggleFavorite() async {
    if (_userCode == null) return;
    final previousState = _isFavorite;

    setState(() {
      _isFavorite = !_isFavorite;
    });
    _favoriteController.forward(from: 0);

    try {
      await AnalyticsService.manageFavorite(
        userCode: _userCode!,
        chapterId: widget.chapter.chapterId,
        action: _isFavorite ? 'ADD' : 'REMOVE',
      );
      if (mounted) {
        CustomSnackbar.showSuccess(
          context,
          _isFavorite ? '⭐ Added to favorites' : 'Removed from favorites',
          title: _isFavorite ? 'Favorited!' : 'Unfavorited',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFavorite = previousState;
        });
        CustomSnackbar.showError(
          context,
          'Failed to update favorite status',
          title: 'Error',
        );
      }
    }
  }

  Future<void> _syncMaterialProgress({
    required MaterialFile file,
    required String materialType,
    required int fileIndex,
    VideoWatchProgress? videoProgress,
    PdfWatchProgress? pdfProgress,
    bool isCompleted = false,
  }) async {
    if (_userCode == null || widget.isParent) return;

    print("  ➡️ Preparing to sync progress for '${file.name}' [index: $fileIndex]");

    try {
      await AnalyticsService.updateMaterialProgress(
        userCode: _userCode!,
        chapterId: widget.chapter.chapterId,
        materialType: materialType,
        fileSno: file.sno,
        isCompleted: isCompleted,
        watchProgressPercentage: videoProgress?.watchedPercentage,
        lastWatchedPositionSeconds: videoProgress?.lastPositionSeconds,
        totalWatchTimeSeconds: videoProgress?.totalDurationSeconds,
      );
      await _recalculateAndSyncChapterProgress();
    } catch (e) {
      print('⚠️ Failed to sync material progress for ${file.name}: $e');
      if (mounted) {
        CustomSnackbar.showError(
          context,
          "Could not save progress for ${file.name}. Check connection.",
          title: "Sync Failed",
        );
      }
    }
  }

  void _markFileAsCompleted(
      MaterialFile file,
      String materialType,
      int fileIndex,
      ) {
    if (mounted &&
        (_fileCompletionStatus[materialType]?[fileIndex] ?? false) == false) {
      print("✔️ Marking '${file.name}' [index: $fileIndex] as completed and syncing.");
      setState(() {
        _fileCompletionStatus[materialType]![fileIndex] = true;
        _calculateOverallCompletion();
      });
      _syncMaterialProgress(
        file: file,
        materialType: materialType,
        isCompleted: true,
        fileIndex: fileIndex,
      );
    }
  }

  void _updateVideoProgress(
      MaterialFile file,
      String materialType,
      int fileIndex,
      VideoWatchProgress progress,
      ) {
    if (mounted) {
      print("🔄 Received video progress update for '${file.name}' [index: $fileIndex]. "
          "Progress: ${progress.watchedPercentage.toStringAsFixed(1)}%");

      bool wasCompleted =
          _fileCompletionStatus[materialType]?[fileIndex] ?? false;
      bool isNowCompleted = progress.watchedPercentage >= 90;

      setState(() {
        _videoWatchProgress[materialType]![fileIndex] = progress;
        if (isNowCompleted && !wasCompleted) {
          print("🎉 Video '${file.name}' reached completion threshold.");
          _fileCompletionStatus[materialType]![fileIndex] = true;
          _calculateOverallCompletion();
        }
      });

      _syncMaterialProgress(
        file: file,
        materialType: materialType,
        videoProgress: progress,
        isCompleted: isNowCompleted,
        fileIndex: fileIndex,
      );
    }
  }

  void _updatePdfProgress(
      MaterialFile file,
      String materialType,
      int fileIndex,
      PdfWatchProgress progress,
      ) {
    if (!mounted) return;
    print("📄 PDF '${file.name}' [index: $fileIndex] progress: Page ${progress.lastPageViewed}/${progress.totalPages}. Syncing.");

    _syncMaterialProgress(
      file: file,
      materialType: materialType,
      pdfProgress: progress,
      fileIndex: fileIndex,
    );
  }

  Future<void> _syncChapterProgressOnEntry() async {
    if (_userCode == null ||
        widget.chapter.completionStatus != 'Not Started' ||
        widget.isParent) return;

    try {
      await AnalyticsService.updateChapterProgress(
        userCode: _userCode!,
        subjectId: widget.subjectId,
        chapterId: widget.chapter.chapterId,
        completionStatus: 'In Progress',
        progressPercentage: widget.chapter.progressPercentage,
      );
    } catch (e) {
      print('⚠️ Failed to update chapter status on entry: $e');
    }
  }

  Future<void> _syncChapterProgressOnExit() async {
    if (_userCode == null || widget.isParent) return;

    final int elapsedMinutes = _stopwatch.elapsed.inMinutes;
    if (elapsedMinutes < 1) return;

    print("🚪 Exiting chapter. Syncing time spent: $elapsedMinutes minutes and progress: ${_overallCompletionPercentage.toStringAsFixed(1)}%");

    try {
      await AnalyticsService.updateChapterProgress(
        userCode: _userCode!,
        subjectId: widget.subjectId,
        chapterId: widget.chapter.chapterId,
        completionStatus: _overallCompletionPercentage >= 100
            ? 'Completed'
            : 'In Progress',
        progressPercentage: _overallCompletionPercentage,
        timeSpentMinutes: elapsedMinutes,
      );
    } catch (e) {
      print('⚠️ Failed to sync chapter progress on exit: $e');
    }
  }

  Future<void> _recalculateAndSyncChapterProgress() async {
    if (_userCode == null || widget.isParent) return;

    _calculateOverallCompletion();
    final newStatus = _overallCompletionPercentage >= 100
        ? 'Completed'
        : 'In Progress';

    try {
      await AnalyticsService.updateChapterProgress(
        userCode: _userCode!,
        subjectId: widget.subjectId,
        chapterId: widget.chapter.chapterId,
        completionStatus: newStatus,
        progressPercentage: _overallCompletionPercentage,
        timeSpentMinutes: 0,
      );
    } catch (e) {
      print('⚠️ Failed to sync overall chapter progress after material update: $e');
    }
  }

  void _calculateOverallCompletion() {
    if (_materialsData == null) return;

    int totalFiles = 0;
    int completedFiles = 0;

    _fileCompletionStatus.forEach((_, fileMap) {
      totalFiles += fileMap.length;
      completedFiles += fileMap.values.where((completed) => completed).length;
    });

    setState(() {
      _overallCompletionPercentage =
      totalFiles > 0 ? (completedFiles / totalFiles) * 100 : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;
    // Add a new breakpoint for small web screens
    final isSmallWeb = !isMobile && screenWidth < 1200;

    return MainLayout(
      activeScreen: AppScreen.mySubjects,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: kIsWeb ? 1400.0 : double.infinity,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ --- MODIFIED: Unified Header ---
                _buildHeader(isMobile),
                SizedBox(height: isMobile ? 20 : 32),
                if (_isLoading)
                  _buildLoadingState()
                else if (_errorMessage != null)
                  _buildErrorState()
                // ✅ --- MODIFIED: Layout Switching ---
                else if (isMobile)
                    _buildMobileLayout()
                  else
                    _buildWebLayout(isSmallWeb),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ --- NEW: Mobile Layout ---
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChapterInfoCard( true),
        const SizedBox(height: 20),
        _buildCompletionTrackerCard(true),
        const SizedBox(height: 20),
        _buildMaterialsSection( true),
      ],
    );
  }

  // ✅ --- NEW: Web/Desktop Layout ---
  Widget _buildWebLayout(bool isSmallWeb) {
    // Adjust flex factors based on screen size for better proportions
    final int leftFlex = isSmallWeb ? 3 : 2;
    final int rightFlex = 5;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Left Column ---
        Expanded(
          flex: leftFlex,
          child: Column(
            children: [
              _buildChapterInfoCard( false),
              const SizedBox(height: 24),
              _buildCompletionTrackerCard( false),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // --- Right Column ---
        Expanded(
          flex: rightFlex,
          child: _buildMaterialsSection( false),
        ),
      ],
    );
  }

  // ✅ --- MODIFIED: This is the new unified header block ---
  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderContentRow(isMobile), // This is the old _buildHeader
          const SizedBox(height: 20),
          _buildTeacherInfoBanner(),
        ],
      ),
    );
  }

  // ✅ --- RENAMED: This was the original _buildHeader method ---
  Widget _buildHeaderContentRow(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.arrow_left,
                    color: AppTheme.darkText,
                    size: isMobile ? 18 : 20,
                  ),
                ),
              ),
            ),
            SizedBox(width: isMobile ? 12 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.subjectName,
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 12 : 14,
                      color: widget.subjectColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.chapter.displayChapterName,
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 20 : 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkText,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (!widget.isParent)
              AnimatedBuilder(
                animation: _favoriteScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _favoriteScaleAnimation.value,
                    child: Material(
                      color: _isFavorite
                          ? widget.subjectColor.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _toggleFavorite,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isFavorite
                                  ? widget.subjectColor.withOpacity(0.4)
                                  : Colors.grey.shade300,
                              width: _isFavorite ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isFavorite ? Iconsax.heart : Iconsax.heart,
                            color: _isFavorite
                                ? widget.subjectColor
                                : AppTheme.bodyText.withOpacity(0.5),
                            size: isMobile ? 20 : 22,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeacherInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.subjectColor.withOpacity(0.1),
            widget.subjectColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.subjectColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Teacher photo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.subjectColor.withOpacity(0.3),
                width: 2,
              ),
              image: widget.selectedTeacher.teacherPhoto != null
                  ? DecorationImage(
                image: NetworkImage(
                    '$_imageBaseUrl${widget.selectedTeacher.teacherPhoto}'),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: widget.selectedTeacher.teacherPhoto == null
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
                  size: 24,
                ),
              ),
            )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teacher',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: widget.subjectColor.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.selectedTeacher.teacherFullName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'Code: ${widget.selectedTeacher.teacherCode}',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        widget.academicYear,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.purple.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildTeacherActionButton(),
        ],
      ),
    );
  }

  Widget _buildChapterInfoCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 10 : 12),
                decoration: BoxDecoration(
                  color: widget.subjectColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Iconsax.book_1,
                  color: widget.subjectColor,
                  size: isMobile ? 20 : 22,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chapter ${widget.chapter.chapterOrder}',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11 : 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.chapter.displayChapterName,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 16 : 18,
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
          ),
          if (widget.chapter.chapterDescription != null) ...[
            SizedBox(height: isMobile ? 12 : 14),
            Text(
              widget.chapter.chapterDescription!,
              style: GoogleFonts.inter(
                fontSize: isMobile ? 13 : 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
          SizedBox(height: isMobile ? 14 : 16),
          Wrap(
            spacing: isMobile ? 8 : 10,
            runSpacing: isMobile ? 8 : 10,
            children: [
              _buildInfoChip(
                Iconsax.activity,
                '${widget.chapter.progressPercentage.toStringAsFixed(0)}%',
                widget.subjectColor,
                isMobile,
              ),
              _buildInfoChip(
                Iconsax.clock,
                '${widget.chapter.timeSpentMinutes} min',
                widget.subjectColor,
                isMobile,
              ),
              _buildStatusChip(widget.chapter.completionStatus, isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
      IconData icon,
      String label,
      Color color,
      bool isMobile,
      ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 14 : 15, color: color),
          SizedBox(width: isMobile ? 6 : 7),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isMobile) {
    Color color;
    IconData icon;
    switch (status) {
      case 'Completed':
        color = const Color(0xFF10B981);
        icon = Iconsax.tick_circle;
        break;
      case 'In Progress':
        color = const Color(0xFFF59E0B);
        icon = Iconsax.clock;
        break;
      default:
        color = Colors.grey.shade600;
        icon = Iconsax.document_text;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 14 : 15, color: color),
          SizedBox(width: isMobile ? 6 : 7),
          Text(
            status,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionTrackerCard(bool isMobile) {
    if (_materialsData == null) return const SizedBox.shrink();

    int totalFiles = 0;
    int completedFiles = 0;

    _fileCompletionStatus.forEach((_, fileMap) {
      totalFiles += fileMap.length;
      completedFiles += fileMap.values.where((completed) => completed).length;
    });

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.chart_success,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learning Progress',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$completedFiles of $totalFiles files completed',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_overallCompletionPercentage.toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _overallCompletionPercentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 16),
          ..._fileCompletionStatus.entries.map((entry) {
            final config = materialTypeConfigs[entry.key];
            if (config == null || entry.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return _buildProgressBreakdownRow(
              config: config,
              completed: entry.value.values.where((c) => c).length,
              total: entry.value.length,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildProgressBreakdownRow({
    required MaterialTypeConfig config,
    required int completed,
    required int total,
  }) {
    final double percentage = total > 0 ? (completed / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        children: [
          Icon(config.icon, color: config.color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              config.title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 6,
                backgroundColor: config.color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(config.color),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              '$completed/$total',
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDocument(MaterialFile file, MaterialTypeConfig config, int index) {
    print('📄 Opening document: ${file.name} [index: $index]');
    _markFileAsCompleted(file, config.key, index);
    if (file.type == 'pdf') {
      if (kIsWeb) {
        launchUrl(Uri.parse(file.fullUrl), mode: LaunchMode.externalApplication);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(
              pdfUrl: file.fullUrl,
              title: file.name,
              subjectColor: config.color,
              onPageChange: (progress) {
                _updatePdfProgress(file, config.key, index, progress);
              },
            ),
          ),
        );
      }
    } else {
      launchUrl(Uri.parse(file.fullUrl), mode: LaunchMode.externalApplication);
    }
  }

  void _openVideo(
      MaterialFile file,
      String materialType,
      int index,
      VideoWatchProgress? currentProgress,
      ) {
    print("📹 Opening video player for '${file.name}' [index: $index]");
    final videoId = _extractVideoId(file.path);
    if (videoId == null || videoId.isEmpty) {
      CustomSnackbar.showError(context, 'Invalid YouTube URL');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YoutubePlayerScreen(
          videoId: videoId,
          title: file.name,
          subjectColor: widget.subjectColor,
          initialProgress: currentProgress,
          onProgressUpdate: (progress) {
            _updateVideoProgress(file, materialType, index, progress);
          },
        ),
      ),
    );
  }

  Widget _buildMaterialsSection(bool isMobile) {
    if (_materialsData == null) return const SizedBox.shrink();

    final materials = _materialsData!.materials;
    List<Widget> materialSections = [];

    materials.forEach((key, value) {
      if (value is Map &&
          value['available'] == true &&
          value['files'] != null) {
        final config = materialTypeConfigs[key];
        if (config != null) {
          final files = (value['files'] as List)
              .map((f) => MaterialFile.fromJson(f))
              .toList();
          if (files.isNotEmpty) {
            materialSections.add(
              _buildMaterialTypeSection(config, files, isMobile),
            );
            materialSections.add(SizedBox(height: isMobile ? 24 : 32));
          }
        }
      }
    });

    return FadeTransition(
      opacity: _fadeAnimation,
      // Wrap in a container for web layout
      child: Container(
        padding: isMobile ? EdgeInsets.zero : const EdgeInsets.all(24),
        decoration: isMobile ? null : BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.only(bottom: isMobile ? 16 : 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.subjectColor.withOpacity(0.15),
                          widget.subjectColor.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.folder_2,
                      color: widget.subjectColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Study Materials',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkText,
                        ),
                      ),
                      Text(
                        '${materialSections.length ~/ 2} material types available',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 12 : 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 20 : 24),
            ...materialSections,
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialTypeSection(
      MaterialTypeConfig config,
      List<MaterialFile> files,
      bool isMobile,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: config.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: config.color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(config.icon, size: 16, color: config.color),
                  const SizedBox(width: 8),
                  Text(
                    config.title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: config.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: config.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${files.length}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12 : 16),
        if (config.key == 'Video')
          _buildVideoGrid(files, config, isMobile)
        else
          _buildDocumentList(files, config, isMobile),
      ],
    );
  }

  Widget _buildVideoGrid(
      List<MaterialFile> files,
      MaterialTypeConfig config,
      bool isMobile,
      ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 2,
        childAspectRatio: isMobile ? 1.4 : 1.3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final isCompleted = _fileCompletionStatus[config.key]?[index] ?? false;
        final watchProgress = _videoWatchProgress[config.key]?[index];

        print("🎨 Building Video Card for '${file.name}' [index: $index]");

        return _buildVideoCard(
          file,
          config,
          index,
          isCompleted,
          watchProgress,
          isMobile,
        );
      },
    );
  }

  Widget _buildVideoCard(
      MaterialFile file,
      MaterialTypeConfig config,
      int index,
      bool isCompleted,
      VideoWatchProgress? watchProgress,
      bool isMobile,
      ) {
    final thumbnailUrl = StudentSubjectService.getYouTubeThumbnail(file.path);
    final hasProgress =
        watchProgress != null && watchProgress.watchedPercentage > 0;
    final progressText = hasProgress
        ? '${watchProgress!.watchedPercentage.toStringAsFixed(0)}% watched'
        : 'Not started';
    final resumeText = hasProgress
        ? 'Resume from ${_formatDuration(watchProgress!.lastPositionSeconds)}'
        : 'Start watching';

    return GestureDetector(
      onTap: () => _openVideo(file, config.key, index, watchProgress),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: config.color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: config.color.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  config.color.withOpacity(0.2),
                                  config.color.withOpacity(0.1),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Iconsax.video,
                                size: isMobile ? 42 : 54,
                                color: config.color.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.2),
                                Colors.transparent,
                                Colors.black.withOpacity(0.4),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${file.sno}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [config.color, config.color.withOpacity(0.8)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: config.color.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Iconsax.play,
                        size: isMobile ? 28 : 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (isCompleted)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Iconsax.tick_circle,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Watched',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (hasProgress && (watchProgress?.watchedPercentage ?? 0) < 100)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      color: Colors.black.withOpacity(0.3),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: watchProgress!.watchedPercentage / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                config.color,
                                config.color.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 14 : 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Iconsax.video,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hasProgress ? resumeText : progressText,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: hasProgress
                                  ? config.color
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentList(
      List<MaterialFile> files,
      MaterialTypeConfig config,
      bool isMobile,
      ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: isMobile ? 10 : 12),
      itemBuilder: (context, index) {
        final file = files[index];
        final isCompleted = _fileCompletionStatus[config.key]?[index] ?? false;

        return _buildDocumentCard(
          file,
          config,
          index,
          isCompleted,
          isMobile,
        );
      },
    );
  }

  Widget _buildDocumentCard(
      MaterialFile file,
      MaterialTypeConfig config,
      int index,
      bool isCompleted,
      bool isMobile,
      ) {
    return GestureDetector(
      onTap: () => _openDocument(file, config, index),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, config.color.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: config.color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: config.color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [config.color, config.color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: config.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(config.icon, color: Colors.white, size: 24),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${file.sno}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 14 : 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: config.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          file.type.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: config.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isCompleted) ...[
                        Icon(
                          Iconsax.tick_circle,
                          size: 12,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: config.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Iconsax.arrow_right_3,
                color: config.color,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _extractVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtube.com')) return uri.queryParameters['v'];
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          BeautifulLoader(
            type: LoaderType.pulse,
            size: 60,
            color: widget.subjectColor,
          ),
          const SizedBox(height: 18),
          Text(
            'Loading materials...',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.bodyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Icon(
            Iconsax.danger,
            size: 64,
            color: Colors.red.withOpacity(0.7),
          ),
          const SizedBox(height: 18),
          Text(
            'Failed to load materials',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? 'Unknown error',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.bodyText.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadMaterials,
            icon: const Icon(Iconsax.refresh, size: 17),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.subjectColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Supporting Classes
class MaterialTypeConfig {
  final IconData icon;
  final String title;
  final Color color;
  final String key;

  MaterialTypeConfig({
    required this.icon,
    required this.title,
    required this.color,
    required this.key,
  });
}

class VideoWatchProgress {
  final double watchedPercentage;
  final int lastPositionSeconds;
  final int totalDurationSeconds;

  VideoWatchProgress({
    required this.watchedPercentage,
    required this.lastPositionSeconds,
    required this.totalDurationSeconds,
  });
}

class PdfWatchProgress {
  final int lastPageViewed;
  final int totalPages;

  PdfWatchProgress({
    required this.lastPageViewed,
    required this.totalPages,
  });
}

class YoutubePlayerScreen extends StatefulWidget {
  final String videoId; final String title; final Color subjectColor; final VideoWatchProgress? initialProgress; final Function(VideoWatchProgress)? onProgressUpdate;
  const YoutubePlayerScreen({super.key, required this.videoId, required this.title, required this.subjectColor, this.initialProgress, this.onProgressUpdate});
  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late YoutubePlayerController _controller;
  Timer? _progressTimer;
  int _currentPositionSeconds = 0;
  int _totalDurationSeconds = 0;
  double _watchedPercentage = 0.0;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();

    // ✅ Load saved progress
    _currentPositionSeconds = widget.initialProgress?.lastPositionSeconds ?? 0;
    _watchedPercentage = widget.initialProgress?.watchedPercentage ?? 0.0;

    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false, // ✅ Changed to false to allow seeking first
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: false,
        enableCaption: true,
        strictRelatedVideos: true,
      ),
    );

    _controller.listen((value) {
      if (!_isPlayerReady && value.metaData.videoId.isNotEmpty) {
        setState(() {
          _isPlayerReady = true;
        });

        // ✅ Auto-resume from last position if available
        if (_currentPositionSeconds > 0) {
          print('📍 Resuming video from ${_currentPositionSeconds}s');
          _controller.seekTo(seconds: _currentPositionSeconds.toDouble());
          _controller.playVideo(); // Start playing after seeking
        } else {
          _controller.playVideo(); // Start from beginning
        }
      }
    });

    _startProgressTracking();
  }


  void _startProgressTracking() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || _controller.value.playerState != PlayerState.playing) return;
      try {
        await _saveProgress();
      } catch (e) {
        if (mounted) print('Error tracking progress: $e');
      }
    });
  }

  Future<void> _saveProgress() async {
    if (!mounted) return;
    final double totalDuration = await _controller.duration;
    final double position = await _controller.currentTime;
    if (totalDuration > 0) {
      final newWatchedPercentage = (position / totalDuration) * 100;
      setState(() {
        _currentPositionSeconds = position.toInt();
        _totalDurationSeconds = totalDuration.toInt();
        _watchedPercentage = newWatchedPercentage > 100 ? 100 : newWatchedPercentage;
      });
      if (widget.onProgressUpdate != null) {
        print("💾 Saving video progress: ${newWatchedPercentage.toStringAsFixed(1)}% at ${_currentPositionSeconds}s");
        widget.onProgressUpdate!(VideoWatchProgress(
          watchedPercentage: _watchedPercentage,
          lastPositionSeconds: _currentPositionSeconds,
          totalDurationSeconds: _totalDurationSeconds,
        ));
      }
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _saveProgress();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async { await _saveProgress(); return true; },
        child: Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
                backgroundColor: Colors.black,
                leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () { _saveProgress().then((_) => Navigator.pop(context)); }),
                title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  if (_isPlayerReady && _totalDurationSeconds > 0)
                    Text('${_formatDuration(_currentPositionSeconds)} / ${_formatDuration(_totalDurationSeconds)}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade400))
                ])
            ),
            body: Column(children: [
              Center(child: Container(width: kIsWeb && MediaQuery.of(context).size.width > 800 ? 800 : double.infinity, height: kIsWeb && MediaQuery.of(context).size.width > 800 ? 450 : MediaQuery.of(context).size.width * 9 / 16, color: Colors.black, child: YoutubePlayer(controller: _controller, aspectRatio: 16 / 9))),
              if (_isPlayerReady && _totalDurationSeconds > 0)
                Container(width: kIsWeb && MediaQuery.of(context).size.width > 800 ? 800 : double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), color: Colors.grey.shade900, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Watch Progress', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    Text('${_watchedPercentage.toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: widget.subjectColor))
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: _watchedPercentage / 100, backgroundColor: Colors.grey.shade800, valueColor: AlwaysStoppedAnimation(widget.subjectColor), minHeight: 6))
                ])),
              Expanded(child: Container(width: kIsWeb && MediaQuery.of(context).size.width > 800 ? 800 : double.infinity, color: Colors.grey.shade900, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Iconsax.info_circle, color: Colors.grey.shade400, size: 18), const SizedBox(width: 8), Text('Your progress is automatically saved', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                if (_watchedPercentage >= 90)
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]), borderRadius: BorderRadius.circular(10)), child: Row(children: [
                    const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Great job! You\'ve completed this video', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)))
                  ]))
              ])))
            ])
        )
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl; final String title; final Color subjectColor; final Function(PdfWatchProgress)? onPageChange;
  const PdfViewerScreen({super.key, required this.pdfUrl, required this.title, required this.subjectColor, this.onPageChange});
  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  bool _isLoading = true;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Iconsax.search_zoom_in), tooltip: 'Zoom In', onPressed: () { _pdfController.zoomLevel = _pdfController.zoomLevel + 0.25; }),
          IconButton(icon: const Icon(Iconsax.search_zoom_out), tooltip: 'Zoom Out', onPressed: () { if (_pdfController.zoomLevel > 1) { _pdfController.zoomLevel = _pdfController.zoomLevel - 0.25; } })
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.pdfUrl,
            controller: _pdfController,
            onDocumentLoaded: (details) { if (mounted) setState(() { _isLoading = false; }); },
            onDocumentLoadFailed: (details) { if (mounted) { setState(() { _isLoading =false; }); CustomSnackbar.showError(context, 'Failed to load PDF'); } },
            onPageChanged: (details) {

              if (widget.onPageChange != null) {

                if (_debounce?.isActive ?? false) _debounce!.cancel();

                _debounce = Timer(const Duration(milliseconds: 1500), () {

                  widget.onPageChange!(

                    PdfWatchProgress(

                      lastPageViewed: details.newPageNumber,

                      totalPages: _pdfController.pageCount,

                    ),

                  );

                });

              }

            },
          ),
          if (_isLoading)
            Container(color: Colors.white, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(widget.subjectColor)),
              const SizedBox(height: 20),
              Text('Loading PDF...', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            ]))),
        ],
      ),
    );
  }
}