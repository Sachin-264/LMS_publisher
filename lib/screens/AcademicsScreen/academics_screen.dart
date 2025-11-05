import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Service/academics_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/screens/AcademicsScreen/academics_content.dart';
import 'package:lms_publisher/screens/AcademicsScreen/materialdetailscreen.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:provider/provider.dart';
import 'academics_bloc.dart';
import 'dart:async';
import 'package:lms_publisher/Util/beautiful_loader.dart';


class AcademicsScreen extends StatelessWidget {
  const AcademicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AcademicsBloc()..add(LoadKPIEvent()),
      child: const MainLayout(
        activeScreen: AppScreen.academics,
        child: AcademicsView(),
      ),
    );
  }
}

enum _AcademicViewType { classes, subjects, chapters, materials }

class AcademicsView extends StatefulWidget {
  const AcademicsView({super.key});

  @override
  _AcademicsViewState createState() => _AcademicsViewState();
}

class _AcademicsViewState extends State<AcademicsView> {
  _AcademicViewType _currentView = _AcademicViewType.classes;
  int? _selectedClassId;
  int? _selectedSubjectId;
  int? _selectedChapterId;
  List<ClassModel> _allClasses = [];
  List<SubjectModel> _allSubjects = [];
  List<ChapterModel> _allChapters = [];
  Timer? _materialsDebounce;

  @override
  void initState() {
    super.initState();
    _loadFiltersData();
    _loadViewData();
  }

  @override
  void dispose() {
    _materialsDebounce?.cancel();
    super.dispose();
  }

  void _loadFiltersData() async {
    final classResponse = await ApiService.getClasses();
    final subjectResponse = await ApiService.getSubjects();

    if (mounted) {
      setState(() {
        if (classResponse['status'] == 'success' && classResponse['data'] != null) {
          _allClasses = (classResponse['data'] as List).map((json) => ClassModel.fromJson(json)).toList();
        }

        if (subjectResponse['status'] == 'success' && subjectResponse['data'] != null) {
          _allSubjects = (subjectResponse['data'] as List).map((json) => SubjectModel.fromJson(json)).toList();
        }
      });
    }
  }

  void _loadViewData() {
    final bloc = context.read<AcademicsBloc>();
    _loadFiltersData();

    switch (_currentView) {
      case _AcademicViewType.classes:
        print('🔄 Tab changed to Classes. Loading latest classes...');
        bloc.add(LoadClassesEvent(schoolRecNo: 1));
        break;
      case _AcademicViewType.subjects:
        print('🔄 Tab changed to Subjects. Loading latest classes and subjects...');
        bloc.add(LoadClassesEvent(schoolRecNo: 1));
        bloc.add(LoadSubjectsEvent(classId: _selectedClassId));
        break;
      case _AcademicViewType.chapters:
        print('🔄 Tab changed to Chapters. Loading latest classes, subjects, and chapters...');
        bloc.add(LoadClassesEvent(schoolRecNo: 1));
        bloc.add(LoadSubjectsEvent(classId: _selectedClassId));
        bloc.add(LoadChaptersEvent(classId: _selectedClassId, subjectId: _selectedSubjectId));
        break;
      case _AcademicViewType.materials:
        print('🔄 Tab changed to Materials. Loading latest classes, subjects, chapters, and materials...');
        bloc.add(LoadClassesEvent(schoolRecNo: 1));
        bloc.add(LoadSubjectsEvent(classId: _selectedClassId));
        if (_selectedSubjectId != null) {
          bloc.add(LoadChaptersEvent(subjectId: _selectedSubjectId));
        }

        bloc.add(LoadMaterialsEvent(
          classId: _selectedClassId,
          subjectId: _selectedSubjectId,
          chapterId: _selectedChapterId,
        ));
        break;
    }
  }

  void _loadViewDataDebounced() {
    if (_currentView != _AcademicViewType.materials) {
      _loadViewData();
      return;
    }

    _materialsDebounce?.cancel();
    _materialsDebounce = Timer(const Duration(milliseconds: 250), _loadViewData);
  }

