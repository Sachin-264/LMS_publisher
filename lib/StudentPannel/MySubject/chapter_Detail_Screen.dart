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

  Map<String, bool> _documentOpenedStatus = {};
  Map<String, double> _videoWatchProgress = {};
  double _overallCompletionPercentage = 0.0;

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

    _documentOpenedStatus = {
      'Worksheet': materials['Worksheet']?['downloaded'] ?? false,
      'RevisionNotes': materials['RevisionNotes']?['downloaded'] ?? false,
      'ExtraQuestions': materials['ExtraQuestions']?['downloaded'] ?? false,
      'SolvedQuestions': materials['SolvedQuestions']?['downloaded'] ?? false,
      'PracticeZone': materials['PracticeZone']?['downloaded'] ?? false,
    };

    if (materials.containsKey('Video') && materials['Video']['available'] == true) {
      final videoProgress = (materials['Video']['progress'] ?? 0.0).toDouble();
      _videoWatchProgress['Video'] = videoProgress;
    }

    _calculateOverallCompletion();
  }

  void _calculateOverallCompletion() {
    if (_materialsData == null) return;

    int totalItems = 0;
    int completedItems = 0;

    final materials = _materialsData!.materials;

    if (materials.containsKey('Video') && materials['Video']['available'] == true) {
      totalItems++;
      final videoProgress = _videoWatchProgress['Video'] ?? 0.0;
      if (videoProgress >= 80.0) completedItems++;
    }

    _documentOpenedStatus.forEach((key, opened) {
      if (materials.containsKey(key) && materials[key]['available'] == true) {
        totalItems++;
        if (opened) completedItems++;
      }
    });

    _overallCompletionPercentage = totalItems > 0 ? (completedItems / totalItems) * 100 : 0.0;
  }

  Future<void> _trackDocumentOpen(String documentType, String url, String title) async {
    if (kIsWeb) {
      await _downloadFile(url, title);

      if (mounted) {
        setState(() {
          _documentOpenedStatus[documentType] = true;
        });
        _calculateOverallCompletion();
      }
    } else {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            pdfUrl: url,
            title: title,
            subjectColor: widget.subjectColor,
          ),
        ),
      );

      if (result == true && mounted) {
        setState(() {
          _documentOpenedStatus[documentType] = true;
        });
        _calculateOverallCompletion();
      }
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final studentId = userProvider.userCode;
    print('📄 Tracked: $documentType opened by student $studentId');
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        CustomSnackbar.showSuccess(context, 'Downloading $fileName...');
      } else {
        throw Exception('Could not download file');
      }
    } catch (e) {
      CustomSnackbar.showError(context, 'Failed to download file');
    }
  }

  void _openVideoPlayer(String videoUrl) {
    // Extract video ID from YouTube URL
    String? videoId = _extractVideoId(videoUrl);

    if (videoId == null || videoId.isEmpty) {
      CustomSnackbar.showError(context, 'Invalid YouTube URL');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YoutubePlayerScreen(
          videoId: videoId,
          subjectColor: widget.subjectColor,
          chapterName: widget.chapter.displayChapterName,
          materials: _materialsData?.materials,
          onProgressUpdate: (progress) {
            if (mounted) {
              setState(() {
                _videoWatchProgress['Video'] = progress;
              });
              _calculateOverallCompletion();

              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final studentId = userProvider.userCode;
              print('🎥 Video progress: $progress% for student $studentId');
            }
          },
        ),
      ),
    );
  }

