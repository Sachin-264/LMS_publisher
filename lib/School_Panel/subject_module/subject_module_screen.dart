// lib/School_Panel/subject_module/subject_module_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'subject_module_bloc.dart';
import 'subject_module_model.dart';
import 'subject_module_api_service.dart';
import '../../Theme/apptheme.dart';
import '../../screens/main_layout.dart';
import '../../Util/custom_snackbar.dart';

// ============================================================================
// CLASS-TEACHER PAIR MODEL
// ============================================================================
class ClassTeacherPair {
  final int classRecNo;
  final String className;
  final int teacherRecNo;
  final String teacherName;

  ClassTeacherPair({
    required this.classRecNo,
    required this.className,
    required this.teacherRecNo,
    required this.teacherName,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassTeacherPair &&
        other.classRecNo == classRecNo &&
        other.teacherRecNo == teacherRecNo;
  }

  @override
  int get hashCode => classRecNo.hashCode ^ teacherRecNo.hashCode;
}

// ============================================================================
// MAIN SUBJECT MODULE SCREEN
// ============================================================================
class SubjectModuleScreen extends StatefulWidget {
  final int schoolRecNo;
  final String academicYear;

  const SubjectModuleScreen({
    super.key,
    required this.schoolRecNo,
    required this.academicYear,
  });

  @override
  State<SubjectModuleScreen> createState() => _SubjectModuleScreenState();
}

class _SubjectModuleScreenState extends State<SubjectModuleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Available Tab State
  String selectedView = 'classes';
  int? selectedClassID;
  String? selectedClassName;
  int? selectedSubjectID;
  String? selectedSubjectName;
  List<AvailableClassModel> availableClasses = [];
  List<AvailableSubjectModel> availableSubjects = [];
  List<AvailableChapterModel> availableChapters = [];
  String? expandedChapterId;

  // My Subjects Tab State
  String mySubjectsView = 'classes';
  int? mySubjectsSelectedClassID;
  String? mySubjectsSelectedClassName;
  int? mySubjectsSelectedSubjectID;
  String? mySubjectsSelectedSubjectName;
  List<SchoolClassModel> myClasses = [];
  List<SchoolSubjectModel> mySubjects = [];
  List<SchoolChapterModel> myChapters = [];
  String? myExpandedChapterId;

