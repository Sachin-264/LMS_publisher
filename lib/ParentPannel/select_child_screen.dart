import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/ParentPannel/Service/parent_student_service.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/StudentPannel/MySubject/my_subject_screen.dart';
import 'package:provider/provider.dart';

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

    // Select the student in provider (changes userCode to studentId)
    userProvider.selectStudent(student.studentId);

    // Navigate to student dashboard
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MySubjectsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ✅ Beautiful App Bar
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryGreen,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Select Your Child',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryGreen,
                        AppTheme.primaryGreen.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 40,
                        right: -30,
                        child: Icon(
                          Iconsax.profile_2user,
                          size: 180,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Icon(
                          Iconsax.heart,
                          size: 60,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ✅ Content
            SliverPadding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              sliver: _isLoading
                  ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading students...',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : _errorMessage != null
                  ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        size: 80,
                        color: Colors.red.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : _students.isEmpty
                  ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.profile_remove,
                        size: 80,
                        color: AppTheme.bodyText.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Students Found',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : SliverGrid(
                gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : (screenWidth > 900 ? 3 : 2),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: isMobile ? 1.2 : 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final student = _students[index];
                    return _StudentCard(
                      student: student,
                      onTap: () => _selectStudent(student),
                    );
                  },
                  childCount: _students.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Beautiful Student Card Widget
class _StudentCard extends StatelessWidget {
  final StudentChild student;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ Photo with beautiful gradient border
                Container(
                  width: 120,
                  height: 120,
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
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                      backgroundImage: student.studentPhotoPath.isNotEmpty
                          ? NetworkImage(student.studentPhotoPath)
                          : null,
                      child: student.studentPhotoPath.isEmpty
                          ? Text(
                        student.firstName.isNotEmpty
                            ? student.firstName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGreen,
                        ),
                      )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Name
                Text(
                  student.fullName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.bodyText,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // ✅ Class & Section
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Iconsax.book_1,
                        size: 14,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Class ${student.currentClass} - ${student.sectionDivision}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ✅ Roll Number
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.card,
                      size: 14,
                      color: AppTheme.bodyText.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Roll No: ${student.rollNumber}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.bodyText,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // ✅ Select Button
                Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.primaryGreen,
                        AppTheme.mackColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Text(
                          'Select',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
    );
  }
}
