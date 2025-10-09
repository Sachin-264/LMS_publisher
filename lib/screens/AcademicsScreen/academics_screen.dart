import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Service/academics_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/screens/AcademicsScreen/academics_content.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'academics_bloc.dart';


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
  List<ClassModel> _allClasses = [];
  List<SubjectModel> _allSubjects = [];

  @override
  void initState() {
    super.initState();
    _loadFiltersData();
    _loadViewData();
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

    // Always refresh the filter data first
    _loadFiltersData();

    // Then load the primary data for the current view
    switch (_currentView) {
      case _AcademicViewType.classes:
        print('🔄 Tab changed to Classes. Loading latest classes...');
        bloc.add(LoadClassesEvent(schoolRecNo: 1));
        break;
      case _AcademicViewType.subjects:
        print('🔄 Tab changed to Subjects. Loading latest classes and subjects...');
        // We need the latest classes to populate the filter
        bloc.add(LoadClassesEvent(schoolRecNo: 1));
        // Then load subjects (it will use the selected class if any)
        bloc.add(LoadSubjectsEvent(schoolRecNo: 1, classId: _selectedClassId));
        break;
      case _AcademicViewType.chapters:
        print('🔄 Tab changed to Chapters. Loading latest classes, subjects, and chapters...');
        // We need the latest classes and subjects for the filters
        bloc.add(LoadClassesEvent(schoolRecNo: 1));
        bloc.add(LoadSubjectsEvent(schoolRecNo: 1, classId: _selectedClassId));
        // Then load chapters
        bloc.add(LoadChaptersEvent(schoolRecNo: 1, classId: _selectedClassId, subjectId: _selectedSubjectId));
        break;
      case _AcademicViewType.materials:
        print('🔄 Tab changed to Materials. Loading latest classes, subjects, chapters, and materials...');
        // We need the latest classes, subjects, and chapters for the filters
        bloc.add(LoadClassesEvent(schoolRecNo: 1));
        bloc.add(LoadSubjectsEvent(schoolRecNo: 1, classId: _selectedClassId));
        // Load chapters for the selected subject to populate the chapter filter
        if (_selectedSubjectId != null) {
          bloc.add(LoadChaptersEvent(schoolRecNo: 1, subjectId: _selectedSubjectId));
        }
        // Then load materials
        bloc.add(LoadMaterialsEvent(schoolRecNo: 1, classId: _selectedClassId, subjectId: _selectedSubjectId));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
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

// In the _buildSwitchButton method, ensure _loadViewData is called
  Widget _buildSwitchButton(String text, IconData icon, int index, int currentIndex) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentView = _AcademicViewType.values[index];
            // Reset selections when going back to broader views
            if (index == 0) { // Classes
              _selectedClassId = null;
              _selectedSubjectId = null;
            } else if (index == 1) { // Subjects
              _selectedSubjectId = null;
            }
          });
          // Load all necessary data for the new view
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
          allSubjects: _allSubjects.where((s) => _selectedClassId == null || s.id == _selectedClassId.toString()).toList(),
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
          allClasses: _allClasses,
          allSubjects: _allSubjects.where((s) => _selectedClassId == null || s.id == _selectedClassId.toString()).toList(),
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
    }
  }
}

