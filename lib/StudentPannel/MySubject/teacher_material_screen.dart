import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/StudentPannel/MySubject/my_subject_screen.dart';
import 'package:lms_publisher/StudentPannel/Service/student_subject_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// ✅ ADDED: Import for the new upload dialog
import 'package:lms_publisher/StudentPannel/MySubject/student_upload_dialog.dart';

const String _imageBaseUrl = "https://storage.googleapis.com/upload-images-34/images/LMS/";
const String _documentBaseUrl = "https://storage.googleapis.com/upload-images-34/documents/LMS/";

class TeacherMaterialsScreen extends StatefulWidget {
  final ChapterModel chapter;
  final String subjectName;
  final int subjectId;
  final Color subjectColor;
  final String studentId;
  final bool isParent;

  final TeacherNavigationData selectedTeacher;
  final List<TeacherNavigationData> allTeachers;
  final List<TeacherNavigationData> otherTeachers;
  final String academicYear;

  const TeacherMaterialsScreen({
    super.key,
    required this.chapter,
    required this.subjectName,
    required this.subjectId,
    required this.subjectColor,
    required this.studentId,
    required this.isParent,
    required this.selectedTeacher,
    required this.allTeachers,
    required this.otherTeachers,
    required this.academicYear,
  });

  @override
  State<TeacherMaterialsScreen> createState() => _TeacherMaterialsScreenState();
}