  // Shared Data
  List<SchoolClassMasterModel> availableSchoolClasses = [];
  List<TeacherModel> availableTeachers = [];
  List<ClassTeacherPair> selectedPairs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          if (_tabController.index == 0) {
            _fetchAvailableData();
          } else {
            _fetchMySubjectsData();
          }
        });
      }
    });
    Future.delayed(Duration.zero, () {
      _fetchAvailableData();
      _fetchSchoolClassesAndTeachers();
      _fetchMySubjectsData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchAvailableData() {
    if (selectedView == 'classes') {
      context.read<SubjectModuleBloc>().add(
        FetchAvailableClassesEvent(
          schoolRecNo: widget.schoolRecNo,
          academicYear: widget.academicYear,
        ),
      );
    } else if (selectedView == 'subjects' && selectedClassID != null) {
      context.read<SubjectModuleBloc>().add(
        FetchAvailableSubjectsEvent(
          schoolRecNo: widget.schoolRecNo,
          classID: selectedClassID!,
          academicYear: widget.academicYear,
        ),
      );
    } else if (selectedView == 'chapters' && selectedSubjectID != null) {
      context.read<SubjectModuleBloc>().add(
        FetchAvailableChaptersEvent(
          schoolRecNo: widget.schoolRecNo,
          subjectID: selectedSubjectID!,
          academicYear: widget.academicYear,
        ),
      );
    }
  }

  void _fetchMySubjectsData() {
    if (mySubjectsView == 'classes') {
      context.read<SubjectModuleBloc>().add(
        FetchSchoolClassesEvent(
          schoolRecNo: widget.schoolRecNo,
          academicYear: widget.academicYear,
        ),
      );
    } else if (mySubjectsView == 'subjects' && mySubjectsSelectedClassID != null) {
      context.read<SubjectModuleBloc>().add(
        FetchSchoolSubjectsEvent(
          schoolRecNo: widget.schoolRecNo,
          classID: mySubjectsSelectedClassID!,
          academicYear: widget.academicYear,
        ),
      );
    } else if (mySubjectsView == 'chapters' && mySubjectsSelectedSubjectID != null) {
      context.read<SubjectModuleBloc>().add(
        FetchSchoolChaptersEvent(
          schoolRecNo: widget.schoolRecNo,
          subjectID: mySubjectsSelectedSubjectID!,
          academicYear: widget.academicYear,
        ),
      );
    }
  }

  void _fetchSchoolClassesAndTeachers() {
    context.read<SubjectModuleBloc>().add(
      FetchSchoolClassMasterEvent(
        schoolRecNo: widget.schoolRecNo,
        academicYear: widget.academicYear,
      ),
    );
    context.read<SubjectModuleBloc>().add(
      FetchTeachersEvent(schoolRecNo: widget.schoolRecNo),
    );
  }

  void _refreshData() {
    //print('🔄 Refreshing data...');
    if (_tabController.index == 0) {
      _fetchAvailableData();
    } else {
      _fetchMySubjectsData();
    }
    _fetchSchoolClassesAndTeachers();
  }

// In _SubjectModuleScreenState class

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubjectModuleBloc, SubjectModuleState>(
      // In SubjectModuleScreenState, inside BlocConsumer
      listener: (context, state) async {
        if (state is SubjectModuleError) {
          CustomSnackbar.showError(context, state.message);
        }
        // NEW: Handle all operation success states
        else if (state is SubjectModuleOperationSuccess) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (!context.mounted) return;
          CustomSnackbar.showSuccess(context, state.message);
          await Future.delayed(const Duration(milliseconds: 300));
          if (!context.mounted) return;
          _refreshData();
        }
        // Keep existing loaded states
        else if (state is AvailableClassesLoaded) {
          setState(() {
            availableClasses = state.classes;
          });
        } else if (state is SchoolClassMasterLoaded) {
          setState(() {
            availableSchoolClasses = state.classes;
          });
        } else if (state is TeachersLoaded) {
          setState(() {
            availableTeachers = state.teachers;
          });
        } else if (state is AvailableSubjectsLoaded) {
          setState(() {
            availableSubjects = state.subjects;
          });
        } else if (state is AvailableChaptersLoaded) {
          setState(() {
            availableChapters = state.chapters;
          });
        } else if (state is SchoolClassesLoaded) {
          setState(() {
            myClasses = state.classes;
          });
        } else if (state is SchoolSubjectsLoaded) {
          setState(() {
            mySubjects = state.subjects;
          });
        } else if (state is SchoolChaptersLoaded) {
          setState(() {
            myChapters = state.chapters;
          });
        }
      },

      builder: (context, state) {
        return MainLayout(
          activeScreen: AppScreen.subjectModule,
          child: _buildContent(state),
        );
      },
    );
  }

  Widget _buildContent(SubjectModuleState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🎨 SEXY GRADIENT HEADER
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGreen,
                      AppTheme.accentGreen,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? 10 : 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFFFFFFF).withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Iconsax.book_1,
                              color: const Color(0xFFFFFFFF),
                              size: isMobile ? 20 : 28,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: isMobile ? 10 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subject Module Manager',
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 16 : 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFFFFF),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Manage subjects, chapters and learning materials',
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 11 : 13,
                              color: const Color(0xFFFFFFFF).withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.calendar_1,
                              size: 16,
                              color: AppTheme.primaryGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.academicYear,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),

              // 🎨 SEXY TABS
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFFFFFFFF),
                    unselectedLabelColor: AppTheme.bodyText,
                    indicator: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(5),
                    labelStyle: GoogleFonts.poppins(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: [
                      Tab(
                        height: isMobile ? 40 : 45,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.add_circle, size: isMobile ? 16 : 18),
                            SizedBox(width: isMobile ? 4 : 6),
                            const Text('Available'),
                          ],
                        ),
                      ),
                      Tab(
                        height: isMobile ? 40 : 45,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.tick_circle, size: isMobile ? 16 : 18),
                            SizedBox(width: isMobile ? 4 : 6),
                            const Text('My Subjects'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),

              SizedBox(
                height: isMobile ? 800 : 1200,
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildAvailableTab(state),
                    _buildMySubjectsTab(state),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================================
  // AVAILABLE TAB
  // ============================================================================
  Widget _buildAvailableTab(SubjectModuleState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Column(
          children: [
            if (selectedView != 'classes')
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 12,
                  vertical: isMobile ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AnimatedButton(
                      onPressed: () {
                        setState(() {
                          selectedView = 'classes';
                          selectedClassID = null;
                          selectedSubjectID = null;
                          expandedChapterId = null;
                        });
                        _fetchAvailableData();
                      },
                      icon: Iconsax.arrow_left_2,
                      label: 'Back to Classes',
                      isPrimary: false,
                    ),
                    if (selectedView == 'chapters') ...[
                      if (!isMobile)
                        Icon(Iconsax.arrow_right_3, size: 14, color: AppTheme.bodyText),
                      _AnimatedButton(
                        onPressed: () {
                          setState(() {
                            selectedView = 'subjects';
                            selectedSubjectID = null;
                            expandedChapterId = null;
                          });
                          _fetchAvailableData();
                        },
                        icon: Iconsax.book,
                        label: 'Back to Subjects',
                        isPrimary: false,
                      ),
                    ],
                  ],
                ),
              ),
            SizedBox(height: isMobile ? 10 : 12),
            Flexible(
              fit: FlexFit.loose,
              child: _buildAvailableContent(state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvailableContent(SubjectModuleState state) {
    if (state is SubjectModuleLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      color: Color(0xFFFFFFFF),
                      strokeWidth: 3,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.bodyText,
              ),
            ),
          ],
        ),
      );
    }

    if (selectedView == 'classes') {
      return _buildAvailableClassesList();
    } else if (selectedView == 'subjects') {
      return _buildAvailableSubjectsList();
    } else if (selectedView == 'chapters') {
      return _buildAvailableChaptersList();
    }

    return _buildEmptyState('No data available', Iconsax.archive_minus);
  }

  Widget _buildAvailableClassesList() {
    if (availableClasses.isEmpty) {
      return _buildEmptyState('No classes available', Iconsax.profile_2user);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth ~/ 250;
        final effectiveCrossAxisCount = crossAxisCount < 1 ? 1 : crossAxisCount;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: availableClasses.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: effectiveCrossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final classModel = availableClasses[index];
            final isAdded = classModel.isAddedBySchool == 1;
            final primaryColor = isAdded ? AppTheme.primaryGreen : Colors.blue;
            return _CompactSquareCard(
              title: classModel.className,
              icon: Iconsax.profile_2user,
              primaryColor: primaryColor,
              stat1Label: 'Subjects',
              stat1Value: classModel.totalSubjects,
              stat2Label: 'Chapters',
              stat2Value: classModel.totalChapters,
              isAdded: isAdded,
              onTap: () {
                setState(() {
                  selectedClassID = classModel.classID;
                  selectedClassName = classModel.className;
                  selectedView = 'subjects';
                });
                _fetchAvailableData();
              },
              trailing: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Iconsax.arrow_right_3,
                  color: primaryColor,
                  size: 14,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvailableSubjectsList() {
    if (availableSubjects.isEmpty) {
      return _buildEmptyState('No subjects available', Iconsax.book_square);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth ~/ 250;
        final effectiveCrossAxisCount = crossAxisCount < 1 ? 1 : crossAxisCount;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: availableSubjects.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: effectiveCrossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final subject = availableSubjects[index];
            final isAdded = subject.isAddedBySchool == 1;
            final primaryColor = isAdded ? AppTheme.primaryGreen : Colors.purple;
            return _CompactSquareCard(
              title: subject.subjectName,
              subtitle: subject.subjectCode,
              icon: Iconsax.book_1,
              primaryColor: primaryColor,
              stat1Label: 'Chapters',
              stat1Value: subject.totalChapters,
              stat2Label: 'Materials',
              stat2Value: subject.totalMaterials,
              isAdded: isAdded,
              onTap: () {
                setState(() {
                  selectedSubjectID = subject.subjectID;
                  selectedSubjectName = subject.subjectName;
                  selectedView = 'chapters';
                });
                _fetchAvailableData();
              },
              trailing: isAdded
                  ? null
                  : _AnimatedButton(
                onPressed: () {
                  _showBulkAddDialog(subject);
                },
                icon: Iconsax.add_circle,
                label: 'Add All',
                isPrimary: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvailableChaptersList() {
    if (availableChapters.isEmpty) {
      return _buildEmptyState('No chapters available', Iconsax.note_favorite);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: availableChapters.length,
      separatorBuilder: (context, index) => const SizedBox(height: 0),
      itemBuilder: (context, index) {
        final chapter = availableChapters[index];
        final isAdded = chapter.isAddedBySchool == 1;
        final uniqueKey = 'chapter_${chapter.chapterID}_${chapter.materialRecNo ?? 'no_mat'}_$index';
        final isExpanded = expandedChapterId == uniqueKey;

        return RepaintBoundary(
          key: ValueKey(uniqueKey),
          child: _SCard(
            isAdded: isAdded,
            onTap: () {
              setState(() {
                if (expandedChapterId == uniqueKey) {
                  expandedChapterId = null;
                } else {
                  expandedChapterId = uniqueKey;
                }
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isAdded
                              ? [
                            AppTheme.primaryGreen,
                            AppTheme.accentGreen,
                          ]
                              : [
                            Colors.teal,
                            Colors.teal.shade700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isAdded ? AppTheme.primaryGreen : Colors.teal).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${chapter.chapterOrder}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chapter.chapterName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkText,
                                  ),
                                ),
                              ),
                              if (isAdded)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryGreen.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Iconsax.tick_circle,
                                        size: 10,
                                        color: Color(0xFFFFFFFF),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'ADDED',
                                        style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFFFFFFF),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.bodyText.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              chapter.chapterCode,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: AppTheme.bodyText,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            chapter.chapterDescription,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.bodyText,
                              height: 1.5,
                            ),
                            maxLines: isExpanded ? null : 2,
                            overflow: isExpanded ? null : TextOverflow.ellipsis,
                          ),
                          if (chapter.hasMaterial == 1) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                _MaterialChip(
                                  icon: Iconsax.video_play,
                                  label: 'Video',
                                  available: chapter.videoLink != null,
                                ),
                                _MaterialChip(
                                  icon: Iconsax.document_text_1,
                                  label: 'Worksheet',
                                  available: chapter.worksheetPath != null,
                                ),
                                _MaterialChip(
                                  icon: Iconsax.note_1,
                                  label: 'Notes',
                                  available: chapter.revisionNotesPath != null,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isAdded)
                      _AnimatedIconButton(
                        onPressed: () {
                          _showAddChapterDialog(chapter);
                        },
                        icon: Iconsax.add_circle,
                        tooltip: 'Add Chapter',
                      ),
                  ],
                ),
                if (isExpanded && chapter.hasMaterial == 1) ...[
                  const Divider(height: 20),
                  Text(
                    'Study Materials',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (chapter.videoLink != null)
                    _StudyMaterialLink(
                      icon: Iconsax.video_play,
                      label: 'Video Lecture',
                      url: chapter.videoLink!,
                      color: Colors.red,
                    ),
                  if (chapter.worksheetPath != null)
                    _StudyMaterialLink(
                      icon: Iconsax.document_text_1,
                      label: 'Worksheet',
                      url: chapter.worksheetPath!,
                      color: Colors.blue,
                    ),
                  if (chapter.revisionNotesPath != null)
                    _StudyMaterialLink(
                      icon: Iconsax.note_1,
                      label: 'Revision Notes',
                      url: chapter.revisionNotesPath!,
                      color: Colors.green,
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================================
  // MY SUBJECTS TAB
  // ============================================================================
  Widget _buildMySubjectsTab(SubjectModuleState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Column(
          children: [
            if (mySubjectsView != 'classes')
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 12,
                  vertical: isMobile ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AnimatedButton(
                      onPressed: () {
                        setState(() {
                          mySubjectsView = 'classes';
                          mySubjectsSelectedClassID = null;
                          mySubjectsSelectedSubjectID = null;
                          myExpandedChapterId = null;
                        });
                        _fetchMySubjectsData();
                      },
                      icon: Iconsax.arrow_left_2,
                      label: 'Back to Classes',
                      isPrimary: false,
                    ),
                    if (mySubjectsView == 'chapters') ...[
                      if (!isMobile)
                        Icon(Iconsax.arrow_right_3, size: 14, color: AppTheme.bodyText),
                      _AnimatedButton(
                        onPressed: () {
                          setState(() {
                            mySubjectsView = 'subjects';
                            mySubjectsSelectedSubjectID = null;
                            myExpandedChapterId = null;
                          });
                          _fetchMySubjectsData();
                        },
                        icon: Iconsax.book,
                        label: 'Back to Subjects',
                        isPrimary: false,
                      ),
                    ],
                  ],
                ),
              ),
            SizedBox(height: isMobile ? 10 : 12),
            Flexible(
              fit: FlexFit.loose,
              child: _buildMySubjectsContent(state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMySubjectsContent(SubjectModuleState state) {
    if (state is SubjectModuleLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      color: Color(0xFFFFFFFF),
                      strokeWidth: 3,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.bodyText,
              ),
            ),
          ],
        ),
      );
    }

    if (mySubjectsView == 'classes') {
      return _buildMyClassesList();
    } else if (mySubjectsView == 'subjects') {
      return _buildMySubjectsList();
    } else if (mySubjectsView == 'chapters') {
      return _buildMyChaptersList();
    }

    return _buildEmptyState('No data available', Iconsax.archive_minus);
  }

  Widget _buildMyClassesList() {
    if (myClasses.isEmpty) {
      return _buildEmptyState(
        'No classes added yet',
        Iconsax.profile_2user,
        subtitle: 'Start by adding subjects from the Available tab',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth ~/ 250;
        final effectiveCrossAxisCount = crossAxisCount < 1 ? 1 : crossAxisCount;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: myClasses.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: effectiveCrossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final classModel = myClasses[index];
            return _CompactSquareCard(
              title: classModel.className,
              icon: Iconsax.profile_2user,
              primaryColor: AppTheme.primaryGreen,
              stat1Label: 'Subjects',
              stat1Value: classModel.addedSubjects,
              stat2Label: 'Chapters',
              stat2Value: classModel.addedChapters,
              isAdded: true,
              onTap: () {
                setState(() {
                  mySubjectsSelectedClassID = classModel.classID;
                  mySubjectsSelectedClassName = classModel.className;
                  mySubjectsView = 'subjects';
                });
                _fetchMySubjectsData();
              },
              trailing: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Iconsax.arrow_right_3,
                  color: AppTheme.primaryGreen,
                  size: 14,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMySubjectsList() {
    if (mySubjects.isEmpty) {
      return _buildEmptyState(
        'No subjects added yet',
        Iconsax.book_square,
        subtitle: 'Add subjects from the Available tab',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: mySubjects.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final subject = mySubjects[index];
        return _buildMySubjectCardWithAllotments(subject);
      },
    );
  }
  Widget _buildMySubjectCardWithAllotments(SchoolSubjectModel subject) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ FIX: Entire Subject Header is now clickable
          InkWell(
            onTap: () {
              setState(() {
                mySubjectsView = 'chapters';
                mySubjectsSelectedSubjectID = subject.subjectID;
                mySubjectsSelectedSubjectName = subject.subjectName;
              });
              _fetchMySubjectsData();
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient.scale(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Iconsax.book,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.customSubjectName ?? subject.subjectName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                          ),
                        ),
                        Text(
                          subject.subjectCode,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.bodyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ✅ Eye icon still visible but entire row is clickable
                  Icon(
                    Iconsax.eye,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),

          // ✅ FIX: Chapter Details Section is also clickable now
          InkWell(
            onTap: () {
              setState(() {
                mySubjectsView = 'chapters';
                mySubjectsSelectedSubjectID = subject.subjectID;
                mySubjectsSelectedSubjectName = subject.subjectName;
              });
              _fetchMySubjectsData();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Iconsax.note_text,
                        size: 18,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chapter Details',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatChip(
                        Iconsax.note_text,
                        '${subject.addedChapters}',
                        'Chapters',
                      ),
                      const SizedBox(width: 12),
                      if (subject.earliestStartDate != null)
                        _buildStatChip(
                          Iconsax.calendar,
                          subject.earliestStartDate!.split(' ')[0],
                          'Start',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // SECTION 2: Teacher Allotments (NOT clickable - keeps add/edit/delete functionality)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Iconsax.teacher,
                      size: 18,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Teacher Allotments',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _showAddAllotmentDialog(subject),
                      icon: const Icon(
                        Iconsax.add_circle,
                        size: 20,
                        color: AppTheme.primaryGreen,
                      ),
                      tooltip: 'Add Allotment',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (subject.allotments.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.info_circle,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'No teacher allotments yet',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...subject.allotments.map((allotment) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Iconsax.teacher,
                              size: 16,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  allotment.className ?? 'Class ${allotment.classRecNo}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.darkText,
                                  ),
                                ),
                                if (allotment.teacherName != null)
                                  Text(
                                    allotment.teacherName!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppTheme.bodyText,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showEditAllotmentDialog(allotment, subject),
                            icon: const Icon(
                              Iconsax.edit,
                              size: 16,
                              color: Colors.orange,
                            ),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            onPressed: () => _confirmDeleteAllotment(allotment),
                            icon: const Icon(
                              Iconsax.trash,
                              size: 16,
                              color: Colors.red,
                            ),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyChaptersList() {
    if (myChapters.isEmpty) {
      return _buildEmptyState(
        'No chapters added yet',
        Iconsax.note_favorite,
        subtitle: 'Add chapters from the Available tab',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: myChapters.length,
      separatorBuilder: (context, index) => const SizedBox(height: 0),
      itemBuilder: (context, index) {
        final chapter = myChapters[index];
        final isActive = chapter.isActiveForSchool == 1;
        final displayChapterName = chapter.customChapterName ?? chapter.chapterName;
        final displaySubjectName = chapter.customSubjectName ?? chapter.subjectName;

        final uniqueKey = 'school_chapter_${chapter.recNo}_$index';
        final isExpanded = myExpandedChapterId == uniqueKey;

        return RepaintBoundary(
          key: ValueKey(uniqueKey),
          child: Opacity(
            opacity: isActive ? 1.0 : 0.5,
            child: _SCard(
              isAdded: true,
              backgroundColor: isActive ? const Color(0xFFFFFFFF) : Colors.grey.shade200,
              onTap: () {
                setState(() {
                  if (myExpandedChapterId == uniqueKey) {
                    myExpandedChapterId = null;
                  } else {
                    myExpandedChapterId = uniqueKey;
                  }
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isActive
                                ? [
                              AppTheme.primaryGreen,
                              AppTheme.accentGreen,
                            ]
                                : [
                              Colors.grey.shade400,
                              Colors.grey.shade500,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (isActive ? AppTheme.primaryGreen : Colors.grey).withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${chapter.chapterOrder}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
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
                                        displayChapterName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isActive ? AppTheme.darkText : Colors.grey.shade600,
                                        ),
                                      ),
                                      if (chapter.customChapterName != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Original: ${chapter.chapterName}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: AppTheme.bodyText,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (!isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Iconsax.close_circle,
                                          size: 10,
                                          color: Color(0xFFFFFFFF),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'INACTIVE',
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFFFFFFF),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bodyText.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    chapter.chapterCode,
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      color: AppTheme.bodyText,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    displaySubjectName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: AppTheme.bodyText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              chapter.chapterDescription,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: isActive ? AppTheme.bodyText : Colors.grey.shade600,
                                height: 1.5,
                              ),
                              maxLines: isExpanded ? null : 2,
                              overflow: isExpanded ? null : TextOverflow.ellipsis,
                            ),
                            if (chapter.hasMaterial == 1) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  _MaterialChip(
                                    icon: Iconsax.video_play,
                                    label: 'Video',
                                    available: chapter.videoLink != null,
                                  ),
                                  _MaterialChip(
                                    icon: Iconsax.document_text_1,
                                    label: 'Worksheet',
                                    available: chapter.worksheetPath != null,
                                  ),
                                  _MaterialChip(
                                    icon: Iconsax.note_1,
                                    label: 'Notes',
                                    available: chapter.revisionNotesPath != null,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          _AnimatedIconButton(
                            onPressed: () {
                              _showEditChapterDialog(chapter);
                            },
                            icon: Iconsax.edit_2,
                            tooltip: 'Edit Chapter',
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 4),
                          _AnimatedIconButton(
                            onPressed: () {
                              _showDeleteDialog(chapter);
                            },
                            icon: Iconsax.trash,
                            tooltip: 'Delete Chapter',
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isExpanded && chapter.hasMaterial == 1) ...[
                    const Divider(height: 20),
                    Text(
                      'Study Materials',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (chapter.videoLink != null)
                      _StudyMaterialLink(
                        icon: Iconsax.video_play,
                        label: 'Video Lecture',
                        url: chapter.videoLink!,
                        color: Colors.red,
                      ),
                    if (chapter.worksheetPath != null)
                      _StudyMaterialLink(
                        icon: Iconsax.document_text_1,
                        label: 'Worksheet',
                        url: chapter.worksheetPath!,
                        color: Colors.blue,
                      ),
                    if (chapter.revisionNotesPath != null)
                      _StudyMaterialLink(
                        icon: Iconsax.note_1,
                        label: 'Revision Notes',
                        url: chapter.revisionNotesPath!,
                        color: Colors.green,
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// In _SubjectModuleScreenState class

// In SubjectModuleScreenState class
  void _showAddChapterDialog(AvailableChapterModel chapter) {
    final customChapterNameController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => _SDialog(
        title: 'Add Chapter',
        icon: Iconsax.book_saved,
        iconColor: AppTheme.primaryGreen,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chapter Preview
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${chapter.chapterOrder}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chapter.chapterName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkText,
                            ),
                          ),
                          Text(
                            chapter.chapterCode,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppTheme.bodyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Custom Chapter Name
              _STextField(
                controller: customChapterNameController,
                label: 'Custom Chapter Name (Optional)',
                hint: 'e.g., अध्याय १ or Algebra',
                icon: Iconsax.note_text,
              ),
            ],
          ),
        ),
        actions: [
          _AnimatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            label: 'Cancel',
            isPrimary: false,
          ),
          _AnimatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Future.delayed(const Duration(milliseconds: 100));
              if (!mounted) return;

              context.read<SubjectModuleBloc>().add(
                AddChapterOnlyEvent(
                  schoolRecNo: widget.schoolRecNo,
                  classID: chapter.classID,
                  subjectID: chapter.subjectID,
                  chapterID: chapter.chapterID,
                  academicYear: widget.academicYear,
                  customChapterName: customChapterNameController.text.isNotEmpty
                      ? customChapterNameController.text
                      : null,
                  createdBy: 'Admin',
                ),
              );
            },
            icon: Iconsax.tick_circle,
            label: 'Add Chapter',
            isPrimary: true,
          ),
        ],
      ),
    );
  }

// ============================================================================
// 🎨 BULK ADD DIALOG - NOW SUPER INTERACTIVE
// ============================================================================
// In SubjectModuleScreenState class
  void _showBulkAddDialog(AvailableSubjectModel subject) {
    final customSubjectNameController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => _SDialog(
        title: 'Add All Chapters',
        icon: Iconsax.add_square,
        iconColor: AppTheme.primaryGreen,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add all ${subject.totalChapters} chapters from "${subject.subjectName}" to your school curriculum?',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.bodyText,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            _STextField(
              controller: customSubjectNameController,
              label: 'Custom Subject Name (Optional)',
              hint: 'e.g., गणित or Mathematics',
              icon: Iconsax.book,
            ),
          ],
        ),
        actions: [
          _AnimatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            label: 'Cancel',
            isPrimary: false,
          ),
          _AnimatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Future.delayed(const Duration(milliseconds: 100));
              if (!mounted) return;

              context.read<SubjectModuleBloc>().add(
                BulkAddSubjectChaptersEvent(
                  schoolRecNo: widget.schoolRecNo,
                  subjectID: subject.subjectID,
                  academicYear: widget.academicYear,
                  customSubjectName: customSubjectNameController.text.isNotEmpty
                      ? customSubjectNameController.text
                      : null,
                  createdBy: 'Admin',
                ),
              );
            },
            icon: Iconsax.tick_circle,
            label: 'Add All',
            isPrimary: true,
          ),
        ],
      ),
    );
  }


// In SubjectModuleScreenState class
  void _showAddAllotmentDialog(SchoolSubjectModel subject) {
    List<ClassTeacherPair> dialogPairs = [];

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return _SDialog(
            title: 'Add Teacher Allotment',
            icon: Iconsax.teacher,
            iconColor: AppTheme.primaryGreen,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.book_square,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            subject.customSubjectName ?? subject.subjectName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ClassTeacherPairManager(
                    availableSchoolClasses: availableSchoolClasses,
                    availableTeachers: availableTeachers,
                    selectedPairs: dialogPairs,
                    onPairsUpdated: (newPairs) {
                      setDialogState(() {
                        dialogPairs = newPairs;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              _AnimatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                label: 'Cancel',
                isPrimary: false,
              ),
              _AnimatedButton(
                onPressed: () async {
                  if (dialogPairs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please select at least one class-teacher pair',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final classRecNos = dialogPairs.map((p) => p.classRecNo).toList();
                  final teacherRecNos = dialogPairs.map((p) => p.teacherRecNo).toList();

                  Navigator.pop(dialogContext);
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (!mounted) return;

                  context.read<SubjectModuleBloc>().add(
                    AddAllotmentEvent(
                      schoolRecNo: widget.schoolRecNo,
                      subjectID: subject.subjectID,
                      academicYear: widget.academicYear,
                      classRecNoList: classRecNos,
                      teacherRecNoList: teacherRecNos,
                      createdBy: 'Admin',
                    ),
                  );
                },
                icon: Iconsax.tick_circle,
                label: 'Add Allotment${dialogPairs.isNotEmpty ? ' (${dialogPairs.length})' : ''}',
                isPrimary: true,
              ),
            ],
          );
        },
      ),
    );
  }

  // UPDATED: Edit Allotment Dialog
  void _showEditAllotmentDialog(AllotmentModel allotment, SchoolSubjectModel subject) {
    int? selectedClassRecNo = allotment.classRecNo;
    int? selectedTeacherRecNo = allotment.teacherRecNo;

    // Find initial objects for dropdowns
    SchoolClassMasterModel? initialClass = availableSchoolClasses.firstWhere(
          (c) => c.classRecNo == selectedClassRecNo,
      orElse: () => availableSchoolClasses.first, // Safe fallback
    );
    TeacherModel? initialTeacher = availableTeachers.firstWhere(
          (t) => t.teacherRecNo == selectedTeacherRecNo,
      orElse: () => availableTeachers.first, // Safe fallback
    );

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return _SDialog(
            title: 'Edit Allotment',
            icon: Iconsax.edit,
            iconColor: Colors.orange,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.book_square, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          subject.customSubjectName ?? subject.subjectName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // NEW SEARCHABLE DROPDOWN for Class
                _SSearchableDropdown<SchoolClassMasterModel>(
                  hintText: 'Select Class',
                  icon: Iconsax.profile_2user,
                  items: availableSchoolClasses,
                  itemToString: (schoolClass) =>
                  '${schoolClass.className} - ${schoolClass.sectionName}',
                  initialValue: initialClass,
                  isRequired: true,
                  onChanged: (schoolClass) {
                    setDialogState(() {
                      selectedClassRecNo = schoolClass?.classRecNo;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // NEW SEARCHABLE DROPDOWN for Teacher
                _SSearchableDropdown<TeacherModel>(
                  hintText: 'Select Teacher',
                  icon: Iconsax.teacher,
                  items: availableTeachers,
                  itemToString: (teacher) => teacher.fullName,
                  initialValue: initialTeacher,
                  isRequired: true,
                  onChanged: (teacher) {
                    setDialogState(() {
                      selectedTeacherRecNo = teacher?.teacherRecNo;
                    });
                  },
                ),
              ],
            ),
            actions: [
              _AnimatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                label: 'Cancel',
                isPrimary: false,
              ),
              _AnimatedButton(
                onPressed: () async {
                  if (selectedClassRecNo == null || selectedTeacherRecNo == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please select both class and teacher',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(dialogContext);
                  await Future.delayed(const Duration(milliseconds: 100));

                  if (!mounted) return;

                  context.read<SubjectModuleBloc>().add(
                    UpdateAllotmentEvent(
                      recNo: allotment.allotmentRecNo,
                      classRecNo: selectedClassRecNo!,
                      teacherRecNo: selectedTeacherRecNo!,
                      modifiedBy: 'Admin',
                    ),
                  );
                },
                icon: Iconsax.tick_circle,
                label: 'Update',
                isPrimary: true,
              ),
            ],
          );
        },
      ),
    );
  }
  // NEW: Delete Allotment Confirmation
  void _confirmDeleteAllotment(AllotmentModel allotment) {
    showDialog(
      context: context,
      builder: (dialogContext) => _SDialog(
        title: 'Delete Allotment',
        icon: Iconsax.trash,
        iconColor: Colors.red,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.danger,
              size: 48,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete this allotment?',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.darkText,
              ),
              textAlign: TextAlign.center,
            ),
            if (allotment.className != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${allotment.className} - ${allotment.teacherName}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          _AnimatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            label: 'Cancel',
            isPrimary: false,
          ),
          _AnimatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Future.delayed(const Duration(milliseconds: 100));

              if (!mounted) return;

              context.read<SubjectModuleBloc>().add(
                DeleteAllotmentEvent(recNo: allotment.allotmentRecNo),
              );
            },
            icon: Iconsax.trash,
            label: 'Delete',
            isPrimary: true,
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }

// In SubjectModuleScreenState class
  void _showEditChapterDialog(SchoolChapterModel chapter) {
    final customChapterNameController = TextEditingController(
      text: chapter.customChapterName ?? '',
    );

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => _SDialog(
        title: 'Edit Chapter',
        icon: Iconsax.edit_2,
        iconColor: Colors.blue,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${chapter.chapterOrder}',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.chapterName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                          ),
                        ),
                        Text(
                          chapter.chapterCode,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppTheme.bodyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _STextField(
              controller: customChapterNameController,
              label: 'Custom Chapter Name',
              hint: 'e.g. Algebra',
              icon: Iconsax.note_text,
            ),
          ],
        ),
        actions: [
          _AnimatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            label: 'Cancel',
            isPrimary: false,
          ),
          _AnimatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Future.delayed(const Duration(milliseconds: 100));
              if (!mounted) return;

              context.read<SubjectModuleBloc>().add(
                UpdateChapterNameEvent(
                  recNo: chapter.recNo,
                  customChapterName: customChapterNameController.text,
                  modifiedBy: 'Admin',
                ),
              );
            },
            icon: Iconsax.tick_circle,
            label: 'Update',
            isPrimary: true,
          ),
        ],
      ),
    );
  }

// In SubjectModuleScreenState class
  void _showDeleteDialog(SchoolChapterModel chapter) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => _SDialog(
        title: 'Delete Chapter',
        icon: Iconsax.trash,
        iconColor: Colors.red,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.warning_2, color: Colors.red, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete chapter: ${chapter.customChapterName ?? chapter.chapterName}?',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.darkText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          _AnimatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            label: 'Cancel',
            isPrimary: false,
          ),
          _AnimatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Future.delayed(const Duration(milliseconds: 100));
              if (!mounted) return;

              context.read<SubjectModuleBloc>().add(
                DeleteChapterEvent(recNo: chapter.recNo),
              );
            },
            icon: Iconsax.trash,
            label: 'Delete',
            isPrimary: true,
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, {String? subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.bodyText.withOpacity(0.1),
                  AppTheme.bodyText.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 50,
              color: AppTheme.bodyText.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.bodyText,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.bodyText.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryGreen),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.bodyText,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CLASS-TEACHER PAIR MANAGER WIDGET
// ============================================================================
// ============================================================================
// CLASS-TEACHER PAIR MANAGER WIDGET
// ============================================================================
class _ClassTeacherPairManager extends StatefulWidget {
  final List<SchoolClassMasterModel> availableSchoolClasses;
  final List<TeacherModel> availableTeachers;
  final List<ClassTeacherPair> selectedPairs;
  final Function(List<ClassTeacherPair>) onPairsUpdated;

  const _ClassTeacherPairManager({
    required this.availableSchoolClasses,
    required this.availableTeachers,
    required this.selectedPairs,
    required this.onPairsUpdated,
  });

  @override
  State<_ClassTeacherPairManager> createState() => _ClassTeacherPairManagerState();
}

class _ClassTeacherPairManagerState extends State<_ClassTeacherPairManager> {
  int? tempClassRecNo;
  String? tempClassName;
  int? tempTeacherRecNo;
  String? tempTeacherName;

  void _addClassTeacherPair() {
    if (tempClassRecNo == null || tempTeacherRecNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select both Class and Teacher.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final newPair = ClassTeacherPair(
      classRecNo: tempClassRecNo!,
      className: tempClassName!,
      teacherRecNo: tempTeacherRecNo!,
      teacherName: tempTeacherName!,
    );

    if (!widget.selectedPairs.contains(newPair)) {
      final updatedPairs = List<ClassTeacherPair>.from(widget.selectedPairs)..add(newPair);
      widget.onPairsUpdated(updatedPairs);

      setState(() {
        tempClassRecNo = null;
        tempClassName = null;
        tempTeacherRecNo = null;
        tempTeacherName = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This Class-Teacher pair is already added!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removePair(ClassTeacherPair pair) {
    final updatedPairs = List<ClassTeacherPair>.from(widget.selectedPairs)..remove(pair);
    widget.onPairsUpdated(updatedPairs);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assign Classes & Teachers',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 12),
          // NEW: S Searchable Dropdown for Class
          _SSearchableDropdown<SchoolClassMasterModel>(
            hintText: 'Select Class',
            icon: Iconsax.profile_2user,
            items: widget.availableSchoolClasses,
            itemToString: (schoolClass) =>
            '${schoolClass.className} - ${schoolClass.sectionName}',
            initialValue: tempClassRecNo != null
                ? widget.availableSchoolClasses.firstWhere(
                  (c) => c.classRecNo == tempClassRecNo,
              orElse: () => widget.availableSchoolClasses.first,
            )
                : null,
            onChanged: (schoolClass) {
              setState(() {
                tempClassRecNo = schoolClass?.classRecNo;
                tempClassName = schoolClass?.className;
              });
            },
          ),
          const SizedBox(height: 10),
          // NEW: S Searchable Dropdown for Teacher
          _SSearchableDropdown<TeacherModel>(
            hintText: 'Select Teacher',
            icon: Iconsax.teacher,
            items: widget.availableTeachers,
            itemToString: (teacher) => teacher.fullName,
            initialValue: tempTeacherRecNo != null
                ? widget.availableTeachers.firstWhere(
                  (t) => t.teacherRecNo == tempTeacherRecNo,
              orElse: () => widget.availableTeachers.first,
            )
                : null,
            onChanged: (teacher) {
              setState(() {
                tempTeacherRecNo = teacher?.teacherRecNo;
                tempTeacherName = teacher?.fullName;
              });
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _AnimatedButton(
              onPressed: _addClassTeacherPair,
              icon: Iconsax.add,
              label: 'Add Pair',
              isPrimary: true,
              backgroundColor: AppTheme.primaryGreen,
            ),
          ),
          if (widget.selectedPairs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Selected Allotments: ${widget.selectedPairs.length}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            // Updated list of selected pairs
            ...widget.selectedPairs.map((pair) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Iconsax.teacher,
                      size: 16,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pair.className,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkText,
                            ),
                          ),
                          Text(
                            pair.teacherName,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppTheme.bodyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _AnimatedIconButton(
                      onPressed: () => _removePair(pair),
                      icon: Iconsax.close_circle,
                      tooltip: 'Remove',
                      color: Colors.red,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}
// ============================================================================
// REUSABLE UI WIDGETS
// ============================================================================

class _CompactSquareCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color primaryColor;
  final String stat1Label;
  final int stat1Value;
  final String stat2Label;
  final int stat2Value;
  final String? stat2Text;
  final bool isAdded;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _CompactSquareCard({
    Key? key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.stat1Label,
    required this.stat1Value,
    required this.stat2Label,
    required this.stat2Value,
    this.stat2Text,
    required this.isAdded,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  State<_CompactSquareCard> createState() => _CompactSquareCardState();
}

class _CompactSquareCardState extends State<_CompactSquareCard> {
  bool isHovered = false;

  Widget _buildPatternBackground(Color color) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: 0.1,
          child: CustomPaint(
            painter: _CardPatternPainter(color),
            child: Container(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.primaryColor.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered ? widget.primaryColor.withOpacity(0.2) : Colors.black.withOpacity(0.08),
                blurRadius: isHovered ? 14 : 8,
                offset: Offset(0, isHovered ? 6 : 3),
              ),
            ],
          ),
          transform: Matrix4.identity()..translate(0.0, isHovered ? -4.0 : 0.0),
          child: Stack(
            children: [
              _buildPatternBackground(widget.primaryColor),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.primaryColor,
                                    widget.primaryColor,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.primaryColor.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.icon,
                                color: const Color(0xFFFFFFFF),
                                size: 24,
                              ),
                            ),
                            if (widget.trailing != null) widget.trailing!,
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.bodyText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatBadge(
                          label: widget.stat1Label,
                          value: widget.stat1Value,
                          color: Colors.orange,
                        ),
                        _StatBadge(
                          label: widget.stat2Label,
                          value: widget.stat2Value,
                          valueText: widget.stat2Text,
                          color: Colors.teal,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.isAdded)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: const Offset(12, -12),
                    child: Transform.rotate(
                      angle: 0.785,
                      child: Container(
                        width: 60,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'ADDED',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFFFFFF),
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
    );
  }
}

class _CardPatternPainter extends CustomPainter {
  final Color color;
  _CardPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.1),
      size.width * 0.2,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.9),
      size.width * 0.3,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int value;
  final String? valueText;
  final Color color;

  const _StatBadge({
    Key? key,
    required this.label,
    required this.value,
    this.valueText,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valueText ?? value.toString(),
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.bodyText,
          ),
        ),
      ],
    );
  }
}

class _SCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isAdded;
  final bool showAddedBadge;
  final Color? borderColor;
  final Color? backgroundColor;

  const _SCard({
    Key? key,
    required this.child,
    this.onTap,
    this.isAdded = false,
    this.showAddedBadge = true,
    this.borderColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<_SCard> createState() => _SCardState();
}

class _SCardState extends State<_SCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.borderColor ??
                  (widget.isAdded
                      ? AppTheme.primaryGreen.withOpacity(0.3)
                      : AppTheme.borderGrey.withOpacity(0.3)),
              width: widget.isAdded ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered ? AppTheme.primaryGreen.withOpacity(0.15) : Colors.black.withOpacity(0.06),
                blurRadius: isHovered ? 12 : 8,
                offset: Offset(0, isHovered ? 4 : 2),
              ),
            ],
          ),
          transform: Matrix4.identity()..translate(0.0, isHovered ? -2.0 : 0.0),
          child: widget.child,
        ),
      ),
    );
  }
}

