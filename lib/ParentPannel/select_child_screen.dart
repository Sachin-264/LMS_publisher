import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/ParentPannel/Service/parent_student_service.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/navigation_helper.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SelectChildScreen extends StatefulWidget {
  const SelectChildScreen({Key? key}) : super(key: key);

  @override
  State<SelectChildScreen> createState() => _SelectChildScreenState();
}

class _SelectChildScreenState extends State<SelectChildScreen> {
  final ParentStudentService _service = ParentStudentService();
  List<StudentChild> _students = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ✅ Image base URL
  static const String _imageBaseUrl = "https://storage.googleapis.com/upload-images-34/images/LMS/";

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final parentId = userProvider.parentUserCode;

    if (parentId == null) {
      setState(() {
        _errorMessage = 'Parent ID not found';
        _isLoading = false;
      });
      return;
    }

    try {
      final students = await _service.getStudentsByParentId(parentId: parentId);
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectStudent(StudentChild student) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    print('🎯 Parent selecting student...');
    print('   StudentID: ${student.studentId}');
    print('   StudentName: ${student.fullName}');

    // ✅ Select the student and store all children
    userProvider.selectStudent(
      student.studentId,
      student.fullName,
      _students, // Pass all students for switching
    );

    print('📋 Available menus:');
    for (var menu in userProvider.menuPermissions) {
      print('   → ${menu.menuCode} (SNo: ${menu.sNo}) - ${menu.menuText}');
    }

    // ✅ Get the lowest SNo menu EXCEPT M000
    final nextMenu = userProvider.getLowestSequenceMenu(excludeM000: true);

    if (nextMenu != null) {
      print('✅ Navigating to: ${nextMenu.menuCode} (SNo: ${nextMenu.sNo})');
      print('   (Skipped M000 - keeping it as home screen)');

      // Navigate to the next screen
      NavigationHelper.navigateToFirstScreen(
        context,
        userProvider,
        excludeM000: true, // ✅ Skip M000 in navigation
      );
    } else {
      print('❌ No menu found after M000, navigating to M000');
      // Fallback to select child screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SelectChildScreen()),
      );
    }
  }


  String _getImageUrl(String photoPath) {
    if (photoPath.isEmpty) return '';
    return '$_imageBaseUrl$photoPath';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
            ? _buildErrorState()
            : _students.isEmpty
            ? _buildEmptyState()
            : Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth < 600 ? 24 : 40,
              vertical: 40,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ Simple title
                Text(
                  'Select Your Child',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth < 600 ? 26 : 32,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.bodyText,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose a profile to view their progress and data',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppTheme.bodyText.withOpacity(0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 50),

                // ✅ Student cards in grid
                if (screenWidth > 900)
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: _students
                        .map((student) => SizedBox(
                      width: 380,
                      child: _StudentSelectionCard(
                        student: student,
                        imageUrl: _getImageUrl(
                            student.studentPhotoPath),
                        onTap: () => _selectStudent(student),
                      ),
                    ))
                        .toList(),
                  )
                else
                  ..._students.map((student) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _StudentSelectionCard(
                      student: student,
                      imageUrl:
                      _getImageUrl(student.studentPhotoPath),
                      onTap: () => _selectStudent(student),
                    ),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading profiles...',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.bodyText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.info_circle,
              size: 70,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppTheme.bodyText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.bodyText.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.profile_remove,
            size: 70,
            color: AppTheme.bodyText.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No Profiles Found',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppTheme.bodyText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No students are linked to your account',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.bodyText.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Clean Student Selection Card
class _StudentSelectionCard extends StatefulWidget {
  final StudentChild student;
  final String imageUrl;
  final VoidCallback onTap;

  const _StudentSelectionCard({
    required this.student,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  State<_StudentSelectionCard> createState() => _StudentSelectionCardState();
}

class _StudentSelectionCardState extends State<_StudentSelectionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..scale(_isHovered ? 1.02 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.primaryGreen.withOpacity(0.3)
                  : Colors.grey.shade200,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppTheme.primaryGreen.withOpacity(0.15)
                    : Colors.black.withOpacity(0.05),
                blurRadius: _isHovered ? 25 : 15,
                offset: Offset(0, _isHovered ? 10 : 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    // ✅ Profile Image
                    _buildProfileImage(),
                    const SizedBox(height: 20),

                    // ✅ Name
                    Text(
                      widget.student.fullName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.bodyText,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ✅ Class Info
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ' ${widget.student.currentClass} • ${widget.student.sectionDivision}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ✅ Student Details Grid
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Roll No',
                            widget.student.rollNumber.isNotEmpty
                                ? widget.student.rollNumber
                                : 'N/A',
                          ),
                          const SizedBox(height: 14),
                          _buildDetailRow(
                            'Gender',
                            widget.student.gender.isNotEmpty
                                ? widget.student.gender
                                : 'N/A',
                          ),
                          const SizedBox(height: 14),
                          _buildDetailRow(
                            'Blood Group',
                            widget.student.bloodGroup.isNotEmpty
                                ? widget.student.bloodGroup
                                : 'N/A',
                          ),
                          if (widget.student.dateOfBirth.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildDetailRow(
                              'Date of Birth',
                              widget.student.dateOfBirth.split(' ')[0],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ✅ Continue Button
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryGreen,
                            AppTheme.mackColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onTap,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Text(
                              'Continue',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            AppTheme.primaryGreen,
            AppTheme.mackColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(4),
        child: ClipOval(
          child: widget.imageUrl.isNotEmpty
              ? CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                ),
              ),
            ),
            errorWidget: (context, url, error) => _buildFallbackAvatar(),
          )
              : _buildFallbackAvatar(),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: AppTheme.primaryGreen.withOpacity(0.1),
      child: Center(
        child: Text(
          widget.student.firstName.isNotEmpty
              ? widget.student.firstName[0].toUpperCase()
              : '?',
          style: GoogleFonts.poppins(
            fontSize: 38,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.bodyText.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.bodyText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
