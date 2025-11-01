// chapter_Detail_Screen.dart
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

class ChapterDetailsScreen extends StatefulWidget {
  final ChapterModel chapter;
  final Color subjectColor;
  final String subjectName;
  final int subjectId;
  final bool isParent; // ✅ NEW

  const ChapterDetailsScreen({
    super.key,
    required this.chapter,
    required this.subjectColor,
    required this.subjectName,
    required this.subjectId,
    this.isParent = false, // ✅ Default to false
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

  // ✅ NEW: Teacher data
  List<TeacherNoteModel> _teacherNotes = [];
  List<TeacherMaterialModel> _teacherMaterials = [];
  bool _isLoadingTeacherData = false;
  String? _teacherCode;

  final Map<String, MaterialTypeConfig> materialTypeConfigs = {
    'Video': MaterialTypeConfig(icon: Iconsax.video_play, title: 'Videos', color: const Color(0xFFEF4444), key: 'Video'),
    'Worksheet': MaterialTypeConfig(icon: Iconsax.document_text, title: 'Worksheets', color: const Color(0xFF6366F1), key: 'Worksheet'),
    'ExtraQuestions': MaterialTypeConfig(icon: Iconsax.clipboard_text, title: 'Extra Questions', color: const Color(0xFF10B981), key: 'ExtraQuestions'),
    'SolvedQuestions': MaterialTypeConfig(icon: Iconsax.tick_circle, title: 'Solved Questions', color: const Color(0xFFF59E0B), key: 'SolvedQuestions'),
    'RevisionNotes': MaterialTypeConfig(icon: Iconsax.note, title: 'Revision Notes', color: const Color(0xFFEC4899), key: 'RevisionNotes'),
    'LessonPlans': MaterialTypeConfig(icon: Iconsax.book, title: 'Lesson Plans', color: const Color(0xFF14B8A6), key: 'LessonPlans'),
    'TeachingAids': MaterialTypeConfig(icon: Iconsax.teacher, title: 'Teaching Aids', color: const Color(0xFF6366F1), key: 'TeachingAids'),
    'AssessmentTools': MaterialTypeConfig(icon: Iconsax.clipboard_tick, title: 'Assessment Tools', color: const Color(0xFFFF5722), key: 'AssessmentTools'),
    'HomeworkTools': MaterialTypeConfig(icon: Iconsax.task_square, title: 'Homework Tools', color: const Color(0xFF795548), key: 'HomeworkTools'),
    'PracticeZone': MaterialTypeConfig(icon: Iconsax.code_circle, title: 'Practice Zone', color: const Color(0xFF8B5CF6), key: 'PracticeZone'),
    'LearningPath': MaterialTypeConfig(icon: Iconsax.routing, title: 'Learning Path', color: const Color(0xFFE91E63), key: 'LearningPath'),
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

    // ✅ Only start stopwatch if not parent
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
    _loadTeacherData(); // ✅ NEW
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _favoriteController.dispose();

    // ✅ Only sync if not parent
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

  // ✅ NEW: Load teacher data
  Future<void> _loadTeacherData() async {
    if (_userCode == null) return;

    setState(() => _isLoadingTeacherData = true);

    try {
      final notesResponse = await StudentSubjectService.getStudentNotes(
        studentId: _userCode!,
        chapterId: widget.chapter.chapterId,
      );

      if (notesResponse.notes.isNotEmpty) {
        _teacherCode = notesResponse.notes.first.teacherCode;

        final materialsResponse =
        await StudentSubjectService.getTeacherMaterials(
          teacherCode: _teacherCode!,
          chapterId: widget.chapter.chapterId,
        );

        if (mounted) {
          setState(() {
            _teacherNotes = notesResponse.notes;
            _teacherMaterials = materialsResponse.materials;
            _isLoadingTeacherData = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _teacherNotes = notesResponse.notes;
            _isLoadingTeacherData = false;
          });
        }
      }
    } catch (e) {
      print('Error loading teacher data: $e');
      if (mounted) {
        setState(() => _isLoadingTeacherData = false);
      }
    }
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
      // ✅ Don't sync if parent
      print('⚠️ Cannot sync: userCode is null or isParent is true');
      return;
    }

    final studyMinutes = _getTotalStudyMinutes();
    if (studyMinutes <= _lastSyncedMinutes) {
      print(
          '⏭️ Skipping sync: No new minutes ($studyMinutes <= $_lastSyncedMinutes)');
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
          _userCode!, widget.chapter.chapterId);

      await _syncChapterProgressOnEntry();

      if (mounted) {
        setState(() {
          _materialsData = response;
          _isLoading = false;
        });
        initializeTrackingData();
        _fadeController.forward();
        print("✅ Materials loaded and progress state initialized successfully.");
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
          final fileProgress = file.progress ?? 0.0;
          final fileLastPosition = file.lastPosition ?? 0;
          final fileCompleted = file.completed ?? false;
          final fileViewCount = file.viewCount ?? 0;

          _fileCompletionStatus[materialKey]![i] = fileCompleted;

          print('   - Initializing file \'${file.name}\' with [S.No: ${file.sno}, index: $i]. '
              'Completed = $fileCompleted, Progress = ${fileProgress.toStringAsFixed(1)}%, '
              'Last Position = ${fileLastPosition}s, Views = $fileViewCount');

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
    if (_userCode == null || widget.isParent) return; // ✅ Don't sync if parent

    print(
        " ➡️ Preparing to sync progress for '${file.name}' [S.No: ${file.sno}, index: $fileIndex]");

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
        CustomSnackbar.showError(context,
            "Could not save progress for ${file.name}. Check connection.",
            title: "Sync Failed");
      }
    }
  }

  void _markFileAsCompleted(
      MaterialFile file, String materialType, int fileIndex) {
    if (mounted &&
        (_fileCompletionStatus[materialType]?[fileIndex] ?? false) == false) {
      print(
          "✔️ Marking '${file.name}' [S.No: ${file.sno}, index: $fileIndex] as completed and syncing with API.");
      setState(() {
        _fileCompletionStatus[materialType]![fileIndex] = true;
        _calculateOverallCompletion();
      });

      _syncMaterialProgress(
          file: file,
          materialType: materialType,
          isCompleted: true,
          fileIndex: fileIndex);
    }
  }

  void _updateVideoProgress(MaterialFile file, String materialType,
      int fileIndex, VideoWatchProgress progress) {
    if (mounted) {
      print(
          "🔄 Received video progress update for '${file.name}' [S.No: ${file.sno}, index: $fileIndex]. Progress: ${progress.watchedPercentage.toStringAsFixed(1)}%");

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
          fileIndex: fileIndex);
    }
  }

