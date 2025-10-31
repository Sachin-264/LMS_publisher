import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Teacher_Panel/MyClass/teacher_class_detail_screen.dart';
import 'package:lms_publisher/Teacher_Panel/teacher_panel_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:provider/provider.dart';

class TeacherClassesScreen extends StatefulWidget {
  const TeacherClassesScreen({super.key});

  @override
  State<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends State<TeacherClassesScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _rawClasses = [];
  Map<int, List<dynamic>> _groupedClasses = {}; // Group by ClassRecNo

  String _selectedAcademicYear = '2025-26';
  final List<String> _academicYears = ['2024-25', '2025-26', '2026-27'];

  String _viewType = 'grid';

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final teacherCode = userProvider.userCode;

      if (teacherCode == null) {
        throw Exception('Teacher code not found');
      }

      final data = await TeacherPanelService.getClassesList(
        teacherCode: teacherCode,
        academicYear: _selectedAcademicYear,
        viewType: _viewType,
      );

      setState(() {
        _rawClasses = data['classes'] ?? [];

        // Group classes by ClassRecNo
        _groupedClasses = {};
        for (var classData in _rawClasses) {
          final classRecNo = classData['ClassRecNo'] as int;
          if (!_groupedClasses.containsKey(classRecNo)) {
            _groupedClasses[classRecNo] = [];
          }
          _groupedClasses[classRecNo]!.add(classData);
        }

        print('\n📊 Grouped Classes:');
        _groupedClasses.forEach((classRecNo, subjects) {
          print('   Class $classRecNo: ${subjects.length} subjects');
          subjects.forEach((s) => print('      - ${s['SubjectName']}'));
        });

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to load classes: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      activeScreen: AppScreen.teacherClasses,
      child: _isLoading
          ? const Center(child: BeautifulLoader())
          : _errorMessage != null
          ? _buildErrorView()
          : _buildContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.info_circle, size: 48, color: Colors.red.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              'Error Loading Classes',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.bodyText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loadClasses,
              icon: const Icon(Iconsax.refresh, size: 18),
              label: Text('Try Again', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isMobile),
              SizedBox(height: isMobile ? 20 : 28),

              _buildFilterBar(isMobile),
              SizedBox(height: isMobile ? 20 : 28),

              _viewType == 'grid'
                  ? _buildGridView(isMobile)
                  : _buildListView(isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Iconsax.book_square,
              color: AppTheme.primaryGreen,
              size: isMobile ? 26 : 30,
            ),
          ),

          SizedBox(width: isMobile ? 14 : 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Classes',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_groupedClasses.length}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _groupedClasses.length == 1 ? 'class assigned' : 'classes assigned',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.bodyText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.calendar_1,
                    size: 18,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: 10),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAcademicYear,
                      icon: Icon(
                        Iconsax.arrow_down_1,
                        size: 16,
                        color: AppTheme.bodyText,
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                      items: _academicYears.map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedAcademicYear = value);
                          _loadClasses();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Iconsax.menu_board, size: isMobile ? 18 : 20, color: AppTheme.primaryGreen),
          SizedBox(width: isMobile ? 10 : 12),
          Text(
            'View Options',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _buildViewToggle(Iconsax.element_3, 'grid', isMobile),
              const SizedBox(width: 8),
              _buildViewToggle(Iconsax.menu, 'list', isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(IconData icon, String type, bool isMobile) {
    final isActive = _viewType == type;
    return InkWell(
      onTap: () => setState(() => _viewType = type),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 8 : 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryGreen.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: isMobile ? 18 : 20,
          color: isActive ? AppTheme.primaryGreen : AppTheme.bodyText,
        ),
      ),
    );
  }

  Widget _buildGridView(bool isMobile) {
    if (_groupedClasses.isEmpty) {
      return _buildEmptyState();
    }

    final classList = _groupedClasses.entries.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 3,
        crossAxisSpacing: isMobile ? 0 : 20,
        mainAxisSpacing: isMobile ? 16 : 20,
        childAspectRatio: isMobile ? 1.4 : 1.1,
      ),
      itemCount: classList.length,
      itemBuilder: (context, index) {
        final entry = classList[index];
        final classRecNo = entry.key;
        final subjects = entry.value;
        final firstSubject = subjects[0]; // Use first subject for display data

        return _buildClassCard(classRecNo, subjects, firstSubject, isMobile);
      },
    );
  }

  Widget _buildListView(bool isMobile) {
    if (_groupedClasses.isEmpty) {
      return _buildEmptyState();
    }

    final classList = _groupedClasses.entries.toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: classList.length,
      separatorBuilder: (context, index) => SizedBox(height: isMobile ? 12 : 16),
      itemBuilder: (context, index) {
        final entry = classList[index];
        final classRecNo = entry.key;
        final subjects = entry.value;
        final firstSubject = subjects[0];

        return _buildClassListItem(classRecNo, subjects, firstSubject, isMobile);
      },
    );
  }

  Widget _buildClassCard(int classRecNo, List<dynamic> subjects, Map<String, dynamic> classData, bool isMobile) {
    final totalStudents = classData['TotalStudents'] ?? 0;
    final subjectCount = subjects.length;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherClassDetailScreen(
              classRecNo: classRecNo,
              className: classData['ClassName'],
              sectionName: classData['SectionName'],
              subjects: subjects,
              academicYear: _selectedAcademicYear,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classData['ClassName'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Section ${classData['SectionName'] ?? ''}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.bodyText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.book_1, size: 14, color: AppTheme.primaryGreen),
                      const SizedBox(width: 6),
                      Text(
                        '$subjectCount',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Iconsax.profile_2user,
                    size: 16,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$totalStudents Students',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),

            const Spacer(),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Details',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Iconsax.arrow_right_3,
                    size: 16,
                    color: AppTheme.primaryGreen,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassListItem(int classRecNo, List<dynamic> subjects, Map<String, dynamic> classData, bool isMobile) {
    final totalStudents = classData['TotalStudents'] ?? 0;
    final subjectCount = subjects.length;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherClassDetailScreen(
              classRecNo: classRecNo,
              className: classData['ClassName'],
              sectionName: classData['SectionName'],
              subjects: subjects,
              academicYear: _selectedAcademicYear,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(isMobile ? 18 : 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${classData['ClassName']} - ${classData['SectionName']}',
                        style: GoogleFonts.inter(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.book_1, size: 12, color: AppTheme.primaryGreen),
                            const SizedBox(width: 4),
                            Text(
                              '$subjectCount ${subjectCount == 1 ? 'Subject' : 'Subjects'}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Iconsax.profile_2user, size: 16, color: AppTheme.bodyText.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Text(
                        '$totalStudents Students',
                        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.bodyText, fontWeight: FontWeight.w500),
                      ),
                    ],
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.book, size: 56, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            'No Classes Found',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No classes are assigned for this academic year',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.bodyText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
