import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Teacher_Panel/teacher_panel_service.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';

const String _imageBaseUrl = "https://storage.googleapis.com/upload-images-34/images/LMS/";

class StudentDetailScreen extends StatefulWidget {
  final Map studentData;
  final String teacherCode;

  const StudentDetailScreen({
    super.key,
    required this.studentData,
    required this.teacherCode,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _noteController = TextEditingController();
  bool _isAddingNote = false;
  bool _isLoadingProfile = false;
  Map? _fullProfileData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (kDebugMode) {
      print('\n========================================');
      print('📄 STUDENT DETAIL SCREEN OPENED');
      print('========================================');
      print('👤 Full Student Data: ${widget.studentData}');
      print('🔑 Available Keys: ${widget.studentData.keys.toList()}');
      print('👨‍🏫 Teacher Code: ${widget.teacherCode}');
    }
    _loadFullProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadFullProfile() async {
    setState(() => _isLoadingProfile = true);

    try {
      int? studentRecNo = int.tryParse(widget.studentData['StudentRecNo']?.toString() ?? '');

      if (studentRecNo != null) {
        final response = await TeacherPanelService.getStudentProfile(
          teacherCode: widget.teacherCode,
          studentRecNo: studentRecNo,
        );

        if (kDebugMode) {
          print('📦 Full Profile Response: $response');
        }

        setState(() {
          // API returns student_info, not student
          _fullProfileData = response['student_info'] as Map?;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading full profile: $e');
      }
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) {
      CustomSnackbar.showError(context, 'Please enter a note');
      return;
    }

    int? studentRecNo = int.tryParse(widget.studentData['StudentRecNo']?.toString() ?? '');

    if (studentRecNo == null) {
      CustomSnackbar.showError(context, 'Student ID not found');
      return;
    }

    if (kDebugMode) {
      print('\n📝 Adding note for student $studentRecNo');
    }

    setState(() => _isAddingNote = true);

    try {
      await TeacherPanelService.addStudentNote(
        teacherCode: widget.teacherCode,
        studentRecNo: studentRecNo,
        noteText: _noteController.text,
        noteCategory: 'General',
        isPrivate: true,
      );

      if (mounted) {
        _noteController.clear();
        CustomSnackbar.showSuccess(context, 'Note added successfully');
        _loadFullProfile(); // Reload to get updated notes
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding note: $e');
      }
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to add note: $e');
      }
    } finally {
      setState(() => _isAddingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoPath = widget.studentData['Student_Photo_Path'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryGreen,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryGreen,
                        AppTheme.primaryGreen.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            // Profile Picture
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: photoPath.isNotEmpty
                                    ? CachedNetworkImage(
                                  imageUrl: '$_imageBaseUrl$photoPath',
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.white,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.white,
                                    child: Center(
                                      child: Text(
                                        _getInitials(widget.studentData['StudentName'] ?? ''),
                                        style: GoogleFonts.inter(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.primaryGreen,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                    : Container(
                                  color: Colors.white,
                                  child: Center(
                                    child: Text(
                                      _getInitials(widget.studentData['StudentName'] ?? ''),
                                      style: GoogleFonts.inter(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Name
                            Text(
                              widget.studentData['StudentName'] ?? 'Unknown',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            // Roll Number Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Iconsax.user, color: Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Roll: ${widget.studentData['Roll_Number'] ?? 'N/A'}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            _buildQuickStats(),
            _buildPillTabBar(),
            Expanded(
              child: _isLoadingProfile
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildAcademicsTab(),
                  _buildNotesTab(),
                  _buildActivityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickStat(
            Iconsax.award,
            'Attendance',
            '${_fullProfileData?['AttendancePercentage'] ?? 'N/A'}%',
            Colors.blue,
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _buildQuickStat(
            Iconsax.chart_21,
            'Performance',
            '${_fullProfileData?['OverallPercentage'] ?? 'N/A'}%',
            Colors.green,
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _buildQuickStat(
            Iconsax.book,
            'Chapters',
            '${_fullProfileData?['CompletedChapters'] ?? 0}',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
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
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(icon: Icon(Iconsax.user, size: 16), text: 'Overview'),
          Tab(icon: Icon(Iconsax.book, size: 16), text: 'Academics'),
          Tab(icon: Icon(Iconsax.note_text, size: 16), text: 'Notes'),
          Tab(icon: Icon(Iconsax.activity, size: 16), text: 'Activity'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoSection(
            'Personal Information',
            Iconsax.user,
            Colors.blue,
            [
              _buildInfoRow('Full Name', widget.studentData['StudentName'] ?? 'N/A'),
              _buildInfoRow('First Name', widget.studentData['First_Name'] ?? 'N/A'),
              _buildInfoRow('Middle Name', widget.studentData['Middle_Name'] ?? 'N/A'),
              _buildInfoRow('Last Name', widget.studentData['Last_Name'] ?? 'N/A'),
              _buildInfoRow('Gender', widget.studentData['Gender'] ?? 'N/A'),
              _buildInfoRow('Date of Birth', widget.studentData['Date_of_Birth'] ?? 'N/A'),
              _buildInfoRow('Age', '${widget.studentData['Age'] ?? 'N/A'} years'),
              _buildInfoRow('Blood Group', _fullProfileData?['Blood_Group'] ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoSection(
            'Contact Details',
            Iconsax.call,
            Colors.green,
            [
              _buildInfoRow('Mobile', widget.studentData['Mobile_Number'] ?? 'N/A'),
              _buildInfoRow('Email', widget.studentData['Email_ID'] ?? 'N/A'),
              _buildInfoRow('Current Address', _fullProfileData?['Current_Address'] ?? 'N/A'),
              _buildInfoRow('Permanent Address', _fullProfileData?['Permanent_Address'] ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoSection(
            'Family Information',
            Iconsax.profile_2user,
            Colors.purple,
            [
              _buildInfoRow('Father Name', widget.studentData['Father_Name'] ?? 'N/A'),
              _buildInfoRow('Father Mobile', widget.studentData['Father_Mobile_Number'] ?? 'N/A'),
              _buildInfoRow('Mother Name', _fullProfileData?['Mother_Name'] ?? 'N/A'),
              _buildInfoRow('Mother Mobile', _fullProfileData?['MotherMobile'] ?? 'N/A'),
              _buildInfoRow('Guardian Name', _fullProfileData?['Guardian_Name'] ?? 'N/A'),
              _buildInfoRow('Guardian Contact', _fullProfileData?['GuardianContact'] ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoSection(
            'Academic Details',
            Iconsax.book_square,
            Colors.orange,
            [
              _buildInfoRow('Admission Number', widget.studentData['Admission_Number'] ?? 'N/A'),
              _buildInfoRow('Class', widget.studentData['Class_Name'] ?? 'N/A'),
              _buildInfoRow('Section', widget.studentData['Section_Name'] ?? 'N/A'),
              _buildInfoRow('Roll Number', widget.studentData['Roll_Number']?.toString() ?? 'N/A'),
              _buildInfoRow('Academic Year', _fullProfileData?['Academic_Year'] ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoSection(
            'Performance Metrics',
            Iconsax.chart_21,
            Colors.teal,
            [
              _buildInfoRow('Overall Percentage', '${_fullProfileData?['OverallPercentage'] ?? 'N/A'}%'),
              _buildInfoRow('Total Assessments', '${_fullProfileData?['TotalAssessments'] ?? 0}'),
              _buildInfoRow('Completed Chapters', '${_fullProfileData?['CompletedChapters'] ?? 0}'),
              _buildInfoRow('In Progress Chapters', '${_fullProfileData?['InProgressChapters'] ?? 0}'),
              _buildInfoRow('Study Minutes', '${_fullProfileData?['TotalStudyMinutes'] ?? 0} mins'),
              _buildInfoRow('Last Active', _fullProfileData?['LastActive'] ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
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
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Iconsax.edit, color: Colors.purple, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add New Note',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Write a private note about this student...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isAddingNote ? null : _addNote,
                      icon: _isAddingNote
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Icon(Iconsax.add, color: Colors.white), // make icon white too
                      label: Text(
                        _isAddingNote ? 'Adding Note...' : 'Add Note',
                        style: const TextStyle(color: Colors.white), // text color white
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white, // ensures white text/icon for all states
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  ],
            ),
          ),
          const SizedBox(height: 20),
          // Display existing notes
          if (_fullProfileData?['teacher_notes'] != null && (_fullProfileData!['teacher_notes'] as List).isNotEmpty)
            ...(_fullProfileData!['teacher_notes'] as List).map((note) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note['NoteText'] ?? '',
                      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.darkText),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note['Created_Date'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.bodyText,
                      ),
                    ),
                  ],
                ),
              );
            }).toList()
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Iconsax.note_text, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No notes yet',
                      style: GoogleFonts.inter(
                        color: AppTheme.bodyText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_fullProfileData?['recent_scores'] != null && (_fullProfileData!['recent_scores'] as List).isNotEmpty)
            _buildScoresSection()
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Iconsax.activity, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No activity recorded',
                      style: GoogleFonts.inter(
                        color: AppTheme.bodyText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoresSection() {
    final scores = _fullProfileData!['recent_scores'] as List;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: scores.map((score) {
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.document_text, color: Colors.blue, size: 20),
            ),
            title: Text(
              score['AssessmentName'] ?? 'Assessment',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(score['Date'] ?? ''),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${score['Score']}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.bodyText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
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
