
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Service/academics_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'academics_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

const String _imageBaseUrl = "https://storage.googleapis.com/upload-images-34/images/LMS/";
const String _documentBaseUrl = "https://storage.googleapis.com/upload-images-34/documents/LMS/";
String getFullDocumentUrl(String filename) {
  if (filename.isEmpty) return '';
  // Use the appropriate base URL based on file extension
  final fileExtension = filename.split('.').last.toLowerCase();
  final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(fileExtension);

  if (isImage) {
    return '$_imageBaseUrl$filename';
  } else {
    return '$_documentBaseUrl$filename';
  }
}


// ADD THIS NEW UTILITY FUNCTION
void showConfirmDeleteDialog(BuildContext context, String itemName, Color color, VoidCallback onDelete) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Confirm Deletion',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppTheme.darkText),
      ),
      content: Text(
        'Are you sure you want to permanently delete "$itemName"? This action cannot be undone. All associated data will also be lost.',
        style: GoogleFonts.inter(color: AppTheme.bodyText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.bodyText)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Close dialog
            onDelete(); // Perform the delete action
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

// ==================== NEW REUSABLE DROPDOWN WIDGET ====================

class StyledDropdownField<T> extends StatelessWidget {
final String label;
final String hint;
final IconData icon;
final T? selectedValue;
final List<DropdownMenuItem<T>> items;
final ValueChanged<T?>? onChanged;
final VoidCallback? onClear;
final bool enabled;

const StyledDropdownField({
super.key,
required this.label,
required this.icon,
required this.selectedValue,
required this.items,
required this.onChanged,
this.hint = '',
this.onClear,
this.enabled = true,
});

@override
Widget build(BuildContext context) {
return DropdownButtonFormField<T>(
value: selectedValue,
decoration: _buildDialogInputDecoration(label, icon, hint: hint, enabled: enabled).copyWith(
suffixIcon: selectedValue != null && onChanged != null
? IconButton(
icon: const Icon(Icons.clear, size: 20),
onPressed: enabled ? onClear : null,
color: enabled ? AppTheme.bodyText.withOpacity(0.7) : AppTheme.borderGrey,
)
    : null,
// Remove default dropdown icon if present in decoration
suffixIconConstraints: BoxConstraints.tightFor(width: 40, height: 40),
),
items: items,
onChanged: enabled ? onChanged : null,
isExpanded: true,
dropdownColor: Colors.white,
style: GoogleFonts.inter(color: enabled ? AppTheme.darkText : AppTheme.bodyText, fontSize: 15),
icon: Icon(Iconsax.arrow_down_1, size: 20, color: enabled ? AppTheme.primaryGreen : AppTheme.borderGrey),
);
}
}

// ==================== REUSABLE WIDGETS (UPDATED) ====================

class SummaryCard extends StatelessWidget {
final IconData icon;
final Color color;
final String value, label;
final bool isLoading;

const SummaryCard({
super.key,
required this.icon,
required this.color,
required this.value,
required this.label,
this.isLoading = false,
});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.all(AppTheme.defaultPadding * 1.2),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: AppTheme.borderGrey.withOpacity(0.3)),
boxShadow: [
BoxShadow(
color: color.withOpacity(0.08),
blurRadius: 20,
offset: const Offset(0, 8),
)
],
),
child: Row(children: [
Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.circular(14),
),
child: Icon(icon, size: 26, color: color),
),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
isLoading
? Container(
width: 50,
height: 28,
decoration: BoxDecoration(
color: AppTheme.borderGrey.withOpacity(0.2),
borderRadius: BorderRadius.circular(6),
),
)
    : Text(
value,
style: GoogleFonts.poppins(
fontWeight: FontWeight.w700,
fontSize: 28,
color: AppTheme.darkText,
),
),
const SizedBox(height: 4),
Text(
label,
style: GoogleFonts.inter(
color: AppTheme.bodyText,
fontSize: 13,
fontWeight: FontWeight.w500,
),
overflow: TextOverflow.ellipsis,
),
],
),
),
]),
);
}
}

class ViewSwitcher extends StatelessWidget {
final dynamic currentView;
final ValueChanged<dynamic> onViewChanged;
const ViewSwitcher({super.key, required this.currentView, required this.onViewChanged});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.all(6),
decoration: BoxDecoration(
color: AppTheme.borderGrey.withOpacity(0.15),
borderRadius: BorderRadius.circular(14),
),
child: SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: Row(children: [
SwitcherButton(text: 'Classes', icon: Iconsax.building, isActive: currentView.toString().contains('classes'), onTap: () => onViewChanged(0)),
SwitcherButton(text: 'Subjects', icon: Iconsax.book_1, isActive: currentView.toString().contains('subjects'), onTap: () => onViewChanged(1)),
SwitcherButton(text: 'Chapters', icon: Iconsax.document_text, isActive: currentView.toString().contains('chapters'), onTap: () => onViewChanged(2)),
SwitcherButton(text: 'Materials', icon: Iconsax.folder_open, isActive: currentView.toString().contains('materials'), onTap: () => onViewChanged(3)),
]),
),
);
}
}

class SwitcherButton extends StatelessWidget {
final String text;
final IconData icon;
final bool isActive;
final VoidCallback onTap;

const SwitcherButton({super.key, required this.text, required this.icon, required this.isActive, required this.onTap});

@override
Widget build(BuildContext context) {
return GestureDetector(
onTap: onTap,
child: AnimatedContainer(
duration: const Duration(milliseconds: 250),
curve: Curves.easeInOut,
margin: const EdgeInsets.all(3),
padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
decoration: BoxDecoration(
color: isActive ? Colors.white : Colors.transparent,
borderRadius: BorderRadius.circular(11),
boxShadow: isActive
? [
BoxShadow(
color: AppTheme.primaryGreen.withOpacity(0.15),
spreadRadius: 1,
blurRadius: 8,
offset: const Offset(0, 2),
)
]
    : [],
),
child: Row(children: [
Icon(icon, size: 19, color: isActive ? AppTheme.primaryGreen : AppTheme.bodyText),
const SizedBox(width: 10),
Text(
text,
style: GoogleFonts.inter(
fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
color: isActive ? AppTheme.primaryGreen : AppTheme.bodyText,
fontSize: 14,
),
),
]),
),
);
}
}

// SingleFilter UPDATED to use StyledDropdownField
class SingleFilter extends StatelessWidget {
final String label;
final int? selectedValue;
final List<ClassModel> items;
final ValueChanged<int?> onChanged;

const SingleFilter({super.key, required this.label, this.selectedValue, required this.items, required this.onChanged});

@override
Widget build(BuildContext context) {
return Padding(
padding: const EdgeInsets.only(bottom: AppTheme.defaultPadding),
child: StyledDropdownField<int>(
label: label,
icon: Iconsax.building, // Default icon for SingleFilter
selectedValue: selectedValue,
items: items.map((item) => DropdownMenuItem(value: int.parse(item.id), child: Text(item.name))).toList(),
onChanged: onChanged,
onClear: () => onChanged(null),
),
);
}
}

class ChaptersPage extends StatefulWidget {
  const ChaptersPage({super.key});

  @override
  State<ChaptersPage> createState() => _ChaptersPageState();
}

class _ChaptersPageState extends State<ChaptersPage> {
  int? selectedClassId;
  int? selectedSubjectId;
  List<ClassModel> allClasses = [];
  List<SubjectModel> allSubjects = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    print('📖 ChaptersPage: Loading initial data...');
    try {
      // Load classes
      final classesResponse = await ApiService.getClasses(schoolRecNo: 1);
      if (classesResponse['success'] == true && classesResponse['data'] != null) {
        setState(() {
          allClasses = (classesResponse['data'] as List).map((json) => ClassModel.fromJson(json)).toList();
        });
        print('✅ ChaptersPage: Loaded ${allClasses.length} classes');
      }

      // Load all subjects
      final subjectsResponse = await ApiService.getSubjects(schoolRecNo: 1);
      if (subjectsResponse['success'] == true && subjectsResponse['data'] != null) {
        setState(() {
          allSubjects = (subjectsResponse['data'] as List).map((json) => SubjectModel.fromJson(json)).toList();
        });
        print('✅ ChaptersPage: Loaded ${allSubjects.length} subjects');
      }

      // Load all chapters initially
      context.read<AcademicsBloc>().add(LoadChaptersEvent(schoolRecNo: 1));
    } catch (e) {
      print('❌ ChaptersPage: Error loading initial data: $e');
    }
  }

  void _onClassChanged(int? classId) {
    print('🔎 ChaptersPage: Class changed to $classId');
    setState(() {
      selectedClassId = classId;
      selectedSubjectId = null;
    });

    // Don't reload chapters yet - wait for subject selection
    print('⏳ ChaptersPage: Waiting for subject selection before loading chapters');
  }

  void _onSubjectChanged(int? subjectId) {
    print('🔎 ChaptersPage: Subject changed to $subjectId');
    setState(() {
      selectedSubjectId = subjectId;
    });

    // Now load chapters based on the selected subject
    if (subjectId != null) {
      print('📖 ChaptersPage: Loading chapters for subject $subjectId');
      context.read<AcademicsBloc>().add(LoadChaptersEvent(
        schoolRecNo: 1,
        subjectId: subjectId,
      ));
    } else {
      // If subject is cleared, load all chapters
      print('📖 ChaptersPage: Loading all chapters');
      context.read<AcademicsBloc>().add(LoadChaptersEvent(schoolRecNo: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AcademicsBloc, AcademicsState>(
      builder: (context, state) {
        List<ChapterModel> chapters = [];
        bool isLoading = state is AcademicsLoading;

        if (state is ChaptersLoaded) {
          chapters = state.chapters;
        }

        return MasterViewTemplate(
          title: 'Chapters',
          buttonLabel: 'Add Chapter',
          onAddPressed: () => showAddChapterDialog(context, allClasses, allSubjects),
          header: const ResponsiveTableHeader(headers: [
            HeaderItem(text: 'Chapter Name', flex: 4),
            HeaderItem(text: 'Subject', flex: 3),
            HeaderItem(text: 'Materials', flex: 2),
            HeaderItem(text: 'Actions', flex: 1, alignment: Alignment.centerRight),
          ]),
          filters: CascadingFilters(
            selectedClassId: selectedClassId,
            selectedSubjectId: selectedSubjectId,
            allClasses: allClasses,
            allSubjects: allSubjects,
            onClassChanged: _onClassChanged,
            onSubjectChanged: _onSubjectChanged,
          ),
          itemCount: isLoading ? 3 : chapters.length,
          itemBuilder: (context, index) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return ChapterListItem(
              item: chapters[index],
              allSubjects: allSubjects,
            );
          },
        );
      },
    );
  }
}


class MaterialsPage extends StatefulWidget {
  const MaterialsPage({super.key});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  int? selectedClassId;
  int? selectedSubjectId;
  int? selectedChapterId;
  String selectedMaterialType = 'All';

  List<ClassModel> allClasses = [];
  List<SubjectModel> allSubjects = [];
  List<ChapterModel> allChapters = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    print('📁 MaterialsPage: Loading initial data...');
    try {
      // Load classes
      final classesResponse = await ApiService.getClasses(schoolRecNo: 1);
      if (classesResponse['success'] == true && classesResponse['data'] != null) {
        setState(() {
          allClasses = (classesResponse['data'] as List).map((json) => ClassModel.fromJson(json)).toList();
        });
        print('✅ MaterialsPage: Loaded ${allClasses.length} classes');
      }

      // Load all subjects
      final subjectsResponse = await ApiService.getSubjects(schoolRecNo: 1);
      if (subjectsResponse['success'] == true && subjectsResponse['data'] != null) {
        setState(() {
          allSubjects = (subjectsResponse['data'] as List).map((json) => SubjectModel.fromJson(json)).toList();
        });
        print('✅ MaterialsPage: Loaded ${allSubjects.length} subjects');
      }

      // Load all materials initially
      context.read<AcademicsBloc>().add(LoadMaterialsEvent(schoolRecNo: 1));
    } catch (e) {
      print('❌ MaterialsPage: Error loading initial data: $e');
    }
  }

  void _onClassChanged(int? classId) {
    print('🔎 MaterialsPage: Class changed to $classId');
    setState(() {
      selectedClassId = classId;
      selectedSubjectId = null;
      selectedChapterId = null;
      allChapters = [];
    });

    // Don't reload materials yet - wait for subject selection
    print('⏳ MaterialsPage: Waiting for subject selection before loading materials');
  }

  Future<void> _onSubjectChanged(int? subjectId) async {
    print('🔎 MaterialsPage: Subject changed to $subjectId');
    setState(() {
      selectedSubjectId = subjectId;
      selectedChapterId = null;
      allChapters = [];
    });

    if (subjectId != null) {
      // Load chapters for the selected subject
      print('📖 MaterialsPage: Loading chapters for subject $subjectId');
      try {
        final chaptersResponse = await ApiService.getChapters(
          schoolRecNo: 1,
          subjectId: subjectId,
        );
        if (chaptersResponse['success'] == true && chaptersResponse['data'] != null) {
          setState(() {
            allChapters = (chaptersResponse['data'] as List).map((json) => ChapterModel.fromJson(json)).toList();
          });
          print('✅ MaterialsPage: Loaded ${allChapters.length} chapters');
        }
      } catch (e) {
        print('❌ MaterialsPage: Error loading chapters: $e');
      }

      // Now load materials for the selected subject
      print('📁 MaterialsPage: Loading materials for subject $subjectId');
      context.read<AcademicsBloc>().add(LoadMaterialsEvent(
        schoolRecNo: 1,
        subjectId: subjectId,
      ));
    } else {
      // If subject is cleared, load all materials
      print('📁 MaterialsPage: Loading all materials');
      context.read<AcademicsBloc>().add(LoadMaterialsEvent(schoolRecNo: 1));
    }
  }

  void _onChapterChanged(int? chapterId) {
    print('🔎 MaterialsPage: Chapter changed to $chapterId');
    setState(() {
      selectedChapterId = chapterId;
    });

    if (chapterId != null) {
      print('📁 MaterialsPage: Loading materials for chapter $chapterId');
      context.read<AcademicsBloc>().add(LoadMaterialsEvent(
        schoolRecNo: 1,
        subjectId: selectedSubjectId,
        chapterId: chapterId,
      ));
    } else if (selectedSubjectId != null) {
      // Load materials for the subject
      print('📁 MaterialsPage: Loading materials for subject $selectedSubjectId');
      context.read<AcademicsBloc>().add(LoadMaterialsEvent(
        schoolRecNo: 1,
        subjectId: selectedSubjectId,
      ));
    } else {
      // Load all materials
      print('📁 MaterialsPage: Loading all materials');
      context.read<AcademicsBloc>().add(LoadMaterialsEvent(schoolRecNo: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AcademicsBloc, AcademicsState>(
      builder: (context, state) {
        List<MaterialModel> materials = [];
        bool isLoading = state is AcademicsLoading;
        bool isGridView = true;

        if (state is MaterialsLoaded) {
          materials = state.materials;
          isGridView = state.isGridView;
        }

        return MasterViewTemplate(
          title: 'Study Materials',
          buttonLabel: 'Add Material',
          onAddPressed: () => showAddMaterialDialog(context, allClasses, allSubjects),
          header: const SizedBox.shrink(),
          headerActions: [
            // Material Type Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.borderGrey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderGrey.withOpacity(0.3)),
              ),
              child: DropdownButton<String>(
                value: selectedMaterialType,
                underline: const SizedBox.shrink(),
                icon: const Icon(Iconsax.arrow_down_1, size: 18),
                items: [
                  'All', 'Video', 'Worksheet', 'Extra Questions', 'Solved Questions',
                  'Revision Notes', 'Lesson Plans', 'Teaching Aids', 'Assessment Tools',
                  'Homework Tools', 'Practice Zone', 'Learning Path'
                ].map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type, style: GoogleFonts.inter(fontSize: 14)),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedMaterialType = value);
                    context.read<AcademicsBloc>().add(FilterMaterialsByTypeEvent(value));
                  }
                },
              ),
            ),
            // View Toggle
            ViewToggleButton(
              icon: Iconsax.grid_1,
              isActive: isGridView,
              onTap: () => context.read<AcademicsBloc>().add(ToggleMaterialViewEvent(true)),
            ),
            ViewToggleButton(
              icon: Iconsax.row_vertical,
              isActive: !isGridView,
              onTap: () => context.read<AcademicsBloc>().add(ToggleMaterialViewEvent(false)),
            ),
          ],
          filters: Column(
            children: [
              // Class, Subject, Chapter Filters
              CascadingFiltersWithChapter(
                selectedClassId: selectedClassId,
                selectedSubjectId: selectedSubjectId,
                selectedChapterId: selectedChapterId,
                allClasses: allClasses,
                allSubjects: allSubjects,
                allChapters: allChapters,
                onClassChanged: _onClassChanged,
                onSubjectChanged: _onSubjectChanged,
                onChapterChanged: _onChapterChanged,
              ),
            ],
          ),
          itemCount: isLoading ? 6 : materials.length,
          itemBuilder: (context, index) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (isGridView) {
              return MaterialGridItem(
                item: materials[index],
                allSubjects: allSubjects,
              );
            } else {
              return Container(); // Add list view if needed
            }
          },
        );
      },
    );
  }
}