class _MaterialChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool available;

  const _MaterialChip({
    Key? key,
    required this.icon,
    required this.label,
    required this.available,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: available ? AppTheme.primaryGreen.withOpacity(0.1) : AppTheme.bodyText.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: available ? AppTheme.primaryGreen.withOpacity(0.3) : AppTheme.bodyText.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: available ? AppTheme.primaryGreen : AppTheme.bodyText.withOpacity(0.5),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: available ? AppTheme.primaryGreen : AppTheme.bodyText.withOpacity(0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyMaterialLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final Color color;

  const _StudyMaterialLink({
    Key? key,
    required this.icon,
    required this.label,
    required this.url,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: color,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Iconsax.export_1,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final String label;
  final bool isPrimary;
  final Color? backgroundColor;

  const _AnimatedButton({
    Key? key,
    required this.onPressed,
    this.icon,
    required this.label,
    this.isPrimary = true,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: isEnabled ? (_) => _controller.forward() : null,
      onTapUp: isEnabled
          ? (_) {
        _controller.reverse();
        widget.onPressed!();
      }
          : null,
      onTapCancel: isEnabled ? () => _controller.reverse() : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: widget.isPrimary && isEnabled
                  ? (widget.backgroundColor != null
                  ? LinearGradient(
                colors: [
                  widget.backgroundColor!,
                  widget.backgroundColor!.withOpacity(0.7),
                ],
              )
                  : AppTheme.primaryGradient)
                  : null,
              color: widget.isPrimary && !isEnabled
                  ? (widget.backgroundColor ?? AppTheme.primaryGreen)
                  .withOpacity(0.5)
                  : widget.isPrimary
                  ? null
                  : AppTheme.bodyText.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isPrimary
                    ? (widget.backgroundColor ?? AppTheme.primaryGreen)
                    .withOpacity(0.3)
                    : AppTheme.bodyText.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: widget.isPrimary && isEnabled
                  ? [
                BoxShadow(
                  color: (widget.backgroundColor ?? AppTheme.primaryGreen)
                      .withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 14,
                    color: widget.isPrimary
                        ? const Color(0xFFFFFFFF)
                        : AppTheme.bodyText,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.isPrimary
                        ? const Color(0xFFFFFFFF)
                        : AppTheme.bodyText,
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

class _AnimatedIconButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final Color? color;

  const _AnimatedIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.color,
  }) : super(key: key);

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null;
    final effectiveColor = widget.color ?? AppTheme.primaryGreen;
    final buttonColor = isEnabled ? effectiveColor : Colors.grey.shade400;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => _controller.forward() : null,
      onTapUp: isEnabled
          ? (_) {
        _controller.reverse();
        widget.onPressed!();
      }
          : null,
      onTapCancel: isEnabled ? () => _controller.reverse() : null,
      child: Tooltip(
        message: widget.tooltip,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Opacity(
            opacity: isEnabled ? 1.0 : 0.6,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    buttonColor,
                    buttonColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: buttonColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                size: 16,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget content;
  final List<Widget> actions;

  const _SDialog({
    Key? key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.content,
    required this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = screenHeight * 0.85; // 85% of screen height

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 450,
          maxHeight: maxDialogHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor.withOpacity(0.1),
                      iconColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content (Scrollable)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: content,
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (int i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      actions[i],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _STextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _STextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.borderGrey,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.darkText,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.bodyText.withOpacity(0.5),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppTheme.primaryGreen,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// ============================================================================
// NEW REUSABLE UI WIDGETS
// ============================================================================

// ============================================================================
// NEW REUSABLE UI WIDGETS
// ============================================================================
// NEW REUSABLE UI WIDGETS - Searchable Dropdown
class _SSearchableDropdown<T> extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final T? initialValue;
  final List<T> items;
  final String Function(T) itemToString;
  final void Function(T?)? onChanged;
  final bool isRequired;

  const _SSearchableDropdown({
    Key? key,
    required this.hintText,
    required this.icon,
    required this.items,
    required this.itemToString,
    required this.onChanged,
    this.initialValue,
    this.isRequired = false,
  }) : super(key: key);

  @override
  State<_SSearchableDropdown<T>> createState() => _SSearchableDropdownState<T>();
}
class _SSearchableDropdownState<T> extends State<_SSearchableDropdown<T>> {
  T? selectedValue;
  final TextEditingController searchController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final LayerLink layerLink = LayerLink();
  OverlayEntry? overlayEntry;
  List<T> filteredItems = [];

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
    filteredItems = widget.items;
    searchController.addListener(filterItems);
    focusNode.addListener(onFocusChange);

    // ✅ Set initial text if selectedValue is not null
    if (selectedValue != null) {
      searchController.text = widget.itemToString(selectedValue as T);
    }
  }

  @override
  void didUpdateWidget(_SSearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ Update selectedValue and searchController.text when parent changes initialValue
    if (widget.initialValue != oldWidget.initialValue) {
      selectedValue = widget.initialValue;
      if (selectedValue != null) {
        searchController.text = widget.itemToString(selectedValue as T);
      } else {
        searchController.clear();
      }
      filteredItems = widget.items;
    }
  }

  @override
  void dispose() {
    searchController.removeListener(filterItems);
    focusNode.removeListener(onFocusChange);
    searchController.dispose();
    focusNode.dispose();
    overlayEntry?.remove();
    super.dispose();
  }

  void filterItems() {
    setState(() {
      if (searchController.text.isEmpty) {
        filteredItems = widget.items;
      } else {
        filteredItems = widget.items.where((item) {
          final itemString = widget.itemToString(item).toLowerCase();
          final searchString = searchController.text.toLowerCase();
          return itemString.contains(searchString);
        }).toList();
      }
    });
    if (overlayEntry != null) {
      overlayEntry!.markNeedsBuild();
    }
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // ✅ Reset filteredItems when gaining focus
      setState(() {
        filteredItems = widget.items;
      });
      showOverlay();
    } else {
      // ✅ INCREASED delay to allow tap to complete
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!focusNode.hasFocus && overlayEntry != null) {
          removeOverlay();
          // ✅ Reset text ONLY if no value is selected
          if (mounted) {
            setState(() {
              if (selectedValue != null) {
                searchController.text = widget.itemToString(selectedValue as T);
              } else {
                searchController.clear();
              }
            });
          }
        }
      });
    }
  }

  void showOverlay() {
    if (overlayEntry == null) {
      overlayEntry = createOverlayEntry();
      Overlay.of(context).insert(overlayEntry!);
    } else {
      overlayEntry!.markNeedsBuild();
    }
  }

  void removeOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  OverlayEntry createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGrey, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final isSelected = item == selectedValue;

                    return InkWell(
                      onTap: () {
                        // ✅ CRITICAL FIX: Update state FIRST, then close overlay
                        final selectedItem = item;
                        final selectedText = widget.itemToString(selectedItem);

                        setState(() {
                          selectedValue = selectedItem;
                          searchController.text = selectedText;
                        });

                        // ✅ Call onChanged BEFORE removing focus
                        widget.onChanged?.call(selectedItem);

                        // ✅ Remove overlay and unfocus AFTER updating state
                        removeOverlay();
                        focusNode.unfocus();
                      },
                      child: Container(
                        color: isSelected ? AppTheme.primaryGreen.withOpacity(0.1) : null,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.itemToString(item),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: isSelected ? AppTheme.primaryGreen : AppTheme.darkText,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Iconsax.tick_circle,
                                size: 16,
                                color: AppTheme.primaryGreen,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              children: [
                Text(
                  widget.hintText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                if (widget.isRequired)
                  Text(
                    ' *',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: focusNode.hasFocus ? AppTheme.primaryGreen : AppTheme.borderGrey,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: focusNode.hasFocus
                      ? AppTheme.primaryGreen.withOpacity(0.1)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              focusNode: focusNode,
              readOnly: false,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.darkText,
              ),
              decoration: InputDecoration(
                hintText: 'Search or ${widget.hintText.toLowerCase()}',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.bodyText.withOpacity(0.5),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    widget.icon,
                    size: 18,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                suffixIcon: Icon(
                  Iconsax.arrow_down_1,
                  size: 18,
                  color: AppTheme.primaryGreen,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}