class _TeacherMaterialsScreenState extends State<TeacherMaterialsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  TeacherMaterialsResponse? _materialsData;

  late TeacherNavigationData _currentTeacher;
  late String _studentCode;

  late TabController _tabController;

  Map<int, String> _assignmentTitleMap = {};

  @override
  void initState() {
    super.initState();
    _currentTeacher = widget.selectedTeacher;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _studentCode = userProvider.userCode ?? '';

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _loadTeacherMaterials();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherMaterials() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await StudentSubjectService.getTeacherMaterials(
        teacherCode: _currentTeacher.teacherCode,
        studentCode: _studentCode,
        chapterId: widget.chapter.chapterId,
      );

      if (mounted) {
        setState(() {
          _materialsData = response;
          _isLoading = false;

          _assignmentTitleMap.clear();
          if (response != null) {
            _assignmentTitleMap = {
              for (var m in response.materials) m.materialRecNo: m.materialTitle
            };
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
        CustomSnackbar.showError(context, _errorMessage!, title: 'Error');
      }
    }
  }

  // ✅ ADDED: Function to show the upload dialog
  void _showUploadDialog(TeacherMaterialModel material) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing on tap outside
      builder: (BuildContext context) {
        return StudentUploadDialog(
          materialRecNo: material.materialRecNo,
          studentCode: _studentCode,
          subjectColor: widget.subjectColor,
          assignmentTitle: material.materialTitle,
        );
      },
    );

    // If the dialog returned true (meaning success), refresh the materials
    if (result == true) {
      _loadTeacherMaterials();
    }
  }


  Future<void> _openDocument(String fileName) async {
    if (fileName.isEmpty) return;

    final String url = '$_documentBaseUrl$fileName';
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        CustomSnackbar.showError(context, 'Could not open document');
      }
    } catch (e) {
      CustomSnackbar.showError(context, 'Error opening document: $e');
    }
  }

  void _switchTeacher(TeacherNavigationData newTeacher) {
    setState(() {
      _currentTeacher = newTeacher;
    });
    _loadTeacherMaterials();
  }

  void _showTeacherSwitcher() {
    if (widget.allTeachers.length <= 1) {
      CustomSnackbar.showInfo(context, 'No other teachers available for this subject');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final otherTeachersList = widget.allTeachers
            .where((teacher) => teacher.teacherCode != _currentTeacher.teacherCode)
            .toList();

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Select Teacher',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.darkText,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'CURRENT TEACHER',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: widget.subjectColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTeacherCard(_currentTeacher, isSelected: true),

                if (otherTeachersList.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'OTHER TEACHERS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...otherTeachersList.map((teacher) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTeacherCard(teacher, isSelected: false),
                    );
                  }).toList(),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeacherCard(TeacherNavigationData teacher, {required bool isSelected}) {
    return GestureDetector(
      onTap: isSelected ? null : () {
        Navigator.pop(context);
        _switchTeacher(teacher);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [widget.subjectColor, widget.subjectColor.withOpacity(0.85)]
                : [Colors.white, Colors.grey.shade50],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? widget.subjectColor : Colors.grey.shade200,
            width: isSelected ? 2.5 : 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: widget.subjectColor.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]
              : [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : widget.subjectColor.withOpacity(0.3),
                  width: isSelected ? 3.5 : 2.5,
                ),
                image: teacher.teacherPhoto != null
                    ? DecorationImage(
                  image: NetworkImage('$_imageBaseUrl${teacher.teacherPhoto}'),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: teacher.teacherPhoto == null
                  ? Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [Colors.white, Colors.white.withOpacity(0.9)]
                        : [widget.subjectColor, widget.subjectColor.withOpacity(0.8)],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Iconsax.teacher,
                    color: isSelected ? widget.subjectColor : Colors.white,
                    size: 28,
                  ),
                ),
              )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          teacher.teacherFullName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : AppTheme.darkText,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.tick_circle, size: 13, color: widget.subjectColor),
                              const SizedBox(width: 4),
                              Text(
                                'Selected',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: widget.subjectColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.25) : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      'Code: ${teacher.teacherCode}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = kIsWeb && screenWidth > 1000;

    return MainLayout(
      activeScreen: AppScreen.mySubjects,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.subjectColor.withOpacity(0.02),
              Colors.white,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildTeacherInfoBanner(),
              const SizedBox(height: 32),
              if (_isLoading)
                _buildLoadingState()
              else if (_errorMessage != null)
                _buildErrorState()
              else if (_materialsData == null)
                  _buildErrorState()
                else
                  isWeb
                      ? _buildWebLayout()
                      : _buildMobileLayout(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          elevation: 2,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(Iconsax.arrow_left, size: 20, color: AppTheme.darkText),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.subjectColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.subjectName.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: widget.subjectColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.chapter.displayChapterName} - Materials',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.darkText,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.subjectColor.withOpacity(0.15),
            widget.subjectColor.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.subjectColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: widget.subjectColor.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.subjectColor.withOpacity(0.5), width: 3),
              boxShadow: [
                BoxShadow(
                  color: widget.subjectColor.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
              image: _currentTeacher.teacherPhoto != null
                  ? DecorationImage(
                image: NetworkImage('$_imageBaseUrl${_currentTeacher.teacherPhoto}'),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: _currentTeacher.teacherPhoto == null
                ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [widget.subjectColor, widget.subjectColor.withOpacity(0.8)],
                ),
              ),
              child: const Center(
                child: Icon(Iconsax.teacher, color: Colors.white, size: 28),
              ),
            )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT TEACHER',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: widget.subjectColor.withOpacity(0.8),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _currentTeacher.teacherFullName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.darkText,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.academicYear,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.allTeachers.length > 1)
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 2,
              child: InkWell(
                onTap: _showTeacherSwitcher,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.arrow_swap, size: 16, color: widget.subjectColor),
                      const SizedBox(width: 6),
                      Text(
                        'Switch',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: widget.subjectColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // WEB LAYOUT
  Widget _buildWebLayout() {
    if (_materialsData == null) return const SizedBox.shrink();

    final materials = _materialsData!.materials;
    final submissions = _materialsData!.submissions;

    final submissionsMap = <int, List<StudentSubmissionModel>>{};
    for (var submission in submissions) {
      submissionsMap.putIfAbsent(submission.materialRecNo, () => []).add(submission);
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildSectionHeader(
                '📋 Assignments',
                Colors.blue.shade700,
                materials.length.toString(),
              ),
            ),
            const SizedBox(width: 60),
            Expanded(
              flex: 3,
              child: _buildSectionHeader(
                '📤 Your Submissions',
                Colors.green.shade700,
                submissions.length.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        ...List.generate(materials.length, (index) {
          final material = materials[index];
          final materialSubmissions = submissionsMap[material.materialRecNo] ?? [];
          final hasSubmissions = materialSubmissions.isNotEmpty;

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildAssignmentCard(material, hasSubmissions),
                ),
                _buildHorizontalConnector(hasSubmissions),
                Expanded(
                  flex: 3,
                  child: _buildWebSubmissionArea(
                    materialSubmissions,
                    material.materialTitle,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWebSubmissionArea(List<StudentSubmissionModel> submissions, String assignmentTitle) {
    if (submissions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 2, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.document_upload, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'No submission yet',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: submissions.map((submission) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSubmissionCard(
            submission,
            assignmentTitle: assignmentTitle,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHorizontalConnector(bool hasSubmissions) {
    return SizedBox(
      width: 60,
      child: hasSubmissions
          ? Padding(
        padding: const EdgeInsets.only(top: 38),
        child: CustomPaint(
          size: const Size(60, 4),
          painter: HorizontalDottedLinePainter(color: Colors.black.withOpacity(0.6)),
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSectionHeader(String title, Color color, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              count,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(TeacherMaterialModel material, bool hasSubmissions) {
    final statusColor = _getStatusColor(material.assignmentStatus ?? 'Active');
    final totalMarks = material.totalMarks ?? 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            hasSubmissions ? Colors.green.shade50.withOpacity(0.3) : Colors.blue.shade50.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSubmissions ? Colors.green.withOpacity(0.3) : Colors.blue.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: hasSubmissions ? Colors.green.withOpacity(0.08) : Colors.blue.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.subjectColor, widget.subjectColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Iconsax.document_text, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    material.materialTitle,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasSubmissions)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Iconsax.tick_circle, size: 12, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.subjectColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    material.materialType,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: widget.subjectColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    material.assignmentStatus ?? 'Active',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.subjectColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MARKS',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: widget.subjectColor.withOpacity(0.6),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        totalMarks.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: widget.subjectColor,
                        ),
                      ),
                    ],
                  ),
                  if (material.dueDate != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'DUE',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: Colors.orange.withOpacity(0.6),
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          material.dueDate!.split(' ')[0],
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (material.materialPath != null && material.materialPath!.isNotEmpty)
              GestureDetector(
                onTap: () => _openDocument(material.materialPath!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.subjectColor.withOpacity(0.1), widget.subjectColor.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.subjectColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.document_download, size: 14, color: widget.subjectColor),
                      const SizedBox(width: 6),
                      Text(
                        'Open Document',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.subjectColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ✅ CHANGED: Replaced dummy button with real dialog call
            if (!hasSubmissions) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showUploadDialog(material), // Call the new function
                icon: Icon(Iconsax.document_upload, size: 16, color: widget.subjectColor),
                label: Text(
                  'Upload Your Work',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.subjectColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: widget.subjectColor.withOpacity(0.4), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(
      StudentSubmissionModel submission, {
        required String assignmentTitle,
      }) {
    final gradeStatus = submission.gradeStatus;
    final marksObtained = submission.marksObtained;
    final totalMarks = submission.totalMarks;
    final percentage = (marksObtained != null && totalMarks > 0) ? (marksObtained / totalMarks * 100) : 0.0;
    Color gradeColor = gradeStatus == 'Graded' ? Colors.green : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.green.shade50.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attempt ${submission.attemptNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkText,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: gradeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    gradeStatus,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: gradeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Iconsax.calendar, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  submission.submissionDate.split(' ')[0],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: widget.subjectColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: widget.subjectColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.document_text, size: 12, color: widget.subjectColor.withOpacity(0.8)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      assignmentTitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: widget.subjectColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            if (marksObtained != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (percentage >= 70 ? Colors.green : percentage >= 50 ? Colors.orange : Colors.red).withOpacity(0.12),
                      (percentage >= 70 ? Colors.green : percentage >= 50 ? Colors.orange : Colors.red).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (percentage >= 70 ? Colors.green : percentage >= 50 ? Colors.orange : Colors.red).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SCORE',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: (percentage >= 70 ? Colors.green : percentage >= 50 ? Colors.orange : Colors.red).withOpacity(0.6),
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$marksObtained/$totalMarks',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: percentage >= 70 ? Colors.green : percentage >= 50 ? Colors.orange : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: percentage >= 70 ? Colors.green : percentage >= 50 ? Colors.orange : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SizedBox(
                            width: 80,
                            height: 4,
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percentage >= 70 ? Colors.green : percentage >= 50 ? Colors.orange : Colors.red,
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
            if (submission.submissionFilePath != null && submission.submissionFilePath!.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _openDocument(submission.submissionFilePath!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.document_download, size: 14, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        'View Submission',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // MOBILE LAYOUT (Tabs)
  Widget _buildMobileLayout() {
    if (_materialsData == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildMobileTabBar(),
        const SizedBox(height: 20),
        IndexedStack(
          index: _tabController.index,
          children: [
            _buildMobileAssignmentsList(),
            _buildMobileSubmissionsList(),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.subjectColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: widget.subjectColor,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        indicator: BoxDecoration(
          color: widget.subjectColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: widget.subjectColor.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
          Tab(
            text: 'Assignments (${_materialsData!.materials.length})',
          ),
          Tab(
            text: 'Submissions (${_materialsData!.submissions.length})',
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAssignmentsList() {
    final materials = _materialsData!.materials;
    if (materials.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Iconsax.document_text, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 14),
              Text(
                'No assignments found',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final submissions = _materialsData!.submissions;
    final submissionsMap = <int, List<StudentSubmissionModel>>{};
    for (var submission in submissions) {
      submissionsMap.putIfAbsent(submission.materialRecNo, () => []).add(submission);
    }

    return Column(
      children: List.generate(materials.length, (index) {
        final material = materials[index];
        final hasSubmissions = (submissionsMap[material.materialRecNo]?.isNotEmpty) ?? false;

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildAssignmentCard(material, hasSubmissions),
        );
      }),
    );
  }

  Widget _buildMobileSubmissionsList() {
    final submissions = _materialsData!.submissions;
    if (submissions.isEmpty) {
      return _buildNoSubmissionsPlaceholder();
    }

    return Column(
      children: List.generate(submissions.length, (index) {
        final submission = submissions[index];
        final title = _assignmentTitleMap[submission.materialRecNo] ?? 'Assignment';

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildSubmissionCard(
            submission,
            assignmentTitle: title,
          ),
        );
      }),
    );
  }

  Widget _buildNoSubmissionsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 2),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Iconsax.document_upload, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              'No submissions yet',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Upload your solutions to assignments',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'Active') return Colors.green;
    if (status == 'Expired') return Colors.red;
    return Colors.orange;
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          BeautifulLoader(type: LoaderType.pulse, size: 70, color: widget.subjectColor),
          const SizedBox(height: 24),
          Text(
            'Loading materials...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
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
          const SizedBox(height: 100),
          Icon(Iconsax.danger, size: 72, color: Colors.red.withOpacity(0.7)),
          const SizedBox(height: 20),
          Text(
            _errorMessage ?? 'Failed to load materials',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadTeacherMaterials,
            icon: const Icon(Iconsax.refresh, size: 18),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.subjectColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class HorizontalDottedLinePainter extends CustomPainter {
  final Color color;

  HorizontalDottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double x = 0;
    final y = size.height / 2;

    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + dashWidth).clamp(0, size.width), y),
        paint,
      );
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(HorizontalDottedLinePainter oldDelegate) => false;
}