// New Cascading Filter Widget with Chapter support
class CascadingFiltersWithChapter extends StatelessWidget {
  final int? selectedClassId;
  final int? selectedSubjectId;
  final int? selectedChapterId;
  final List<ClassModel> allClasses;
  final List<SubjectModel> allSubjects;
  final List<ChapterModel> allChapters;
  final ValueChanged<int?> onClassChanged;
  final ValueChanged<int?> onSubjectChanged;
  final ValueChanged<int?> onChapterChanged;

  const CascadingFiltersWithChapter({
    super.key,
    this.selectedClassId,
    this.selectedSubjectId,
    this.selectedChapterId,
    required this.allClasses,
    required this.allSubjects,
    required this.allChapters,
    required this.onClassChanged,
    required this.onSubjectChanged,
    required this.onChapterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filteredSubjects = selectedClassId != null
        ? allSubjects.where((s) => s.classId == selectedClassId.toString()).toList()
        : allSubjects;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.defaultPadding * 1.5),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(mainAxisSize: MainAxisSize.min, children: [
            _buildClassDropdown(),
            const SizedBox(height: 14),
            _buildSubjectDropdown(filteredSubjects),
            const SizedBox(height: 14),
            _buildChapterDropdown(),
          ]);
        }
        return Row(children: [
          Expanded(child: _buildClassDropdown()),
          const SizedBox(width: 14),
          Expanded(child: _buildSubjectDropdown(filteredSubjects)),
          const SizedBox(width: 14),
          Expanded(child: _buildChapterDropdown()),
        ]);
      }),
    );
  }

  Widget _buildClassDropdown() {
    return StyledDropdownField<int>(
      label: "Select Class",
      icon: Iconsax.building,
      selectedValue: selectedClassId,
      items: allClasses.map((item) => DropdownMenuItem(value: int.parse(item.id), child: Text(item.name))).toList(),
      onChanged: (value) {
        print('🔎 CascadingFiltersWithChapter: Class Changed to $value');
        onClassChanged(value);
        onSubjectChanged(null);
        onChapterChanged(null);
      },
      onClear: () {
        print('🔎 CascadingFiltersWithChapter: Class Cleared');
        onClassChanged(null);
        onSubjectChanged(null);
        onChapterChanged(null);
      },
    );
  }

  Widget _buildSubjectDropdown(List<SubjectModel> subjects) {
    return StyledDropdownField<int>(
      label: "Select Subject",
      icon: Iconsax.book_1,
      selectedValue: selectedSubjectId,
      items: subjects.map((item) => DropdownMenuItem(value: int.parse(item.id), child: Text(item.name))).toList(),
      onChanged: selectedClassId != null ? (value) {
        print('🔎 CascadingFiltersWithChapter: Subject Changed to $value');
        onSubjectChanged(value);
        onChapterChanged(null);
      } : null,
      onClear: () {
        print('🔎 CascadingFiltersWithChapter: Subject Cleared');
        onSubjectChanged(null);
        onChapterChanged(null);
      },
      enabled: selectedClassId != null && subjects.isNotEmpty,
    );
  }

  Widget _buildChapterDropdown() {
    return StyledDropdownField<int>(
      label: "Select Chapter",
      icon: Iconsax.document_text_1,
      selectedValue: selectedChapterId,
      items: allChapters.map((item) => DropdownMenuItem(value: int.parse(item.id), child: Text(item.name))).toList(),
      onChanged: allChapters.isNotEmpty ? (value) {
        print('🔎 CascadingFiltersWithChapter: Chapter Changed to $value');
        onChapterChanged(value);
      } : null,
      onClear: () {
        print('🔎 CascadingFiltersWithChapter: Chapter Cleared');
        onChapterChanged(null);
      },
      enabled: allChapters.isNotEmpty,
    );
  }
}



class CascadingFilters extends StatelessWidget {
final int? selectedClassId;
final int? selectedSubjectId;
final List<ClassModel> allClasses;
final List<SubjectModel> allSubjects;
final ValueChanged<int?> onClassChanged;
final ValueChanged<int?> onSubjectChanged;

const CascadingFilters({
super.key,
this.selectedClassId,
this.selectedSubjectId,
required this.allClasses,
required this.allSubjects,
required this.onClassChanged,
required this.onSubjectChanged,
});

@override
Widget build(BuildContext context) {
final filteredSubjects = selectedClassId != null
? allSubjects.where((s) => s.classId == selectedClassId.toString()).toList()
    : allSubjects;

return Padding(
padding: const EdgeInsets.only(bottom: AppTheme.defaultPadding * 1.5),
child: LayoutBuilder(builder: (context, constraints) {
if (constraints.maxWidth < 700) {
return Column(mainAxisSize: MainAxisSize.min, children: [
_buildClassDropdown(),
const SizedBox(height: 14),
_buildSubjectDropdown(filteredSubjects),
]);
}
return Row(children: [
Expanded(child: _buildClassDropdown()),
const SizedBox(width: 14),
Expanded(child: _buildSubjectDropdown(filteredSubjects)),
const Spacer(flex: 2),
]);
}),
);

}

Widget _buildClassDropdown() {
return StyledDropdownField<int>(
label: "Select Class",
icon: Iconsax.building,
selectedValue: selectedClassId,
items: allClasses.map((item) => DropdownMenuItem(value: int.parse(item.id), child: Text(item.name))).toList(),
onChanged: (value) {
print('🔎 CascadingFilters: Class Changed to $value'); // ADDED PRINT
onClassChanged(value);
onSubjectChanged(null);
},
onClear: () {
print('🔎 CascadingFilters: Class Cleared'); // ADDED PRINT
onClassChanged(null);
onSubjectChanged(null);
},
);
}

Widget _buildSubjectDropdown(List<SubjectModel> subjects) {
return StyledDropdownField<int>(
label: "Select Subject",
icon: Iconsax.book_1,
selectedValue: selectedSubjectId,
items: subjects.map((item) => DropdownMenuItem(value: int.parse(item.id), child: Text(item.name))).toList(),
onChanged: selectedClassId != null ? (value) {
print('🔎 CascadingFilters: Subject Changed to $value'); // ADDED PRINT
onSubjectChanged(value);
} : null,
onClear: () {
print('🔎 CascadingFilters: Subject Cleared'); // ADDED PRINT
onSubjectChanged(null);
},
enabled: selectedClassId != null && subjects.isNotEmpty,
);
}
}

class ViewToggleButton extends StatelessWidget {
final IconData icon;
final bool isActive;
final VoidCallback onTap;

const ViewToggleButton({super.key, required this.icon, required this.isActive, required this.onTap});

@override
Widget build(BuildContext context) {
return InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(10),
child: Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: isActive ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.transparent,
borderRadius: BorderRadius.circular(10),
),
child: Icon(icon, size: 22, color: isActive ? AppTheme.primaryGreen : AppTheme.bodyText),
),
);
}
}

