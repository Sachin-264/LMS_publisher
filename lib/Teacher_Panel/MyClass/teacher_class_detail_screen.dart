import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Teacher_Panel/MyClass/teacher_subject_chapter_screen.dart';
import 'package:lms_publisher/Teacher_Panel/MyClass/student_detail_screen.dart';
import 'package:lms_publisher/Teacher_Panel/teacher_panel_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';
import 'package:provider/provider.dart';

class TeacherClassDetailScreen extends StatefulWidget {
  final int classRecNo;
  final String className;
  final String sectionName;
  final List subjects;
  final String academicYear;

  const TeacherClassDetailScreen({
    super.key,
    required this.classRecNo,
    required this.className,
    required this.sectionName,
    required this.subjects,
    required this.academicYear,
  });

  @override
  State<TeacherClassDetailScreen> createState() =>
      _TeacherClassDetailScreenState();
}

class _TeacherClassDetailScreenState extends State<TeacherClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingStudents = true;
  List _students = [];
  String _teacherCode = '';

  // CHANGED: Added your image base URL
  static const String _imageBaseUrl =
      "https://storage.googleapis.com/upload-images-34/images/LMS/";

  // For colorful cards
  final List<Color> _cardColors = [
    AppTheme.primaryGreen,
    AppTheme.mackColor,
    AppTheme.cleoColor,
    const Color(0xFF6366F1), // Indigo
    const Color(0xFFEC4899), // Pink
    const Color(0xFF8B5CF6), // Purple
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStudents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoadingStudents = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _teacherCode = userProvider.userCode ?? '';
      final classRecNo = widget.classRecNo;

      if (_teacherCode.isEmpty) {
        throw Exception("Teacher code not found. Please log in again.");
      }

      final data = await TeacherPanelService.getStudentsList(
        teacherCode: _teacherCode,
        classRecNo: classRecNo,
      );

      setState(() {
        _students = data['students'] ?? [];
        _isLoadingStudents = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStudents = false;
      });
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to load students: $e');
      }
    }
  }

  Future<void> _openStudentDetail(Map studentBasicData) async {
    // Try to find the student ID from various possible field names
    int? studentRecNo;

    if (studentBasicData['RecNo'] != null) {
      studentRecNo = int.tryParse(studentBasicData['RecNo'].toString());
    } else if (studentBasicData['StudentRecNo'] != null) {
      // This will match your new JSON
      studentRecNo = int.tryParse(studentBasicData['StudentRecNo'].toString());
    } else if (studentBasicData['Student_RecNo'] != null) {
      studentRecNo = int.tryParse(studentBasicData['Student_RecNo'].toString());
    } else if (studentBasicData['StudentID'] != null) {
      studentRecNo = int.tryParse(studentBasicData['StudentID'].toString());
    }

    if (studentRecNo == null) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Student ID not found');
      }
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
          child: BeautifulLoader(
            type: LoaderType.pulse,
            color: AppTheme.primaryGreen,
          )),
    );

    try {
      final profileData = await TeacherPanelService.getStudentProfile(
        teacherCode: _teacherCode,
        studentRecNo: studentRecNo,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Navigate to detail screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDetailScreen(
              studentData: profileData['student'] ?? studentBasicData,
              teacherCode: _teacherCode,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      // Show error
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to load profile: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          _buildPillTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSubjectsTab(),
                _buildStudentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left, color: AppTheme.darkText),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '${widget.className} - ${widget.sectionName}',
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
          color: AppTheme.borderGrey,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: AppTheme.defaultBorderRadius * 1.5, // 18.0
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: AppTheme.defaultBorderRadius, // 12.0
            ),
            child: const Icon(Iconsax.building_3, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.className} - ${widget.sectionName}',
                  style: AppTheme.headline2.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildHeaderStat(
                        Iconsax.book_1, '${widget.subjects.length} Subjects'),
                    const SizedBox(width: 16),
                    _buildHeaderStat(Iconsax.profile_2user,
                        '${_students.length} Students'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.9)),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTheme.buttonText.copyWith(
            fontSize: 13,
            color: Colors.white.withOpacity(0.95),
          ),
        ),
      ],
    );
  }

  Widget _buildPillTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor.withOpacity(0.7),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppTheme.primaryGreen,
        unselectedLabelColor: AppTheme.bodyText,
        labelStyle: AppTheme.labelText.copyWith(fontSize: 14),
        unselectedLabelStyle: AppTheme.labelText
            .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Iconsax.book_1, size: 18),
                SizedBox(width: 8),
                Text('Subjects'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Iconsax.profile_2user, size: 18),
                SizedBox(width: 8),
                Text('Students'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: widget.subjects.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final subject = widget.subjects[index];
        final color = _cardColors[index % _cardColors.length];
        return _buildSubjectCard(subject, color);
      },
    );
  }

  Widget _buildSubjectCard(Map subject, Color color) {
    final avgPerformance =
        double.tryParse(subject['AveragePerformance']?.toString() ?? '0') ?? 0.0;
    final materialsCount = subject['MaterialsCount'] ?? 0;
    final subjectId =
        subject['SubjectID']?.toString() ?? subject['subjectID']?.toString() ?? '';
    final subjectName = subject['SubjectName'] ?? subject['subjectName'] ?? '';

    return InkWell(
      onTap: () async {
        if (subjectId.isEmpty) {
          CustomSnackbar.showError(context, 'Subject ID is missing');
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherSubjectChaptersScreen(
              teacherCode:
              Provider.of<UserProvider>(context, listen: false).userCode ??
                  '',
              subjectId: subjectId,
              subjectName: subjectName,
              subjectColor: color, // Pass the dynamic color
              classRecNo: widget.classRecNo,
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
              color: AppTheme.shadowColor,
              blurRadius: 12,
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
                    color: color.withOpacity(0.1),
                    borderRadius: AppTheme.defaultBorderRadius, // 12.0
                  ),
                  child: Icon(Iconsax.book_1, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        style: AppTheme.headline1.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Subject ID: $subjectId',
                        style: AppTheme.bodyText1.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Iconsax.arrow_right_3,
                  size: 20,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSubjectStat(
                    Iconsax.document_text,
                    '$materialsCount',
                    'Materials',
                    AppTheme.cleoColor, // Use a brand color
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSubjectStat(
                    Iconsax.chart_21,
                    '${avgPerformance.toStringAsFixed(1)}%',
                    'Avg Score',
                    AppTheme.accentGreen, // Use a brand color
                  ),
                ),
              ],
            ),
            if (subject['CurrentChapter'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey,
                  borderRadius: AppTheme.defaultBorderRadius, // 10.0
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.book, size: 16, color: AppTheme.bodyText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current: ${subject['CurrentChapter']}',
                        style: AppTheme.bodyText1.copyWith(
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectStat(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: AppTheme.defaultBorderRadius, // 10.0
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTheme.labelText.copyWith(
                    fontSize: 16, color: AppTheme.darkText),
              ),
              Text(
                label,
                style: AppTheme.bodyText1.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTab() {
    if (_isLoadingStudents) {
      return Center(
          child: BeautifulLoader(
            type: LoaderType.pulse,
            color: AppTheme.primaryGreen,
            size: 80,
            message: 'Loading students...',
          ));
    }

    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.profile_2user,
                size: 64, color: AppTheme.bodyText.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'No Students Found',
              style: AppTheme.headline1.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'No students are enrolled in this class',
              style: AppTheme.bodyText1,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _students.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final student = _students[index];
        final color = _cardColors[index % _cardColors.length];
        return _buildStudentCard(student, color);
      },
    );
  }

  // --- WIDGET FULLY UPDATED ---
  Widget _buildStudentCard(Map student, Color color) {
    // CHANGED: Get new data fields from JSON
    final rollNo = student['Roll_Number'] ?? 'N/A';
    final statusId = student['Status_ID'];
    final statusText = (statusId == 1) ? 'Active' : 'Inactive';
    final photoPath = student['Student_Photo_Path'] as String?;

    // CHANGED: Check for photo and build URL
    final bool hasPhoto = photoPath != null && photoPath.isNotEmpty;
    final String? photoUrl = hasPhoto ? _imageBaseUrl + photoPath : null;

    return InkWell(
      onTap: () => _openStudentDetail(student),
      borderRadius: AppTheme.defaultBorderRadius * 1.5, // 18.0
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: AppTheme.defaultBorderRadius * 1.5, // 18.0
          border: Border.all(color: AppTheme.borderGrey, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // CHANGED: Avatar with gradient and photo
            CircleAvatar(
              radius: 32.5, // 65 / 2
              backgroundColor: color.withOpacity(0.2),
              // CHANGED: Use NetworkImage for photo
              backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
              // CHANGED: Fallback to initials if no photo
              child: hasPhoto
                  ? null
                  : Text(
                _getInitials(student['StudentName'] ?? ''),
                style: AppTheme.headline2
                    .copyWith(fontSize: 22, color: color),
              ),
            ),
            const SizedBox(width: 16),

            // Student info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['StudentName'] ?? 'Unknown',
                    style: AppTheme.labelText.copyWith(
                        fontSize: 16, color: AppTheme.darkText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.user, size: 12, color: color),
                            const SizedBox(width: 4),
                            // CHANGED: Use corrected rollNo variable
                            Text(
                              'Roll: $rollNo',
                              style: AppTheme.labelText
                                  .copyWith(fontSize: 11, color: color),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          // CHANGED: Use a different color for status if it's inactive
                          color: (statusId == 1
                              ? AppTheme.accentGreen
                              : AppTheme.cleoColor)
                              .withOpacity(0.1),
                          borderRadius: AppTheme.defaultBorderRadius, // 12.0
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              // CHANGED: Show different icon for status
                              statusId == 1
                                  ? Iconsax.tick_circle
                                  : Iconsax.info_circle,
                              size: 10,
                              color: statusId == 1
                                  ? AppTheme.accentGreen
                                  : AppTheme.cleoColor,
                            ),
                            const SizedBox(width: 4),
                            // CHANGED: Use corrected statusText variable
                            Text(
                              statusText,
                              style: AppTheme.labelText.copyWith(
                                fontSize: 10,
                                color: statusId == 1
                                    ? AppTheme.accentGreen
                                    : AppTheme.cleoColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: AppTheme.defaultBorderRadius, // 10.0
              ),
              child: Icon(Iconsax.arrow_right_3, color: color, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      if (parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
}