// Add this helper method
  String? _extractVideoId(String url) {
    try {
      final uri = Uri.parse(url);

      // https://www.youtube.com/watch?v=VIDEO_ID
      if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'];
      }
      // https://youtu.be/VIDEO_ID
      else if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      }

      return null;
    } catch (e) {
      print('Error extracting video ID: $e');
      return null;
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

                // Two-column layout for web, single column for mobile
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
  // ========== WEB TWO-COLUMN LAYOUT ==========
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

// ========== MOBILE SINGLE-COLUMN LAYOUT ==========
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
    int totalItems = 0;
    int completedItems = 0;

    if (materials.containsKey('Video') && materials['Video']['available'] == true) {
      totalItems++;
      final videoProgress = _videoWatchProgress['Video'] ?? 0.0;
      if (videoProgress >= 80.0) completedItems++;
    }

    _documentOpenedStatus.forEach((key, opened) {
      if (materials.containsKey(key) && materials[key]['available'] == true) {
        totalItems++;
        if (opened) completedItems++;
      }
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
                      '$completedItems of $totalItems materials completed',
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
          SizedBox(height: isMobile ? 14 : 16),
          _buildChecklistItems(isMobile),
        ],
      ),
    );
  }

  Widget _buildChecklistItems(bool isMobile) {
    final materials = _materialsData!.materials;
    List<Widget> checklistItems = [];

    if (materials.containsKey('Video') && materials['Video']['available'] == true) {
      final videoProgress = _videoWatchProgress['Video'] ?? 0.0;
      checklistItems.add(_buildChecklistItem(
        'Video Lesson',
        Iconsax.video,
        videoProgress >= 80.0,
        isMobile,
      ));
    }

    final documentTypes = {
      'Worksheet': 'Worksheet',
      'RevisionNotes': 'Revision Notes',
      'ExtraQuestions': 'Extra Questions',
      'SolvedQuestions': 'Solved Questions',
      'PracticeZone': 'Practice Zone',
    };

    documentTypes.forEach((key, title) {
      if (materials.containsKey(key) && materials[key]['available'] == true) {
        checklistItems.add(_buildChecklistItem(
          title,
          Iconsax.document_text,
          _documentOpenedStatus[key] ?? false,
          isMobile,
        ));
      }
    });

    return Wrap(
      spacing: isMobile ? 8 : 10,
      runSpacing: isMobile ? 8 : 10,
      children: checklistItems,
    );
  }

  Widget _buildChecklistItem(String title, IconData icon, bool isCompleted, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF10B981).withOpacity(0.12)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF10B981).withOpacity(0.4)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Iconsax.tick_circle : icon,
            size: isMobile ? 13 : 14,
            color: isCompleted ? const Color(0xFF10B981) : Colors.grey.shade600,
          ),
          SizedBox(width: isMobile ? 6 : 7),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: isCompleted ? const Color(0xFF10B981) : Colors.grey.shade700,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsSection(bool isMobile, bool isDesktop) {
    if (_materialsData == null) return const SizedBox.shrink();

    final materials = _materialsData!.materials;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
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
                      'Video lessons & practice resources',
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

          // Video Section
          if (materials.containsKey('Video') && materials['Video']['available'] == true) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Iconsax.video,
                        size: 14,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Video Content',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildVideoCard(materials['Video'], isMobile),
            const SizedBox(height: 32),
          ],

          // Documents Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.subjectColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.subjectColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.document_text,
                      size: 14,
                      color: widget.subjectColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Practice Resources',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: widget.subjectColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 14 : 16),
          _buildDocumentsGrid(materials, isMobile, isDesktop),
        ],
      ),
    );
  }


  Widget _buildVideoCard(Map<dynamic, dynamic> videoData, bool isMobile) {
    final videoUrl = videoData['url'] ?? '';
    final thumbnailUrl = StudentSubjectService.getYouTubeThumbnail(videoUrl);
    final progress = _videoWatchProgress['Video'] ?? (videoData['progress'] ?? 0.0).toDouble();

    Widget videoContent = Container(
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
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
                                const Color(0xFFEF4444).withOpacity(0.2),
                                const Color(0xFFDC2626).withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Iconsax.video,
                              size: isMobile ? 42 : 54,
                              color: const Color(0xFFEF4444).withOpacity(0.5),
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
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.4),
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
              if (progress >= 80.0)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(20),
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
                        const Icon(Iconsax.tick_circle, size: 14, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          'Completed',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Iconsax.video,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: isMobile ? 10 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Video Lesson',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 15 : 17,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkText,
                            ),
                          ),
                          Text(
                            'Watch and learn at your pace',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 11 : 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (progress > 0) ...[
                  SizedBox(height: isMobile ? 12 : 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Watch Progress',
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 11 : 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${progress.toStringAsFixed(0)}%',
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 12 : 14,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade200,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation(Color(0xFFEF4444)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (kIsWeb) {
      return GestureDetector(
        onTap: () => _openVideoPlayer(videoUrl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: videoContent,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openVideoPlayer(videoUrl),
      child: videoContent,
    );
  }

  Widget _buildDocumentsGrid(Map<dynamic, dynamic> materials, bool isMobile, bool isDesktop) {
    final documentConfigs = [
      {'key': 'Worksheet', 'title': 'Worksheet', 'icon': Iconsax.document_text, 'color': const Color(0xFF6366F1)},
      {'key': 'RevisionNotes', 'title': 'Revision Notes', 'icon': Iconsax.note, 'color': const Color(0xFFEC4899)},
      {'key': 'ExtraQuestions', 'title': 'Extra Questions', 'icon': Iconsax.task_square, 'color': const Color(0xFF10B981)},
      {'key': 'SolvedQuestions', 'title': 'Solved Questions', 'icon': Iconsax.tick_square, 'color': const Color(0xFFF59E0B)},
      {'key': 'PracticeZone', 'title': 'Practice Zone', 'icon': Iconsax.edit, 'color': const Color(0xFF8B5CF6)},
    ];

    // For web two-column layout, use 2 columns; desktop 3, mobile 2
    final crossAxisCount = kIsWeb && isDesktop ? 2 : (isMobile ? 2 : 3);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isMobile ? 0.95 : 1.0,
        crossAxisSpacing: isMobile ? 12 : 16,
        mainAxisSpacing: isMobile ? 12 : 16,
      ),
      itemCount: documentConfigs.where((config) {
        return materials.containsKey(config['key']) &&
            materials[config['key']]['available'] == true;
      }).length,
      itemBuilder: (context, index) {
        final availableDocs = documentConfigs.where((config) {
          return materials.containsKey(config['key']) &&
              materials[config['key']]['available'] == true;
        }).toList();

        final config = availableDocs[index];
        final docData = materials[config['key']];

        return _buildDocumentCard(
          docData,
          config['title'] as String,
          config['key'] as String,
          config['icon'] as IconData,
          config['color'] as Color,
          isMobile,
        );
      },
    );
  }


  Widget _buildDocumentCard(
      Map<dynamic, dynamic> docData,
      String title,
      String documentType,
      IconData icon,
      Color color,
      bool isMobile,
      ) {
    final filePath = docData['file_path'] ?? '';
    final fullUrl = StudentSubjectService.getDocumentUrl(filePath);
    final isDownloaded = _documentOpenedStatus[documentType] ?? docData['downloaded'] == true;

    return GestureDetector(
      onTap: () => _trackDocumentOpen(documentType, fullUrl, title),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              color.withOpacity(0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 9 : 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: isMobile ? 18 : 20),
                ),
                const Spacer(),
                if (isDownloaded)
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Iconsax.tick_circle,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            SizedBox(height: isMobile ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Iconsax.document, size: 11, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'PDF',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 8 : 10),
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: isMobile ? 9 : 10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        kIsWeb ? Iconsax.document_download : (isDownloaded ? Iconsax.folder_open : Iconsax.eye),
                        size: isMobile ? 14 : 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        kIsWeb ? 'Download' : (isDownloaded ? 'Open' : 'View'),
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

// ========== YOUTUBE PLAYER SCREEN ==========
class YoutubePlayerScreen extends StatefulWidget {
  final String videoId;
  final Color subjectColor;
  final String chapterName;
  final Function(double) onProgressUpdate;
  final Map<dynamic, dynamic>? materials;

  const YoutubePlayerScreen({
    super.key,
    required this.videoId,
    required this.subjectColor,
    required this.chapterName,
    required this.onProgressUpdate,
    this.materials,
  });

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late YoutubePlayerController _controller;
  double _currentProgress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();

    // Create controller using fromVideoId (as per documentation)
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: false,
        enableCaption: true,
        strictRelatedVideos: true,
      ),
    );

    // Start tracking progress after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      _startProgressTracking();
    });
  }

  void _startProgressTracking() {
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) return;

      try {
        final currentTime = await _controller.currentTime;
        final duration = await _controller.duration;

        if (duration > 0 && currentTime > 0) {
          final progress = (currentTime / duration) * 100;

          if (progress > _currentProgress) {
            setState(() {
              _currentProgress = progress.clamp(0, 100);
            });
            widget.onProgressUpdate(_currentProgress);
          }
        }
      } catch (e) {
        print('Error tracking progress: $e');
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _controller.close();
    super.dispose();
  }

  void _openDocument(String url, String title, Color color) {
    if (kIsWeb) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            pdfUrl: url,
            title: title,
            subjectColor: color,
          ),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getAvailableDocuments() {
    if (widget.materials == null) return [];

    final documentConfigs = [
      {
        'key': 'Worksheet',
        'title': 'Worksheet',
        'icon': Iconsax.document_text,
        'color': const Color(0xFF6366F1),
        'description': 'Practice problems'
      },
      {
        'key': 'RevisionNotes',
        'title': 'Revision Notes',
        'icon': Iconsax.note,
        'color': const Color(0xFFEC4899),
        'description': 'Quick revision'
      },
      {
        'key': 'ExtraQuestions',
        'title': 'Extra Questions',
        'icon': Iconsax.task_square,
        'color': const Color(0xFF10B981),
        'description': 'Additional practice'
      },
      {
        'key': 'SolvedQuestions',
        'title': 'Solved Questions',
        'icon': Iconsax.tick_square,
        'color': const Color(0xFFF59E0B),
        'description': 'With solutions'
      },
      {
        'key': 'PracticeZone',
        'title': 'Practice Zone',
        'icon': Iconsax.edit,
        'color': const Color(0xFF8B5CF6),
        'description': 'Test yourself'
      },
    ];

    List<Map<String, dynamic>> availableDocs = [];
    for (var config in documentConfigs) {
      final key = config['key'] as String;
      if (widget.materials!.containsKey(key) &&
          widget.materials![key]['available'] == true) {
        availableDocs.add({
          ...config,
          'filePath': widget.materials![key]['file_path'] ?? '',
        });
      }
    }

    return availableDocs;
  }

  @override
  Widget build(BuildContext context) {
    final availableDocs = _getAvailableDocuments();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.chapterName,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Video Player with fixed dimensions for web
          Container(
            width: double.infinity,
            height: kIsWeb
                ? (screenWidth > 800 ? 450.0 : screenWidth * 9 / 16)
                : screenWidth * 9 / 16,
            color: Colors.black,
            child: Center(
              child: kIsWeb && screenWidth > 800
                  ? SizedBox(
                width: 800,
                height: 450,
                child: YoutubePlayer(
                  controller: _controller,
                  aspectRatio: 16 / 9,
                ),
              )
                  : YoutubePlayer(
                controller: _controller,
                aspectRatio: 16 / 9,
              ),
            ),
          ),
          // Progress and Documents Section
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.shade900,
                    Colors.black,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: kIsWeb ? 800 : double.infinity,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgressSection(),
                        if (availableDocs.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          _buildDocumentsSection(availableDocs),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Watch Progress',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade800,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _currentProgress / 100,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFEF4444)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentProgress.toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_currentProgress >= 80)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withOpacity(0.2),
                  const Color(0xFF059669).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.tick_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Great Progress!',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You\'ve completed this video lesson',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentsSection(List<Map<String, dynamic>> documents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Iconsax.document_text,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Study Materials',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Access documents while watching',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...documents.map((doc) => _buildDocumentItem(doc)).toList(),
      ],
    );
  }

  Widget _buildDocumentItem(Map<String, dynamic> doc) {
    final color = doc['color'] as Color;
    final icon = doc['icon'] as IconData;
    final title = doc['title'] as String;
    final description = doc['description'] as String;
    final filePath = doc['filePath'] as String;
    final fullUrl = StudentSubjectService.getDocumentUrl(filePath);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDocument(fullUrl, title, color),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Iconsax.arrow_right_3,
                    color: color,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
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