class AcademicsDashboard extends StatelessWidget {
  const AcademicsDashboard();

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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is ClassesLoaded) {
          print('✅ ClassView: ClassesLoaded with ${state.classes.length} classes');

          if (state.classes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text('No classes available'),
              ),
            );
          }

          return MasterViewTemplate(
            key: ValueKey('classes_${state.classes.length}_${DateTime.now().millisecondsSinceEpoch}'),
            title: "All Classes",
            buttonLabel: "Add Class",
            onAddPressed: () => showAddClassDialog(context),
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
    print('🏗️ ChapterView: Building...');

    return BlocBuilder<AcademicsBloc, AcademicsState>(
      buildWhen: (previous, current) {
        final shouldRebuild = current is ChaptersLoaded || current is AcademicsLoading;
        print('🏗️ ChapterView buildWhen: shouldRebuild=$shouldRebuild');
        return shouldRebuild;
      },
      builder: (context, state) {
        print('🏗️ ChapterView builder: state=${state.runtimeType}');

        if (state is AcademicsLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is ChaptersLoaded) {
          print('✅ ChapterView: ChaptersLoaded with ${state.chapters.length} chapters');

          return MasterViewTemplate(
            key: ValueKey('chapters_${state.chapters.length}_${DateTime.now().millisecondsSinceEpoch}'),
            title: "All Chapters",
            buttonLabel: "Add Chapter",
            onAddPressed: () => showAddChapterDialog(context, allClasses, allSubjects),
            filters: allClasses.isNotEmpty
                ? CascadingFilters(
              selectedClassId: selectedClassId,
              selectedSubjectId: selectedSubjectId,
              allClasses: allClasses,
              allSubjects: allSubjects,
              onClassChanged: onClassFilterChanged,
              onSubjectChanged: onSubjectFilterChanged,
            )
                : null,
            header: const ResponsiveTableHeader(headers: [
              HeaderItem(text: "CHAPTER", flex: 4),
              HeaderItem(text: "SUBJECT", flex: 3),
              HeaderItem(text: "MATERIALS", flex: 2),
              HeaderItem(text: "ACTIONS", flex: 1, alignment: Alignment.centerRight),
            ]),
            itemCount: state.chapters.isEmpty ? 1 : state.chapters.length,
            itemBuilder: (context, index) {
              if (state.chapters.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: Text('No chapters available')),
                );
              }

              return ChapterListItem(
                key: ValueKey('chapter_${state.chapters[index].id}'),
                item: state.chapters[index],
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

class MaterialView extends StatelessWidget {
  final int? selectedClassId;
  final int? selectedSubjectId;
  final List<ClassModel> allClasses;
  final List<SubjectModel> allSubjects;
  final ValueChanged<int?> onClassFilterChanged;
  final ValueChanged<int?> onSubjectFilterChanged;

  const MaterialView({
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return MasterViewTemplate(
          key: ValueKey('materials_${materials.length}_${DateTime.now().millisecondsSinceEpoch}'),
          title: "All Materials",
          buttonLabel: "Add Material",
          onAddPressed: () {
            print('➕ MaterialView: Add Material button pressed');
            showAddMaterialDialog(context, allClasses, allSubjects);
          },
          filters: allClasses.isNotEmpty
              ? CascadingFilters(
            selectedClassId: selectedClassId,
            selectedSubjectId: selectedSubjectId,
            allClasses: allClasses,
            allSubjects: allSubjects,
            onClassChanged: (classId) {
              print('🔄 MaterialView: Class filter changed to $classId');
              onClassFilterChanged(classId);
            },
            onSubjectChanged: (subjectId) {
              print('🔄 MaterialView: Subject filter changed to $subjectId');
              onSubjectFilterChanged(subjectId);
            },
          )
              : null,
          headerActions: [
            // RESPONSIVE Header Actions with Type Filter
            LayoutBuilder(
              builder: (context, constraints) {
                print('📐 MaterialView headerActions: constraints.maxWidth=${constraints.maxWidth}');

                // Mobile layout (< 700px) - Use Column to stack vertically
                if (constraints.maxWidth < 700) {
                  print('📱 MaterialView: Using MOBILE header layout');
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Material Type Filter (Full Width)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppTheme.borderGrey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: context.read<AcademicsBloc>().currentMaterialTypeFilter,
                          underline: const SizedBox(),
                          isExpanded: true, // Important for mobile to prevent overflow
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
                      ),
                    ],
                  );
                }

                // Desktop/Tablet layout (>= 700px)
                print('🖥️ MaterialView: Using DESKTOP header layout');
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.borderGrey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: context.read<AcademicsBloc>().currentMaterialTypeFilter,
                    underline: const SizedBox(),
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

  Widget buildGridView(BuildContext context, List<MaterialModel> materials, List<SubjectModel> allSubjects) {
    final screenWidth = MediaQuery.of(context).size.width;
    print('🎨 buildGridView: Building grid for ${materials.length} materials, screenWidth=$screenWidth');

    // Responsive grid configuration
    double maxCrossAxisExtent;
    double childAspectRatio;
    double crossAxisSpacing;
    double mainAxisSpacing;

    if (screenWidth < 600) {
      // Mobile phones (single column or 2 columns)
      maxCrossAxisExtent = screenWidth < 400 ? screenWidth - 32 : 200;
      childAspectRatio = 0.75;
      crossAxisSpacing = 12;
      mainAxisSpacing = 12;
      print('📱 buildGridView: MOBILE grid config - maxExtent=$maxCrossAxisExtent, aspectRatio=$childAspectRatio');
    } else if (screenWidth < 900) {
      // Tablets (2-3 columns)
      maxCrossAxisExtent = 250;
      childAspectRatio = 0.80;
      crossAxisSpacing = 16;
      mainAxisSpacing = 16;
      print('📱 buildGridView: TABLET grid config - maxExtent=$maxCrossAxisExtent, aspectRatio=$childAspectRatio');
    } else if (screenWidth < 1200) {
      // Small Desktop (3-4 columns)
      maxCrossAxisExtent = 280;
      childAspectRatio = 0.85;
      crossAxisSpacing = AppTheme.defaultPadding;
      mainAxisSpacing = AppTheme.defaultPadding;
      print('🖥️ buildGridView: SMALL DESKTOP grid config - maxExtent=$maxCrossAxisExtent, aspectRatio=$childAspectRatio');
    } else {
      // Large Desktop (4+ columns)
      maxCrossAxisExtent = 300;
      childAspectRatio = 0.85;
      crossAxisSpacing = AppTheme.defaultPadding;
      mainAxisSpacing = AppTheme.defaultPadding;
      print('🖥️ buildGridView: LARGE DESKTOP grid config - maxExtent=$maxCrossAxisExtent, aspectRatio=$childAspectRatio');
    }

    return GridView.builder(
      key: const ValueKey('grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(screenWidth < 600 ? 8 : AppTheme.defaultPadding),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        print('🎨 buildGridView: Building item $index - ${materials[index].name}');
        return MaterialGridItem(
          key: ValueKey('material_${materials[index].id}'),
          item: materials[index],
          allSubjects: allSubjects,
        );
      },
    );
  }
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
    print('🏗️ SubjectView: Building...');

    return BlocBuilder<AcademicsBloc, AcademicsState>(
      buildWhen: (previous, current) {
        // Force rebuild on SubjectsLoaded or Loading states
        final shouldRebuild = current is SubjectsLoaded || current is AcademicsLoading;
        print('🏗️ SubjectView buildWhen: previous=${previous.runtimeType}, current=${current.runtimeType}, shouldRebuild=$shouldRebuild');
        return shouldRebuild;
      },
      builder: (context, state) {
        print('🏗️ SubjectView builder: state=${state.runtimeType}');

        if (state is AcademicsLoading) {
          print('⏳ SubjectView: Showing loading indicator');
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is SubjectsLoaded) {
          print('✅ SubjectView: SubjectsLoaded with ${state.subjects.length} subjects');

          return MasterViewTemplate(
            key: ValueKey('subjects_${state.subjects.length}_${DateTime.now().millisecondsSinceEpoch}'), // Force rebuild
            title: "All Subjects",
            buttonLabel: "Add Subject",
            onAddPressed: () {
              print('➕ SubjectView: Add button clicked');
              showAddSubjectDialog(context, allClasses);
            },
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
                key: ValueKey('subject_${state.subjects[index].id}'), // Add unique key
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