  @override
  Widget build(BuildContext context) {
    // --- ADDED THIS ---
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Academics Module', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.darkText)),
                const SizedBox(height: 4),
                Text('Manage all your educational content from classes to materials.', style: GoogleFonts.inter(color: AppTheme.bodyText)),
              ],
            ),
          ),
          const AcademicsDashboard(),
          const SizedBox(height: AppTheme.defaultPadding * 1.5),
          _buildViewSwitcher(),
          const SizedBox(height: AppTheme.defaultPadding),
          _buildCurrentView(),
        ],
      ),
    );
    // --- AND CLOSED IT HERE ---
  }

  Widget _buildViewSwitcher() {
    int currentIndex = _currentView.index;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.borderGrey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSwitchButton('Classes', Iconsax.building, 0, currentIndex),
          _buildSwitchButton('Subjects', Iconsax.book_1, 1, currentIndex),
          _buildSwitchButton('Chapters', Iconsax.document_text, 2, currentIndex),
          _buildSwitchButton('Materials', Iconsax.folder_open, 3, currentIndex),
        ],
      ),
    );
  }

  Widget _buildSwitchButton(String text, IconData icon, int index, int currentIndex) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentView = _AcademicViewType.values[index];
            if (index == 0) {
              _selectedClassId = null;
              _selectedSubjectId = null;
              _selectedChapterId = null;
              _allChapters = [];
            } else if (index == 1) {
              _selectedSubjectId = null;
              _selectedChapterId = null;
              _allChapters = [];
            } else if (index == 2) {
              _selectedChapterId = null;
            }
          });
          _loadViewData();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 5)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isActive ? AppTheme.primaryGreen : AppTheme.bodyText),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isActive ? AppTheme.primaryGreen : AppTheme.bodyText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case _AcademicViewType.classes:
        return ClassView(key: const ValueKey('classes'));
      case _AcademicViewType.subjects:
        return SubjectView(
          key: const ValueKey('subjects'),
          selectedClassId: _selectedClassId,
          allClasses: _allClasses,
          onClassFilterChanged: (classId) {
            setState(() => _selectedClassId = classId);
            _loadViewData();
          },
        );
      case _AcademicViewType.chapters:
        return ChapterView(
          key: const ValueKey('chapters'),
          selectedClassId: _selectedClassId,
          selectedSubjectId: _selectedSubjectId,
          allClasses: _allClasses,
          allSubjects: _allSubjects,
          onClassFilterChanged: (classId) {
            setState(() {
              _selectedClassId = classId;
              _selectedSubjectId = null;
            });
            _loadViewData();
          },
          onSubjectFilterChanged: (subjectId) {
            setState(() => _selectedSubjectId = subjectId);
            _loadViewData();
          },
        );
      case _AcademicViewType.materials:
        return MaterialView(
          key: const ValueKey('materials'),
          selectedClassId: _selectedClassId,
          selectedSubjectId: _selectedSubjectId,
          selectedChapterId: _selectedChapterId,
          allClasses: _allClasses,
          allSubjects: _allSubjects,
          allChapters: _allChapters,
          onClassFilterChanged: (classId) {
            setState(() {
              _selectedClassId = classId;
              _selectedSubjectId = null;
              _selectedChapterId = null;
              _allChapters = [];
            });
            _loadViewDataDebounced();
          },
          onSubjectFilterChanged: (subjectId) async {
            setState(() {
              _selectedSubjectId = subjectId;
              _selectedChapterId = null;
              _allChapters = [];
            });

            if (subjectId != null) {
              print('📖 Loading chapters for subject: $subjectId');
              try {
                final chaptersResponse = await ApiService.getChapters(
                  schoolRecNo: 1,
                  subjectId: subjectId,
                );

                if (chaptersResponse['status'] == 'success' && chaptersResponse['data'] != null) {
                  setState(() {
                    _allChapters = (chaptersResponse['data'] as List)
                        .map((json) => ChapterModel.fromJson(json))
                        .toList();
                  });
                  print('✅ Loaded ${_allChapters.length} chapters');
                }
              } catch (e) {
                print('❌ Error loading chapters: $e');
              }
            }

            // ✅ IMPORTANT: Load chapters in BLoC after setState
            _loadViewData();
          },

          onChapterFilterChanged: (chapterId) {
            setState(() => _selectedChapterId = chapterId);
            _loadViewDataDebounced();
          },
        );
    }
  }
}

