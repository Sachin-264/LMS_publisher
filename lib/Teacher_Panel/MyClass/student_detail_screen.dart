import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Teacher_Panel/teacher_panel_service.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';

const String _imageBaseUrl =
    "https://storage.googleapis.com/upload-images-34/images/LMS/";

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

class _StudentDetailScreenState extends State<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _noteController = TextEditingController();
  bool _isAddingNote = false;
  bool _isLoadingProfile = true; // Start as true
  Map? _fullProfileData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      int? studentRecNo =
      int.tryParse(widget.studentData['StudentRecNo']?.toString() ?? '');

      if (studentRecNo != null) {
        final response = await TeacherPanelService.getStudentProfile(
          teacherCode: widget.teacherCode,
          studentRecNo: studentRecNo,
        );

        setState(() {
          _fullProfileData = response['student_info'] as Map?;
          _isLoadingProfile = false;
        });
      } else {
        throw Exception('Invalid StudentRecNo');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading full profile: $e');
      }
      if (mounted) {
        CustomSnackbar.showError(
            context, 'Failed to load full profile: $e',
            title: 'Error');
      }
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) {
      CustomSnackbar.showError(context, 'Please enter a note');
      return;
    }

    int? studentRecNo =
    int.tryParse(widget.studentData['StudentRecNo']?.toString() ?? '');

    if (studentRecNo == null) {
      CustomSnackbar.showError(context, 'Student ID not found');
      return;
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
      if (mounted) {
        setState(() => _isAddingNote = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoPath = widget.studentData['Student_Photo_Path'] ?? '';

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryGreen,
              leading: IconButton(
                icon: const Icon(Iconsax.arrow_left, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
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
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 4),
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
                                    color: AppTheme.background,
                                    child: Center(
                                      child: BeautifulLoader(
                                          type: LoaderType.circular,
                                          size: 30),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      _buildInitialsFallback(),
                                )
                                    : _buildInitialsFallback(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Name
                            Text(
                              widget.studentData['StudentName'] ?? 'Unknown',
                              style: AppTheme.headline2.copyWith(fontSize: 24),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            // Roll Number Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Iconsax.user,
                                      color: Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Roll: ${widget.studentData['Roll_Number'] ?? 'N/A'}',
                                    style: AppTheme.buttonText.copyWith(
                                        fontSize: 13),
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
                  ? Center(
                  child: BeautifulLoader(
                    type: LoaderType.pulse,
                    size: 80,
                    color: AppTheme.primaryGreen,
                    message: 'Loading profile...',
                  ))
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

  Widget _buildInitialsFallback() {
    return Container(
      color: AppTheme.background,
      child: Center(
        child: Text(
          _getInitials(widget.studentData['StudentName'] ?? ''),
          style: AppTheme.headline2.copyWith(
            fontSize: 40,
            color: AppTheme.primaryGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: AppTheme.defaultBorderRadius * 1.5, // 18.0
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
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
            AppTheme.cleoColor, // Brand color
          ),
          Container(width: 1, height: 40, color: AppTheme.borderGrey),
          _buildQuickStat(
            Iconsax.chart_21,
            'Performance',
            '${_fullProfileData?['OverallPercentage'] ?? 'N/A'}%',
            AppTheme.accentGreen, // Brand color
          ),
          Container(width: 1, height: 40, color: AppTheme.borderGrey),
          _buildQuickStat(
            Iconsax.book,
            'Chapters',
            '${_fullProfileData?['CompletedChapters'] ?? 0}',
            AppTheme.mackColor, // Brand color
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.headline1.copyWith(fontSize: 18),
        ),
        Text(
          label,
          style: AppTheme.bodyText1.copyWith(
            fontSize: 11,
            color: AppTheme.bodyText,
          ),
        ),
      ],
    );
  }

  Widget _buildPillTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
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
        labelStyle: AppTheme.labelText.copyWith(fontSize: 12),
        unselectedLabelStyle: AppTheme.labelText.copyWith(
            fontSize: 12, fontWeight: FontWeight.w600),
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildInfoSection(
            'Personal Information',
            Iconsax.user,
            [
              _buildInfoRow(
                  'Full Name', widget.studentData['StudentName'] ?? 'N/A'),
              _buildInfoRow(
                  'First Name', widget.studentData['First_Name'] ?? 'N/A'),
              _buildInfoRow(
                  'Middle Name', widget.studentData['Middle_Name'] ?? 'N/A'),
              _buildInfoRow(
                  'Last Name', widget.studentData['Last_Name'] ?? 'N/A'),
              _buildInfoRow('Gender', widget.studentData['Gender'] ?? 'N/A'),
              _buildInfoRow(
                  'Date of Birth', widget.studentData['Date_of_Birth'] ?? 'N/A'),
              _buildInfoRow('Age', '${widget.studentData['Age'] ?? 'N/A'} years'),
              _buildInfoRow(
                  'Blood Group', _fullProfileData?['Blood_Group'] ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoSection(
            'Contact Details',
            Iconsax.call,
            [
              _buildInfoRow(
                  'Mobile', widget.studentData['Mobile_Number'] ?? 'N/A'),
              _buildInfoRow('Email', widget.studentData['Email_ID'] ?? 'N/A'),
              _buildInfoRow('Current Address',
                  _fullProfileData?['Current_Address'] ?? 'N/A'),
              _buildInfoRow('Permanent Address',
                  _fullProfileData?['Permanent_Address'] ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoSection(
            'Family Information',
            Iconsax.profile_2user,
            [
              _buildInfoRow(
                  'Father Name', widget.studentData['Father_Name'] ?? 'N/A'),
              _buildInfoRow('Father Mobile',
                  widget.studentData['Father_Mobile_Number'] ?? 'N/A'),
              _buildInfoRow(
                  'Mother Name', _fullProfileData?['Mother_Name'] ?? 'N/A'),
              _buildInfoRow(
                  'Mother Mobile', _fullProfileData?['MotherMobile'] ?? 'N/A'),
              _buildInfoRow('Guardian Name',
                  _fullProfileData?['Guardian_Name'] ?? 'N/A'),
              _buildInfoRow('Guardian Contact',
                  _fullProfileData?['GuardianContact'] ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildInfoSection(
            'Academic Details',
            Iconsax.book_square,
            [
              _buildInfoRow('Admission Number',
                  widget.studentData['Admission_Number'] ?? 'N/A'),
              _buildInfoRow(
                  'Class', widget.studentData['Class_Name'] ?? 'N/A'),
              _buildInfoRow(
                  'Section', widget.studentData['Section_Name'] ?? 'N/A'),
              _buildInfoRow('Roll Number',
                  widget.studentData['Roll_Number']?.toString() ?? 'N/A'),
              _buildInfoRow('Academic Year',
                  _fullProfileData?['Academic_Year'] ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoSection(
            'Performance Metrics',
            Iconsax.chart_21,
            [
              _buildInfoRow('Overall Percentage',
                  '${_fullProfileData?['OverallPercentage'] ?? 'N/A'}%'),
              _buildInfoRow('Total Assessments',
                  '${_fullProfileData?['TotalAssessments'] ?? 0}'),
              _buildInfoRow('Completed Chapters',
                  '${_fullProfileData?['CompletedChapters'] ?? 0}'),
              _buildInfoRow('In Progress Chapters',
                  '${_fullProfileData?['InProgressChapters'] ?? 0}'),
              _buildInfoRow('Study Minutes',
                  '${_fullProfileData?['TotalStudyMinutes'] ?? 0} mins'),
              _buildInfoRow(
                  'Last Active', _fullProfileData?['LastActive'] ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    final notes = _fullProfileData?['teacher_notes'] as List?;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: AppTheme.defaultBorderRadius * 1.5, // 18.0
              border: Border.all(color: AppTheme.borderGrey),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowColor,
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
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: AppTheme.defaultBorderRadius, // 12.0
                      ),
                      child: const Icon(Iconsax.edit,
                          color: AppTheme.primaryGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add New Note',
                      style: AppTheme.headline1.copyWith(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Write a private note about this student...',
                    hintStyle: AppTheme.bodyText1
                        .copyWith(color: AppTheme.bodyText.withOpacity(0.7)),
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.defaultBorderRadius, // 12.0
                      borderSide: BorderSide(color: AppTheme.borderGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppTheme.defaultBorderRadius, // 12.0
                      borderSide: BorderSide(color: AppTheme.borderGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppTheme.defaultBorderRadius, // 12.0
                      borderSide: BorderSide(color: AppTheme.primaryGreen),
                    ),
                    filled: true,
                    fillColor: AppTheme.lightGrey,
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
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Iconsax.add, color: Colors.white),
                    label: Text(
                      _isAddingNote ? 'Adding Note...' : 'Add Note',
                      style: AppTheme.buttonText,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.defaultBorderRadius, // 12.0
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Display existing notes
          if (notes != null && notes.isNotEmpty)
            ...notes.map((note) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: AppTheme.defaultBorderRadius, // 12.0
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note['NoteText'] ?? '',
                      style: AppTheme.bodyText1.copyWith(color: AppTheme.darkText),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note['Created_Date'] ?? '',
                      style: AppTheme.bodyText1
                          .copyWith(fontSize: 11, color: AppTheme.bodyText),
                    ),
                  ],
                ),
              );
            }).toList()
          else
            _buildEmptyTabState(
                Iconsax.note_text, 'No notes yet', 'Add a note above to get started.'),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    final scores = _fullProfileData?['recent_scores'] as List?;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          if (scores != null && scores.isNotEmpty)
            ...scores.map((score) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: AppTheme.defaultBorderRadius, // 12.0
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withOpacity(0.1),
                        borderRadius: AppTheme.defaultBorderRadius, // 12.0
                      ),
                      child: const Icon(Iconsax.document_text,
                          color: AppTheme.accentGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            score['AssessmentName'] ?? 'Assessment',
                            style: AppTheme.labelText,
                          ),
                          Text(
                            score['Date'] ?? '',
                            style: AppTheme.bodyText1.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${score['Score']}',
                        style: AppTheme.labelText.copyWith(
                          color: AppTheme.accentGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList()
          else
            _buildEmptyTabState(Iconsax.activity, 'No activity recorded', 'Student activity will appear here.'),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
      String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: AppTheme.defaultBorderRadius * 1.5, // 18.0
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderGrey),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTheme.headline1.copyWith(fontSize: 16),
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
              style: AppTheme.bodyText1,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: AppTheme.labelText.copyWith(
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTabState(IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(icon, size: 64, color: AppTheme.borderGrey.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTheme.labelText
                  .copyWith(color: AppTheme.bodyText, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: AppTheme.bodyText1,
              textAlign: TextAlign.center,
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