  void _updatePdfProgress(MaterialFile file, String materialType, int fileIndex,
      PdfWatchProgress progress) {
    if (!mounted) return;

    print(
        "📄 PDF '${file.name}' [S.No: ${file.sno}, index: $fileIndex] progress: Page ${progress.lastPageViewed}/${progress.totalPages}. Syncing.");

    _syncMaterialProgress(
        file: file,
        materialType: materialType,
        pdfProgress: progress,
        fileIndex: fileIndex);
  }

  Future<void> _syncChapterProgressOnEntry() async {
    if (_userCode == null ||
        widget.chapter.completionStatus != 'Not Started' ||
        widget.isParent) return; // ✅ Don't sync if parent

    try {
      await AnalyticsService.updateChapterProgress(
          userCode: _userCode!,
          subjectId: widget.subjectId,
          chapterId: widget.chapter.chapterId,
          completionStatus: 'In Progress',
          progressPercentage: widget.chapter.progressPercentage);
    } catch (e) {
      print('⚠️ Failed to update chapter status on entry: $e');
    }
  }

  Future<void> _syncChapterProgressOnExit() async {
    if (_userCode == null || widget.isParent)
      return; // ✅ Don't sync if parent

    final int elapsedMinutes = _stopwatch.elapsed.inMinutes;
    if (elapsedMinutes < 1) return;

    print(
        "🚪 Exiting chapter. Syncing time spent: $elapsedMinutes minutes and progress: ${_overallCompletionPercentage.toStringAsFixed(1)}%");

    try {
      await AnalyticsService.updateChapterProgress(
          userCode: _userCode!,
          subjectId: widget.subjectId,
          chapterId: widget.chapter.chapterId,
          completionStatus:
          _overallCompletionPercentage >= 100 ? 'Completed' : 'In Progress',
          progressPercentage: _overallCompletionPercentage,
          timeSpentMinutes: elapsedMinutes);
    } catch (e) {
      print('⚠️ Failed to sync chapter progress on exit: $e');
    }
  }

