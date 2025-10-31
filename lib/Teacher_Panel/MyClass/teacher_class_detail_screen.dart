import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Teacher_Panel/MyClass/subject_chapter_screen.dart';
import 'package:lms_publisher/Teacher_Panel/MyClass/student_detail_screen.dart';
import 'package:lms_publisher/Teacher_Panel/teacher_panel_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

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
  State<TeacherClassDetailScreen> createState() => _TeacherClassDetailScreenState();
}

class _TeacherClassDetailScreenState extends State<TeacherClassDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingStudents = true;
  List _students = [];
  String _teacherCode = '';

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
    if (kDebugMode) {
      print('\n========================================');
      print('👥 LOADING STUDENTS LIST');
      print('========================================');
    }

    setState(() {
      _isLoadingStudents = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _teacherCode = userProvider.userCode ?? '';
      final classRecNo = widget.classRecNo;

      if (kDebugMode) {
        print('👨🏫 Teacher Code: $_teacherCode');
        print('🏫 Class RecNo: $classRecNo');
      }

      final data = await TeacherPanelService.getStudentsList(
        teacherCode: _teacherCode,
        classRecNo: classRecNo,
      );

      if (kDebugMode) {
        print('✅ Students loaded successfully');
        print('📊 Total Students: ${data['students']?.length ?? 0}');
        if (data['students'] != null && data['students'].isNotEmpty) {
          print('📋 First Student Sample: ${data['students'][0]}');
          print('📋 Available Keys: ${data['students'][0].keys.toList()}');
        }
      }

      setState(() {
        _students = data['students'] ?? [];
        _isLoadingStudents = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading students: $e');
        print('❌ Stack trace: ${StackTrace.current}');
      }

      setState(() {
        _isLoadingStudents = false;
      });
      CustomSnackbar.showError(context, 'Failed to load students: $e');
    }
  }


  Future<void> _openStudentDetail(Map studentBasicData) async {
    if (kDebugMode) {
      print('\n========================================');
      print('📖 OPENING STUDENT DETAIL');
      print('========================================');
      print('👤 Student Data (FULL): $studentBasicData');
      print('👤 Student Name: ${studentBasicData['StudentName']}');
      print('🔍 Checking for ID fields...');
      print('   - RecNo: ${studentBasicData['RecNo']}');
      print('   - StudentRecNo: ${studentBasicData['StudentRecNo']}');
      print('   - StudentID: ${studentBasicData['StudentID']}');
      print('   - Student_RecNo: ${studentBasicData['Student_RecNo']}');
    }

    // Try to find the student ID from various possible field names
    int? studentRecNo;

    if (studentBasicData['RecNo'] != null) {
      studentRecNo = int.tryParse(studentBasicData['RecNo'].toString());
    } else if (studentBasicData['StudentRecNo'] != null) {
      studentRecNo = int.tryParse(studentBasicData['StudentRecNo'].toString());
    } else if (studentBasicData['Student_RecNo'] != null) {
      studentRecNo = int.tryParse(studentBasicData['Student_RecNo'].toString());
    } else if (studentBasicData['StudentID'] != null) {
      studentRecNo = int.tryParse(studentBasicData['StudentID'].toString());
    }

    if (studentRecNo == null) {
      if (kDebugMode) {
        print('❌ Could not find valid student RecNo in data');
      }
      if (mounted) {
        CustomSnackbar.showError(context, 'Student ID not found');
      }
      return;
    }

    if (kDebugMode) {
      print('✅ Found Student RecNo: $studentRecNo');
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: BeautifulLoader()),
    );

    try {
      if (kDebugMode) {
        print('🔍 Fetching detailed profile for RecNo: $studentRecNo');
      }

      final profileData = await TeacherPanelService.getStudentProfile(
        teacherCode: _teacherCode,
        studentRecNo: studentRecNo,
      );

      if (kDebugMode) {
        print('✅ Profile loaded successfully');
        print('📦 Full Response: $profileData');
        print('📦 Student Data: ${profileData['student']}');
      }

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
      if (kDebugMode) {
        print('❌ Error fetching student profile: $e');
        print('❌ Stack trace: ${StackTrace.current}');
      }

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
      backgroundColor: Colors.grey.shade50,
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
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left, color: AppTheme.darkText),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '${widget.className} - ${widget.sectionName}',
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
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.book_square, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.className} - ${widget.sectionName}',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildHeaderStat(Iconsax.book_1, '${widget.subjects.length} Subjects'),
                    const SizedBox(width: 16),
                    _buildHeaderStat(Iconsax.profile_2user, '${_students.length} Students'),
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
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppTheme.primaryGreen,
        unselectedLabelColor: AppTheme.bodyText,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.book_1, size: 18),
                const SizedBox(width: 8),
                Text('Subjects'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.profile_2user, size: 18),
                const SizedBox(width: 8),
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
        return _buildSubjectCard(subject);
      },
    );
  }

  Widget _buildSubjectCard(Map subject) {
    final avgPerformance = double.tryParse(subject['AveragePerformance']?.toString() ?? '0') ?? 0.0;
    final materialsCount = subject['MaterialsCount'] ?? 0;
    final subjectId = subject['SubjectID']?.toString() ?? subject['subjectID']?.toString() ?? '';
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
              teacherCode: Provider.of<UserProvider>(context, listen: false).userCode ?? '',
              subjectId: subjectId,
              subjectName: subjectName,
              subjectColor: Colors.blue,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.book_1, color: AppTheme.primaryGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Subject ID: $subjectId',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.bodyText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Iconsax.arrow_right_3,
                  size: 20,
                  color: AppTheme.primaryGreen,
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
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSubjectStat(
                    Iconsax.chart_21,
                    '${avgPerformance.toStringAsFixed(1)}%',
                    'Avg Score',
                    AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            if (subject['CurrentChapter'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.book, size: 16, color: AppTheme.bodyText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current: ${subject['CurrentChapter']}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.bodyText,
                          fontWeight: FontWeight.w500,
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

  Widget _buildSubjectStat(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
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
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.bodyText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTab() {
    if (_isLoadingStudents) {
      return const Center(child: BeautifulLoader());
    }

    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.profile_2user, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No Students Found',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No students are enrolled in this class',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.bodyText,
              ),
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
        return _buildStudentCard(student, index);
      },
    );
  }

  Widget _buildStudentCard(Map student, int index) {
    final colors = [
      Colors.blue,
      Colors.purple,
      AppTheme.primaryGreen,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.cyan,
    ];
    final color = colors[index % colors.length];

    return InkWell(
      onTap: () => _openStudentDetail(student),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with gradient
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getInitials(student['StudentName'] ?? ''),
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
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
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.user, size: 12, color: color),
                            const SizedBox(width: 4),
                            Text(
                              'Roll: ${student['RollNo'] ?? 'N/A'}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.tick_circle, size: 10, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              student['Status'] ?? 'Active',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
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
                borderRadius: BorderRadius.circular(10),
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
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
