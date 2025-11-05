import 'package:flutter/material.dart';
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

  // ViewType removed as requested

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
        viewType: 'grid', // Default to grid as filter bar is removed
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
          ? _buildLoadingState() // Use themed loader
          : _errorMessage != null
          ? _buildErrorView()
          : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 120),
        child: BeautifulLoader(
          type: LoaderType.pulse,
          size: 80,
          color: AppTheme.primaryGreen,
          message: 'Loading your classes...',
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: AppTheme.defaultBorderRadius * 1.5,
          border: Border.all(color: AppTheme.borderGrey),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor,
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
                color: AppTheme.mackColor.withOpacity(0.1), // Brand error color
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.danger,
                  size: 48, color: AppTheme.mackColor), // Brand error color
            ),
            const SizedBox(height: 20),
            Text(
              'Error Loading Classes',
              style: AppTheme.headline1.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: AppTheme.bodyText1.copyWith(color: AppTheme.bodyText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loadClasses,
              icon: const Icon(Iconsax.refresh, size: 18),
              label: Text('Try Again',
                  style: AppTheme.buttonText.copyWith(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.defaultBorderRadius),
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
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isMobile),
              SizedBox(height: isMobile ? 20 : 28),

              // Filter bar removed as requested

              _buildGridView(isMobile),
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
        color: AppTheme.background,
        borderRadius: AppTheme.defaultBorderRadius * 1.5, // 18
        border: Border.all(color: AppTheme.borderGrey),
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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: AppTheme.defaultBorderRadius,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(
              Iconsax.book_square,
              color: Colors.white,
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
                  style: AppTheme.headline1.copyWith(
                    fontSize: isMobile ? 20 : 24,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_groupedClasses.length}',
                        style: AppTheme.labelText.copyWith(
                          fontSize: 12,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _groupedClasses.length == 1
                          ? 'class assigned'
                          : 'classes assigned',
                      style: AppTheme.bodyText1.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: AppTheme.defaultBorderRadius,
                border: Border.all(color: AppTheme.borderGrey),
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
                      style: AppTheme.labelText.copyWith(
                        fontSize: 14,
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

  // Filter bar and toggle methods removed as requested

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
        crossAxisSpacing: isMobile ? 16 : 20,
        mainAxisSpacing: isMobile ? 16 : 20,
        childAspectRatio: isMobile ? 1.4 : 1.15,
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

  // _buildListView and _buildClassListItem removed as requested

  Widget _buildClassCard(int classRecNo, List<dynamic> subjects,
      Map<String, dynamic> classData, bool isMobile) {
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
      borderRadius: AppTheme.defaultBorderRadius * 1.5, // 18
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: AppTheme.defaultBorderRadius * 1.5, // 18
          border: Border.all(color: AppTheme.borderGrey, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor.withOpacity(0.7),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classData['ClassName'] ?? '',
                    style: AppTheme.headline2.copyWith(fontSize: 20),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Section ${classData['SectionName'] ?? ''}',
                    style: AppTheme.bodyText1.copyWith(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Card Body with Stats
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildStatRow(
                    icon: Iconsax.book_1,
                    label: '$subjectCount ${subjectCount == 1 ? 'Subject' : 'Subjects'}',
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    icon: Iconsax.profile_2user,
                    label: '$totalStudents Total Student Enrolled',
                    color: AppTheme.mackColor, // Using brand color
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Card Footer Button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: AppTheme.borderGrey),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Details',
                    style: AppTheme.labelText.copyWith(
                      fontSize: 13,
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

  Widget _buildStatRow(
      {required IconData icon, required String label, required Color color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: AppTheme.defaultBorderRadius,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTheme.labelText.copyWith(
            fontSize: 14,
            color: AppTheme.darkText,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: AppTheme.defaultBorderRadius * 1.5,
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.book,
                size: 56, color: AppTheme.primaryGreen.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          Text(
            'No Classes Found',
            style: AppTheme.headline1.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'No classes are assigned for this academic year',
            style: AppTheme.bodyText1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}