class MasterViewTemplate extends StatelessWidget {
final String title, buttonLabel;
final VoidCallback? onAddPressed;
final Widget header;
final int itemCount;
final IndexedWidgetBuilder itemBuilder;
final Widget? filters;
final List<Widget>? headerActions;

const MasterViewTemplate({
super.key,
required this.title,
required this.buttonLabel,
this.onAddPressed,
required this.header,
required this.itemCount,
required this.itemBuilder,
this.filters,
this.headerActions,
});

@override
Widget build(BuildContext context) {
return StyledContainer(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Expanded(
child: Text(
title,
style: GoogleFonts.poppins(
fontSize: 22,
fontWeight: FontWeight.w600,
color: AppTheme.darkText,
),
),
),
if (headerActions != null) ...headerActions!,
if (headerActions != null) const SizedBox(width: 16),
ElevatedButton.icon(
onPressed: onAddPressed,
icon: const Icon(Iconsax.add, size: 20),
label: Text(buttonLabel, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
style: ElevatedButton.styleFrom(
backgroundColor: AppTheme.primaryGreen,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
elevation: 0,
shadowColor: AppTheme.primaryGreen.withOpacity(0.3),
),
),
],
),
const Divider(height: 40, thickness: 1),
if (filters != null) filters!,
LayoutBuilder(
builder: (context, constraints) {
final isMobile = constraints.maxWidth < 700;
final showHeader = !(header is SizedBox);

return Column(
mainAxisSize: MainAxisSize.min,
children: [
if (!isMobile && showHeader) header,
if (!isMobile && showHeader) const SizedBox(height: 12),
ListView.separated(
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
itemCount: itemCount,
itemBuilder: itemBuilder,
separatorBuilder: (context, index) => const SizedBox(height: 0),
),
],
);
},
),
],
),
);

}
}

class ResponsiveTableHeader extends StatelessWidget {
final List<HeaderItem> headers;
const ResponsiveTableHeader({super.key, required this.headers});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
decoration: BoxDecoration(
color: AppTheme.borderGrey.withOpacity(0.08),
borderRadius: BorderRadius.circular(10),
),
child: Row(
children: headers
    .map((header) => Expanded(
flex: header.flex,
child: Align(
alignment: header.alignment,
child: Text(
header.text,
style: GoogleFonts.inter(
fontWeight: FontWeight.w600,
color: AppTheme.bodyText,
letterSpacing: 0.3,
fontSize: 13,
),
),
),
))
    .toList(),
),
);
}
}

class HeaderItem {
final String text;
final int flex;
final Alignment alignment;
const HeaderItem({required this.text, this.flex = 1, this.alignment = Alignment.centerLeft});
}

class StyledContainer extends StatelessWidget {
final Widget child;
const StyledContainer({super.key, required this.child});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.all(AppTheme.defaultPadding * 2),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(20),
border: Border.all(color: AppTheme.borderGrey.withOpacity(0.3)),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.04),
spreadRadius: 1,
blurRadius: 20,
offset: const Offset(0, 6),
)
],
),
child: child,
);
}
}

class StatusBadge extends StatelessWidget {
final bool isActive;
const StatusBadge({super.key, required this.isActive});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
decoration: BoxDecoration(
color: (isActive ? Colors.green : Colors.grey).withOpacity(0.12),
borderRadius: BorderRadius.circular(8),
border: Border.all(
color: (isActive ? Colors.green : Colors.grey).withOpacity(0.3),
width: 1,
),
),
child: Text(
isActive ? 'Active' : 'Inactive',
style: GoogleFonts.inter(
color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
fontWeight: FontWeight.w600,
fontSize: 12,
),
),
);
}
}

// ==================== REPLACED ClassListItem WIDGET ====================
class ClassListItem extends StatelessWidget {
  final ClassModel item;
  const ClassListItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return EnhancedListItem(
      icon: Iconsax.building_4,
      iconColor: Colors.blue,
      title: item.name,
      subtitle: item.description, // Show description instead of status
      statusBadge: StatusBadge(isActive: item.isActive), // Keep status badge in case it's needed elsewhere
      onEdit: () => showEditClassDialog(context, item),
      onDelete: () => showConfirmDeleteDialog( // ADDED onDelete
        context,
        item.name,
        Colors.blue,
            () => context.read<AcademicsBloc>().add(DeleteClassEvent(classId: int.parse(item.id), hardDelete: true)),
      ),
      onTap: () => showDetailDialog(
        context,
        DetailDialogData(
          title: item.name,
          icon: Iconsax.building_4,
          color: Colors.blue,
          fields: [
            DetailField(label: 'Class Name', value: item.name, icon: Iconsax.edit),
            DetailField(label: 'Description', value: item.description, icon: Iconsax.document_text), // Added description
            DetailField(label: 'Subjects', value: item.subjectCount.toString(), icon: Iconsax.book_1),
            DetailField(label: 'Status', value: item.isActive ? 'Active' : 'Inactive', icon: Iconsax.status),
          ],
          onEdit: () {
            Navigator.pop(context);
            showEditClassDialog(context, item);
          },
        ),
      ),
      webCells: [
        WebCell(flex: 3, child: Text(item.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15))),
        WebCell(
            flex: 3,
            child: Text(
              item.description,
              style: GoogleFonts.inter(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )), // Changed to description
        WebCell(flex: 2, child: Text(item.subjectCount.toString(), style: GoogleFonts.inter(fontSize: 14))),
        WebCell(flex: 1, child: StatusBadge(isActive: item.isActive)), // Status is now in its own column
        WebCell(
          flex: 1,
          alignment: Alignment.centerRight,
          child: ActionButtons(
            onEdit: () => showEditClassDialog(context, item),
            onDelete: () => showConfirmDeleteDialog( // ADDED onDelete
              context,
              item.name,
              Colors.blue,
                  () => context.read<AcademicsBloc>().add(DeleteClassEvent(classId: int.parse(item.id), hardDelete: true)),
            ),
            onView: () => showDetailDialog(
              context,
              DetailDialogData(
                title: item.name,
                icon: Iconsax.building_4,
                color: Colors.blue,
                fields: [
                  DetailField(label: 'Class Name', value: item.name, icon: Iconsax.edit),
                  DetailField(label: 'Description', value: item.description, icon: Iconsax.document_text),
                  DetailField(label: 'Subjects', value: item.subjectCount.toString(), icon: Iconsax.book_1),
                  DetailField(label: 'Status', value: item.isActive ? 'Active' : 'Inactive', icon: Iconsax.status),
                ],
                onEdit: () {
                  Navigator.pop(context);
                  showEditClassDialog(context, item);
                },
              ),
            ),
            usePopupOnMobile: true,
          ),
        ),
      ],
      mobileInfoRows: [
        buildInfoRow(Iconsax.document_text, "Desc: ${item.description}", maxLines: 2), // Changed to description
        const SizedBox(height: 8),
        buildInfoRow(Iconsax.book_1, "Subjects: ${item.subjectCount}"),
      ],
    );
  }
}

class SubjectListItem extends StatelessWidget {
  final SubjectModel item;
  final List<ClassModel> allClasses;

  const SubjectListItem({
    super.key,
    required this.item,
    required this.allClasses,
  });

  @override
  Widget build(BuildContext context) {
    print('📋 SubjectListItem: Rendering ${item.name}');

    return EnhancedListItem(
      icon: Iconsax.book_1,
      iconColor: Colors.green,
      title: item.name,
      subtitle: item.className,
      statusBadge: StatusBadge(isActive: item.isActive),
      onEdit: () {
        print('✏️ SubjectListItem: Edit clicked for ${item.name}');
        showEditSubjectDialog(context, item, allClasses);
      },
      onDelete: () {
        print('🗑️ SubjectListItem: Delete clicked for ${item.name}');
        showConfirmDeleteDialog(
          context,
          item.name,
          Colors.green,
              () {
            print('🗑️ SubjectListItem: Delete confirmed for ${item.name} (ID: ${item.id})');
            context.read<AcademicsBloc>().add(
              DeleteSubjectEvent(
                subjectId: int.parse(item.id),
                hardDelete: true,
              ),
            );
          },
        );
      },
      onTap: () {
        print('👁️ SubjectListItem: View details clicked for ${item.name}');
        showDetailDialog(
          context,
          DetailDialogData(
            title: item.name,
            icon: Iconsax.book_1,
            color: Colors.green,
            fields: [
              DetailField(
                label: 'Subject Name',
                value: item.name,
                icon: Iconsax.edit,
              ),
              DetailField(
                label: 'Class',
                value: item.className,
                icon: Iconsax.building,
              ),
              DetailField(
                label: 'Chapters',
                value: item.chapterCount.toString(),
                icon: Iconsax.document_text,
              ),
              DetailField(
                label: 'Description',
                value: item.description,
                icon: Iconsax.info_circle,
              ),
              DetailField(
                label: 'Status',
                value: item.isActive ? 'Active' : 'Inactive',
                icon: Iconsax.status,
              ),
            ],
            onEdit: () {
              Navigator.pop(context);
              showEditSubjectDialog(context, item, allClasses);
            },
          ),
        );
      },
      webCells: [
        WebCell(
          flex: 3,
          child: Text(
            item.name,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        WebCell(
          flex: 3,
          child: Text(
            item.className,
            style: GoogleFonts.inter(fontSize: 14),
          ),
        ),
        WebCell(
          flex: 2,
          child: Text(
            item.chapterCount.toString(),
            style: GoogleFonts.inter(fontSize: 14),
          ),
        ),
        WebCell(
          flex: 2,
          child: StatusBadge(isActive: item.isActive),
        ),
        WebCell(
          flex: 1,
          alignment: Alignment.centerRight,
          child: ActionButtons(
            onEdit: () {
              print('✏️ SubjectListItem (Web): Edit clicked for ${item.name}');
              showEditSubjectDialog(context, item, allClasses);
            },
            onDelete: () {
              print('🗑️ SubjectListItem (Web): Delete clicked for ${item.name}');
              showConfirmDeleteDialog(
                context,
                item.name,
                Colors.green,
                    () {
                  print('🗑️ SubjectListItem (Web): Delete confirmed for ${item.name} (ID: ${item.id})');
                  context.read<AcademicsBloc>().add(
                    DeleteSubjectEvent(
                      subjectId: int.parse(item.id),
                      hardDelete: true,
                    ),
                  );
                },
              );
            },
            onView: () {
              print('👁️ SubjectListItem (Web): View details clicked for ${item.name}');
              showDetailDialog(
                context,
                DetailDialogData(
                  title: item.name,
                  icon: Iconsax.book_1,
                  color: Colors.green,
                  fields: [
                    DetailField(
                      label: 'Subject Name',
                      value: item.name,
                      icon: Iconsax.edit,
                    ),
                    DetailField(
                      label: 'Class',
                      value: item.className,
                      icon: Iconsax.building,
                    ),
                    DetailField(
                      label: 'Chapters',
                      value: item.chapterCount.toString(),
                      icon: Iconsax.document_text,
                    ),
                    DetailField(
                      label: 'Description',
                      value: item.description,
                      icon: Iconsax.info_circle,
                    ),
                    DetailField(
                      label: 'Status',
                      value: item.isActive ? 'Active' : 'Inactive',
                      icon: Iconsax.status,
                    ),
                  ],
                  onEdit: () {
                    Navigator.pop(context);
                    showEditSubjectDialog(context, item, allClasses);
                  },
                ),
              );
            },
            usePopupOnMobile: true,
          ),
        ),
      ],
      mobileInfoRows: [
        buildInfoRow(
          Iconsax.document_text,
          "Chapters: ${item.chapterCount}",
        ),
        const SizedBox(height: 8),
        buildInfoRow(
          Iconsax.info_circle,
          item.description,
          maxLines: 2,
        ),
      ],
    );
  }
}


// ==================== REPLACED ChapterListItem WIDGET ====================
class ChapterListItem extends StatelessWidget {
  final ChapterModel item;
  final List<SubjectModel> allSubjects;
  const ChapterListItem({super.key, required this.item, required this.allSubjects});

  @override
  Widget build(BuildContext context) {
    return EnhancedListItem(
      icon: Iconsax.document_text_1,
      iconColor: Colors.orange,
      title: item.name,
      subtitle: item.subjectName,
      onEdit: () => showEditChapterDialog(context, item, allSubjects),
      onDelete: () => showConfirmDeleteDialog( // ADDED onDelete
        context,
        item.name,
        Colors.orange,
            () => context.read<AcademicsBloc>().add(DeleteChapterEvent(chapterId: int.parse(item.id), hardDelete: true)),
      ),
      onTap: () => showDetailDialog(
        context,
        DetailDialogData(
          title: item.name,
          icon: Iconsax.document_text_1,
          color: Colors.orange,
          fields: [
            DetailField(label: 'Chapter Name', value: item.name, icon: Iconsax.edit),
            DetailField(label: 'Subject', value: item.subjectName, icon: Iconsax.book_1),
            DetailField(label: 'Materials', value: item.materialCount.toString(), icon: Iconsax.folder_open),
          ],
          onEdit: () {
            Navigator.pop(context);
            showEditChapterDialog(context, item, allSubjects);
          },
        ),
      ),
      webCells: [
        WebCell(flex: 4, child: Text(item.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15))),
        WebCell(flex: 3, child: Text(item.subjectName, style: GoogleFonts.inter(fontSize: 14))),
        WebCell(flex: 2, child: Text(item.materialCount.toString(), style: GoogleFonts.inter(fontSize: 14))),
        WebCell(
          flex: 1,
          alignment: Alignment.centerRight,
          child: ActionButtons(
            onEdit: () => showEditChapterDialog(context, item, allSubjects),
            onDelete: () => showConfirmDeleteDialog( // ADDED onDelete
              context,
              item.name,
              Colors.orange,
                  () => context.read<AcademicsBloc>().add(DeleteChapterEvent(chapterId: int.parse(item.id), hardDelete: true)),
            ),
            onView: () => showDetailDialog(
              context,
              DetailDialogData(
                title: item.name,
                icon: Iconsax.document_text_1,
                color: Colors.orange,
                fields: [
                  DetailField(label: 'Chapter Name', value: item.name, icon: Iconsax.edit),
                  DetailField(label: 'Subject', value: item.subjectName, icon: Iconsax.book_1),
                  DetailField(label: 'Materials', value: item.materialCount.toString(), icon: Iconsax.folder_open),
                ],
                onEdit: () {
                  Navigator.pop(context);
                  showEditChapterDialog(context, item, allSubjects);
                },
              ),
            ),
            usePopupOnMobile: true,
          ),
        ),
      ],
      mobileInfoRows: [
        buildInfoRow(Iconsax.folder_open, "Materials: ${item.materialCount}"),
      ],
    );
  }
}

class MaterialGridItem extends StatefulWidget {
  final MaterialModel item;
  final List<SubjectModel> allSubjects;