class AcademicsDashboard extends StatelessWidget {
  const AcademicsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AcademicsBloc, AcademicsState>(
      buildWhen: (previous, current) => current is KPILoaded,
      builder: (context, state) {
        String totalClasses = '0';
        String totalSubjects = '0';
        String totalChapters = '0';
        String totalMaterials = '0';
        bool isLoading = state is! KPILoaded;

        if (state is KPILoaded) {
          totalClasses = state.totalClasses;
          totalSubjects = state.totalSubjects;
          totalChapters = state.totalChapters;
          totalMaterials = state.totalMaterials;
        }

        return LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          final kpiCards = [
            SummaryCard(icon: Iconsax.building, color: Colors.blue, value: totalClasses, label: 'Total Classes', isLoading: isLoading),
            SummaryCard(icon: Iconsax.book_1, color: Colors.green, value: totalSubjects, label: 'Total Subjects', isLoading: isLoading),
            SummaryCard(icon: Iconsax.document_text, color: Colors.orange, value: totalChapters, label: 'Total Chapters', isLoading: isLoading),
            SummaryCard(icon: Iconsax.folder, color: Colors.purple, value: totalMaterials, label: 'Total Materials', isLoading: isLoading),
          ];

          if (isMobile) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: kpiCards.map((card) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.defaultPadding),
                child: card,
              )).toList(),
            );
          }

          return Row(
            children: kpiCards.map((card) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding / 2),
                child: card,
              ),
            )).toList(),
          );
        });
      },
    );
  }
}

