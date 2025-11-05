// assignment_submission_screen.dart (with overflow fixes)

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Teacher_Panel/teacher_material_service.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart'; // Assuming you have this
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

const String _imageBaseUrl =
    "https://storage.googleapis.com/upload-images-34/images/LMS/";
const String _documentBaseUrl =
    "https://storage.googleapis.com/upload-images-34/documents/LMS/";

String getFullImageUrl(String? filename) {
  if (filename == null || filename.isEmpty) return '';
  return '$_imageBaseUrl$filename';
}

String getFullDocumentUrl(String? filename) {
  if (filename == null || filename.isEmpty) return '';
  return '$_documentBaseUrl$filename';
}

String _safeString(dynamic value, [String defaultValue = 'N/A']) {
  if (value == null) return defaultValue;
  if (value is String && value.isEmpty) return defaultValue;
  return value.toString();
}

num _safeNum(dynamic value, [num defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is num) return value;
  if (value is String) {
    return num.tryParse(value) ?? defaultValue;
  }
  return defaultValue;
}

bool _safeBool(dynamic value, [bool defaultValue = false]) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  if (value is num) return value != 0;
  return defaultValue;
}

enum SubmissionFilter {
  all,
  graded,
  pending,
  notSubmitted,
}

class AssignmentSubmissionsScreen extends StatefulWidget {
  final String teacherCode;
  final int materialRecNo;
  final String materialTitle;
  final int totalMarks;
  final int classRecNo;

  const AssignmentSubmissionsScreen({
    super.key,
    required this.teacherCode,
    required this.materialRecNo,
    required this.materialTitle,
    required this.totalMarks,
    required this.classRecNo,
  });

  @override
  State<AssignmentSubmissionsScreen> createState() =>
      _AssignmentSubmissionsScreenState();
}