  const MaterialGridItem({super.key, required this.item, required this.allSubjects});

  @override
  MaterialGridItemState createState() => MaterialGridItemState();
}


class MaterialGridItemState extends State<MaterialGridItem> {
  bool isHovered = false;

  Map<String, String> getPathsForMaterial(MaterialModel item) {
    Map<String, String> paths = {};

    // Check for YouTube video link first
    if (item.videoLink.isNotEmpty && isYoutubeVideo(item.videoLink)) {
      paths['VideoLink'] = item.videoLink;
    }

    if (item.isVideoFile && item.link.isNotEmpty) {
      paths['VideoFile'] = item.link;
    }
    if (item.worksheetPath.isNotEmpty) {
      paths['WorksheetPath'] = item.worksheetPath;
    }
    if (item.extraQuestionsPath.isNotEmpty) {
      paths['ExtraQuestionsPath'] = item.extraQuestionsPath;
    }
    if (item.solvedQuestionsPath.isNotEmpty) {
      paths['SolvedQuestionsPath'] = item.solvedQuestionsPath;
    }
    if (item.revisionNotesPath.isNotEmpty) {
      paths['RevisionNotesPath'] = item.revisionNotesPath;
    }
    if (item.lessonPlansPath.isNotEmpty) {
      paths['LessonPlansPath'] = item.lessonPlansPath;
    }
    if (item.teachingAidsPath.isNotEmpty) {
      paths['TeachingAidsPath'] = item.teachingAidsPath;
    }
    if (item.assessmentToolsPath.isNotEmpty) {
      paths['AssessmentToolsPath'] = item.assessmentToolsPath;
    }
    if (item.homeworkToolsPath.isNotEmpty) {
      paths['HomeworkToolsPath'] = item.homeworkToolsPath;
    }
    if (item.practiceZonePath.isNotEmpty) {
      paths['PracticeZonePath'] = item.practiceZonePath;
    }
    if (item.learningPathPath.isNotEmpty) {
      paths['LearningPathPath'] = item.learningPathPath;
    }
    return paths;
  }

  @override
  Widget build(BuildContext context) {
    final color = getMaterialColor(widget.item.type);
    final icon = getMaterialIcon(widget.item.type);
    final materialPaths = getPathsForMaterial(widget.item);

    String? firstPath;
    String? firstType;
    for (var entry in materialPaths.entries) {
      if (entry.value.isNotEmpty) {
        firstPath = entry.value;
        firstType = entry.key;
        break;
      }
    }

    // Determine if it's a YouTube video
    final isYouTubeVideo = firstType == 'VideoLink' && firstPath != null && isYoutubeVideo(firstPath);
    final isVideoFile = firstType == 'VideoFile' && firstPath != null && firstPath.isNotEmpty;
    final isDocument = !isYouTubeVideo && !isVideoFile && firstPath != null && firstPath.isNotEmpty;

    String fullDocumentUrl = '';
    if (firstPath != null && firstPath.isNotEmpty) {
      if (isVideoFile) {
        fullDocumentUrl = firstPath;
      } else if (!isYouTubeVideo) {
        fullDocumentUrl = getFullDocumentUrl(firstPath);
      }
    }

    final isImageFile = isDocument && ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(firstPath?.split('.').last.toLowerCase());

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (materialPaths.length == 1 && firstPath != null && firstPath.isNotEmpty) {
            if (isYouTubeVideo) {
              // Launch YouTube video
              launchUrl(Uri.parse(firstPath), mode: LaunchMode.externalApplication);
            } else if (isVideoFile) {
              launchUrl(Uri.parse(firstPath), mode: LaunchMode.platformDefault);
            } else {
              launchUrl(Uri.parse(fullDocumentUrl), mode: LaunchMode.platformDefault);
            }
          } else {
            showDetailDialog(
              context,
              DetailDialogData(
                title: widget.item.name,
                icon: icon,
                color: color,
                documentPath: isYouTubeVideo ? firstPath : fullDocumentUrl,
                materialPaths: materialPaths,
                fields: [
                  DetailField(label: 'Material Name', value: widget.item.name, icon: Iconsax.edit),
                  DetailField(label: 'Type', value: widget.item.type, icon: icon),
                  DetailField(
                    label: 'Uploaded On',
                    value: '${widget.item.uploadedOn.day}/${widget.item.uploadedOn.month}/${widget.item.uploadedOn.year}',
                    icon: Iconsax.calendar,
                  ),
                  if (isYouTubeVideo)
                    DetailField(label: 'Video Link', value: firstPath ?? '', icon: Iconsax.video),
                  if (isVideoFile)
                    DetailField(label: 'Video File', value: firstPath ?? '', icon: Iconsax.video),
                  if (isDocument)
                    DetailField(label: 'File Name', value: firstPath ?? '', icon: Iconsax.document_text),
                ],
                onEdit: () {
                  Navigator.pop(context);
                  showEditMaterialDialog(context, widget.item, widget.allSubjects);
                },
              ),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isHovered ? color.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? color.withOpacity(0.3) : AppTheme.borderGrey.withOpacity(0.4),
            ),
            boxShadow: isHovered
                ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 6))]
                : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail/Icon Section
              Expanded(
                flex: 3,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: isYouTubeVideo && widget.item.thumbnail != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: widget.item.thumbnail!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: Icon(Iconsax.video, color: color, size: 30),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(Iconsax.video, color: Colors.red, size: 30),
                              ),
                            ),
                            // Play button overlay
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          : isVideoFile
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Icon(Iconsax.video, color: color, size: 40),
                        ),
                      )
                          : isImageFile
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: fullDocumentUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: Icon(icon, color: color, size: 30),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Icon(Iconsax.image, color: Colors.red, size: 30),
                          ),
                        ),
                      )
                          : Center(
                        child: Icon(icon, color: color, size: 40),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Title and Actions Section
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.name,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ActionButtons(
                          onEdit: () => showEditMaterialDialog(context, widget.item, widget.allSubjects),
                          onDelete: () => showConfirmDeleteDialog(
                            context,
                            widget.item.name,
                            color,
                                () => context.read<AcademicsBloc>().add(
                              DeleteMaterialEvent(recNo: int.parse(widget.item.id), hardDelete: true),
                            ),
                          ),
                          onView: () => showDetailDialog(
                            context,
                            DetailDialogData(
                              title: widget.item.name,
                              icon: icon,
                              color: color,
                              documentPath: isYouTubeVideo ? firstPath : fullDocumentUrl,
                              materialPaths: materialPaths,
                              fields: [
                                DetailField(label: 'Material Name', value: widget.item.name, icon: Iconsax.edit),
                                DetailField(label: 'Type', value: widget.item.type, icon: icon),
                                DetailField(
                                  label: 'Uploaded On',
                                  value: '${widget.item.uploadedOn.day}/${widget.item.uploadedOn.month}/${widget.item.uploadedOn.year}',
                                  icon: Iconsax.calendar,
                                ),
                                if (isYouTubeVideo)
                                  DetailField(label: 'Video Link', value: firstPath ?? '', icon: Iconsax.video),
                                if (isVideoFile)
                                  DetailField(label: 'Video File', value: firstPath ?? '', icon: Iconsax.video),
                                if (isDocument)
                                  DetailField(label: 'File Name', value: firstPath ?? '', icon: Iconsax.document_text),
                              ],
                              onEdit: () {
                                Navigator.pop(context);
                                showEditMaterialDialog(context, widget.item, widget.allSubjects);
                              },
                            ),
                          ),
                          usePopup: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Iconsax.calendar, size: 14, color: AppTheme.bodyText),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.item.uploadedOn.day}/${widget.item.uploadedOn.month}/${widget.item.uploadedOn.year}',
                          style: GoogleFonts.inter(color: AppTheme.bodyText, fontSize: 12),
                        ),
                      ],
                    ),
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




// ==================== REPLACED EnhancedListItem WIDGET ====================
class EnhancedListItem extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? statusBadge;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;
  final VoidCallback? onDelete; // ADDED
  final List<WebCell> webCells;
  final List<Widget> mobileInfoRows;

  const EnhancedListItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.statusBadge,
    this.onEdit,
    this.onTap,
    this.onDelete, // ADDED
    required this.webCells,
    required this.mobileInfoRows,
  });

  @override
  _EnhancedListItemState createState() => _EnhancedListItemState();
}

class _EnhancedListItemState extends State<EnhancedListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        if (isMobile) {
          return GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(18.0),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderGrey.withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [widget.iconColor.withOpacity(0.15), widget.iconColor.withOpacity(0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon, size: 22, color: widget.iconColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            if (widget.subtitle != null)
                              Text(
                                widget.subtitle!,
                                style: GoogleFonts.inter(color: AppTheme.bodyText, fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                      if (widget.statusBadge != null) widget.statusBadge!,
                    ],
                  ),
                  const Divider(height: 28),
                  ...widget.mobileInfoRows,
                  const SizedBox(height: 8),
                  Align(
                      alignment: Alignment.centerRight,
                      child: ActionButtons(
                        onEdit: widget.onEdit,
                        onView: widget.onTap,
                        onDelete: widget.onDelete, // ADDED
                        usePopup: true,
                      )),
                ],
              ),
            ),
          );
        }

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: _isHovered ? widget.iconColor.withOpacity(0.03) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border(bottom: BorderSide(color: AppTheme.borderGrey.withOpacity(0.3))),
              ),
              child: Row(
                children: widget.webCells
                    .map((cell) => Expanded(
                  flex: cell.flex,
                  child: Align(alignment: cell.alignment, child: cell.child),
                ))
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class WebCell {
final Widget child;
final int flex;
final Alignment alignment;
WebCell({required this.child, this.flex = 1, this.alignment = Alignment.centerLeft});
}

// ==================== REPLACED ActionButtons WIDGET ====================
class ActionButtons extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onView;
  final VoidCallback? onDelete; // ADDED
  final bool usePopup;
  final bool usePopupOnMobile;

  const ActionButtons({
    super.key,
    this.onEdit,
    this.onView,
    this.onDelete, // ADDED
    this.usePopup = false,
    this.usePopupOnMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    if (usePopupOnMobile) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 700) {
            return _buildPopupMenu();
          }
          return _buildIconButtons();
        },
      );
    }

    if (usePopup) return _buildPopupMenu();
    return _buildIconButtons();
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<int>(
      onSelected: (item) {
        if (item == 0 && onView != null) onView!();
        if (item == 1 && onEdit != null) onEdit!();
        if (item == 2 && onDelete != null) onDelete!(); // ADDED
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        if (onView != null)
          PopupMenuItem<int>(
            value: 0,
            child: Row(
              children: [
                Icon(Iconsax.eye, size: 18, color: AppTheme.primaryGreen),
                const SizedBox(width: 10),
                Text('View Details', style: GoogleFonts.inter(fontSize: 14)),
              ],
            ),
          ),
        if (onEdit != null)
          PopupMenuItem<int>(
            value: 1,
            child: Row(
              children: [
                Icon(Iconsax.edit, size: 18, color: Colors.blue),
                const SizedBox(width: 10),
                Text('Edit', style: GoogleFonts.inter(fontSize: 14)),
              ],
            ),
          ),
        if (onDelete != null) // ADDED
          PopupMenuItem<int>(
            value: 2,
            child: Row(
              children: [
                Icon(Iconsax.trash, size: 18, color: Colors.red),
                const SizedBox(width: 10),
                Text('Delete', style: GoogleFonts.inter(fontSize: 14)),
              ],
            ),
          ),
      ],
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.borderGrey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Iconsax.more, color: AppTheme.bodyText, size: 20),
      ),
    );
  }

  Widget _buildIconButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onView != null)
          IconButton(
            icon: const Icon(Iconsax.eye, size: 20, color: AppTheme.primaryGreen),
            onPressed: onView,
            tooltip: 'View Details',
          ),
        if (onEdit != null)
          IconButton(
            icon: const Icon(Iconsax.edit, size: 20, color: Colors.blue),
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
        if (onDelete != null) // ADDED
          IconButton(
            icon: const Icon(Iconsax.trash, size: 20, color: Colors.red),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
      ],
    );
  }
}