class ClassView extends StatelessWidget {
  const ClassView({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final canAdd = userProvider.hasPermission('M004', 'add');
    print('🏗️ ClassView: Building...');
    return BlocBuilder<AcademicsBloc, AcademicsState>(
      buildWhen: (previous, current) {
        final shouldRebuild = current is ClassesLoaded || current is AcademicsLoading;
        print('🏗️ ClassView buildWhen: shouldRebuild=$shouldRebuild');
        return shouldRebuild;
      },
      builder: (context, state) {
        print('🏗️ ClassView builder: state=${state.runtimeType}');
        if (state is AcademicsLoading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(64.0),
              child: BeautifulLoader(
                type: LoaderType.dots,
                message: 'Loading classes...',
                color: AppTheme.primaryGreen,
                size: 50,
              ),
            ),
          );
        }

        if (state is ClassesLoaded) {
          print('✅ ClassView: ClassesLoaded with ${state.classes.length} classes');

          // FIXED: Show "Add Class" button when empty
          if (state.classes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.building,
                        size: 64,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Classes Yet',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start by creating your first class to organize your academic content.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppTheme.bodyText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (canAdd)
                      ElevatedButton.icon(
                        onPressed: () {
                          print('🔐 ClassView Empty State: Checking ADD permission for M004');
                          if (userProvider.hasPermission('M004', 'add')) {
                            print('✅ ClassView Empty State: ADD permission granted');
                            showAddClassDialog(context);
                          } else {
                            print('❌ ClassView Empty State: ADD permission denied');
                            _showPermissionDeniedDialog(context, 'add classes');
                          }
                        },
                        icon: const Icon(Iconsax.add),
                        label: Text(
                          'Add Your First Class',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          return MasterViewTemplate(
            key: ValueKey('classes_${state.classes.length}_${DateTime.now().millisecondsSinceEpoch}'),
            title: "All Classes",
            buttonLabel: canAdd ? "Add Class" : null,
            buttonIcon: Iconsax.add,
            onAddPressed: canAdd
                ? () {
              print('🔐 ClassView: Checking ADD permission for M004');
              if (userProvider.hasPermission('M004', 'add')) {
                print('✅ ClassView: ADD permission granted');
                showAddClassDialog(context);
              } else {
                print('❌ ClassView: ADD permission denied');
                _showPermissionDeniedDialog(context, 'add classes');
              }
            }
                : null,
            header: const ResponsiveTableHeader(headers: [
              HeaderItem(text: "CLASS NAME", flex: 4),
              HeaderItem(text: "Description", flex: 4),
              HeaderItem(text: "SUBJECTS", flex: 3),
              HeaderItem(text: "STATUS", flex: 2),
              HeaderItem(text: "ACTIONS", flex: 1, alignment: Alignment.centerRight),
            ]),
            itemCount: state.classes.length,
            itemBuilder: (context, index) => ClassListItem(
              key: ValueKey('class_${state.classes[index].id}'),
              item: state.classes[index],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}


class ChapterView extends StatelessWidget {
  final int? selectedClassId;
  final int? selectedSubjectId;
  final List<ClassModel> allClasses;
  final List<SubjectModel> allSubjects;
  final ValueChanged<int?> onClassFilterChanged;
  final ValueChanged<int?> onSubjectFilterChanged;

  const ChapterView({
    super.key,
    this.selectedClassId,
    this.selectedSubjectId,
    required this.allClasses,
    required this.allSubjects,
    required this.onClassFilterChanged,
    required this.onSubjectFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final canAdd = userProvider.hasPermission('M004', 'add');

    print('🏗️ ChapterView: Building...');
    print('🔍 ChapterView: selectedClassId=$selectedClassId, selectedSubjectId=$selectedSubjectId');

    return BlocBuilder<AcademicsBloc, AcademicsState>(
      buildWhen: (previous, current) {
        final shouldRebuild = current is ChaptersLoaded || current is AcademicsLoading;
        print('🏗️ ChapterView buildWhen: shouldRebuild=$shouldRebuild');
        return shouldRebuild;
      },
      builder: (context, state) {
        print('🏗️ ChapterView builder: state=${state.runtimeType}');

        if (state is AcademicsLoading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(64.0),
              child: BeautifulLoader(
                type: LoaderType.dots,
                message: 'Loading chapters...',
                color: AppTheme.primaryGreen,
                size: 50,
              ),
            ),
          );
        }

        if (state is ChaptersLoaded) {
          print('📖 ChapterView: ChaptersLoaded with ${state.chapters.length} chapters');

          // ✅ Filter chapters based on selections
          List<ChapterModel> filteredChapters = state.chapters;

          if (selectedSubjectId != null) {
            filteredChapters = state.chapters
                .where((ch) => ch.subjectId == selectedSubjectId)
                .toList();
            print('📖 ChapterView: Filtered to ${filteredChapters.length} chapters for subject $selectedSubjectId');
          } else if (selectedClassId != null) {
            // Get all subjects for the selected class
            final classSubjectIds = allSubjects
                .where((s) => s.classId == selectedClassId)
                .map((s) => s.id)
                .toSet();

            filteredChapters = state.chapters
                .where((ch) => classSubjectIds.contains(ch.subjectId))
                .toList();
            print('📖 ChapterView: Filtered to ${filteredChapters.length} chapters for class $selectedClassId');
          }

          return MasterViewTemplate(
            key: ValueKey('chapters_${filteredChapters.length}_${DateTime.now().millisecondsSinceEpoch}'),
            title: 'All Chapters',
            buttonLabel: canAdd ? 'Add Chapter' : null,
            buttonIcon: Iconsax.add,
            onAddPressed: canAdd
                ? () {
              print('🏗️ ChapterView: Checking ADD permission for M004');
              if (userProvider.hasPermission('M004', 'add')) {
                print('✅ ChapterView: ADD permission granted');
                showAddChapterDialog(context, allClasses, allSubjects);
              } else {
                print('❌ ChapterView: ADD permission denied');
                showPermissionDeniedDialog(context, 'add chapters');
              }
            }
                : null,
            filters: CascadingFilters(
              selectedClassId: selectedClassId,
              selectedSubjectId: selectedSubjectId,
              allClasses: allClasses,
              allSubjects: allSubjects,
              onClassChanged: onClassFilterChanged,
              onSubjectChanged: onSubjectFilterChanged,
            ),
            header: const ResponsiveTableHeader(
              headers: [
                HeaderItem(text: 'CHAPTER', flex: 4),
                HeaderItem(text: 'SUBJECT', flex: 3),
                HeaderItem(text: 'MATERIALS', flex: 2),
                HeaderItem(text: 'ACTIONS', flex: 1, alignment: Alignment.centerRight),
              ],
            ),
            itemCount: filteredChapters.isEmpty ? 1 : filteredChapters.length,
            itemBuilder: (context, index) {
              if (filteredChapters.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: Text('No chapters available')),
                );
              }
              return ChapterListItem(
                key: ValueKey('chapter_${filteredChapters[index].id}'),
                item: filteredChapters[index],
                allSubjects: allSubjects,
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// Add this function at the end of the file, before the last closing brace

void showPermissionDeniedDialog(BuildContext context, String action) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Iconsax.info_circle, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Text(
            'Permission Denied',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Text(
        'You do not have permission to $action.',
        style: GoogleFonts.inter(fontSize: 14),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'OK',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}



class SubjectView extends StatelessWidget {
  final int? selectedClassId;
  final List<ClassModel> allClasses;
  final ValueChanged<int?> onClassFilterChanged;

  const SubjectView({
    super.key,
    this.selectedClassId,
    required this.allClasses,
    required this.onClassFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final canAdd = userProvider.hasPermission('M004', 'add');

    print('🏗️ SubjectView: Building...');
    return BlocBuilder<AcademicsBloc, AcademicsState>(
      buildWhen: (previous, current) {
        final shouldRebuild = current is SubjectsLoaded || current is AcademicsLoading;
        print('🏗️ SubjectView buildWhen: previous=${previous.runtimeType}, current=${current.runtimeType}, shouldRebuild=$shouldRebuild');
        return shouldRebuild;
      },
      builder: (context, state) {
        print('🏗️ SubjectView builder: state=${state.runtimeType}');

        if (state is AcademicsLoading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(64.0),
              child: BeautifulLoader(
                type: LoaderType.dots,
                message: 'Loading chapters...',
                color: AppTheme.primaryGreen,
                size: 50,
              ),
            ),
          );
        }


        if (state is SubjectsLoaded) {
          print('✅ SubjectView: SubjectsLoaded with ${state.subjects.length} subjects');

          return MasterViewTemplate(
            key: ValueKey('subjects_${state.subjects.length}_${DateTime.now().millisecondsSinceEpoch}'),
            title: "All Subjects",
            buttonLabel: canAdd ? "Add Subject" : null,
            buttonIcon: Iconsax.add,
            onAddPressed: canAdd ? () {
              print('➕ SubjectView: Add button clicked');
              print('🔐 SubjectView: Checking ADD permission for M004');
              if (userProvider.hasPermission('M004', 'add')) {
                print('✅ SubjectView: ADD permission granted');
                showAddSubjectDialog(context, allClasses);
              } else {
                print('❌ SubjectView: ADD permission denied');
                _showPermissionDeniedDialog(context, 'add subjects');
              }
            } : null,
            filters: allClasses.isNotEmpty
                ? SingleFilter(
              label: "Filter by Class",
              selectedValue: selectedClassId,
              items: allClasses,
              onChanged: onClassFilterChanged,
            )
                : null,
            header: const ResponsiveTableHeader(headers: [
              HeaderItem(text: "SUBJECT", flex: 3),
              HeaderItem(text: "CLASS", flex: 3),
              HeaderItem(text: "CHAPTERS", flex: 2),
              HeaderItem(text: "STATUS", flex: 2),
              HeaderItem(text: "ACTIONS", flex: 1, alignment: Alignment.centerRight),
            ]),
            itemCount: state.subjects.isEmpty ? 1 : state.subjects.length,
            itemBuilder: (context, index) {
              if (state.subjects.isEmpty) {
                print('⚠️ SubjectView: No subjects to display');
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: Text('No subjects available')),
                );
              }

              print('📋 SubjectView: Building SubjectListItem for index $index');
              return SubjectListItem(
                key: ValueKey('subject_${state.subjects[index].id}'),
                item: state.subjects[index],
                allClasses: allClasses,
              );
            },
          );
        }

        print('⚠️ SubjectView: Unknown state, showing empty');
        return const SizedBox.shrink();
      },
    );
  }
}

class MaterialView extends StatelessWidget {
  final int? selectedClassId;
  final int? selectedSubjectId;
  final int? selectedChapterId;
  final List<ClassModel> allClasses;
  final List<SubjectModel> allSubjects;
  final List<ChapterModel> allChapters;
  final ValueChanged<int?> onClassFilterChanged;
  final ValueChanged<int?> onSubjectFilterChanged;
  final ValueChanged<int?> onChapterFilterChanged;

  const MaterialView({
    super.key,
    this.selectedClassId,
    this.selectedSubjectId,
    this.selectedChapterId,
    required this.allClasses,
    required this.allSubjects,
    required this.allChapters,
    required this.onClassFilterChanged,
    required this.onSubjectFilterChanged,
    required this.onChapterFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final canAdd = userProvider.hasPermission('M004', 'add');
    print('🏗️ MaterialView: Building...');
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    print('📱 MaterialView: Screen width=$screenWidth, isMobile=$isMobile');

    return BlocBuilder<AcademicsBloc, AcademicsState>(
      buildWhen: (previous, current) {
        final shouldRebuild = current is MaterialsLoaded || current is AcademicsLoading;
        print('🏗️ MaterialView buildWhen: shouldRebuild=$shouldRebuild, state=${current.runtimeType}');
        return shouldRebuild;
      },
      builder: (context, state) {
        print('🏗️ MaterialView builder: state=${state.runtimeType}');
        List<MaterialModel> materials = [];
        if (state is MaterialsLoaded) {
          materials = state.materials;
          print('✅ MaterialView: MaterialsLoaded with ${materials.length} materials');
        }

        if (state is AcademicsLoading) {
          print('⏳ MaterialView: Loading state...');
          final screenWidth = MediaQuery.of(context).size.width;
          double maxCrossAxisExtent = screenWidth < 600
              ? (screenWidth < 400 ? screenWidth - 32 : 200)
              : (screenWidth < 900 ? 250 : (screenWidth < 1200 ? 280 : 300));
          double childAspectRatio = screenWidth < 600 ? 0.75 : (screenWidth < 900 ? 0.80 : 0.85);
          double spacing = screenWidth < 900 ? 12 : AppTheme.defaultPadding;

          return GridView.builder(
            key: const ValueKey('grid_skeleton'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(screenWidth < 600 ? 8 : AppTheme.defaultPadding),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxCrossAxisExtent,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return _buildMaterialSkeletonCard(context);
            },
          );
        }

        return MasterViewTemplate(
          key: ValueKey('materials_${materials.length}_${DateTime.now().millisecondsSinceEpoch}'),
          title: "All Materials",
          buttonLabel: canAdd ? "Add Material" : null,
          buttonIcon: Iconsax.add,
          onAddPressed: canAdd
              ? () async {
            print('➕ MaterialView: Add Material button pressed');
            print('🔐 MaterialView: Checking ADD permission for M004');
            if (userProvider.hasPermission('M004', 'add')) {
              print('✅ MaterialView: ADD permission granted');

              // ✅ Navigate to MaterialDetailScreen in Add mode
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MaterialDetailScreen(
                    isAddMode: true,
                    allClasses: allClasses,
                    allSubjects: allSubjects,
                    allChapters: allChapters,
                  ),
                ),
              );

              // Reload materials after adding
              print('🔄 MaterialView: Reloading materials after add');
              context.read<AcademicsBloc>().add(LoadMaterialsEvent());
            } else {
              print('❌ MaterialView: ADD permission denied');
              _showPermissionDeniedDialog(context, 'add materials');
            }
          }
              : null,
          filters: allClasses.isNotEmpty
              ? CascadingFiltersWithChapter(
            selectedClassId: selectedClassId,
            selectedSubjectId: selectedSubjectId,
            selectedChapterId: selectedChapterId,
            allClasses: allClasses,
            allSubjects: allSubjects,
            allChapters: allChapters,
            onClassChanged: (classId) {
              print('🔄 MaterialView: Class filter changed to $classId');
              onClassFilterChanged(classId);
            },
            onSubjectChanged: (subjectId) {
              print('🔄 MaterialView: Subject filter changed to $subjectId');
              onSubjectFilterChanged(subjectId);
            },
            onChapterChanged: (chapterId) {
              print('🔄 MaterialView: Chapter filter changed to $chapterId');
              onChapterFilterChanged(chapterId);
            },
          )
              : null,
          headerActions: [
            LayoutBuilder(
              builder: (context, constraints) {
                print('📐 MaterialView headerActions: constraints.maxWidth=${constraints.maxWidth}');
                return Container(
                  width: isMobile ? double.infinity : null,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.borderGrey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: context.read<AcademicsBloc>().currentMaterialTypeFilter,
                    underline: const SizedBox(),
                    isExpanded: isMobile,
                    icon: const Icon(Iconsax.arrow_down_1, size: 18),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.darkText,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Types')),
                      DropdownMenuItem(value: 'Video', child: Text('Video')),
                      DropdownMenuItem(value: 'Worksheet', child: Text('Worksheet')),
                      DropdownMenuItem(value: 'Extra Questions', child: Text('Extra Questions')),
                      DropdownMenuItem(value: 'Solved Questions', child: Text('Solved Questions')),
                      DropdownMenuItem(value: 'Revision Notes', child: Text('Revision Notes')),
                      DropdownMenuItem(value: 'Lesson Plans', child: Text('Lesson Plans')),
                      DropdownMenuItem(value: 'Teaching Aids', child: Text('Teaching Aids')),
                      DropdownMenuItem(value: 'Assessment Tools', child: Text('Assessment Tools')),
                      DropdownMenuItem(value: 'Homework Tools', child: Text('Homework Tools')),
                      DropdownMenuItem(value: 'Practice Zone', child: Text('Practice Zone')),
                      DropdownMenuItem(value: 'Learning Path', child: Text('Learning Path')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        print('🔄 MaterialView: Material type filter changed to $value');
                        context.read<AcademicsBloc>().add(FilterMaterialsByTypeEvent(value));
                      }
                    },
                  ),
                );
              },
            ),
          ],
          placeHeaderActionsOnNewRow: isMobile,
          header: const SizedBox.shrink(),
          itemCount: 1,
          itemBuilder: (context, index) {
            if (materials.isEmpty) {
              print('⚠️ MaterialView: No materials to display');
              return const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: Text('No materials available')),
              );
            }

            print('🎨 MaterialView: Building grid view with ${materials.length} materials');
            return buildGridView(context, materials, allSubjects);
          },
        );

      },
    );
  }

  // Add this method inside the MaterialView class in academics_screen.dart

  Widget buildGridView(BuildContext context, List<MaterialModel> materials, List<SubjectModel> allSubjects) {
    final screenWidth = MediaQuery.of(context).size.width;

    double maxCrossAxisExtent = screenWidth < 600
        ? (screenWidth < 400 ? screenWidth - 32 : 200)
        : (screenWidth < 900 ? 250 : (screenWidth < 1200 ? 280 : 300));

    double childAspectRatio = screenWidth < 600 ? 0.75 : (screenWidth < 900 ? 0.80 : 0.85);
    double spacing = screenWidth < 900 ? 12 : AppTheme.defaultPadding;

    return GridView.builder(
      key: const ValueKey('grid_materials'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(screenWidth < 600 ? 8 : AppTheme.defaultPadding),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        return MaterialGridItem(
          key: ValueKey('material_${materials[index].recNo}'),
          item: materials[index],
          allSubjects: allSubjects,
        );
      },
    );
  }


  Widget _buildMaterialSkeletonCard(BuildContext context) {
    final color = AppTheme.borderGrey;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _SkeletonBox(borderRadius: 12),
          ),
          SizedBox(height: 10),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonLine(widthFactor: 0.9),
                SizedBox(height: 8),
                _SkeletonLine(widthFactor: 0.5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  final double borderRadius;

  const _SkeletonBox({this.borderRadius = 8});

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment(-1.0 - 0.3 + 0.6 * _controller.value, 0),
                end: Alignment(1.0 + 0.3 + 0.6 * _controller.value, 0),
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade300,
                  Colors.grey.shade200,
                ],
                stops: const [0.2, 0.5, 0.8],
              ).createShader(rect);
            },
            child: Container(color: Colors.white),
            blendMode: BlendMode.srcATop,
          );
        },
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double widthFactor;

  const _SkeletonLine({this.widthFactor = 1});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: const _SkeletonBox(borderRadius: 6),
    );
  }
}

// Permission Denied Dialog Helper
void _showPermissionDeniedDialog(BuildContext context, String action) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.shield_cross, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Permission Denied',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'You do not have permission to $action. Please contact your administrator.',
        style: GoogleFonts.inter(color: AppTheme.bodyText),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('Understood', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}