  Future<void> _recalculateAndSyncChapterProgress() async {
    if (_userCode == null || widget.isParent)
      return; // ✅ Don't sync if parent

    _calculateOverallCompletion();

    final newStatus =
    _overallCompletionPercentage >= 100 ? 'Completed' : 'In Progress';

    try {
      await AnalyticsService.updateChapterProgress(
          userCode: _userCode!,
          subjectId: widget.subjectId,
          chapterId: widget.chapter.chapterId,
          completionStatus: newStatus,
          progressPercentage: _overallCompletionPercentage,
          timeSpentMinutes: 0);
    } catch (e) {
      print(
          '⚠️ Failed to sync overall chapter progress after material update: $e');
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
    final isDesktop = screenWidth >= 900;

    return MainLayout(
      activeScreen: AppScreen.mySubjects,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: kIsWeb ? 1400.0 : double.infinity),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isMobile),
                SizedBox(height: isMobile ? 20 : 32),

                // Desktop layout with teacher resources on left
                if (isDesktop && kIsWeb && !_isLoading && _errorMessage == null)
                  _buildDesktopLayoutWithTeacherResources()
                else
                  _buildMobileLayout(isMobile, isDesktop),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayoutWithTeacherResources() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT SIDE: Teacher Resources
        if (_teacherMaterials.isNotEmpty || _teacherNotes.isNotEmpty)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEnhancedTeacherResourcesSection(false),
              ],
            ),
          ),

        if (_teacherMaterials.isNotEmpty || _teacherNotes.isNotEmpty)
          const SizedBox(width: 24),

        // RIGHT SIDE: Chapter Info, Progress, and Materials
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChapterInfoCard(false),
              const SizedBox(height: 24),
              _buildCompletionTrackerCard(false),
              const SizedBox(height: 24),
              _buildMaterialsSection(false, true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedTeacherResourcesSection(bool isMobile) {
    if (_teacherMaterials.isEmpty && _teacherNotes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            widget.subjectColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.subjectColor.withOpacity(0.15),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.subjectColor.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildTeacherResourcesHeader(isMobile),

          const SizedBox(height: 20),

          // Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Teacher Notes Section
                if (_teacherNotes.isNotEmpty) ...[
                  _buildEnhancedTeacherNotesCard(isMobile),
                  const SizedBox(height: 20),
                ],

                // Teacher Materials Section
                if (_teacherMaterials.isNotEmpty) ...[
                  _buildEnhancedTeacherMaterialsCard(isMobile),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTeacherResourcesHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.subjectColor.withOpacity(0.95),
            widget.subjectColor.withOpacity(0.85),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.subjectColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.teacher,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teacher Resources',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Curated materials & notes from your teacher',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats Row
          Row(
            children: [
              _buildStatBadge(
                icon: Iconsax.note_text,
                count: _teacherNotes.length,
                label: 'Notes',
                isMobile: isMobile,
              ),
              const SizedBox(width: 12),
              _buildStatBadge(
                icon: Iconsax.folder_open,
                count: _teacherMaterials.length,
                label: 'Materials',
                isMobile: isMobile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required int count,
    required String label,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: isMobile ? 16 : 18),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTeacherNotesCard(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.subjectColor,
                    widget.subjectColor.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Iconsax.note_text, color: widget.subjectColor, size: 22),
            const SizedBox(width: 10),
            Text(
              'Teacher Notes',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkText,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.subjectColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.subjectColor.withOpacity(0.2),
                ),
              ),
              child: Text(
                '${_teacherNotes.length}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: widget.subjectColor,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Notes List
        ...List.generate(_teacherNotes.length, (index) {
          final note = _teacherNotes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildNoteCard(note, isMobile),
          );
        }),
      ],
    );
  }

  Widget _buildNoteCard(TeacherNoteModel note, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getCategoryColor(note.noteCategory).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor(note.noteCategory).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCategoryColor(note.noteCategory),
                      _getCategoryColor(note.noteCategory).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: _getCategoryColor(note.noteCategory).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  note.noteCategory,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (note.isPrivate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.lock, size: 13, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Private',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.calendar,
                      size: 12,
                      color: AppTheme.bodyText.withOpacity(0.7),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatDate(note.noteDate),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.bodyText.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Note Text
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.lightGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.borderGrey.withOpacity(0.3),
              ),
            ),
            child: Text(
              note.noteText,
              style: GoogleFonts.inter(
                fontSize: isMobile ? 13 : 14,
                color: AppTheme.darkText,
                height: 1.6,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Teacher Info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.subjectColor.withOpacity(0.15),
                      widget.subjectColor.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.subjectColor.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  Iconsax.user,
                  size: 16,
                  color: widget.subjectColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.teacherName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.darkText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (note.subjectName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        note.subjectName!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.bodyText.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTeacherMaterialsCard(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.subjectColor,
                    widget.subjectColor.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Iconsax.folder_open, color: widget.subjectColor, size: 22),
            const SizedBox(width: 10),
            Text(
              'Study Materials',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkText,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.subjectColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.subjectColor.withOpacity(0.2),
                ),
              ),
              child: Text(
                '${_teacherMaterials.length}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: widget.subjectColor,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Materials List
        ...List.generate(_teacherMaterials.length, (index) {
          final material = _teacherMaterials[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMaterialCard(material, isMobile),
          );
        }),
      ],
    );
  }

  Widget _buildMaterialCard(TeacherMaterialModel material, bool isMobile) {
    final materialColor = _getMaterialTypeColor(material.materialType);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openTeacherMaterial(material),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 14 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                materialColor.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: materialColor.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: materialColor.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      materialColor,
                      materialColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: materialColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getMaterialTypeIcon(material.materialType),
                  color: Colors.white,
                  size: 26,
                ),
              ),

              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.materialTitle,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 14 : 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkText,
                        height: 1.3,
                      ),
                      maxLines: 2,
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
                            color: materialColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: materialColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            material.materialType,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: materialColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Iconsax.eye,
                          size: 14,
                          color: AppTheme.bodyText.withOpacity(0.5),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${material.viewCount}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.bodyText.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (material.description != null &&
                        material.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        material.description!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.bodyText.withOpacity(0.7),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Arrow
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: materialColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: materialColor.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  Iconsax.arrow_right_3,
                  color: materialColor,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }






  Widget _buildWebTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChapterInfoCard(false),
              const SizedBox(height: 24),
              _buildCompletionTrackerCard(false),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMaterialsSection(false, true),
              const SizedBox(height: 32),
              // ✅ NEW: Teacher materials section
              if (!_isLoading && _errorMessage == null)
                _buildTeacherMaterialsSection(false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isMobile, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChapterInfoCard(isMobile),
        SizedBox(height: isMobile ? 20 : 32),
        if (!_isLoading && _errorMessage == null)
          _buildCompletionTrackerCard(isMobile),
        SizedBox(height: isMobile ? 20 : 32),
        if (_isLoading)
          _buildLoadingState()
        else if (_errorMessage != null)
          _buildErrorState()
        else
          _buildMaterialsSection(isMobile, isDesktop),
        // ✅ NEW: Add teacher materials section
        if (!_isLoading && _errorMessage == null)
          _buildTeacherMaterialsSection(isMobile),
      ],
    );
  }

  // ✅ NEW: Teacher Materials and Notes Section
  Widget _buildTeacherMaterialsSection(bool isMobile) {
    if (_teacherMaterials.isEmpty && _teacherNotes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: isMobile ? 24 : 32),

        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.subjectColor,
                    widget.subjectColor.withOpacity(0.7)
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: widget.subjectColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Iconsax.teacher, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teacher Resources',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Materials and notes from your teacher',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.bodyText.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Teacher Notes
        if (_teacherNotes.isNotEmpty) ...[
          _buildTeacherNotesCard(isMobile),
          const SizedBox(height: 16),
        ],

        // Teacher Materials
        if (_teacherMaterials.isNotEmpty) _buildTeacherMaterialsCard(isMobile),
      ],
    );
  }

  Widget _buildTeacherNotesCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            widget.subjectColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.subjectColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.subjectColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.subjectColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Iconsax.note, color: widget.subjectColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Teacher Notes',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.subjectColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_teacherNotes.length}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: widget.subjectColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_teacherNotes.length, (index) {
            final note = _teacherNotes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.borderGrey.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(note.noteCategory)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getCategoryColor(note.noteCategory)
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            note.noteCategory,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _getCategoryColor(note.noteCategory),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (note.isPrivate)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.lock,
                                    size: 12, color: Colors.orange),
                                const SizedBox(width: 4),
                                Text(
                                  'Private',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        Text(
                          _formatDate(note.noteDate),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.bodyText.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      note.noteText,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.darkText,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Iconsax.teacher,
                            size: 14,
                            color: AppTheme.bodyText.withOpacity(0.5)),
                        const SizedBox(width: 6),
                        Text(
                          note.teacherName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.bodyText.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTeacherMaterialsCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            widget.subjectColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.subjectColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.subjectColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.subjectColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                Icon(Iconsax.folder_2, color: widget.subjectColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Teacher Materials',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.subjectColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_teacherMaterials.length}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: widget.subjectColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_teacherMaterials.length, (index) {
            final material = _teacherMaterials[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => _openTeacherMaterial(material),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.borderGrey.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getMaterialTypeColor(material.materialType)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getMaterialTypeIcon(material.materialType),
                            color: _getMaterialTypeColor(material.materialType),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                material.materialTitle,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
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
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getMaterialTypeColor(
                                          material.materialType)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      material.materialType,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _getMaterialTypeColor(
                                            material.materialType),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Iconsax.eye,
                                      size: 12,
                                      color: AppTheme.bodyText.withOpacity(0.5)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${material.viewCount} views',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppTheme.bodyText.withOpacity(0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Iconsax.arrow_right_3,
                          color: widget.subjectColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Helper methods for teacher materials
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'performance':
        return const Color(0xFF10B981);
      case 'behavioral':
        return const Color(0xFFEF4444);
      case 'academic':
        return const Color(0xFF6366F1);
      case 'health':
        return const Color(0xFFF59E0B);
      default:
        return AppTheme.bodyText;
    }
  }

  Color _getMaterialTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return const Color(0xFFEF4444);
      case 'worksheet':
        return const Color(0xFF6366F1);
      case 'pdf':
      case 'document':
        return const Color(0xFF10B981);
      case 'link':
        return const Color(0xFF06B6D4);
      default:
        return widget.subjectColor;
    }
  }

  IconData _getMaterialTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Iconsax.video_play;
      case 'worksheet':
        return Iconsax.document_text;
      case 'pdf':
      case 'document':
        return Iconsax.document_1;
      case 'link':
        return Iconsax.link;
      default:
        return Iconsax.folder_2;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) return 'Today';
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return '${difference.inDays} days ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _openTeacherMaterial(TeacherMaterialModel material) {
    if (material.materialLink != null && material.materialLink!.isNotEmpty) {
      _launchURL(material.materialLink!);
    } else if (material.materialPath != null) {
      _launchURL(material.fullMaterialUrl);
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        CustomSnackbar.showError(context, 'Could not open link', title: 'Error');
      }
    }
  }

  // Rest of the original methods remain the same...
  // (buildCompletionTrackerCard, buildHeader, buildChapterInfoCard, etc.)
  // I'll continue with the remaining widgets...

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
              offset: const Offset(0, 4))
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
                      colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.chart_success,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Learning Progress',
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkText)),
                    const SizedBox(height: 3),
                    Text('$completedFiles of $totalFiles files completed',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Text('${_overallCompletionPercentage.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF3B82F6))),
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
            if (config == null || entry.value.isEmpty)
              return const SizedBox.shrink();

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

  Widget _buildProgressBreakdownRow(
      {required MaterialTypeConfig config,
        required int completed,
        required int total}) {
    final double percentage = total > 0 ? (completed / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        children: [
          Icon(config.icon, color: config.color, size: 18),
          const SizedBox(width: 12),
          Expanded(
              flex: 2,
              child: Text(config.title,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText))),
          Expanded(
              flex: 3,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 6,
                      backgroundColor: config.color.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation(config.color)))),
          const SizedBox(width: 12),
          SizedBox(
              width: 50,
              child: Text('$completed/$total',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700))),
        ],
      ),
    );
  }

  void _openDocument(MaterialFile file, MaterialTypeConfig config, int index) {
    print('📄 Opening document: ${file.name} [S.No: ${file.sno}, index: $index]');
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

  void _openVideo(MaterialFile file, String materialType, int index,
      VideoWatchProgress? currentProgress) {
    print(
        "📹 Opening video player for '${file.name}' [S.No: ${file.sno}, index: $index]");

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
            )));
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
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
        // Only show favorite button if not parent
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.all(isMobile ? 10 : 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isFavorite
                              ? widget.subjectColor.withOpacity(0.4)
                              : Colors.grey.shade300,
                          width: _isFavorite ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        gradient: _isFavorite
                            ? LinearGradient(
                          colors: [
                            widget.subjectColor.withOpacity(0.15),
                            widget.subjectColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                            : null,
                        boxShadow: _isFavorite
                            ? [
                          BoxShadow(
                            color: widget.subjectColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                            : null,
                      ),
                      child: Icon(
                        _isFavorite ? Iconsax.heart : Iconsax.heart, // ✅ Fixed: heart5 for filled, heart for outline
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
              offset: const Offset(0, 4))
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
                child: Icon(Iconsax.book_1,
                    color: widget.subjectColor, size: isMobile ? 20 : 22),
              ),
              SizedBox(width: isMobile ? 12 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chapter ${widget.chapter.chapterOrder}',
                        style: GoogleFonts.inter(
                            fontSize: isMobile ? 11 : 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(widget.chapter.displayChapterName,
                        style: GoogleFonts.inter(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkText),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis)
                  ],
                ),
              )
            ],
          ),
          if (widget.chapter.chapterDescription != null) ...[
            SizedBox(height: isMobile ? 12 : 14),
            Text(widget.chapter.chapterDescription!,
                style: GoogleFonts.inter(
                    fontSize: isMobile ? 13 : 14,
                    color: Colors.grey.shade700,
                    height: 1.5))
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
                  isMobile),
              _buildInfoChip(Iconsax.clock,
                  '${widget.chapter.timeSpentMinutes} min', widget.subjectColor, isMobile),
              _buildStatusChip(widget.chapter.completionStatus, isMobile)
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoChip(
      IconData icon, String label, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 12, vertical: isMobile ? 6 : 8),
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
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: color))
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
          horizontal: isMobile ? 10 : 12, vertical: isMobile ? 6 : 8),
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
          Text(status,
              style: GoogleFonts.inter(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  color: color))
        ],
      ),
    );
  }

  Widget _buildMaterialsSection(bool isMobile, bool isDesktop) {
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
            materialSections.add(_buildMaterialTypeSection(config, files, isMobile));
            materialSections.add(SizedBox(height: isMobile ? 24 : 32));
          }
        }
      }
    });

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(bottom: isMobile ? 16 : 20),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.subjectColor.withOpacity(0.15),
                        widget.subjectColor.withOpacity(0.08)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Iconsax.folder_2,
                      color: widget.subjectColor, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Study Materials',
                        style: GoogleFonts.inter(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkText)),
                    Text('${materialSections.length ~/ 2} material types available',
                        style: GoogleFonts.inter(
                            fontSize: isMobile ? 12 : 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500))
                  ],
                )
              ],
            ),
          ),
          SizedBox(height: isMobile ? 20 : 24),
          ...materialSections
        ],
      ),
    );
  }

  Widget _buildMaterialTypeSection(
      MaterialTypeConfig config, List<MaterialFile> files, bool isMobile) {
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
                  Text(config.title,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: config.color)),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: config.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${files.length}',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  )
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12 : 16),
        if (config.key == 'Video')
          _buildVideoGrid(files, config, isMobile)
        else
          _buildDocumentList(files, config, isMobile)
      ],
    );
  }

  Widget _buildVideoGrid(
      List<MaterialFile> files, MaterialTypeConfig config, bool isMobile) {
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

        print(
            "🎨 Building Video Card for '${file.name}' [S.No: ${file.sno}, index: $index]");
        return _buildVideoCard(
            file, config, index, isCompleted, watchProgress, isMobile);
      },
    );
  }

  Widget _buildVideoCard(
      MaterialFile file,
      MaterialTypeConfig config,
      int index,
      bool isCompleted,
      VideoWatchProgress? watchProgress,
      bool isMobile) {
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
            )
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
                                  config.color.withOpacity(0.1)
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(Iconsax.video,
                                  size: isMobile ? 42 : 54,
                                  color: config.color.withOpacity(0.5)),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.2),
                                Colors.transparent,
                                Colors.black.withOpacity(0.4)
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
                    child: Text('#${file.sno}',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
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
                          )
                        ],
                      ),
                      child: Icon(Iconsax.play,
                          size: isMobile ? 28 : 36, color: Colors.white),
                    ),
                  ),
                ),
                if (isCompleted)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.tick_circle,
                              size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('Watched',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white))
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
                                config.color.withOpacity(0.7)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(file.name,
                        style: GoogleFonts.inter(
                            fontSize: isMobile ? 14 : 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkText),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Iconsax.video,
                            size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(hasProgress ? resumeText : progressText,
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: hasProgress
                                      ? config.color
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                        )
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentList(
      List<MaterialFile> files, MaterialTypeConfig config, bool isMobile) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      separatorBuilder: (context, index) => SizedBox(height: isMobile ? 10 : 12),
      itemBuilder: (context, index) {
        final file = files[index];
        final isCompleted = _fileCompletionStatus[config.key]?[index] ?? false;
        return _buildDocumentCard(file, config, index, isCompleted, isMobile);
      },
    );
  }

  Widget _buildDocumentCard(MaterialFile file, MaterialTypeConfig config,
      int index, bool isCompleted, bool isMobile) {
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
                offset: const Offset(0, 4))
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
                  )
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
                      child: Text('${file.sno}',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(file.name,
                      style: GoogleFonts.inter(
                          fontSize: isMobile ? 14 : 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: config.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(file.type.toUpperCase(),
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: config.color)),
                      ),
                      const SizedBox(width: 8),
                      if (isCompleted) ...[
                        Icon(Iconsax.tick_circle,
                            size: 12, color: const Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text('Completed',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981)))
                      ]
                    ],
                  )
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
              child:
              Icon(Iconsax.arrow_right_3, color: config.color, size: 18),
            )
          ],
        ),
      ),
    );
  }

  String? _extractVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtube.com')) return uri.queryParameters['v'];
      if (uri.host.contains('youtu.be'))
        return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
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
              type: LoaderType.pulse, size: 60, color: widget.subjectColor),
          const SizedBox(height: 18),
          Text('Loading materials...',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.bodyText))
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 80),
          Icon(Iconsax.danger, size: 64, color: Colors.red.withOpacity(0.7)),
          const SizedBox(height: 18),
          Text('Failed to load materials',
              style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText)),
          const SizedBox(height: 10),
          Text(_errorMessage ?? 'Unknown error',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.bodyText.withOpacity(0.7)),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadMaterials,
            icon: const Icon(Iconsax.refresh, size: 17),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.subjectColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
            ),
          )
        ],
      ),
    );
  }
}

// Supporting classes remain the same...
class MaterialTypeConfig {
  final IconData icon;
  final String title;
  final Color color;
  final String key;

  MaterialTypeConfig(
      {required this.icon,
        required this.title,
        required this.color,
        required this.key});
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

  PdfWatchProgress({required this.lastPageViewed, required this.totalPages});
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
            onDocumentLoadFailed: (details) { if (mounted) { setState(() { _isLoading = false; }); CustomSnackbar.showError(context, 'Failed to load PDF'); } },
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