Widget buildInfoRow(IconData icon, String text, {int maxLines = 1}) {
return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
Icon(icon, size: 17, color: AppTheme.bodyText),
const SizedBox(width: 10),
Expanded(
child: Text(
text,
maxLines: maxLines,
overflow: TextOverflow.ellipsis,
style: GoogleFonts.inter(fontSize: 13),
),
),
]);
}

IconData getMaterialIcon(String type) {
switch (type) {
case 'Video':
case 'Video_Link':
return Iconsax.video_play;
case 'Worksheet':
case 'Worksheet_Path':
return Iconsax.document_text_1;
case 'Notes':
case 'Revision_Notes_Path':
return Iconsax.note_1;
case 'Questions':
case 'Extra_Questions_Path':
case 'Solved_Questions_Path':
return Iconsax.document_text;
case 'Lesson_Plans_Path':
return Iconsax.ruler;
case 'Teaching_Aids_Path':
return Iconsax.clipboard_text;
case 'Assessment_Tools_Path':
return Iconsax.award;
case 'Homework_Tools_Path':
return Iconsax.home;
case 'Practice_Zone_Path':
return Iconsax.cpu;
case 'Learning_Path_Path':
return Iconsax.chart_2;
default:
return Iconsax.document;
}
}

Color getMaterialColor(String type) {
switch (type) {
case 'Video':
case 'Video_Link':
return Colors.red;
case 'Worksheet':
case 'Worksheet_Path':
return Colors.orange;
case 'Notes':
case 'Revision_Notes_Path':
return Colors.blue;
case 'Questions':
case 'Extra_Questions_Path':
case 'Solved_Questions_Path':
return Colors.purple;
case 'Lesson_Plans_Path':
return Colors.pink;
case 'Teaching_Aids_Path':
return Colors.teal;
case 'Assessment_Tools_Path':
return Colors.deepOrange;
case 'Homework_Tools_Path':
return Colors.indigo;
case 'Practice_Zone_Path':
return Colors.green.shade800;
case 'Learning_Path_Path':
return AppTheme.primaryGreen;
default:
return Colors.grey;
}
}

// ==================== DETAIL VIEW DIALOG ====================

class DetailField {
final String label;
final String value;
final IconData icon;

DetailField({required this.label, required this.value, required this.icon});
}

// ==================== DETAIL VIEW DIALOG (DetailDialogData) ====================

// ==================== DETAIL VIEW DIALOG (DetailDialogData) ====================

class DetailDialogData {
  final String title;
  final IconData icon;
  final Color color;
  final List<DetailField> fields;
  final VoidCallback? onEdit;
  final String? documentPath; // Full URL for document/video action
  final Map<String, String>? materialPaths; // Map of material type to file path

  DetailDialogData({
    required this.title,
    required this.icon,
    required this.color,
    required this.fields,
    this.onEdit,
    this.documentPath,
    this.materialPaths,
  });
}

