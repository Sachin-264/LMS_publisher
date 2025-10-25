
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Service/academics_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lms_publisher/screens/AcademicsScreen/materialdetailscreen.dart';
import 'dart:ui';
import 'academics_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:provider/provider.dart';




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

// XML Generation Helper for Multiple Files
String generateXmlFromFiles(List<String> files) {
  if (files.isEmpty) return '';

  StringBuffer xml = StringBuffer('<Files>');
  for (int i = 0; i < files.length; i++) {
    // Escape XML special characters
    String escapedPath = files[i]
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');

    xml.write('<File Sno="${i + 1}" Path="$escapedPath" />');
  }
  xml.write('</Files>');

  return xml.toString();
}

// XML Parsing Helper to Extract Files - DETAILED DEBUG VERSION
List<Map<String, dynamic>> parseXmlFiles(String xmlString) {
  if (xmlString.isEmpty) return [];

  print('🔍 [parseXmlFiles] Input XML: $xmlString');

  try {
    final List<Map<String, dynamic>> files = [];

    // ✅ UPDATED REGEX - Now includes Name attribute
    final filePattern = RegExp(
      r'<File\s+Sno="(\d+)"\s+Path="([^"]+)"\s+Type="([^"]+)"(?:\s+Name="([^"]*)")?\s*/?>',
      caseSensitive: false,
    );

    final matches = filePattern.allMatches(xmlString);
    print('🔍 [parseXmlFiles] Found ${matches.length} file matches');

    for (final match in matches) {
      final sno = int.tryParse(match.group(1) ?? '0') ?? 0;
      final path = match.group(2) ?? '';
      final type = match.group(3) ?? '';
      final name = match.group(4) ?? 'Unnamed File'; // ✅ EXTRACT NAME

      // Decode HTML entities
      final decodedPath = path
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&apos;', "'");

      final decodedName = name
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&apos;', "'");

      print('📄 [parseXmlFiles] File #$sno: name=$decodedName, type=$type, path=$decodedPath');

      files.add({
        'sno': sno,
        'path': decodedPath,
        'type': type,
        'name': decodedName, // ✅ ADD NAME
      });
    }

    print('✅ [parseXmlFiles] Successfully parsed ${files.length} files');
    return files;
  } catch (e) {
    print('❌ [parseXmlFiles] Error: $e');
    return [];
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
items: items.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
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
      final subjectsResponse = await ApiService.getSubjects();
      if (subjectsResponse['success'] == true && subjectsResponse['data'] != null) {
        setState(() {
          allSubjects = (subjectsResponse['data'] as List).map((json) => SubjectModel.fromJson(json)).toList();
        });
        print('✅ ChaptersPage: Loaded ${allSubjects.length} subjects');
      }

      // Load all chapters initially
      context.read<AcademicsBloc>().add(LoadChaptersEvent());
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
      context.read<AcademicsBloc>().add(LoadChaptersEvent());
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
      context.read<AcademicsBloc>().add(LoadMaterialsEvent());
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
      context.read<AcademicsBloc>().add(LoadMaterialsEvent());
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
      context.read<AcademicsBloc>().add(LoadMaterialsEvent());
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
          onAddPressed: () async {
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
            context.read<AcademicsBloc>().add(LoadMaterialsEvent());
          },
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
              return _buildMaterialSkeletonCard(context);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _SkeletonBox(borderRadius: 12),
          ),
          const SizedBox(height: 10),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    // Filter subjects based on selected class
    final availableSubjects = selectedClassId != null
        ? allSubjects.where((s) => s.classId == selectedClassId).toList()
        : <SubjectModel>[];

    // Filter chapters based on selected subject
    final availableChapters = selectedSubjectId != null
        ? allChapters.where((ch) => ch.subjectId == selectedSubjectId).toList()
        : <ChapterModel>[];

    if (isMobile) {
      // Mobile: Vertical layout
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildClassFilter(),
          const SizedBox(height: 12),
          _buildSubjectFilter(availableSubjects),
          const SizedBox(height: 12),
          _buildChapterFilter(availableChapters),
        ],
      );
    }

    // Desktop: Horizontal layout
    return Row(
      children: [
        Expanded(child: _buildClassFilter()),
        const SizedBox(width: 12),
        Expanded(child: _buildSubjectFilter(availableSubjects)),
        const SizedBox(width: 12),
        Expanded(child: _buildChapterFilter(availableChapters)),
      ],
    );
  }

  Widget _buildClassFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selectedClassId,
          hint: Row(
            children: [
              const Icon(Iconsax.building, size: 18, color: AppTheme.bodyText),
              const SizedBox(width: 8),
              Text(
                'All Classes',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.bodyText,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: const Icon(Iconsax.arrow_down_1, size: 18),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.darkText,
          ),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Row(
                children: [
                  const Icon(Iconsax.building, size: 18, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    'All Classes',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            ...allClasses.map((c) {
              return DropdownMenuItem<int?>(
                value: c.id,
                child: Row(
                  children: [
                    const Icon(Iconsax.building, size: 18, color: AppTheme.bodyText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
          onChanged: (value) {
            onClassChanged(value);
          },
        ),
      ),
    );
  }

  Widget _buildSubjectFilter(List<SubjectModel> availableSubjects) {
    final isEnabled = selectedClassId != null && availableSubjects.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.white : Colors.grey[100],
        border: Border.all(
          color: isEnabled ? AppTheme.borderGrey : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selectedSubjectId,
          hint: Row(
            children: [
              Icon(
                Iconsax.book,
                size: 18,
                color: isEnabled ? AppTheme.bodyText : Colors.grey[400],
              ),
              const SizedBox(width: 8),
              Text(
                isEnabled ? 'All Subjects' : 'Select class first',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isEnabled ? AppTheme.bodyText : Colors.grey[400],
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(
            Iconsax.arrow_down_1,
            size: 18,
            color: isEnabled ? AppTheme.darkText : Colors.grey[400],
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.darkText,
          ),
          items: isEnabled
              ? [
            DropdownMenuItem<int?>(
              value: null,
              child: Row(
                children: [
                  const Icon(Iconsax.book, size: 18, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    'All Subjects',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            ...availableSubjects.map((s) {
              return DropdownMenuItem<int?>(
                value: s.id,
                child: Row(
                  children: [
                    const Icon(Iconsax.book, size: 18, color: AppTheme.bodyText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ]
              : null,
          onChanged: isEnabled ? (value) => onSubjectChanged(value) : null,
        ),
      ),
    );
  }

  Widget _buildChapterFilter(List<ChapterModel> availableChapters) {
    final isEnabled = selectedSubjectId != null && availableChapters.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.white : Colors.grey[100],
        border: Border.all(
          color: isEnabled ? AppTheme.borderGrey : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selectedChapterId,
          hint: Row(
            children: [
              Icon(
                Iconsax.document_text,
                size: 18,
                color: isEnabled ? AppTheme.bodyText : Colors.grey[400],
              ),
              const SizedBox(width: 8),
              Text(
                isEnabled ? 'All Chapters' : 'Select subject first',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isEnabled ? AppTheme.bodyText : Colors.grey[400],
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(
            Iconsax.arrow_down_1,
            size: 18,
            color: isEnabled ? AppTheme.darkText : Colors.grey[400],
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.darkText,
          ),
          items: isEnabled
              ? [
            DropdownMenuItem<int?>(
              value: null,
              child: Row(
                children: [
                  const Icon(Iconsax.document_text, size: 18, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    'All Chapters',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            ...availableChapters.map((ch) {
              return DropdownMenuItem<int?>(
                value: ch.id,
                child: Row(
                  children: [
                    const Icon(Iconsax.document_text, size: 18, color: AppTheme.bodyText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ch.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ]
              : null,
          onChanged: isEnabled ? (value) => onChapterChanged(value) : null,
        ),
      ),
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
items: allClasses.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
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
items: subjects.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
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
  final String title;
  final String? buttonLabel; // MADE NULLABLE
  final IconData? buttonIcon;
  final VoidCallback? onAddPressed;
  final Widget header;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Widget? filters;
  final List<Widget>? headerActions;
  final bool placeHeaderActionsOnNewRow;

  const MasterViewTemplate({
    super.key,
    required this.title,
    this.buttonLabel, // MADE OPTIONAL
    this.buttonIcon,
    this.onAddPressed,
    required this.header,
    required this.itemCount,
    required this.itemBuilder,
    this.filters,
    this.headerActions,
    this.placeHeaderActionsOnNewRow = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return StyledContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Responsive Header
          _buildResponsiveHeader(context, isMobile),

          const Divider(height: 40, thickness: 1),

          // Filters
          if (filters != null) ...[
            filters!,
            const SizedBox(height: AppTheme.defaultPadding),
          ],

          // Header Actions on new row for mobile (if needed)
          if (isMobile && placeHeaderActionsOnNewRow && headerActions != null && headerActions!.isNotEmpty) ...[
            ...headerActions!,
            const SizedBox(height: AppTheme.defaultPadding),
          ],

          // Content
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

  Widget _buildResponsiveHeader(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Column(
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
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Only show button if label and callback are provided
              if (buttonLabel != null && onAddPressed != null)
                _buildMobileIconButton(context),
            ],
          ),
        ],
      );
    } else {
      return Row(
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
          if (headerActions != null && !placeHeaderActionsOnNewRow)
            ...headerActions!,
          if (headerActions != null && !placeHeaderActionsOnNewRow)
            const SizedBox(width: 16),
          // Only show button if label and callback are provided
          if (buttonLabel != null && onAddPressed != null)
            _buildDesktopButton(context),
        ],
      );
    }
  }

  Widget _buildMobileIconButton(BuildContext context) {
    return Material(
      color: AppTheme.primaryGreen,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: onAddPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            buttonIcon ?? Iconsax.add,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onAddPressed,
      icon: Icon(buttonIcon ?? Iconsax.add, size: 20),
      label: Text(buttonLabel!, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        elevation: 0,
        shadowColor: AppTheme.primaryGreen.withOpacity(0.3),
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
    final userProvider = Provider.of<UserProvider>(context);
    final canEdit = userProvider.hasPermission('M004', 'edit');
    final canDelete = userProvider.hasPermission('M004', 'delete');

    return EnhancedListItem(
      icon: Iconsax.building_4,
      iconColor: Colors.blue,
      title: item.name,
      subtitle: item.description,
      statusBadge: StatusBadge(isActive: item.isActive),
      onEdit: canEdit ? () {
        print('🔐 ClassListItem: Checking EDIT permission for M004');
        if (userProvider.hasPermission('M004', 'edit')) {
          print('✅ ClassListItem: EDIT permission granted');
          showEditClassDialog(context, item);
        } else {
          print('❌ ClassListItem: EDIT permission denied');
          _showPermissionDeniedDialog(context, 'edit classes');
        }
      } : null,
      onDelete: canDelete ? () {
        print('🔐 ClassListItem: Checking DELETE permission for M004');
        if (userProvider.hasPermission('M004', 'delete')) {
          print('✅ ClassListItem: DELETE permission granted');
          showConfirmDeleteDialog(
            context,
            item.name,
            Colors.blue,
                () {
              context.read<AcademicsBloc>().add(DeleteClassEvent(
                classId:item.id,
                hardDelete: true,
              ));
            },
          );
        } else {
          print('❌ ClassListItem: DELETE permission denied');
          _showPermissionDeniedDialog(context, 'delete classes');
        }
      } : null,
      onTap: () {
        showDetailDialog(
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
            onEdit: canEdit ? () {
              Navigator.pop(context);
              showEditClassDialog(context, item);
            } : null,
          ),
        );
      },
      webCells: [
        WebCell(
          flex: 3,
          child: Text(item.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
        WebCell(
          flex: 3,
          child: Text(
            item.description,
            style: GoogleFonts.inter(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        WebCell(
          flex: 2,
          child: Text(item.subjectCount.toString(), style: GoogleFonts.inter(fontSize: 14)),
        ),
        WebCell(
          flex: 1,
          child: StatusBadge(isActive: item.isActive),
        ),
        WebCell(
          flex: 1,
          alignment: Alignment.centerRight,
          child: ActionButtons(
            onEdit: canEdit ? () => showEditClassDialog(context, item) : null,
            onDelete: canDelete ? () {
              showConfirmDeleteDialog(
                context,
                item.name,
                Colors.blue,
                    () {
                  context.read<AcademicsBloc>().add(DeleteClassEvent(
                    classId: item.id,
                    hardDelete: true,
                  ));
                },
              );
            } : null,
            onView: () {
              showDetailDialog(
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
                  onEdit: canEdit ? () {
                    Navigator.pop(context);
                    showEditClassDialog(context, item);
                  } : null,
                ),
              );
            },
            usePopupOnMobile: true,
          ),
        ),
      ],
      mobileInfoRows: [
        buildInfoRow(Iconsax.document_text, 'Desc: ${item.description}', maxLines: 2),
        const SizedBox(height: 8),
        buildInfoRow(Iconsax.book_1, 'Subjects: ${item.subjectCount}'),
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
    final userProvider = Provider.of<UserProvider>(context);
    final canEdit = userProvider.hasPermission('M004', 'edit');
    final canDelete = userProvider.hasPermission('M004', 'delete');

    print('📋 SubjectListItem: Rendering ${item.name}');

    return EnhancedListItem(
      icon: Iconsax.book_1,
      iconColor: Colors.green,
      title: item.name,
      subtitle: null,
      statusBadge: StatusBadge(isActive: item.isActive),
      onEdit: canEdit ? () {
        print('🔐 SubjectListItem: Checking EDIT permission for M004');
        print('✅ SubjectListItem: Edit clicked for ${item.name}');
        if (userProvider.hasPermission('M004', 'edit')) {
          print('✅ SubjectListItem: EDIT permission granted');
          showEditSubjectDialog(context, item, allClasses);
        } else {
          print('❌ SubjectListItem: EDIT permission denied');
          _showPermissionDeniedDialog(context, 'edit subjects');
        }
      } : null,
      onDelete: canDelete ? () {
        print('🔐 SubjectListItem: Checking DELETE permission for M004');
        print('⚠️ SubjectListItem: Delete clicked for ${item.name}');
        if (userProvider.hasPermission('M004', 'delete')) {
          print('✅ SubjectListItem: DELETE permission granted');
          showConfirmDeleteDialog(
            context,
            item.name,
            Colors.green,
                () {
              print('🗑️ SubjectListItem: Delete confirmed for ${item.name} (ID: ${item.id})');
              context.read<AcademicsBloc>().add(
                DeleteSubjectEvent(
                  subjectId: item.id,
                  hardDelete: true,
                ),
              );
            },
          );
        } else {
          print('❌ SubjectListItem: DELETE permission denied');
          _showPermissionDeniedDialog(context, 'delete subjects');
        }
      } : null,
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
                value: item.className??'',
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
            onEdit: canEdit ? () {
              Navigator.pop(context);
              showEditSubjectDialog(context, item, allClasses);
            } : null,
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
            item.className ?? '',
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
            onEdit: canEdit ? () {
              print('📝 SubjectListItem: Web Edit clicked for ${item.name}');
              showEditSubjectDialog(context, item, allClasses);
            } : null,
            onDelete: canDelete ? () {
              print('🗑️ SubjectListItem: Web Delete clicked for ${item.name}');
              showConfirmDeleteDialog(
                context,
                item.name,
                Colors.green,
                    () {
                  print('🗑️ SubjectListItem: Web Delete confirmed for ${item.name} (ID: ${item.id})');
                  context.read<AcademicsBloc>().add(
                    DeleteSubjectEvent(
                      subjectId:item.id,
                      hardDelete: true,
                    ),
                  );
                },
              );
            } : null,
            onView: () {
              print('👁️ SubjectListItem: Web View details clicked for ${item.name}');
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
                      value: item.className??'',
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
                  onEdit: canEdit ? () {
                    Navigator.pop(context);
                    showEditSubjectDialog(context, item, allClasses);
                  } : null,
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
          'Chapters: ${item.chapterCount}',
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
    final userProvider = Provider.of<UserProvider>(context);
    final canEdit = userProvider.hasPermission('M004', 'edit');
    final canDelete = userProvider.hasPermission('M004', 'delete');

    return EnhancedListItem(
      icon: Iconsax.document_text_1,
      iconColor: Colors.orange,
      title: item.name,
      subtitle: item.subjectName,
      onEdit: canEdit ? () {
        print('🔐 ChapterListItem: Checking EDIT permission for M004');
        if (userProvider.hasPermission('M004', 'edit')) {
          print('✅ ChapterListItem: EDIT permission granted');
          showEditChapterDialog(context, item, allSubjects);
        } else {
          print('❌ ChapterListItem: EDIT permission denied');
          _showPermissionDeniedDialog(context, 'edit chapters');
        }
      } : null,
      onDelete: canDelete ? () {
        print('🔐 ChapterListItem: Checking DELETE permission for M004');
        if (userProvider.hasPermission('M004', 'delete')) {
          print('✅ ChapterListItem: DELETE permission granted');
          showConfirmDeleteDialog(
            context,
            item.name,
            Colors.orange,
                () {
              context.read<AcademicsBloc>().add(DeleteChapterEvent(
                chapterId: item.id,
                hardDelete: true,
              ));
            },
          );
        } else {
          print('❌ ChapterListItem: DELETE permission denied');
          _showPermissionDeniedDialog(context, 'delete chapters');
        }
      } : null,
      onTap: () {
        showDetailDialog(
          context,
          DetailDialogData(
            title: item.name,
            icon: Iconsax.document_text_1,
            color: Colors.orange,
            fields: [
              DetailField(label: 'Chapter Name', value: item.name, icon: Iconsax.edit),
              DetailField(label: 'Subject', value: item.subjectName??'', icon: Iconsax.book_1),
              DetailField(label: 'Materials', value: item.materialCount.toString(), icon: Iconsax.folder_open),
            ],
            onEdit: canEdit ? () {
              Navigator.pop(context);
              showEditChapterDialog(context, item, allSubjects);
            } : null,
          ),
        );
      },
      webCells: [
        WebCell(
          flex: 4,
          child: Text(item.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
        WebCell(
          flex: 3,
          child: Text(item.subjectName??'', style: GoogleFonts.inter(fontSize: 14)),
        ),
        WebCell(
          flex: 2,
          child: Text(item.materialCount.toString(), style: GoogleFonts.inter(fontSize: 14)),
        ),
        WebCell(
          flex: 1,
          alignment: Alignment.centerRight,
          child: ActionButtons(
            onEdit: canEdit ? () => showEditChapterDialog(context, item, allSubjects) : null,
            onDelete: canDelete ? () {
              showConfirmDeleteDialog(
                context,
                item.name,
                Colors.orange,
                    () {
                  context.read<AcademicsBloc>().add(DeleteChapterEvent(
                    chapterId: item.id,
                    hardDelete: true,
                  ));
                },
              );
            } : null,
            onView: () {
              showDetailDialog(
                context,
                DetailDialogData(
                  title: item.name,
                  icon: Iconsax.document_text_1,
                  color: Colors.orange,
                  fields: [
                    DetailField(label: 'Chapter Name', value: item.name, icon: Iconsax.edit),
                    DetailField(label: 'Subject', value: item.subjectName??'', icon: Iconsax.book_1),
                    DetailField(label: 'Materials', value: item.materialCount.toString(), icon: Iconsax.folder_open),
                  ],
                  onEdit: canEdit ? () {
                    Navigator.pop(context);
                    showEditChapterDialog(context, item, allSubjects);
                  } : null,
                ),
              );
            },
            usePopupOnMobile: true,
          ),
        ),
      ],
      mobileInfoRows: [
        buildInfoRow(Iconsax.folder_open, 'Materials: ${item.materialCount}'),
      ],
    );
  }
}




class MaterialGridScreen extends StatelessWidget {
  final List<MaterialModel> materials;
  final List<SubjectModel> allSubjects;

  const MaterialGridScreen(
      {super.key, required this.materials, required this.allSubjects});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materials'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = (constraints.maxWidth / 350).floor();
          if (crossAxisCount < 2) {
            crossAxisCount = 2;
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              //
              //  <-- THIS IS THE LINE TO CHANGE
              //
              // To increase the card height, make this number smaller.
              // A value of 1.0 is a square. A value less than 1.0 is a rectangle that is taller than it is wide.
              // Let's try a smaller value for a noticeable height increase.
              childAspectRatio: 0.65,
            ),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              return MaterialGridItem(
                item: materials[index],
                allSubjects: allSubjects,
              );
            },
          );
        },
      ),
    );
  }
}

class MaterialGridItem extends StatefulWidget {
  final MaterialModel item;
  final List<SubjectModel> allSubjects;

  const MaterialGridItem({
    super.key,
    required this.item,
    required this.allSubjects,
  });

  @override
  MaterialGridItemState createState() => MaterialGridItemState();
}

class MaterialGridItemState extends State<MaterialGridItem> {
  bool isHovered = false;

  // Get all available materials count
  int getTotalMaterialsCount() {
    int count = 0;
    if (widget.item.videoLinks.isNotEmpty) count += widget.item.videoLinks.length;
    if (widget.item.worksheets.isNotEmpty) count += widget.item.worksheets.length;
    if (widget.item.extraQuestions.isNotEmpty) count += widget.item.extraQuestions.length;
    if (widget.item.solvedQuestions.isNotEmpty) count += widget.item.solvedQuestions.length;
    if (widget.item.revisionNotes.isNotEmpty) count += widget.item.revisionNotes.length;
    if (widget.item.lessonPlans.isNotEmpty) count += widget.item.lessonPlans.length;
    if (widget.item.teachingAids.isNotEmpty) count += widget.item.teachingAids.length;
    if (widget.item.assessmentTools.isNotEmpty) count += widget.item.assessmentTools.length;
    if (widget.item.homeworkTools.isNotEmpty) count += widget.item.homeworkTools.length;
    if (widget.item.practiceZone.isNotEmpty) count += widget.item.practiceZone.length;
    if (widget.item.learningPath.isNotEmpty) count += widget.item.learningPath.length;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final canEdit = userProvider.hasPermission('M004', 'edit');
    final canDelete = userProvider.hasPermission('M004', 'delete');

    // Get subject color
    Color subjectColor = AppTheme.primaryGreen;
    try {
      final subject = widget.allSubjects.firstWhere((s) => s.id == widget.item.subjectId);
      final colorHex = subject.color.startsWith('#') ? subject.color : '#${subject.color}';
      subjectColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      // Use default color if subject not found
    }

    final totalFiles = getTotalMaterialsCount();

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MaterialDetailScreen(
                material: widget.item,
                allClasses: const [], // Empty list for detail view
                allSubjects: widget.allSubjects,
                allChapters: const [], // Empty list for detail view
                isAddMode: false,
              ),
            ),
          );
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered
                  ? subjectColor.withOpacity(0.4)
                  : AppTheme.borderGrey.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? subjectColor.withOpacity(0.15)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isHovered ? 15 : 10,
                offset: Offset(0, isHovered ? 6 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: subjectColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.chapterName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (canEdit || canDelete)
                          PopupMenuButton<String>(
                            icon: const Icon(Iconsax.more, size: 18),
                            onSelected: (value) {
                              if (value == 'edit' && canEdit) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MaterialDetailScreen(
                                      material: widget.item,
                                      allClasses: const [],
                                      allSubjects: widget.allSubjects,
                                      allChapters: const [],
                                      isAddMode: false,
                                    ),
                                  ),
                                );
                              }
                              else if (value == 'delete' && canDelete) {
                                _showDeleteConfirmation(context);
                              }
                            },
                            itemBuilder: (context) => [
                              if (canEdit)
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Iconsax.edit, size: 16),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                              if (canDelete)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Iconsax.trash, size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: subjectColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.item.subjectName,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: subjectColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.item.className,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.bodyText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Materials Count Section
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (totalFiles > 0) ...[
                        Icon(
                          Iconsax.folder_open,
                          size: 36,
                          color: subjectColor.withOpacity(0.7),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$totalFiles',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: subjectColor,
                          ),
                        ),
                        Text(
                          totalFiles == 1 ? 'File' : 'Files',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.bodyText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Material type badges
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            if (widget.item.videoLinks.isNotEmpty)
                              _buildMaterialTypeBadge(
                                'Video',
                                Iconsax.video,
                                Colors.red,
                                widget.item.videoLinks.length,
                              ),
                            if (widget.item.worksheets.isNotEmpty)
                              _buildMaterialTypeBadge(
                                'Worksheet',
                                Iconsax.document,
                                Colors.blue,
                                widget.item.worksheets.length,
                              ),
                            if (widget.item.revisionNotes.isNotEmpty)
                              _buildMaterialTypeBadge(
                                'Notes',
                                Iconsax.note,
                                Colors.purple,
                                widget.item.revisionNotes.length,
                              ),
                            if (widget.item.extraQuestions.isNotEmpty)
                              _buildMaterialTypeBadge(
                                'Extra Q',
                                Iconsax.document_text,
                                Colors.orange,
                                widget.item.extraQuestions.length,
                              ),
                            if (widget.item.solvedQuestions.isNotEmpty)
                              _buildMaterialTypeBadge(
                                'Solved',
                                Iconsax.tick_circle,
                                Colors.green,
                                widget.item.solvedQuestions.length,
                              ),
                          ],
                        ),
                      ] else ...[
                        Icon(
                          Iconsax.folder_2,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Materials',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.bodyText,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Footer
              if (widget.item.uploadedOn != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.clock, size: 12, color: AppTheme.bodyText),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatDate(widget.item.uploadedOn!),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.bodyText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
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

  Widget _buildMaterialTypeBadge(String label, IconData icon, Color color, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
    return '${(diff.inDays / 365).floor()} years ago';
  }

  void _showMaterialDetailDialog(BuildContext context, Color subjectColor) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: subjectColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Iconsax.folder_open, color: subjectColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.chapterName,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${widget.item.subjectName} - ${widget.item.className}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.bodyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Iconsax.close_circle),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Materials List
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.item.videoLinks.isNotEmpty)
                        _buildMaterialSection(
                          'Videos',
                          Iconsax.video,
                          Colors.red,
                          widget.item.videoLinks,
                          isVideo: true,
                        ),
                      if (widget.item.worksheets.isNotEmpty)
                        _buildMaterialSection(
                          'Worksheets',
                          Iconsax.document,
                          Colors.blue,
                          widget.item.worksheets,
                        ),
                      if (widget.item.extraQuestions.isNotEmpty)
                        _buildMaterialSection(
                          'Extra Questions',
                          Iconsax.document_text,
                          Colors.orange,
                          widget.item.extraQuestions,
                        ),
                      if (widget.item.solvedQuestions.isNotEmpty)
                        _buildMaterialSection(
                          'Solved Questions',
                          Iconsax.tick_circle,
                          Colors.green,
                          widget.item.solvedQuestions,
                        ),
                      if (widget.item.revisionNotes.isNotEmpty)
                        _buildMaterialSection(
                          'Revision Notes',
                          Iconsax.note,
                          Colors.purple,
                          widget.item.revisionNotes,
                        ),
                      if (widget.item.lessonPlans.isNotEmpty)
                        _buildMaterialSection(
                          'Lesson Plans',
                          Iconsax.note_1,
                          Colors.teal,
                          widget.item.lessonPlans,
                        ),
                      if (widget.item.teachingAids.isNotEmpty)
                        _buildMaterialSection(
                          'Teaching Aids',
                          Iconsax.teacher,
                          Colors.indigo,
                          widget.item.teachingAids,
                        ),
                      if (widget.item.assessmentTools.isNotEmpty)
                        _buildMaterialSection(
                          'Assessment Tools',
                          Iconsax.task_square,
                          Colors.pink,
                          widget.item.assessmentTools,
                        ),
                      if (widget.item.homeworkTools.isNotEmpty)
                        _buildMaterialSection(
                          'Homework Tools',
                          Iconsax.clipboard_text,
                          Colors.brown,
                          widget.item.homeworkTools,
                        ),
                      if (widget.item.practiceZone.isNotEmpty)
                        _buildMaterialSection(
                          'Practice Zone',
                          Iconsax.activity,
                          Colors.cyan,
                          widget.item.practiceZone,
                        ),
                      if (widget.item.learningPath.isNotEmpty)
                        _buildMaterialSection(
                          'Learning Path',
                          Iconsax.map,
                          Colors.lime,
                          widget.item.learningPath,
                        ),
                      if (getTotalMaterialsCount() == 0)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Text(
                              'No materials available',
                              style: GoogleFonts.inter(
                                color: AppTheme.bodyText,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialSection(
      String title,
      IconData icon,
      Color color,
      List<Map<String, dynamic>> files, {
        bool isVideo = false,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${files.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...files.map((file) {
            final sno = file['sno'] ?? 0;
            final path = file['path'] ?? '';

            return InkWell(
              onTap: () async {
                final url = isVideo ? path : getFullDocumentUrl(path);
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$sno',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        path.length > 40 ? '${path.substring(0, 40)}...' : path,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ),
                    Icon(
                      isVideo ? Iconsax.play_circle : Iconsax.document_download,
                      size: 18,
                      color: color,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showConfirmDeleteDialog(
      context,
      widget.item.chapterName,
      AppTheme.primaryGreen,
          () {
        context.read<AcademicsBloc>().add(
          DeleteMaterialEvent(
            recNo: widget.item.recNo,
            hardDelete: true,
          ),
        );
      },
    );
  }
}




// Local skeleton widgets for this file (shimmer effect)
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
  final VoidCallback? onDelete;
  final bool usePopup;
  final bool usePopupOnMobile;

  const ActionButtons({
    super.key,
    this.onEdit,
    this.onView,
    this.onDelete,
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

    if (usePopup) {
      return _buildPopupMenu();
    }

    return _buildIconButtons();
  }

  Widget _buildPopupMenu() {
    // Build list of available actions
    final List<PopupMenuEntry<int>> menuItems = [];

    if (onView != null) {
      menuItems.add(
        PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              const Icon(Iconsax.eye, size: 18, color: AppTheme.primaryGreen),
              const SizedBox(width: 10),
              Text('View Details', style: GoogleFonts.inter(fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (onEdit != null) {
      menuItems.add(
        PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              const Icon(Iconsax.edit, size: 18, color: Colors.blue),
              const SizedBox(width: 10),
              Text('Edit', style: GoogleFonts.inter(fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (onDelete != null) {
      menuItems.add(
        PopupMenuItem<int>(
          value: 2,
          child: Row(
            children: [
              const Icon(Iconsax.trash, size: 18, color: Colors.red),
              const SizedBox(width: 10),
              Text('Delete', style: GoogleFonts.inter(fontSize: 14, color: Colors.red)),
            ],
          ),
        ),
      );
    }

    // If no actions available, return empty container
    if (menuItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<int>(
      onSelected: (item) {
        if (item == 0 && onView != null) onView!();
        if (item == 1 && onEdit != null) onEdit!();
        if (item == 2 && onDelete != null) onDelete!();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => menuItems,
      icon: Icon(Iconsax.more, size: 20, color: AppTheme.bodyText.withOpacity(0.7)),
    );
  }

  Widget _buildIconButtons() {
    final List<Widget> buttons = [];

    if (onView != null) {
      buttons.add(
        IconButton(
          icon: const Icon(Iconsax.eye, size: 18),
          color: AppTheme.primaryGreen,
          tooltip: 'View Details',
          onPressed: onView,
        ),
      );
    }

    if (onEdit != null) {
      buttons.add(
        IconButton(
          icon: const Icon(Iconsax.edit, size: 18),
          color: Colors.blue,
          tooltip: 'Edit',
          onPressed: onEdit,
        ),
      );
    }

    if (onDelete != null) {
      buttons.add(
        IconButton(
          icon: const Icon(Iconsax.trash, size: 18),
          color: Colors.red,
          tooltip: 'Delete',
          onPressed: onDelete,
        ),
      );
    }

    // If no actions available, return empty container
    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: buttons,
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
'ClassID': item.id,
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
                  value: c.id,
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
            'SubjectID': item.id,
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
context.read<AcademicsBloc>().add(LoadChaptersEvent());
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
items: allClasses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
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
final orderController = TextEditingController(text: item.order.toString());

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
'ChapterID': item.id,
'ChapterDescription': descController.text,
'ChapterOrder': int.tryParse(orderController.text) ?? 0,
'ModifiedBy': 'Admin',
});
if (context.mounted) {
Navigator.pop(context);
context.read<AcademicsBloc>().add(LoadChaptersEvent());
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