class _AssignmentSubmissionsScreenState
    extends State<AssignmentSubmissionsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _submittedStudents = []; // ✅ CHANGED
  List<Map<String, dynamic>> _notSubmittedStudents = []; // ✅ CHANGED

  late TabController _tabController;
  SubmissionFilter _currentFilter = SubmissionFilter.all;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentFilter = SubmissionFilter.values[_tabController.index];
        });
      }
    });
    _loadSubmissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final response = await TeacherMaterialService.getSubmissions(
        teacherCode: widget.teacherCode,
        materialRecNo: widget.materialRecNo,
        classRecNo: widget.classRecNo, // ✅ ADD THIS LINE
        filterStatus: 'All',
      );

      if (mounted) {
        setState(() {
          // ✅ UPDATED: Get data from new API structure
          _submittedStudents = List<Map<String, dynamic>>.from(
            response['submitted_students'] ?? [],
          );
          _notSubmittedStudents = List<Map<String, dynamic>>.from(
            response['not_submitted_students'] ?? [],
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackbar.showError(context, 'Error: $e', title: 'Error');
      }
    }
  }

// ✅ UPDATE: Filter getters
  List<Map<String, dynamic>> get _pendingSubmissions => _submittedStudents
      .where((s) => _safeString(s['GradeStatus']) == 'Pending')
      .toList();

  List<Map<String, dynamic>> get _gradedSubmissions => _submittedStudents
      .where((s) => _safeString(s['GradeStatus']) == 'Graded')
      .toList();

  List<Map<String, dynamic>> get _filteredData {
    switch (_currentFilter) {
      case SubmissionFilter.graded:
        return _gradedSubmissions;
      case SubmissionFilter.pending:
        return _pendingSubmissions;
      case SubmissionFilter.notSubmitted:
        return _notSubmittedStudents;
      case SubmissionFilter.all:
      default:
        return [..._submittedStudents, ..._notSubmittedStudents];
    }
  }


  @override
  Widget build(BuildContext context) {
    // ✅ GET isMobile HERE
    final bool isMobile = MediaQuery.of(context).size.width < 650;

    return Scaffold(
      backgroundColor: AppTheme.lightGrey, // Changed to lightGrey
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : Column( // ✅ MAKE COLUMN THE DIRECT CHILD OF BODY
        children: [
          _buildSummarySection(isMobile),
          // Only show Tab Bar on Web
          if (!isMobile) _buildTabBar(),
          Expanded(
            child: _buildSubmissionList(isMobile),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppTheme.background,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left, color: AppTheme.darkText),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.materialTitle,
            style: AppTheme.headline1.copyWith(
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Total Marks: ${widget.totalMarks}',
            style: AppTheme.bodyText1.copyWith(
              fontSize: 12,
              color: AppTheme.bodyText,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _loadSubmissions,
          icon: const Icon(
            Iconsax.refresh,
            color: AppTheme.assignmentColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: BeautifulLoader(
        type: LoaderType.pulse,
        color: AppTheme.assignmentColor,
        size: 80,
        message: 'Loading Submissions...',
      ),
    );
  }

  // Responsive Summary Section
  Widget _buildSummarySection(bool isMobile) {
    final summaryCards = [
      _buildClickableSummaryBox(
        'All',
        (_submittedStudents.length + _notSubmittedStudents.length).toString(),
        Iconsax.document,
        AppTheme.cleoColor,
        SubmissionFilter.all,
        0,
        isMobile,
      ),
      _buildClickableSummaryBox(
        'Graded',
        _gradedSubmissions.length.toString(),
        Iconsax.verify,
        AppTheme.accentGreen,
        SubmissionFilter.graded,
        1,
        isMobile,
      ),
      _buildClickableSummaryBox(
        'Pending',
        _pendingSubmissions.length.toString(),
        Iconsax.timer,
        AppTheme.assignmentColor,
        SubmissionFilter.pending,
        2,
        isMobile,
      ),
      _buildClickableSummaryBox(
        'Missing',
        _notSubmittedStudents.length.toString(),
        Iconsax.close_circle,
        AppTheme.mackColor,
        SubmissionFilter.notSubmitted,
        3,
        isMobile,
      ),
    ];

    if (isMobile) {
      // On Mobile: Horizontally scrolling list
      return Container(
        height: 100, // Reduced height
        color: AppTheme.background,
        // ✅ UPDATED PADDING: 16.0 vertical was too much
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: summaryCards.length,
          itemBuilder: (context, index) => summaryCards[index],
          separatorBuilder: (context, index) => const SizedBox(width: 12),
        ),
      );
    }

    // On Web: Themed container with a Row
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.background, // Changed to white
        borderRadius: AppTheme.defaultBorderRadius * 1.5, // 18.0
        border: Border.all(
          color: AppTheme.borderGrey, // Use standard border
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submission Summary',
            style: AppTheme.headline1.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: summaryCards
                .map((card) => Expanded(child: card))
                .toList()
                .expand((widget) => [widget, const SizedBox(width: 12)])
                .toList()
              ..removeLast(),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableSummaryBox(
      String label,
      String count,
      IconData icon,
      Color color,
      SubmissionFilter filter,
      int tabIndex,
      bool isMobile,
      ) {
    final isSelected = _currentFilter == filter;

    // Use the main assignment color for selection
    const selectionColor = AppTheme.assignmentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _tabController.animateTo(tabIndex);
          setState(() => _currentFilter = filter);
        },
        borderRadius: AppTheme.defaultBorderRadius, // 12.0
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isMobile ? 120 : null, // Fixed width for mobile scrolling
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? selectionColor.withOpacity(0.1)
                : AppTheme.background,
            borderRadius: AppTheme.defaultBorderRadius, // 12.0
            border: Border.all(
              color: isSelected ? selectionColor : AppTheme.borderGrey,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: selectionColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ]
                : [
              BoxShadow(
                color: AppTheme.shadowColor.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count,
                    style: AppTheme.headline1.copyWith(
                      fontSize: 28, // Made count larger
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: AppTheme.bodyText1.copyWith(
                      fontSize: 12, // Made label smaller
                      fontWeight: FontWeight.w700,
                      color: isSelected ? selectionColor : AppTheme.bodyText,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Web-only Tab Bar
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: AppTheme.defaultBorderRadius, // 12.0
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicator: BoxDecoration(
          color: AppTheme.assignmentColor, // Use new theme color
          borderRadius: AppTheme.defaultBorderRadius, // 12.0
          boxShadow: [
            BoxShadow(
              color: AppTheme.assignmentColor
                  .withOpacity(0.3), // Use new theme color
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.bodyText,
        labelStyle: AppTheme.labelText.copyWith(fontSize: 12),
        unselectedLabelStyle: AppTheme.labelText
            .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: [
          _buildTab('All', Iconsax.document, 0),
          _buildTab('Graded', Iconsax.verify, 1),
          _buildTab('Pending', Iconsax.timer, 2),
          _buildTab('Missing', Iconsax.close_circle, 3),
        ],
      ),
    );
  }

  Widget _buildTab(String label, IconData icon, int index) {
    return Tab(
      height: 45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildSubmissionList(bool isMobile) {
    if (_filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.folder_open,
              size: 64,
              color: AppTheme.bodyText.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${_getFilterLabel()} found',
              style: AppTheme.headline1.copyWith(
                fontSize: 16,
                color: AppTheme.bodyText,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      itemCount: _filteredData.length,
      itemBuilder: (context, index) {
        final item = _filteredData[index];
        final isNotSubmitted = _currentFilter == SubmissionFilter.notSubmitted ||
            (_currentFilter == SubmissionFilter.all &&
                index >= _submittedStudents.length);

        return isNotSubmitted
            ? _buildNotSubmittedCard(item)
            : _buildSubmissionCard(item);
      },
    );
  }

  String _getFilterLabel() {
    switch (_currentFilter) {
      case SubmissionFilter.graded:
        return 'graded submissions';
      case SubmissionFilter.pending:
        return 'pending submissions';
      case SubmissionFilter.notSubmitted:
        return 'missing submissions';
      case SubmissionFilter.all:
      default:
        return 'submissions';
    }
  }

  Widget _buildSubmissionCard(Map<String, dynamic> submission) {
    final studentName = _safeString(submission['StudentName'], 'Unknown');
    final classSection = _safeString(submission['ClassSection']);
    final submissionDate = submission['SubmissionDate'];
    final gradeStatus = _safeString(submission['GradeStatus'], 'Pending');
    final marks = _safeNum(submission['MarksAfterPenalty']);
    final isLate = _safeBool(submission['IsLateSubmission']);
    final daysLate = _safeNum(submission['DaysLate']).toInt();
    final filePath = submission['SubmissionFilePath'];
    final studentPhoto = submission['StudentPhotoPath'];
    final isPending = gradeStatus == 'Pending';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSubmissionDetailsDialog(submission),
        borderRadius: AppTheme.defaultBorderRadius, // 14.0
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: AppTheme.defaultBorderRadius, // 14.0
            border: Border.all(
              color: AppTheme.borderGrey,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowColor.withOpacity(0.7),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.assignmentColor
                            .withOpacity(0.3), // Use new theme color
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: _buildAvatar(
                          studentPhoto, studentName, AppTheme.assignmentColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: AppTheme.labelText.copyWith(
                            fontSize: 16, // Made name larger
                            color: AppTheme.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.cleoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            classSection,
                            style: AppTheme.labelText.copyWith(
                              fontSize: 10,
                              color: AppTheme.cleoColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPending)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.assignmentColor
                            .withOpacity(0.12), // Use new theme color
                        borderRadius:
                        AppTheme.defaultBorderRadius * 0.75, // 8.0
                        border: Border.all(
                          color: AppTheme.assignmentColor
                              .withOpacity(0.3), // Use new theme color
                        ),
                      ),
                      child: Text(
                        'Pending',
                        style: AppTheme.labelText.copyWith(
                            fontSize: 12, // Made status text larger
                            color: AppTheme.assignmentColor), // Use new theme color
                      ),
                    )
                  else
                  // NEW: Improved Marks display
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          marks.toStringAsFixed(1),
                          style: AppTheme.headline1.copyWith(
                            fontSize: 18,
                            color: AppTheme.accentGreen,
                          ),
                        ),
                        Text(
                          ' / ${widget.totalMarks}',
                          style: AppTheme.bodyText1.copyWith(
                            fontSize: 12,
                            color: AppTheme.bodyText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: AppTheme.borderGrey),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Iconsax.calendar_1,
                    size: 14,
                    color: AppTheme.bodyText,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      submissionDate != null
                          ? DateFormat('MMM dd, yyyy hh:mm a')
                          .format(DateTime.parse(submissionDate))
                          : 'No date',
                      style: AppTheme.bodyText1.copyWith(
                        fontSize: 11,
                        color: AppTheme.bodyText,
                      ),
                    ),
                  ),
                  if (isLate)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.mackColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Iconsax.clock,
                            size: 10,
                            color: AppTheme.mackColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${daysLate}d late',
                            style: AppTheme.labelText.copyWith(
                              fontSize: 10,
                              color: AppTheme.mackColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (filePath != null && filePath.toString().isNotEmpty)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final url = getFullDocumentUrl(filePath.toString());
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        borderRadius:
                        AppTheme.defaultBorderRadius * 0.75, // 8.0
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.document_download,
                                size: 14,
                                color: AppTheme
                                    .assignmentColor, // Use new theme color
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'View',
                                style: AppTheme.labelText.copyWith(
                                  fontSize: 11,
                                  color: AppTheme
                                      .assignmentColor, // Use new theme color
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showGradingDialog(submission),
                      borderRadius:
                      AppTheme.defaultBorderRadius * 0.75, // 8.0
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPending ? Iconsax.edit : Iconsax.refresh,
                              size: 14,
                              color: AppTheme
                                  .assignmentColor, // Use new theme color
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPending ? 'Grade' : 'Edit',
                              style: AppTheme.labelText.copyWith(
                                fontSize: 11,
                                color: AppTheme
                                    .assignmentColor, // Use new theme color
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotSubmittedCard(Map<String, dynamic> student) {
    final studentName = _safeString(student['StudentName'], 'Unknown');
    final classSection = _safeString(student['ClassSection'], 'N/A');
    final rollNumber = _safeString(student['RollNumber'], 'N/A');
    final studentPhoto = student['StudentPhotoPath'];
    final dueDate = student['DueDate'];
    final submissionStatus = _safeString(student['SubmissionStatus'], 'Pending');
    final daysOverdue = _safeNum(student['DaysOverdue']).toInt();
    final isOverdue = submissionStatus == 'Overdue';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: AppTheme.defaultBorderRadius,
        border: Border.all(
          color: isOverdue ? AppTheme.mackColor.withOpacity(0.3) : AppTheme.borderGrey,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isOverdue
                ? AppTheme.mackColor.withOpacity(0.1)
                : AppTheme.shadowColor.withOpacity(0.7),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.mackColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _buildAvatar(
                    studentPhoto,
                    studentName,
                    AppTheme.mackColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: AppTheme.labelText.copyWith(
                        fontSize: 16,
                        color: AppTheme.darkText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.cleoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            classSection,
                            style: AppTheme.labelText.copyWith(
                              fontSize: 10,
                              color: AppTheme.cleoColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.bodyText.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Roll: $rollNumber',
                            style: AppTheme.labelText.copyWith(
                              fontSize: 10,
                              color: AppTheme.bodyText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.mackColor.withOpacity(0.12),
                  borderRadius: AppTheme.defaultBorderRadius * 0.75,
                  border: Border.all(
                    color: AppTheme.mackColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Not Submitted',
                  style: AppTheme.labelText.copyWith(
                    fontSize: 12,
                    color: AppTheme.mackColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppTheme.borderGrey),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Iconsax.calendar_1,
                size: 14,
                color: isOverdue ? AppTheme.mackColor : AppTheme.bodyText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dueDate != null
                      ? 'Due: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(dueDate))}'
                      : 'No due date',
                  style: AppTheme.bodyText1.copyWith(
                    fontSize: 11,
                    color: isOverdue ? AppTheme.mackColor : AppTheme.bodyText,
                  ),
                ),
              ),
              if (isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.mackColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Iconsax.clock,
                        size: 10,
                        color: AppTheme.mackColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${daysOverdue}d overdue',
                        style: AppTheme.labelText.copyWith(
                          fontSize: 10,
                          color: AppTheme.mackColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildAvatar(dynamic photoPath, String name, Color color) {
    final path = photoPath?.toString() ?? '';
    final initials = name.isNotEmpty
        ? (name.split(' ').length > 1
        ? (name.split(' ')[0].isNotEmpty ? name.split(' ')[0][0] : '') +
        (name.split(' ')[1].isNotEmpty ? name.split(' ')[1][0] : '')
        : name[0])
        : '?';

    if (path.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: getFullImageUrl(path),
        fit: BoxFit.cover,
        placeholder: (context, url) => BeautifulLoader(
          type: LoaderType.circular,
          color: color,
          size: 20,
        ),
        errorWidget: (context, url, error) => Container(
          color: color.withOpacity(0.1),
          child: Center(
            child: Text(
              initials.toUpperCase(),
              style: AppTheme.headline2.copyWith(
                fontSize: 18,
                color: color,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: color.withOpacity(0.1),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: AppTheme.headline2.copyWith(
            fontSize: 18,
            color: color,
          ),
        ),
      ),
    );
  }

  // --- REDESIGNED DIALOGS ---

  Widget _buildDialogHeader(BuildContext ctx,
      {required IconData icon, required String title}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.assignmentColor.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: AppTheme.borderGrey),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.assignmentColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTheme.headline1.copyWith(fontSize: 18),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Iconsax.close_circle, color: AppTheme.bodyText),
          ),
        ],
      ),
    );
  }

  void _showSubmissionDetailsDialog(Map<String, dynamic> submission) {
    final studentName = _safeString(submission['StudentName'], 'Unknown');
    final classSection = _safeString(submission['ClassSection']);
    final submissionDate = submission['SubmissionDate'];
    final gradeStatus = _safeString(submission['GradeStatus'], 'Pending');
    final marks = _safeNum(submission['MarksAfterPenalty']);
    final marksObtained = _safeNum(submission['MarksObtained']);
    final penalty = _safeNum(submission['PenaltyMarks']);
    final feedback =
    _safeString(submission['TeacherFeedback'], 'No feedback provided');
    final isLate = _safeBool(submission['IsLateSubmission']);
    final daysLate = _safeNum(submission['DaysLate']).toInt();
    final filePath = submission['SubmissionFilePath'];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: AppTheme.defaultBorderRadius * 1.5), // 20.0
        backgroundColor: AppTheme.background,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogHeader(ctx,
                  icon: Iconsax.document_text, title: 'Submission Details'),
              Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      _buildDetailRow('Student Name', studentName, Iconsax.user),
                  _buildDetailRow('Class', classSection, Iconsax.book),
                  _buildDetailRow(
                      'Submission Date',
                      submissionDate != null
                          ? DateFormat('MMM dd, yyyy hh:mm a')
                  .format(DateTime.parse(submissionDate))
                  : 'N/A',
              Iconsax.calendar,
              ),
              _buildDetailRow('Status', gradeStatus, Iconsax.info_circle),
              if (gradeStatus != 'Pending') ...[
                _buildDetailRow('Marks Obtained',
                    marksObtained.toStringAsFixed(1), Iconsax.medal_star),
                if (penalty > 0)
                  _buildDetailRow('Penalty',
                      '-${penalty.toStringAsFixed(1)}', Iconsax.minus_cirlce),
                _buildDetailRow(
                    'Final Marks',
                    '${marks.toStringAsFixed(1)} / ${widget.totalMarks}',
                    Iconsax.chart),
              ],
              if (isLate)
                _buildDetailRow('Late Submission', '$daysLate days late',
                    Iconsax.clock,
                    color: AppTheme.mackColor),
              const SizedBox(height: 16),
              if (gradeStatus != 'Pending') ...[
                Text(
                  'Teacher Feedback',
                  style: AppTheme.labelText.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGrey,
                    borderRadius: AppTheme.defaultBorderRadius, // 12.0
                  ),
                  child: Text(
                    feedback,
                    style: AppTheme.bodyText1.copyWith(
                        color: AppTheme.darkText),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (filePath != null && filePath.toString().isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final url =
                      getFullDocumentUrl(filePath.toString());
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon:
                    const Icon(Iconsax.document_download, size: 18),
                    label: Text('View Submission',
                        style: AppTheme.buttonText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme
                          .assignmentColor, // Use new theme color
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        AppTheme.defaultBorderRadius, // 12.0
                      ),
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
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 18,
              color: color ?? AppTheme.assignmentColor), // Use new theme color
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodyText1.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.labelText.copyWith(
                    fontSize: 16, // Made value larger
                    color: color ?? AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGradingDialog(Map<String, dynamic> submission) {
    final marksController = TextEditingController(
      text: submission['MarksObtained']?.toString() ?? '',
    );
    final feedbackController = TextEditingController(
      text: submission['TeacherFeedback'] ?? '',
    );
    final submissionRecNo = submission['SubmissionRecNo'];
    final studentName = _safeString(submission['StudentName'], 'Unknown');
    final isPending = _safeString(submission['GradeStatus']) == 'Pending';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              borderRadius: AppTheme.defaultBorderRadius * 1.5, // 20.0
              color: AppTheme.background,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowColor.withOpacity(0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildDialogHeader(
                  ctx,
                  icon: isPending ? Iconsax.edit : Iconsax.refresh,
                  title: isPending ? 'Grade Submission' : 'Update Grade',
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student: $studentName',
                        style: AppTheme.bodyText1.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      // Marks
                      Text(
                        'Marks Obtained',
                        style: AppTheme.labelText.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: marksController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppTheme.labelText.copyWith(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Enter marks (0-${widget.totalMarks})',
                          hintStyle: AppTheme.bodyText1,
                          prefixIcon: const Icon(
                            Iconsax.medal_star,
                            color: AppTheme.assignmentColor,
                          ),
                          suffixText: '/ ${widget.totalMarks}',
                          filled: true,
                          fillColor: AppTheme.lightGrey,
                          border: OutlineInputBorder(
                            borderRadius: AppTheme.defaultBorderRadius, // 12.0
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppTheme.defaultBorderRadius, // 12.0
                            borderSide: BorderSide(
                              color: AppTheme.assignmentColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Feedback
                      Text(
                        'Feedback (Optional)',
                        style: AppTheme.labelText.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: feedbackController,
                        maxLines: 4,
                        style: AppTheme.bodyText1
                            .copyWith(fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Write feedback for the student...',
                          hintStyle: AppTheme.bodyText1,
                          filled: true,
                          fillColor: AppTheme.lightGrey,
                          border: OutlineInputBorder(
                            borderRadius: AppTheme.defaultBorderRadius, // 12.0
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppTheme.defaultBorderRadius, // 12.0
                            borderSide: BorderSide(
                              color: AppTheme.assignmentColor,
                              width: 2,
                            ),
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                marksController.dispose();
                                feedbackController.dispose();
                                Navigator.pop(ctx);
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: AppTheme.lightGrey,
                                foregroundColor: AppTheme.bodyText,
                                padding:
                                const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  AppTheme.defaultBorderRadius, // 10.0
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: AppTheme.buttonText.copyWith(
                                    color: AppTheme.darkText, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final marks = double.tryParse(
                                  marksController.text.trim(),
                                );
                                if (marks == null ||
                                    marks < 0 ||
                                    marks > widget.totalMarks) {
                                  CustomSnackbar.showError(
                                    context,
                                    'Marks must be 0-${widget.totalMarks}',
                                  );
                                  return;
                                }

                                try {
                                  await TeacherMaterialService.gradeSubmission(
                                    teacherCode: widget.teacherCode,
                                    submissionRecNo: submissionRecNo,
                                    marksObtained: marks,
                                    teacherFeedback:
                                    feedbackController.text.trim().isEmpty
                                        ? null
                                        : feedbackController.text.trim(),
                                  );

                                  if (mounted) {
                                    marksController.dispose();
                                    feedbackController.dispose();
                                    Navigator.pop(ctx);
                                    await _loadSubmissions();
                                    CustomSnackbar.showSuccess(
                                      context,
                                      'Grade ${isPending ? "submitted" : "updated"} successfully!',
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    CustomSnackbar.showError(
                                        context, 'Error: $e');
                                  }
                                }
                              },
                              icon: Icon(
                                isPending
                                    ? Iconsax.tick_circle
                                    : Iconsax.refresh,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(
                                isPending ? 'Submit Grade' : 'Update Grade',
                                style:
                                AppTheme.buttonText.copyWith(fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.assignmentColor,
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  AppTheme.defaultBorderRadius, // 10.0
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
}