void showDetailDialog(BuildContext context, DetailDialogData data) {
  // Check if the path is a file or a video link
  final isAvailable = data.documentPath != null && data.documentPath!.isNotEmpty;
  final isVideoLink = isAvailable && isYoutubeVideo(data.documentPath!);
  final isDocumentAvailable = isAvailable && !isVideoLink;
  final isImageFile = isDocumentAvailable && ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(data.documentPath?.split('.').last.toLowerCase());

  void launchDocument() async {
    if (data.documentPath != null && data.documentPath!.isNotEmpty) {
      final url = Uri.parse(data.documentPath!);
      // Use launchUrl for universal support on web and mobile
      // If it's a video link, use LaunchMode.externalApplication to open it in the native YouTube app/dedicated window if possible.
      // If it's a document, LaunchMode.platformDefault is fine for view/download.
      final mode = isVideoLink ? LaunchMode.externalApplication : LaunchMode.platformDefault;

      if (!await launchUrl(url, mode: mode)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch ${data.documentPath}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void downloadDocument(String filename) async {
    // Get the full URL based on file type
    final fileExtension = filename.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(fileExtension);

    final url = Uri.parse(isImage ? '$_imageBaseUrl$filename' : '$_documentBaseUrl$filename');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not download $filename'), backgroundColor: Colors.red),
        );
      }
    }
  }

  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(data.icon, color: data.color, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.bodyText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.title,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Iconsax.close_circle, color: AppTheme.borderGrey, size: 26),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 24,
                ),
              ],
            ),
            const Divider(height: 36, thickness: 1.5, color: AppTheme.borderGrey),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Regular fields
                    ...data.fields
                        .where((field) => field.value.isNotEmpty && field.value != 'null')
                        .map(
                          (field) => Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderGrey.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: data.color.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(field.icon, size: 20, color: data.color),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    field.label,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.bodyText,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    field.value,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.darkText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .toList(),

                    // Material files section
                    if (data.materialPaths != null && data.materialPaths!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderGrey.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: data.color.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Iconsax.folder_open, size: 20, color: data.color),
                                const SizedBox(width: 14),
                                Text(
                                  'Material Files',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.bodyText,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ...data.materialPaths!.entries.where((entry) => entry.value.isNotEmpty).map((entry) {
                              final materialType = entry.key;
                              final filename = entry.value;
                              final isVideo = materialType == 'Video_Link';
                              final fileExtension = filename.split('.').last.toLowerCase();
                              final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(fileExtension);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        getMaterialIcon(materialType),
                                        size: 18,
                                        color: getMaterialColor(materialType),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              materialType.replaceAll('_', ' '),
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.darkText,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              isVideo ? filename : filename.split('/').last,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppTheme.bodyText,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          if (isVideo) {
                                            launchUrl(Uri.parse(filename), mode: LaunchMode.externalApplication);
                                          } else {
                                            downloadDocument(filename);
                                          }
                                        },
                                        icon: Icon(
                                          isVideo ? Iconsax.play : Iconsax.document_download,
                                          size: 14,
                                        ),
                                        label: Text(
                                          isVideo ? 'Play' : 'Download',
                                          style: GoogleFonts.inter(fontSize: 11),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isVideo ? Colors.red : AppTheme.primaryGreen,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          minimumSize: Size(0, 32),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Document View/Download Button
                if (isAvailable) ...[
                  ElevatedButton.icon(
                    onPressed: launchDocument,
                    icon: Icon(
                        isVideoLink ? Iconsax.video_play :
                        isImageFile ? Iconsax.image : Iconsax.document_download,
                        size: 18
                    ),
                    label: Text(
                      isVideoLink ? 'View Video' :
                      isImageFile ? 'View Image' : 'View/Download',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isVideoLink ? Colors.red :
                      isImageFile ? Colors.blue : AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.bodyText),
                  ),
                ),
                if (data.onEdit != null) const SizedBox(width: 12),
                if (data.onEdit != null)
                  ElevatedButton.icon(
                    onPressed: data.onEdit,
                    icon: const Icon(Iconsax.edit, size: 18),
                    label: Text('Edit', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: data.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      elevation: 0,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}


void showAddClassDialog(BuildContext context) {
final nameController = TextEditingController();
final descController = TextEditingController();
final orderController = TextEditingController();

showDialog(
context: context,
builder: (context) => AddEditDialog(
title: "Add New Class",
icon: Iconsax.building,
color: Colors.blue,
onSave: () async {
await ApiService.manageAcademicModule({
'table': 'Class_Master',
'operation': 'ADD',
'ClassName': nameController.text,
'ClassDescription': descController.text,
'DisplayOrder': int.tryParse(orderController.text) ?? 0,
'SchoolRecNo': 1,
'CreatedBy': 'Admin',
});
if (context.mounted) {
Navigator.pop(context);
context.read<AcademicsBloc>().add(LoadClassesEvent(schoolRecNo: 1));
context.read<AcademicsBloc>().add(LoadKPIEvent());
}
},
fields: [
DialogField(controller: nameController, label: "Class Name", hint: "e.g., Class 11", icon: Iconsax.edit),
DialogField(controller: descController, label: "Description", hint: "Class description", icon: Iconsax.document_text, maxLines: 3),
DialogField(controller: orderController, label: "Display Order", hint: "1", icon: Iconsax.sort, keyboardType: TextInputType.number),
],
),
);
}

void showEditClassDialog(BuildContext context, ClassModel item) {
final nameController = TextEditingController(text: item.name);
final descController = TextEditingController(text: item.description);
// Assuming '1' is the default if the model doesn't store display order directly for editing
final orderController = TextEditingController(text: '1');

showDialog(
context: context,
builder: (context) => AddEditDialog(
title: "Edit Class",
subtitle: item.name,
icon: Iconsax.building,
color: Colors.blue,
onSave: () async {
await ApiService.manageAcademicModule({
'table': 'Class_Master',
'operation': 'UPDATE',
'ClassID': int.parse(item.id),
'ClassDescription': descController.text,
'DisplayOrder': int.tryParse(orderController.text) ?? 0,
'ModifiedBy': 'Admin',
});
if (context.mounted) {
Navigator.pop(context);
context.read<AcademicsBloc>().add(LoadClassesEvent(schoolRecNo: 1));
}
},
fields: [
DialogField(controller: nameController, label: "Class Name", hint: "e.g., Class 11", icon: Iconsax.edit, readOnly: true),
DialogField(controller: descController, label: "Description", hint: "Class description", icon: Iconsax.document_text, maxLines: 3),
DialogField(controller: orderController, label: "Display Order", hint: "1", icon: Iconsax.sort, keyboardType: TextInputType.number),
],
),
);
}

// showAddSubjectDialog UPDATED to use StyledDropdownField
void showAddSubjectDialog(BuildContext context, List<ClassModel> allClasses) {
  print('📚 showAddSubjectDialog: Opening dialog');

  // Capture the bloc reference BEFORE showing the dialog
  final academicsBloc = context.read<AcademicsBloc>();

  final nameController = TextEditingController();
  final codeController = TextEditingController();
  final descController = TextEditingController();
  int? selectedClassId;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (builderContext, setState) {
        print('🏗️ showAddSubjectDialog: Rebuilding. ClassID: $selectedClassId');

        return AddEditDialog(
          title: 'Add New Subject',
          icon: Iconsax.book_1,
          color: Colors.green,
          onSave: () async {
            print('💾 showAddSubjectDialog: Save clicked');

            if (selectedClassId != null && nameController.text.isNotEmpty) {
              print('💾 showAddSubjectDialog: Validations passed. Saving...');

              try {
                final response = await ApiService.manageAcademicModule({
                  'table': 'Subject_Name_Master',
                  'operation': 'ADD',
                  'ClassID': selectedClassId,
                  'SubjectName': nameController.text,
                  'SubjectCode': codeController.text,
                  'SubjectDescription': descController.text,
                  'CreatedBy': 'Admin',
                });

                print('📥 showAddSubjectDialog: Response - $response');

                if (response['status'] == 'success' || response['success'] == true) {
                  print('✅ showAddSubjectDialog: Subject added successfully');

                  if (context.mounted) {
                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${nameController.text} added successfully!'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );

                    // Wait for backend processing
                    print('⏳ showAddSubjectDialog: Waiting 500ms for backend processing...');
                    await Future.delayed(const Duration(milliseconds: 500));

                    // Reload data using captured bloc reference
                    print('🔄 showAddSubjectDialog: Triggering data reload...');
                    academicsBloc.add(LoadSubjectsEvent(schoolRecNo: 1));
                    academicsBloc.add(LoadKPIEvent());
                  }
                } else {
                  throw Exception(response['message'] ?? 'Failed to add subject');
                }
              } catch (e) {
                print('❌ showAddSubjectDialog: Exception - $e');

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding subject: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            } else {
              print('⚠️ showAddSubjectDialog: Validation failed');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all required fields'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          },
          fields: [
            DialogField(
              controller: null,
              label: 'Select Class',
              hint: 'Choose a class',
              icon: Iconsax.building,
              customWidget: StyledDropdownField<int>(
                label: "Select Class",
                icon: Iconsax.building,
                selectedValue: selectedClassId,
                items: allClasses
                    .map((c) => DropdownMenuItem(
                  value: int.parse(c.id),
                  child: Text(c.name),
                ))
                    .toList(),
                onChanged: (value) {
                  print('🔎 showAddSubjectDialog: Class changed to $value');
                  setState(() {
                    selectedClassId = value;
                  });
                },
                onClear: () {
                  print('🔎 showAddSubjectDialog: Class cleared');
                  setState(() {
                    selectedClassId = null;
                  });
                },
              ),
            ),
            DialogField(
              controller: nameController,
              label: 'Subject Name',
              hint: 'e.g., Mathematics',
              icon: Iconsax.edit,
            ),
            DialogField(
              controller: codeController,
              label: 'Subject Code',
              hint: 'e.g., MATH10',
              icon: Iconsax.code,
            ),
            DialogField(
              controller: descController,
              label: 'Description',
              hint: 'Subject description',
              icon: Iconsax.document_text,
              maxLines: 3,
            ),
          ],
        );
      },
    ),
  );
}


void showEditSubjectDialog(
    BuildContext context,
    SubjectModel item,
    List<ClassModel> allClasses,
    ) {
  print('✏️ showEditSubjectDialog: Opening for ${item.name}');

  // Capture the bloc reference BEFORE showing the dialog
  final academicsBloc = context.read<AcademicsBloc>();

  final nameController = TextEditingController(text: item.name);
  final descController = TextEditingController(text: item.description);

  showDialog(
    context: context,
    builder: (dialogContext) => AddEditDialog(
      title: "Edit Subject",
      subtitle: item.name,
      icon: Iconsax.book_1,
      color: Colors.green,
      onSave: () async {
        print('💾 showEditSubjectDialog: Save clicked for ${item.name}');
        print('💾 showEditSubjectDialog: SubjectID: ${item.id}');
        print('💾 showEditSubjectDialog: New Description: ${descController.text}');

        try {
          final response = await ApiService.manageAcademicModule({
            'table': 'Subject_Name_Master',
            'operation': 'UPDATE',
            'SubjectID': int.parse(item.id),
            'SubjectDescription': descController.text,
            'ModifiedBy': 'Admin',
          });

          print('📥 showEditSubjectDialog: API Response: $response');

          if (response['status'] == 'success' || response['success'] == true) {
            print('✅ showEditSubjectDialog: Update successful');

            if (context.mounted) {
              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} updated successfully!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );

              // Wait for backend to process
              print('⏳ showEditSubjectDialog: Waiting 500ms for backend processing...');
              await Future.delayed(const Duration(milliseconds: 500));

              // Reload data using captured bloc reference
              print('🔄 showEditSubjectDialog: Triggering data reload...');
              academicsBloc.add(LoadSubjectsEvent(schoolRecNo: 1));
              academicsBloc.add(LoadKPIEvent());
            }
          } else {
            print('❌ showEditSubjectDialog: Update failed - ${response['message'] ?? 'Unknown error'}');
            throw Exception(response['message'] ?? 'Failed to update subject');
          }
        } catch (e) {
          print('❌ showEditSubjectDialog: Exception caught - $e');

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating subject: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
      fields: [
        DialogField(
          controller: nameController,
          label: "Subject Name",
          hint: "e.g., Mathematics",
          icon: Iconsax.edit,
          readOnly: true,
        ),
        DialogField(
          controller: descController,
          label: "Description",
          hint: "Subject description",
          icon: Iconsax.document_text,
          maxLines: 3,
        ),
      ],
    ),
  );
}


// showAddChapterDialog UPDATED to use StyledDropdownField
void showAddChapterDialog(BuildContext context, List<ClassModel> allClasses, List<SubjectModel> allSubjects) {
final nameController = TextEditingController();
final codeController = TextEditingController();
final descController = TextEditingController();
final orderController = TextEditingController();
int? selectedClassId;
int? selectedSubjectId;

showDialog(
context: context,
builder: (context) => StatefulBuilder(
builder: (context, setState) {
final filteredSubjects = selectedClassId != null
? allSubjects.where((s) => s.classId == selectedClassId.toString()).toList()
    : [];

return AddEditDialog(
title: "Add New Chapter",
icon: Iconsax.document_text_1,
color: Colors.orange,
onSave: () async {
if (selectedSubjectId != null) {
await ApiService.manageAcademicModule({
'table': 'Chapter_Master',
'operation': 'ADD',
'SubjectID': selectedSubjectId,
'ChapterName': nameController.text,
'ChapterCode': codeController.text,
'ChapterDescription': descController.text,
'ChapterOrder': int.tryParse(orderController.text) ?? 0,
'CreatedBy': 'Admin',
});
if (context.mounted) {
Navigator.pop(context);
context.read<AcademicsBloc>().add(LoadChaptersEvent(schoolRecNo: 1));
context.read<AcademicsBloc>().add(LoadKPIEvent());
}
}
},
fields: [
DialogField(
controller: null,
label: "Select Class",
hint: "Choose a class",
icon: Iconsax.building,
customWidget: StyledDropdownField<int>(
label: "Select Class",
icon: Iconsax.building,
selectedValue: selectedClassId,
items: allClasses.map((c) => DropdownMenuItem(value: int.parse(c.id), child: Text(c.name))).toList(),
onChanged: (value) => setState(() {
selectedClassId = value;
selectedSubjectId = null;
}),
onClear: () => setState(() {
selectedClassId = null;
selectedSubjectId = null;
}),
),
),
DialogField(
controller: null,
label: "Select Subject",
hint: "Choose a subject",
icon: Iconsax.book_1,
customWidget: StyledDropdownField<int>(
label: "Select Subject",
icon: Iconsax.book_1,
selectedValue: selectedSubjectId,
items: filteredSubjects.map((s) => DropdownMenuItem(value: int.parse(s.id), child: Text(s.name))).toList(),
onChanged: filteredSubjects.isNotEmpty ? (value) => setState(() => selectedSubjectId = value) : null,
onClear: () => setState(() => selectedSubjectId = null),
enabled: filteredSubjects.isNotEmpty,
),
),
DialogField(controller: nameController, label: "Chapter Name", hint: "e.g., Real Numbers", icon: Iconsax.edit),
DialogField(controller: codeController, label: "Chapter Code", hint: "e.g., MATH_CH01", icon: Iconsax.code),
DialogField(controller: descController, label: "Description", hint: "Chapter description", icon: Iconsax.document_text, maxLines: 3),
DialogField(controller: orderController, label: "Chapter Order", hint: "1", icon: Iconsax.sort, keyboardType: TextInputType.number),
],
);
},
),

);
}

void showEditChapterDialog(BuildContext context, ChapterModel item, List<SubjectModel> allSubjects) {
final nameController = TextEditingController(text: item.name);
final descController = TextEditingController(text: item.description);
final orderController = TextEditingController(text: item.chapterOrder.toString());

showDialog(
context: context,
builder: (context) => AddEditDialog(
title: "Edit Chapter",
subtitle: item.name,
icon: Iconsax.document_text_1,
color: Colors.orange,
onSave: () async {
await ApiService.manageAcademicModule({
'table': 'Chapter_Master',
'operation': 'UPDATE',
'ChapterID': int.parse(item.id),
'ChapterDescription': descController.text,
'ChapterOrder': int.tryParse(orderController.text) ?? 0,
'ModifiedBy': 'Admin',
});
if (context.mounted) {
Navigator.pop(context);
context.read<AcademicsBloc>().add(LoadChaptersEvent(schoolRecNo: 1));
}
},
fields: [
DialogField(controller: nameController, label: "Chapter Name", hint: "e.g., Real Numbers", icon: Iconsax.edit, readOnly: true),
DialogField(controller: descController, label: "Description", hint: "Chapter description", icon: Iconsax.document_text, maxLines: 3),
DialogField(controller: orderController, label: "Chapter Order", hint: "1", icon: Iconsax.sort, keyboardType: TextInputType.number),
],
),
);
}


void showAddMaterialDialog(BuildContext context, List<ClassModel> allClasses, List<SubjectModel> allSubjects) {
  // Capture the bloc reference BEFORE showing the dialog
  final academicsBloc = context.read<AcademicsBloc>();

  // Create copies of the lists to avoid affecting the original lists
  final List<ClassModel> dialogClasses = List.from(allClasses);
  final List<SubjectModel> dialogSubjects = List.from(allSubjects);

  int? selectedClassId;
  int? selectedSubjectId;
  int? selectedChapterId;
  List<ChapterModel> chapters = [];
  Map<String, List<String>> uploadedFiles = {};
  Map<String, bool> uploadingStates = {}; // Track uploading state for each material type

  final List<String> materialTypes = [
    'Video_Link',
    'Worksheet_Path',
    'Extra_Questions_Path',
    'Solved_Questions_Path',
    'Revision_Notes_Path',
    'Lesson_Plans_Path',
    'Teaching_Aids_Path',
    'Assessment_Tools_Path',
    'Homework_Tools_Path',
    'Practice_Zone_Path',
    'Learning_Path_Path',
  ];

  for (String type in materialTypes) {
    uploadedFiles[type] = [];
    uploadingStates[type] = false; // Initialize uploading state for each type
  }

  Future<void> loadChapters(int subjectId, void Function(void Function()) setState) async {
    print('📖 _loadChapters: Loading chapters for subject: $subjectId');
    final response = await ApiService.getChapters(subjectId: subjectId);
    if (context.mounted && (response['status'] == 'success' || response['success'] == true) && response['data'] != null) {
      setState(() {
        chapters = (response['data'] as List).map((json) => ChapterModel.fromJson(json)).toList();
      });
      print('✅ _loadChapters: Loaded ${chapters.length} chapters');
    } else {
      setState(() {
        chapters = [];
      });
      print('⚠️ _loadChapters: No chapters data found');
    }
  }

  Future<void> pickAndUploadFiles(String materialType, void Function(void Function()) setState) async {
    if (!context.mounted) return;

    try {
      setState(() {
        uploadingStates[materialType] = true; // Set uploading state for this specific type
      });
      print('📁 FilePicker: Starting file picking for $materialType...');

      if (materialType == 'Video_Link') {
        final TextEditingController linkController = TextEditingController();
        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Iconsax.video, color: Colors.red, size: 24),
                ),
                SizedBox(width: 12),
                Text('Add YouTube Video Link', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the YouTube video URL you want to add as a learning material.',
                  style: GoogleFonts.inter(color: AppTheme.bodyText),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: linkController,
                  decoration: InputDecoration(
                    hintText: 'https://www.youtube.com/watch?v=...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.bodyText.withOpacity(0.6)),
                    prefixIcon: Icon(Iconsax.link, color: AppTheme.primaryGreen),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.borderGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, linkController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Add', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );

        if (result != null && result.isNotEmpty) {
          setState(() {
            uploadedFiles[materialType] = [result];
          });
          print('✅ Added video link: $result');
        }
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
          allowMultiple: true,
        );

        if (!context.mounted) return;

        if (result != null && result.files.isNotEmpty) {
          List<String> newFileNames = [];
          for (var file in result.files) {
            File? fileToUpload;
            if (file.path != null) {
              fileToUpload = File(file.path!);
            } else if (file.bytes != null) {
              final tempDir = Directory.systemTemp;
              final tempFile = File('${tempDir.path}/${file.name ?? 'tempfile'}');
              await tempFile.writeAsBytes(file.bytes!);
              fileToUpload = tempFile;
            }

            if (fileToUpload != null) {
              final fileForUpload = XFile(fileToUpload.path);
              print('📁 FilePicker: File picked: ${fileForUpload.name}');
              print('📤 uploadDocument: File path for upload: ${fileToUpload.path}');

              final filename = await ApiService.uploadDocument(fileForUpload, context: context);
              print('📥 Upload Result: $filename');

              if (filename != null && filename.isNotEmpty) {
                newFileNames.add(filename);
                if (file.path == null && file.bytes != null) {
                  try {
                    await fileToUpload.delete();
                  } catch (e) {
                    print('⚠️ Warning: Could not delete temp file: $e');
                  }
                }
              }
            }
          }

          if (newFileNames.isNotEmpty) {
            setState(() {
              uploadedFiles[materialType] = [...uploadedFiles[materialType]!, ...newFileNames];
            });
            print('✅ Upload State: $materialType files = ${uploadedFiles[materialType]}');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${newFileNames.length} files uploaded successfully!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('File upload failed'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print('❌ Upload Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() {
          uploadingStates[materialType] = false; // Reset uploading state for this specific type
        });
      }
    }
  }

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (builderContext, setState) {
        print('🏗️ showAddMaterialDialog: Rebuilding State. ClassID: $selectedClassId, SubjectID: $selectedSubjectId');

        final filteredSubjects = selectedClassId != null
            ? dialogSubjects.where((s) => s.classId == selectedClassId.toString()).toList()
            : <SubjectModel>[];

        final subjectDropdownEnabled = filteredSubjects.isNotEmpty;
        final subjectDropdownItemCount = filteredSubjects.length;
        print('💡 Subject Dropdown Debug: filteredSubjects.length=$subjectDropdownItemCount, enabled=$subjectDropdownEnabled');

        return AddEditDialog(
          title: 'Add New Material',
          icon: Iconsax.folder_add,
          color: Colors.purple,
          onSave: () async {
            print('💾 onSave: Validating input...');
            if (selectedChapterId != null) {
              bool hasContent = false;
              for (String type in materialTypes) {
                if (uploadedFiles[type]!.isNotEmpty) {
                  hasContent = true;
                  break;
                }
              }

              if (hasContent) {
                print('💾 Saving Material: ChapterID=$selectedChapterId');

                // Prepare the data - CHECK THE FIELD NAME
                String? videoLinkOrPath;
                bool isVideoFile = false;

                if (uploadedFiles['Video_Link']!.isNotEmpty) {
                  final linkOrPath = uploadedFiles['Video_Link']!.first;
                  if (isYoutubeVideo(linkOrPath)) {
                    // It's a YouTube link - use Video_Link field
                    videoLinkOrPath = linkOrPath;
                    print('🎬 Video Link (YouTube): $videoLinkOrPath');
                  } else {
                    // It's a file - use Video_File_Path field
                    videoLinkOrPath = linkOrPath;
                    isVideoFile = true;
                    print('🎬 Video File Path: $videoLinkOrPath');
                  }
                }

                final response = await ApiService.addMaterial(
                  chapterId: selectedChapterId!,
                  // Use correct field name based on type
                  videoLink: (!isVideoFile && videoLinkOrPath != null) ? videoLinkOrPath : null,
                  videoFilePath: (isVideoFile && videoLinkOrPath != null) ? videoLinkOrPath : null,
                  worksheetPath: uploadedFiles['Worksheet_Path']!.isNotEmpty ? uploadedFiles['Worksheet_Path']!.first : null,
                  extraQuestionsPath: uploadedFiles['Extra_Questions_Path']!.isNotEmpty ? uploadedFiles['Extra_Questions_Path']!.first : null,
                  solvedQuestionsPath: uploadedFiles['Solved_Questions_Path']!.isNotEmpty ? uploadedFiles['Solved_Questions_Path']!.first : null,
                  revisionNotesPath: uploadedFiles['Revision_Notes_Path']!.isNotEmpty ? uploadedFiles['Revision_Notes_Path']!.first : null,
                  lessonPlansPath: uploadedFiles['Lesson_Plans_Path']!.isNotEmpty ? uploadedFiles['Lesson_Plans_Path']!.first : null,
                  teachingAidsPath: uploadedFiles['Teaching_Aids_Path']!.isNotEmpty ? uploadedFiles['Teaching_Aids_Path']!.first : null,
                  assessmentToolsPath: uploadedFiles['Assessment_Tools_Path']!.isNotEmpty ? uploadedFiles['Assessment_Tools_Path']!.first : null,
                  homeworkToolsPath: uploadedFiles['Homework_Tools_Path']!.isNotEmpty ? uploadedFiles['Homework_Tools_Path']!.first : null,
                  practiceZonePath: uploadedFiles['Practice_Zone_Path']!.isNotEmpty ? uploadedFiles['Practice_Zone_Path']!.first : null,
                  learningPathPath: uploadedFiles['Learning_Path_Path']!.isNotEmpty ? uploadedFiles['Learning_Path_Path']!.first : null,
                );

                print('📥 Save Response: $response');

                if (context.mounted) {
                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Material added successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );

                  await Future.delayed(const Duration(milliseconds: 500));
                  // Use the captured bloc reference instead of context.read
                  print('🔄 Reloading materials after save...');
                  academicsBloc.add(LoadMaterialsEvent(schoolRecNo: 1));
                  academicsBloc.add(LoadKPIEvent());

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Material added successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please select a Chapter and provide a Link or upload at least one File.'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please select a Chapter.'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }
            }
          },
          fields: [
            // Class Dropdown
            DialogField(
              controller: null,
              label: 'Select Class',
              hint: 'Choose a class',
              icon: Iconsax.building,
              customWidget: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: StyledDropdownField<int>(
                  key: ValueKey('class_dropdown_$selectedClassId'),
                  label: "Select Class",
                  icon: Iconsax.building,
                  selectedValue: selectedClassId,
                  items: dialogClasses.map((c) => DropdownMenuItem(value: int.parse(c.id), child: Text(c.name))).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedClassId = value;
                      selectedSubjectId = null;
                      selectedChapterId = null;
                      chapters = [];
                    });
                    final subjectsForSelectedClass = dialogSubjects.where((s) => s.classId == value.toString()).toList();
                    print('🔎 Class Changed to $value. Subjects filtered. Chapters cleared. Subjects available in new state: ${subjectsForSelectedClass.length}');
                  },
                  onClear: () {
                    setState(() {
                      selectedClassId = null;
                      selectedSubjectId = null;
                      selectedChapterId = null;
                      chapters = [];
                    });
                    print('🔎 Class Cleared');
                  },
                ),
              ),
            ),

            // Subject Dropdown
            DialogField(
              controller: null,
              label: 'Select Subject',
              hint: 'Choose a subject',
              icon: Iconsax.book_1,
              customWidget: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: StyledDropdownField<int>(
                  key: ValueKey('subject_dropdown_$selectedClassId'),
                  label: "Select Subject",
                  icon: Iconsax.book_1,
                  selectedValue: selectedSubjectId,
                  items: filteredSubjects.map((s) => DropdownMenuItem(value: int.parse(s.id), child: Text(s.name))).toList(),
                  onChanged: filteredSubjects.isNotEmpty
                      ? (value) async {
                    setState(() {
                      selectedSubjectId = value;
                      selectedChapterId = null;
                      chapters = [];
                    });
                    print('🔎 Subject Changed to $value. Chapters loading...');
                    if (value != null) {
                      await loadChapters(value, setState);
                    }
                  }
                      : null,
                  onClear: () {
                    setState(() {
                      selectedSubjectId = null;
                      selectedChapterId = null;
                      chapters = [];
                    });
                    print('🔎 Subject Cleared');
                  },
                  enabled: filteredSubjects.isNotEmpty,
                ),
              ),
            ),

            // Chapter Dropdown
            DialogField(
              controller: null,
              label: 'Select Chapter',
              hint: 'Choose a chapter',
              icon: Iconsax.document_text_1,
              customWidget: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: StyledDropdownField<int>(
                  key: ValueKey('chapter_dropdown_$selectedSubjectId'),
                  label: "Select Chapter",
                  icon: Iconsax.document_text_1,
                  selectedValue: selectedChapterId,
                  items: chapters.map((ch) => DropdownMenuItem(value: int.parse(ch.id), child: Text(ch.name))).toList(),
                  onChanged: chapters.isNotEmpty
                      ? (value) {
                    setState(() {
                      selectedChapterId = value;
                    });
                    print('🔎 Chapter Changed to $value');
                  }
                      : null,
                  onClear: () {
                    setState(() {
                      selectedChapterId = null;
                    });
                    print('🔎 Chapter Cleared');
                  },
                  enabled: chapters.isNotEmpty,
                ),
              ),
            ),

            // Material Types Section
            DialogField(
              controller: null,
              label: 'Material Files',
              hint: 'Upload files for different material types',
              icon: Iconsax.folder_open,
              customWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select material types to upload files',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.bodyText),
                  ),
                  const SizedBox(height: 12),
                  ...materialTypes.map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderGrey.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: getMaterialColor(type).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(getMaterialIcon(type), size: 18, color: getMaterialColor(type)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        type == 'Video_Link' ? 'YouTube Video Link' : type.replaceAll('_', ' '),
                                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.darkText),
                                      ),
                                      if (uploadedFiles[type]!.isNotEmpty)
                                        Text(
                                          '${uploadedFiles[type]!.length} file(s) added',
                                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryGreen),
                                        ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: uploadingStates[type]! ? null : () => pickAndUploadFiles(type, setState),
                                  icon: uploadingStates[type]!
                                      ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                      : Icon(Iconsax.document_upload, size: 16),
                                  label: Text(
                                    type == 'Video_Link' ? 'Add Link' : (uploadingStates[type]! ? 'Uploading...' : 'Upload File'),
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: getMaterialColor(type),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: Size(0, 32),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                            if (uploadedFiles[type]!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Added files:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.bodyText)),
                                    const SizedBox(height: 8),
                                    ...uploadedFiles[type]!.map((filename) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(type == 'Video_Link' ? Iconsax.link : Iconsax.document, size: 14, color: Colors.green),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  type == 'Video_Link' ? 'YouTube Link' : filename,
                                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.green),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.clear, size: 16, color: Colors.red),
                                                onPressed: () {
                                                  setState(() {
                                                    uploadedFiles[type]!.remove(filename);
                                                  });
                                                },
                                                padding: EdgeInsets.zero,
                                                constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

void showEditMaterialDialog(BuildContext context, MaterialModel item, List<SubjectModel> allSubjects) {
  // Determine which type of material this is for the title
  String materialType = item.type.replaceAll('_', ' ');

  // Controllers for the material fields. Only non-empty paths are initialized.
  // Removed videoController since we're no longer using YouTube links
  final videoFileController = TextEditingController(text: item.isVideoFile ? item.link : '');
  final worksheetController = TextEditingController(text: item.worksheetPath.isNotEmpty ? item.worksheetPath : '');
  final notesController = TextEditingController(text: item.revisionNotesPath.isNotEmpty ? item.revisionNotesPath : '');
  final extraQuestionsController = TextEditingController(text: item.extraQuestionsPath.isNotEmpty ? item.extraQuestionsPath : '');
  final solvedQuestionsController = TextEditingController(text: item.solvedQuestionsPath.isNotEmpty ? item.solvedQuestionsPath : '');
  final lessonPlansController = TextEditingController(text: item.lessonPlansPath.isNotEmpty ? item.lessonPlansPath : '');
  final teachingAidsController = TextEditingController(text: item.teachingAidsPath.isNotEmpty ? item.teachingAidsPath : '');
  final assessmentToolsController = TextEditingController(text: item.assessmentToolsPath.isNotEmpty ? item.assessmentToolsPath : '');
  final homeworkToolsController = TextEditingController(text: item.homeworkToolsPath.isNotEmpty ? item.homeworkToolsPath : '');
  final practiceZoneController = TextEditingController(text: item.practiceZonePath.isNotEmpty ? item.practiceZonePath : '');
  final learningPathController = TextEditingController(text: item.learningPathPath.isNotEmpty ? item.learningPathPath : '');

  // State for tracking if we're adding a new video file
  bool isAddingNewVideo = false;
  String? newVideoFilePath;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        Future<void> pickAndUploadVideoFile() async {
          try {
            setState(() => isAddingNewVideo = true);
            print('📁 FilePicker: Starting video file picking...');

            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'],
              allowMultiple: false, // Only allow one video file
            );

            if (!context.mounted) return;

            if (result != null && result.files.isNotEmpty) {
              final file = result.files.first;
              File? fileToUpload;

              if (file.path != null) {
                fileToUpload = File(file.path!);
              } else if (file.bytes != null) {
                final tempDir = Directory.systemTemp;
                final tempFile = File('${tempDir.path}/${file.name ?? 'temp_video'}');
                await tempFile.writeAsBytes(file.bytes!);
                fileToUpload = tempFile;
              }

              if (fileToUpload != null) {
                final fileForUpload = XFile(fileToUpload.path);
                print('📁 FilePicker: Video file picked: ${fileForUpload.name}');
                print('🚀 [uploadDocument] Video file path for upload: ${fileToUpload.path}');

                final filename = await ApiService.uploadDocument(fileForUpload);
                print('📁 Upload Result: $filename');

                if (filename != null && filename.isNotEmpty) {
                  setState(() {
                    newVideoFilePath = filename;
                    videoFileController.text = filename;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('✅ Video file uploaded successfully!'),
                        backgroundColor: Colors.green
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('❌ Video file upload failed'),
                        backgroundColor: Colors.red
                    ),
                  );
                }

                // Clean up temp file if we created one
                if (file.path == null && file.bytes != null) {
                  try {
                    await fileToUpload.delete();
                  } catch (e) {
                    print('Warning: Could not delete temp file: $e');
                  }
                }
              }
            } else {
              print('⚠️ FilePicker: No video file selected.');
            }
          } catch (e) {
            print('❌ Upload Error: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('❌ Upload failed: $e'), backgroundColor: Colors.red),
              );
            }
          } finally {
            if (context.mounted) {
              setState(() => isAddingNewVideo = false);
            }
          }
        }

        return AddEditDialog(
          title: "Edit $materialType",
          subtitle: item.name,
          icon: getMaterialIcon(item.type),
          color: getMaterialColor(item.type),
          onSave: () async {
            print('💾 Updating Material: RecNo=${item.id}');

            Map<String, dynamic> updateData = {
              'table': 'Study_Material',
              'operation': 'UPDATE',
              'RecNo': int.parse(item.id),
            };

            // Update video file if changed
            if (newVideoFilePath != null && newVideoFilePath!.isNotEmpty) {
              updateData['Video_File_Path'] = newVideoFilePath;
              updateData['Is_Video_File'] = true;
              print('   Updating Video_File_Path: $newVideoFilePath');
            } else if (item.isVideoFile && videoFileController.text.isNotEmpty) {
              updateData['Video_File_Path'] = videoFileController.text;
              updateData['Is_Video_File'] = true;
              print('   Keeping existing Video_File_Path: ${videoFileController.text}');
            }

            // Update other material paths if they have values
            if (worksheetController.text.isNotEmpty) {
              updateData['Worksheet_Path'] = worksheetController.text;
              print('   Updating Worksheet_Path: ${worksheetController.text}');
            }

            if (extraQuestionsController.text.isNotEmpty) {
              updateData['Extra_Questions_Path'] = extraQuestionsController.text;
              print('   Updating Extra_Questions_Path: ${extraQuestionsController.text}');
            }

            if (solvedQuestionsController.text.isNotEmpty) {
              updateData['Solved_Questions_Path'] = solvedQuestionsController.text;
              print('   Updating Solved_Questions_Path: ${solvedQuestionsController.text}');
            }

            if (notesController.text.isNotEmpty) {
              updateData['Revision_Notes_Path'] = notesController.text;
              print('   Updating Revision_Notes_Path: ${notesController.text}');
            }

            if (lessonPlansController.text.isNotEmpty) {
              updateData['Lesson_Plans_Path'] = lessonPlansController.text;
              print('   Updating Lesson_Plans_Path: ${lessonPlansController.text}');
            }

            if (teachingAidsController.text.isNotEmpty) {
              updateData['Teaching_Aids_Path'] = teachingAidsController.text;
              print('   Updating Teaching_Aids_Path: ${teachingAidsController.text}');
            }

            if (assessmentToolsController.text.isNotEmpty) {
              updateData['Assessment_Tools_Path'] = assessmentToolsController.text;
              print('   Updating Assessment_Tools_Path: ${assessmentToolsController.text}');
            }

            if (homeworkToolsController.text.isNotEmpty) {
              updateData['Homework_Tools_Path'] = homeworkToolsController.text;
              print('   Updating Homework_Tools_Path: ${homeworkToolsController.text}');
            }

            if (practiceZoneController.text.isNotEmpty) {
              updateData['Practice_Zone_Path'] = practiceZoneController.text;
              print('   Updating Practice_Zone_Path: ${practiceZoneController.text}');
            }

            if (learningPathController.text.isNotEmpty) {
              updateData['Learning_Path_Path'] = learningPathController.text;
              print('   Updating Learning_Path_Path: ${learningPathController.text}');
            }

            print('📤 [updateMaterial] Sending request with data: $updateData');
            final response = await ApiService.manageAcademicModule(updateData);
            print('📥 [updateMaterial] Received response: $response');

            if (context.mounted) {
              Navigator.pop(context);
              context.read<AcademicsBloc>().add(LoadMaterialsEvent(schoolRecNo: 1));
            }
          },
          fields: [
            // Video File Section
            if (item.isVideoFile || item.type == 'Video_File')
              DialogField(
                controller: videoFileController,
                label: "Video File",
                hint: "Video file path",
                icon: Iconsax.video,
                customWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: videoFileController,
                      readOnly: true,
                      style: GoogleFonts.inter(color: AppTheme.darkText),
                      decoration: _buildDialogInputDecoration(
                        "Video File",
                        Iconsax.video,
                        hint: "Video file path",
                        enabled: false,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: isAddingNewVideo ? null : pickAndUploadVideoFile,
                      icon: isAddingNewVideo
                          ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Icon(Iconsax.document_upload, size: 16),
                      label: Text(
                        isAddingNewVideo ? 'Uploading...' : 'Upload New Video',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size(0, 32),
                      ),
                    ),
                  ],
                ),
              ),

            // Displaying all other potential fields with their current values
            if (worksheetController.text.isNotEmpty)
              DialogField(controller: worksheetController, label: "Worksheet Path", hint: "/uploads/...", icon: Iconsax.document_text_1),

            if (extraQuestionsController.text.isNotEmpty)
              DialogField(controller: extraQuestionsController, label: "Extra Questions Path", hint: "/uploads/...", icon: Iconsax.document_text),

            if (solvedQuestionsController.text.isNotEmpty)
              DialogField(controller: solvedQuestionsController, label: "Solved Questions Path", hint: "/uploads/...", icon: Iconsax.document_text),

            if (notesController.text.isNotEmpty)
              DialogField(controller: notesController, label: "Revision Notes Path", hint: "/uploads/...", icon: Iconsax.note_1),

            if (lessonPlansController.text.isNotEmpty)
              DialogField(controller: lessonPlansController, label: "Lesson Plans Path", hint: "/uploads/...", icon: Iconsax.ruler),

            if (teachingAidsController.text.isNotEmpty)
              DialogField(controller: teachingAidsController, label: "Teaching Aids Path", hint: "/uploads/...", icon: Iconsax.clipboard_text),

            if (assessmentToolsController.text.isNotEmpty)
              DialogField(controller: assessmentToolsController, label: "Assessment Tools Path", hint: "/uploads/...", icon: Iconsax.award),

            if (homeworkToolsController.text.isNotEmpty)
              DialogField(controller: homeworkToolsController, label: "Homework Tools Path", hint: "/uploads/...", icon: Iconsax.home),

            if (practiceZoneController.text.isNotEmpty)
              DialogField(controller: practiceZoneController, label: "Practice Zone Path", hint: "/uploads/...", icon: Iconsax.cpu),

            if (learningPathController.text.isNotEmpty)
              DialogField(controller: learningPathController, label: "Learning Path Path", hint: "/uploads/...", icon: Iconsax.chart_2),
          ],
        );
      },
    ),
  );
}

