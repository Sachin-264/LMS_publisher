import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/StudentPannel/Service/student_subject_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_charts/charts.dart'; // Import Syncfusion charts

class ChapterDetailsScreen extends StatefulWidget {
  final ChapterModel chapter;
  final Color subjectColor;
  final String subjectName;

  const ChapterDetailsScreen({
    super.key,
    required this.chapter,
    required this.subjectColor,
    required this.subjectName,
  });

  @override
  State<ChapterDetailsScreen> createState() => _ChapterDetailsScreenState();
}

class _ChapterDetailsScreenState extends State<ChapterDetailsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  MaterialsResponse? _materialsData;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Track which materials have been opened/completed
  Map<String, bool> _materialCompletionStatus = {};
  Map<String, Map<int, bool>> _fileCompletionStatus = {};
  double _overallCompletionPercentage = 0.0;

  // Video watch progress tracking
  Map<String, Map<int, VideoWatchProgress>> _videoWatchProgress = {}; // materialType -> {fileIndex -> progress}
  Map<String, int> _materialTimeSpent = {}; // materialType -> total minutes spent

  // Material type configuration with all 11 types
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
    'TeachingAids': MaterialTypeConfig(
      icon: Iconsax.teacher,
      title: 'Teaching Aids',
      color: const Color(0xFF6366F1),
      key: 'TeachingAids',
    ),
    'AssessmentTools': MaterialTypeConfig(
      icon: Iconsax.clipboard_tick,
      title: 'Assessment Tools',
      color: const Color(0xFFFF5722),
      key: 'AssessmentTools',
    ),
    'HomeworkTools': MaterialTypeConfig(
      icon: Iconsax.task_square,
      title: 'Homework Tools',
      color: const Color(0xFF795548),
      key: 'HomeworkTools',
    ),
    'PracticeZone': MaterialTypeConfig(
      icon: Iconsax.code_circle,
      title: 'Practice Zone',
      color: const Color(0xFF8B5CF6),
      key: 'PracticeZone',
    ),
    'LearningPath': MaterialTypeConfig(
      icon: Iconsax.routing,
      title: 'Learning Path',
      color: const Color(0xFFE91E63),
      key: 'LearningPath',
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
    _loadMaterials();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final studentId = userProvider.userCode;
      if (studentId == null) {
        throw Exception('Student ID not found');
      }

      print('🔍 Fetching materials for ChapterID: ${widget.chapter.chapterId}');
      final response = await StudentSubjectService.getChapterMaterials(
        studentId,
        widget.chapter.chapterId,
      );

      if (mounted) {
        setState(() {
          _materialsData = response;
          _isLoading = false;
          _initializeTrackingData();
        });
        _fadeController.forward();
      }
    } catch (e, stackTrace) {
      print('❌ Error loading materials: $e');
      print('📍 Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
        CustomSnackbar.showError(
          context,
          _errorMessage!,
          title: 'Failed to Load Materials',
        );
      }
    }
  }

  void _initializeTrackingData() {
    if (_materialsData == null) return;

    final materials = _materialsData!.materials;
    _materialCompletionStatus.clear();
    _fileCompletionStatus.clear();
    _videoWatchProgress.clear();
    _materialTimeSpent.clear();

    // Initialize completion tracking for each material type
    materials.forEach((key, value) {
      if (value is Map && value['available'] == true) {
        _materialCompletionStatus[key] = value['completed'] ?? false;
        _materialTimeSpent[key] = value['total_watch_time'] ?? 0;

        // Initialize file completion tracking
        if (value['files'] != null) {
          final files = value['files'] as List;
          _fileCompletionStatus[key] = {};

          // Initialize video watch progress for Video type
          if (key == 'Video') {
            _videoWatchProgress[key] = {};
            for (int i = 0; i < files.length; i++) {
              _fileCompletionStatus[key]![i] = false;
              _videoWatchProgress[key]![i] = VideoWatchProgress(
                watchedPercentage: value['progress'] ?? 0.0,
                lastPositionSeconds: value['last_position'] ?? 0,
                totalDurationSeconds: 0, // Will be set when video loads
              );
            }
          } else {
            for (int i = 0; i < files.length; i++) {
              _fileCompletionStatus[key]![i] = false;
            }
          }
        }
      }
    });

    _calculateOverallCompletion();
  }

  void _calculateOverallCompletion() {
    if (_materialsData == null) return;

    int totalFiles = 0;
    int completedFiles = 0;

    _fileCompletionStatus.forEach((materialType, fileMap) {
      totalFiles += fileMap.length;
      completedFiles += fileMap.values.where((completed) => completed).length;
    });

    _overallCompletionPercentage = totalFiles > 0
        ? (completedFiles / totalFiles) * 100
        : 0.0;
  }

  void _markFileAsCompleted(String materialType, int fileIndex) {
    if (mounted) {
      setState(() {
        if (_fileCompletionStatus[materialType] != null) {
          _fileCompletionStatus[materialType]![fileIndex] = true;
        }
        _calculateOverallCompletion();
      });
    }
  }

  void _updateVideoProgress(String materialType, int fileIndex, VideoWatchProgress progress) {
    if (mounted) {
      setState(() {
        if (_videoWatchProgress[materialType] != null) {
          _videoWatchProgress[materialType]![fileIndex] = progress;

          // Mark as completed if watched > 90%
          if (progress.watchedPercentage >= 90) {
            _markFileAsCompleted(materialType, fileIndex);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;
    final isDesktop = screenWidth >= 900;
    final contentMaxWidth = kIsWeb ? 1400.0 : double.infinity;

    return MainLayout(
      activeScreen: AppScreen.mySubjects,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isMobile),
                SizedBox(height: isMobile ? 20 : 32),
                if (isDesktop && kIsWeb && !_isLoading && _errorMessage == null)
                  _buildWebTwoColumnLayout()
                else
                  _buildMobileLayout(isMobile, isDesktop),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT COLUMN - Progress & Chapter Details
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChapterInfoCard(false),
              const SizedBox(height: 24),
              _buildCompletionTrackerCard(false),
              const SizedBox(height: 24),
              _buildAnalyticsDashboard(),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // RIGHT COLUMN - Study Materials
        Expanded(
          flex: 6,
          child: _buildMaterialsSection(false, true),
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
      ],
    );
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

  Widget _buildInfoChip(IconData icon, String label, Color color, bool isMobile) {
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

    final materials = _materialsData!.materials;
    int totalFiles = 0;
    int completedFiles = 0;

    _fileCompletionStatus.forEach((key, fileMap) {
      totalFiles += fileMap.length;
      completedFiles += fileMap.values.where((completed) => completed).length;
    });

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.05),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Iconsax.chart_success,
                  color: Colors.white,
                  size: isMobile ? 18 : 20,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learning Progress',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 15 : 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$completedFiles of $totalFiles files completed',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11 : 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: isMobile ? 50 : 56,
                height: isMobile ? 50 : 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3B82F6).withOpacity(0.1),
                      const Color(0xFF8B5CF6).withOpacity(0.1),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: isMobile ? 44 : 50,
                        height: isMobile ? 44 : 50,
                        child: CircularProgressIndicator(
                          value: _overallCompletionPercentage / 100,
                          strokeWidth: 4,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${_overallCompletionPercentage.toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 14 : 16),
          Container(
            height: isMobile ? 7 : 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withOpacity(0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _overallCompletionPercentage / 100,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsDashboard() {
    if (_materialsData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(0.15),
                      const Color(0xFF059669).withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.chart,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Study Analytics',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Time Distribution',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _buildTimeDistributionChart(),
          ),
          const SizedBox(height: 24),
          Text(
            'Material Breakdown',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 12),
          _buildMaterialBreakdown(),
        ],
      ),
    );
  }

  Widget _buildTimeDistributionChart() {
  List<_ChartData> chartData = [];
  int totalTime = 0;

  _materialTimeSpent.forEach((key, minutes) {
  totalTime += minutes;
  });

  if (totalTime == 0) {
  return Center(
  child: Text(
  'No study time recorded yet',
  style: GoogleFonts.inter(
  fontSize: 13,
  color: Colors.grey.shade600,
  ),
  ),
  );
  }

  _materialTimeSpent.forEach((key, minutes) {
  if (minutes > 0) {
  final config = materialTypeConfigs[key];
  if (config != null) {
  chartData.add(_ChartData(config.title, minutes.toDouble(), config.color));
  }
  }
  });

  return Row(
  children: [
  Expanded(
  flex: 2,
  child: SfCircularChart(
  series: <CircularSeries>[
  PieSeries<_ChartData, String>(
  dataSource: chartData,
  pointColorMapper: (_ChartData data, _) => data.color,
  xValueMapper: (_ChartData data, _) => data.x,
  yValueMapper: (_ChartData data, _) => data.y,
  dataLabelSettings: DataLabelSettings(
  isVisible: true,
  builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
  double percentage = (data.y / totalTime) * 100;
  return Text(
  '${percentage.toStringAsFixed(0)}%',
  style: GoogleFonts.inter(
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: Colors.white,
  ),
  );
  },
  labelPosition: ChartDataLabelPosition.inside,
  ),
  radius: '80%',
  explode: true,
  explodeOffset: '2%',
  ),
  ],
  ),
  ),
  const SizedBox(width: 20),
  Expanded(
  flex: 1,
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: _materialTimeSpent.entries.map((entry) {
  final config = materialTypeConfigs[entry.key];
  if (config != null && entry.value > 0) {
  return Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Row(
  children: [
  Container(
  width: 12,
  height: 12,
  decoration: BoxDecoration(
  color: config.color,
  borderRadius: BorderRadius.circular(3),
  ),
  ),
  const SizedBox(width: 8),
  Expanded(
  child: Text(
  '${config.title}: ${entry.value}m',
  style: GoogleFonts.inter(
  fontSize: 11,
  color: Colors.grey.shade700,
  fontWeight: FontWeight.w600,
  ),
  ),
  ),
  ],
  ),
  );
  }
  return const SizedBox.shrink();
  }).toList(),
  ),
  ),
  ],
  );
  }

  Widget _buildMaterialBreakdown() {
  final materials = _materialsData!.materials;
  List<Widget> rows = [];

  materials.forEach((key, value) {
  if (value is Map && value['available'] == true && value['files'] != null) {
  final config = materialTypeConfigs[key];
  if (config != null) {
  final files = value['files'] as List;
  final completedCount = _fileCompletionStatus[key]?.values.where((c) => c).length ?? 0;
  final progress = files.isNotEmpty ? (completedCount / files.length) * 100 : 0.0;

  rows.add(
  Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  children: [
  Icon(config.icon, size: 16, color: config.color),
  const SizedBox(width: 8),
  Expanded(
  child: Text(
  config.title,
  style: GoogleFonts.inter(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: AppTheme.darkText,
  ),
  ),
  ),
  Text(
  '$completedCount/${files.length}',
  style: GoogleFonts.inter(
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: config.color,
  ),
  ),
  ],
  ),
  const SizedBox(height: 6),
  ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: LinearProgressIndicator(
  value: progress / 100,
  backgroundColor: config.color.withOpacity(0.1),
  valueColor: AlwaysStoppedAnimation(config.color),
  minHeight: 6,
  ),
  ),
  ],
  ),
  ),
  );
  }
  }
  });

  return Column(children: rows);
  }

  Widget _buildMaterialsSection(bool isMobile, bool isDesktop) {
  if (_materialsData == null) return const SizedBox.shrink();

  final materials = _materialsData!.materials;
  List<Widget> materialSections = [];

  materials.forEach((key, value) {
  if (value is Map && value['available'] == true && value['files'] != null) {
  final config = materialTypeConfigs[key];
  if (config != null) {
  final files = (value['files'] as List)
      .map((f) => MaterialFile.fromJson(f))
      .toList();

  if (files.isNotEmpty) {
  materialSections.add(_buildMaterialTypeSection(
  config,
  files,
  value as Map<String, dynamic>,
  isMobile,
  ));
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
  bottom: BorderSide(
  color: Colors.grey.shade200,
  width: 2,
  ),
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
  '${materials.length} material types available',
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
  );
  }

  Widget _buildMaterialTypeSection(
  MaterialTypeConfig config,
  List<MaterialFile> files,
  Map<String, dynamic> metadata,
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
  border: Border.all(
  color: config.color.withOpacity(0.3),
  ),
  ),
  child: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
  Icon(
  config.icon,
  size: 16,
  color: config.color,
  ),
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
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

  Widget _buildVideoGrid(List<MaterialFile> files, MaterialTypeConfig config, bool isMobile) {
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
  return _buildVideoCard(file, config, index, isCompleted, watchProgress, isMobile);
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
  final hasProgress = watchProgress != null && watchProgress.watchedPercentage > 0;
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
  colors: [
  Colors.white,
  Colors.grey.shade50,
  ],
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
  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  const Icon(Iconsax.tick_circle, size: 12, color: Colors.white),
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
  if (hasProgress && watchProgress!.watchedPercentage < 100)
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
  colors: [config.color, config.color.withOpacity(0.7)],
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
  Icon(Iconsax.video, size: 12, color: Colors.grey.shade600),
  const SizedBox(width: 4),
  Expanded(
  child: Text(
  hasProgress ? resumeText : progressText,
  style: GoogleFonts.inter(
  fontSize: 10,
  color: hasProgress ? config.color : Colors.grey.shade600,
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

  Widget _buildDocumentList(List<MaterialFile> files, MaterialTypeConfig config, bool isMobile) {
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
  colors: [
  Colors.white,
  config.color.withOpacity(0.02),
  ],
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
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
  Icon(Iconsax.tick_circle, size: 12, color: const Color(0xFF10B981)),
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

  void _openVideo(MaterialFile file, String materialType, int index, VideoWatchProgress? currentProgress) {
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
  _updateVideoProgress(materialType, index, progress);
  },
  ),
  ),
  );
  }

  void _openDocument(MaterialFile file, MaterialTypeConfig config, int index) {
  _markFileAsCompleted(config.key, index);

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
  ),
  ),
  );
  }
  } else {
  launchUrl(Uri.parse(file.fullUrl), mode: LaunchMode.externalApplication);
  }
  }

  String? _extractVideoId(String url) {
  try {
  final uri = Uri.parse(url);
  if (uri.host.contains('youtube.com')) {
  return uri.queryParameters['v'];
  } else if (uri.host.contains('youtu.be')) {
  return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
  }
  return null;
  } catch (e) {
  print('Error extracting video ID: $e');
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
  children: [
  const SizedBox(height: 80),
  Icon(Iconsax.danger, size: 64, color: Colors.red.withOpacity(0.7)),
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
  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
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

// (The rest of your code: MaterialTypeConfig, VideoWatchProgress, YoutubePlayerScreen, PdfViewerScreen, etc. remains the same as you provided)
// Make sure to include the helper classes (MaterialTypeConfig, VideoWatchProgress) and the other screens (YoutubePlayerScreen, PdfViewerScreen)
// in the same file or import them correctly if they are in separate files.

// ========== HELPER CLASSES ==========

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

  VideoWatchProgress copyWith({
    double? watchedPercentage,
    int? lastPositionSeconds,
    int? totalDurationSeconds,
  }) {
    return VideoWatchProgress(
      watchedPercentage: watchedPercentage ?? this.watchedPercentage,
      lastPositionSeconds: lastPositionSeconds ?? this.lastPositionSeconds,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
    );
  }
}

// ========== YOUTUBE PLAYER SCREEN WITH PROGRESS TRACKING ==========

class YoutubePlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final Color subjectColor;
  final VideoWatchProgress? initialProgress;
  final Function(VideoWatchProgress)? onProgressUpdate;

  const YoutubePlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
    required this.subjectColor,
    this.initialProgress,
    this.onProgressUpdate,
  });

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
    _currentPositionSeconds = widget.initialProgress?.lastPositionSeconds ?? 0;
    _watchedPercentage = widget.initialProgress?.watchedPercentage ?? 0.0;

    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: false,
        enableCaption: true,
        strictRelatedVideos: true,
      ),
    );

    _controller.listen((event) {
      if (event.playerState == PlayerState.playing && !_isPlayerReady) {
        _isPlayerReady = true;
        _startProgressTracking();
      }
    });
  }

  void _startProgressTracking() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      // Check if the widget is still in the tree before proceeding.
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_controller.value.playerState == PlayerState.playing) {
        try {
          final currentTimeInSeconds = await _controller.currentTime;
          final totalDurationInSeconds = await _controller.duration;

          // Ensure duration is positive to avoid division by zero.
          if (mounted && totalDurationInSeconds > 0) {
            setState(() {
              _currentPositionSeconds = currentTimeInSeconds.toInt();
              _totalDurationSeconds = totalDurationInSeconds.toInt();
              _watchedPercentage = (currentTimeInSeconds / totalDurationInSeconds) * 100;
            });

            // Save progress roughly every 10 seconds.
            if (_currentPositionSeconds > 0 && _currentPositionSeconds % 10 < 2) {
              _saveProgress();
            }
          }
        } catch (e) {
          // It's good practice to check if the widget is mounted before printing.
          if (mounted) {
            print('Error tracking progress: $e');
          }
        }
      }
    });
  }

  void _saveProgress() {
    if (widget.onProgressUpdate != null && _totalDurationSeconds > 0) {
      final progress = VideoWatchProgress(
        watchedPercentage: _watchedPercentage,
        lastPositionSeconds: _currentPositionSeconds,
        totalDurationSeconds: _totalDurationSeconds,
      );
      widget.onProgressUpdate!(progress);
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _saveProgress();
    _controller.close();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async {
        _saveProgress();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              _saveProgress();
              Navigator.pop(context);
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (_totalDurationSeconds > 0)
                Text(
                  '${_formatDuration(_currentPositionSeconds)} / ${_formatDuration(_totalDurationSeconds)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade400,
                  ),
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            Center(
              child: Container(
                width: kIsWeb && screenWidth > 800 ? 800 : double.infinity,
                height: kIsWeb && screenWidth > 800 ? 450 : screenWidth * 9 / 16,
                color: Colors.black,
                child: YoutubePlayer(
                  controller: _controller,
                  aspectRatio: 16 / 9,
                ),
              ),
            ),
            if (_totalDurationSeconds > 0)
              Container(
                width: kIsWeb && screenWidth > 800 ? 800 : double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: Colors.grey.shade900,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Watch Progress',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${_watchedPercentage.toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: widget.subjectColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _watchedPercentage / 100,
                        backgroundColor: Colors.grey.shade800,
                        valueColor: AlwaysStoppedAnimation(widget.subjectColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Container(
                width: kIsWeb && screenWidth > 800 ? 800 : double.infinity,
                color: Colors.grey.shade900,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Iconsax.info_circle,
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your progress is automatically saved',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_watchedPercentage >= 90)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.tick_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Great job! You\'ve completed this video',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
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
}

// ========== PDF VIEWER SCREEN ==========

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final Color subjectColor;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
    required this.subjectColor,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Iconsax.search_zoom_in),
              tooltip: 'Zoom In',
              onPressed: () {
                _pdfController.zoomLevel = _pdfController.zoomLevel + 0.25;
              },
            ),
            IconButton(
              icon: const Icon(Iconsax.search_zoom_out),
              tooltip: 'Zoom Out',
              onPressed: () {
                if (_pdfController.zoomLevel > 1) {
                  _pdfController.zoomLevel = _pdfController.zoomLevel - 0.25;
                }
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            SfPdfViewer.network(
              widget.pdfUrl,
              controller: _pdfController,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  CustomSnackbar.showSuccess(context, 'PDF loaded successfully');
                }
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  CustomSnackbar.showError(context, 'Failed to load PDF');
                }
              },
            ),
            if (_isLoading)
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(widget.subjectColor),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Loading PDF...',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
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
}


// Helper class for Syncfusion Chart data
class _ChartData {
  _ChartData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}