class DialogField {
final TextEditingController? controller;
final String label;
final String hint;
final IconData icon;
final int maxLines;
final TextInputType keyboardType;
final Widget? customWidget;
final bool readOnly;

DialogField({
this.controller,
required this.label,
required this.hint,
required this.icon,
this.maxLines = 1,
this.keyboardType = TextInputType.text,
this.customWidget,
this.readOnly = false,
});
}

class AddEditDialog extends StatelessWidget {
final String title;
final String? subtitle;
final IconData icon;
final Color color;
final List<DialogField> fields;
final VoidCallback onSave;

const AddEditDialog({
super.key,
required this.title,
this.subtitle,
required this.icon,
required this.color,
required this.fields,
required this.onSave,
});

@override
Widget build(BuildContext context) {
return Dialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
elevation: 0,
backgroundColor: Colors.white,
child: Container(
constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750),
padding: const EdgeInsets.all(32),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: color.withOpacity(0.1),
borderRadius: BorderRadius.circular(16),
),
child: Icon(icon, color: color, size: 28),
),
const SizedBox(width: 18),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: GoogleFonts.poppins(
fontSize: 24,
fontWeight: FontWeight.w700,
color: AppTheme.darkText,
),
),
if (subtitle != null)
Text(
subtitle!,
style: GoogleFonts.inter(
fontSize: 14,
color: AppTheme.bodyText,
),
),
],
),
),
IconButton(
icon: Icon(Iconsax.close_circle, color: AppTheme.borderGrey, size: 26),
onPressed: () => Navigator.pop(context),
splashRadius: 24,
),
],
),
const Divider(height: 36, thickness: 1.5, color: AppTheme.borderGrey),
Flexible(
child: SingleChildScrollView(
child: Column(
mainAxisSize: MainAxisSize.min,
children: fields
    .map((field) => Padding(
padding: const EdgeInsets.only(bottom: 18),
child: field.customWidget ??
TextFormField(
controller: field.controller,
maxLines: field.maxLines,
keyboardType: field.keyboardType,
readOnly: field.readOnly,
style: GoogleFonts.inter(color: field.readOnly ? AppTheme.bodyText : AppTheme.darkText),
decoration: _buildDialogInputDecoration(
field.label,
field.icon,
hint: field.hint,
enabled: !field.readOnly,
),
),
))
    .toList(),
),
),
),
const SizedBox(height: 20),
Row(
mainAxisAlignment: MainAxisAlignment.end,
children: [
TextButton(
onPressed: () => Navigator.pop(context),
style: TextButton.styleFrom(
padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
),
child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.bodyText)),
),
const SizedBox(width: 12),
ElevatedButton(
onPressed: onSave,
style: ElevatedButton.styleFrom(
backgroundColor: color,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
elevation: 0,
),
child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
),
],
),
],
),
),
);
}
}

InputDecoration _buildDialogInputDecoration(String label, IconData icon, {String? hint, bool enabled = true}) {
return InputDecoration(
labelText: label,
hintText: hint,
hintStyle: GoogleFonts.inter(color: AppTheme.bodyText.withOpacity(0.5), fontSize: 14),
labelStyle: GoogleFonts.inter(color: AppTheme.bodyText, fontWeight: FontWeight.w500),
prefixIcon: Padding(
padding: const EdgeInsets.only(left: 10, right: 10),
child: Icon(icon, size: 20, color: enabled ? AppTheme.primaryGreen : AppTheme.borderGrey),
),
prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.borderGrey.withOpacity(0.5))),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide(color: AppTheme.borderGrey.withOpacity(0.5)),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
),
disabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide(color: AppTheme.borderGrey.withOpacity(0.2)),
),
filled: true,
fillColor: enabled ? Colors.white : AppTheme.borderGrey.withOpacity(0.1),
contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
enabled: enabled,
);
}

