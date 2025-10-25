import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/screens/AcademicsScreen/academics_bloc.dart';
import 'package:lms_publisher/Service/academics_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _imageBaseUrl = "https://storage.googleapis.com/upload-images-34/images/LMS/";
const String _documentBaseUrl = "https://storage.googleapis.com/upload-images-34/documents/LMS/";

String getFullDocumentUrl(String filename) {
  if (filename.isEmpty) return '';
  final fileExtension = filename.split('.').last.toLowerCase();
  final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(fileExtension);

  if (isImage) {
    return '$_imageBaseUrl$filename';
  } else {
    return '$_documentBaseUrl$filename';
  }
}

// Helper function to generate XML from file list with type and name
String generateXmlFromFiles(List<Map<String, dynamic>> files) {
  if (files.isEmpty) return '';

  final buffer = StringBuffer('<Files>');
  for (int i = 0; i < files.length; i++) {
    // Escape XML special characters for path
    String escapedPath = files[i]['path']!
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');

    // Escape XML special characters for name
    String escapedName = (files[i]['name'] ?? 'Unnamed File')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');

    String fileType = files[i]['type'] ?? 'pdf';

    // ✅ Now includes Name attribute
    buffer.write('<File Sno="${i + 1}" Path="$escapedPath" Type="$fileType" Name="$escapedName"/>');
  }
  buffer.write('</Files>');

  print('🔧 [generateXmlFromFiles] Generated XML with ${files.length} files');
  return buffer.toString();
}


// Helper to get YouTube thumbnail
String getYoutubeThumbnail(String url) {
  final videoId = extractYoutubeVideoId(url);
  if (videoId != null) {
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }
  return '';
}

String? extractYoutubeVideoId(String url) {
  final regExp = RegExp(
    r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\s?]+)',
    caseSensitive: false,
  );
  final match = regExp.firstMatch(url);
  return match?.group(1);
}

class MaterialDetailScreen extends StatefulWidget {
  final MaterialModel? material;
  final List<ClassModel> allClasses;
  final List<SubjectModel> allSubjects;
  final List<ChapterModel> allChapters;
  final bool isAddMode;

  const MaterialDetailScreen({
    super.key,
    this.material,
    required this.allClasses,
    required this.allSubjects,
    required this.allChapters,
    this.isAddMode = false,
  });

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  bool isEditMode = false;
  bool isUploading = false;

  // For Add mode
  int? selectedClassId;
  int? selectedSubjectId;
  int? selectedChapterId;
  List<ChapterModel> filteredChapters = [];

  // File extension preferences for upload
  String defaultFileExtension = 'pdf'; // pdf, doc, docx, jpg, png, etc.
  bool alwaysAskExtension = false; // Ask every time or use default

  // Controllers for edit mode
  final Map<String, List<Map<String, String>>> editedFiles = {};

  @override
  void initState() {
    super.initState();
    _loadExtensionPreferences();

    if (widget.isAddMode) {
      isEditMode = true;
      _initializeEmptyFiles();
    } else {
      _initializeEditedFiles();
    }
  }

  Future<void> _loadExtensionPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      defaultFileExtension = prefs.getString('defaultFileExtension') ?? 'pdf';
      alwaysAskExtension = prefs.getBool('alwaysAskExtension') ?? false;
    });
  }

  Future<void> _saveExtensionPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('defaultFileExtension', defaultFileExtension);
    await prefs.setBool('alwaysAskExtension', alwaysAskExtension);
  }

  void _initializeEmptyFiles() {
    editedFiles['video'] = [];
    editedFiles['worksheet'] = [];
    editedFiles['extraQuestions'] = [];
    editedFiles['solvedQuestions'] = [];
    editedFiles['revisionNotes'] = [];
    editedFiles['lessonPlans'] = [];
    editedFiles['teachingAids'] = [];
    editedFiles['assessmentTools'] = [];
    editedFiles['homeworkTools'] = [];
    editedFiles['practiceZone'] = [];
    editedFiles['learningPath'] = [];
  }

  void _initializeEditedFiles() {
    editedFiles['video'] = widget.material!.videoLinks.map((f) => {
      'path': f['path'].toString(),
      'type': 'video',
      'name': f['name']?.toString() ?? 'Video', // ✅ Preserve name
    }).toList();

    editedFiles['worksheet'] = widget.material!.worksheets.map((f) => {
      'path': f['path'].toString(),
      'type': f['type']?.toString() ?? 'pdf',
      'name': f['name']?.toString() ?? 'Worksheet', // ✅ Preserve name
    }).toList();

    editedFiles['extraQuestions'] = widget.material!.extraQuestions.map((f) => {
      'path': f['path'].toString(),
      'type': f['type']?.toString() ?? 'pdf',
      'name': f['name']?.toString() ?? 'Extra Questions', // ✅ Preserve name
    }).toList();

    editedFiles['solvedQuestions'] = widget.material!.solvedQuestions.map((f) => {
      'path': f['path'].toString(),
      'type': f['type']?.toString() ?? 'pdf',
      'name': f['name']?.toString() ?? 'Solved Questions', // ✅ Preserve name
    }).toList();

    editedFiles['revisionNotes'] = widget.material!.revisionNotes.map((f) => {
      'path': f['path'].toString(),
      'type': f['type']?.toString() ?? 'pdf',
      'name': f['name']?.toString() ?? 'Revision Notes', // ✅ Preserve name
    }).toList();

    editedFiles['lessonPlans'] = widget.material!.lessonPlans.map((f) => {
      'path': f['path'].toString(),
      'type': f['type']?.toString() ?? 'pdf',
      'name': f['name']?.toString() ?? 'Lesson Plan', // ✅ Preserve name
    }).toList();

    editedFiles['teachingAids'] = widget.material!.teachingAids.map((f) => {
      'path': f['path'].toString(),
      'type': f['type']?.toString() ?? 'pdf',
      'name': f['name']?.toString() ?? 'Teaching Aid', // ✅ Preserve name
    }).toList();

    editedFiles['assessmentTools'] = widget.material!.assessmentTools.map((f) => {
      'path': f['path'].toString(),
      'type': f['type']?.toString() ?? 'pdf',
      'name': f['name']?.toString() ?? 'Assessment Tool', // ✅ Preserve name
    }).toList();

    editedFiles['homeworkTools'] = widget.material!.homeworkTools.map((f) => {
      'path': f['path'].toString(),
      'type': f['type']?.toString() ?? 'pdf',
      'name': f['name']?.toString() ?? 'Homework Tool', // ✅ Preserve name
    }).toList();

    editedFiles['practiceZone'] = widget.material!.practiceZone.map((f) => {
      'path': f['path'].toString(),
      'type': f['type']?.toString() ?? 'pdf',
      'name': f['name']?.toString() ?? 'Practice Zone', // ✅ Preserve name
    }).toList();

    editedFiles['learningPath'] = widget.material!.learningPath.map((f) => {
      'path': f['path'].toString(),
      'type': f['type']?.toString() ?? 'pdf',
      'name': f['name']?.toString() ?? 'Learning Path', // ✅ Preserve name
    }).toList();
  }


  Future<void> _loadChaptersForSubject(int subjectId) async {
    try {
      final response = await ApiService.getChapters(
        schoolRecNo: 1,
        subjectId: subjectId,
      );

      if (response['status'] == 'success' && response['data'] != null) {
        setState(() {
          filteredChapters = (response['data'] as List)
              .map((json) => ChapterModel.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading chapters: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading chapters: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color get subjectColor {
    try {
      int subjectId = widget.isAddMode ? (selectedSubjectId ?? 0) : widget.material!.subjectId;
      final subject = widget.allSubjects.firstWhere((s) => s.id == subjectId);
      final colorHex = subject.color.startsWith('#') ? subject.color : '#${subject.color}';
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryGreen;
    }
  }

  String get chapterName {
    if (widget.isAddMode) {
      if (selectedChapterId != null) {
        try {
          return filteredChapters.firstWhere((ch) => ch.id == selectedChapterId).name;
        } catch (e) {
          return 'Select Chapter';
        }
      }
      return 'Select Chapter';
    }
    return widget.material!.chapterName;
  }

  String get subjectName {
    if (widget.isAddMode) {
      if (selectedSubjectId != null) {
        try {
          return widget.allSubjects.firstWhere((s) => s.id == selectedSubjectId).name;
        } catch (e) {
          return 'Select Subject';
        }
      }
      return 'Select Subject';
    }
    return widget.material!.subjectName;
  }

  String get className {
    if (widget.isAddMode) {
      if (selectedClassId != null) {
        try {
          return widget.allClasses.firstWhere((c) => c.id == selectedClassId).name;
        } catch (e) {
          return 'Select Class';
        }
      }
      return 'Select Class';
    }
    return widget.material!.className;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;
    final userProvider = Provider.of<UserProvider>(context);
    final canEdit = widget.isAddMode || userProvider.hasPermission('M004', 'edit');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppTheme.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isAddMode ? 'Add Material' : (isEditMode ? 'Edit Material' : 'Material Details'),
          style: GoogleFonts.poppins(
            color: AppTheme.darkText,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [

          // ✅ Edit Button - Always visible in detail view when not editing
          if (canEdit && !isEditMode && !widget.isAddMode)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isEditMode = true;
                });
              },
              icon: const Icon(Iconsax.edit, size: 18),
              label: const Text('Edit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),

          // ✅ Save/Cancel buttons when editing
          if (isEditMode) ...[
            if (!widget.isAddMode)
              TextButton(
                onPressed: () {
                  setState(() {
                    isEditMode = false;
                    _initializeEditedFiles();
                  });
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: AppTheme.bodyText),
                ),
              ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: isUploading ? null : _saveChanges,
              icon: isUploading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Iconsax.tick_circle, size: 18),
              label: Text(widget.isAddMode ? 'Add Material' : 'Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 380,
          color: Colors.white,
          child: _buildMaterialInfo(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildDocumentsSections(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: _buildMaterialInfo(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildDocumentsSections(),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isAddMode && isEditMode) ...[
            Text(
              'Select Chapter',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 16),

            // Class Dropdown
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selectedClassId != null ? AppTheme.primaryGreen : AppTheme.borderGrey),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField<int>(
                value: selectedClassId,
                decoration: InputDecoration(
                  labelText: 'Class',
                  labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (selectedClassId != null ? AppTheme.primaryGreen : AppTheme.bodyText).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Iconsax.building,
                      color: selectedClassId != null ? AppTheme.primaryGreen : AppTheme.bodyText,
                      size: 20,
                    ),
                  ),
                ),
                items: widget.allClasses.map((c) {
                  return DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      c.name,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedClassId = value;
                    selectedSubjectId = null;
                    selectedChapterId = null;
                    filteredChapters = [];
                  });
                },
                validator: (value) {
                  if (value == null) return 'Please select a class';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Subject Dropdown
            Container(
              decoration: BoxDecoration(
                color: selectedClassId != null ? Colors.white : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selectedSubjectId != null ? AppTheme.primaryGreen : AppTheme.borderGrey),
                boxShadow: selectedClassId != null ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ] : [],
              ),
              child: DropdownButtonFormField<int>(
                value: selectedSubjectId,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (selectedSubjectId != null ? AppTheme.primaryGreen : AppTheme.bodyText).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Iconsax.book,
                      color: selectedSubjectId != null ? AppTheme.primaryGreen : AppTheme.bodyText,
                      size: 20,
                    ),
                  ),
                ),
                items: widget.allSubjects
                    .where((s) => s.classId == selectedClassId)
                    .map((s) {
                  return DropdownMenuItem(
                    value: s.id,
                    child: Text(
                      s.name,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
                onChanged: selectedClassId == null
                    ? null
                    : (value) async {
                  setState(() {
                    selectedSubjectId = value;
                    selectedChapterId = null;
                    filteredChapters = [];
                  });

                  if (value != null) {
                    await _loadChaptersForSubject(value);
                  }
                },
                validator: (value) {
                  if (value == null) return 'Please select a subject';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Chapter Dropdown
            Container(
              decoration: BoxDecoration(
                color: selectedSubjectId != null ? Colors.white : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selectedChapterId != null ? AppTheme.primaryGreen : AppTheme.borderGrey),
                boxShadow: selectedSubjectId != null ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ] : [],
              ),
              child: DropdownButtonFormField<int>(
                value: selectedChapterId,
                decoration: InputDecoration(
                  labelText: 'Chapter',
                  labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (selectedChapterId != null ? AppTheme.primaryGreen : AppTheme.bodyText).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Iconsax.document_text,
                      color: selectedChapterId != null ? AppTheme.primaryGreen : AppTheme.bodyText,
                      size: 20,
                    ),
                  ),
                ),
                items: filteredChapters.map((ch) {
                  return DropdownMenuItem(
                    value: ch.id,
                    child: Text(
                      ch.name,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
                onChanged: selectedSubjectId == null
                    ? null
                    : (value) {
                  setState(() {
                    selectedChapterId = value;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Please select a chapter';
                  return null;
                },
              ),
            ),

            if (filteredChapters.isEmpty && selectedSubjectId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'No chapters available for this subject',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.orange,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
          ] else ...[
            // Subject Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: subjectColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: subjectColor.withOpacity(0.3)),
              ),
              child: Text(
                subjectName,
                style: GoogleFonts.inter(
                  color: subjectColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Chapter Name
            Text(
              chapterName,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText,
              ),
            ),

            const SizedBox(height: 8),

            // Class Name
            Row(
              children: [
                Icon(Iconsax.building, size: 16, color: AppTheme.bodyText),
                const SizedBox(width: 8),
                Text(
                  className,
                  style: GoogleFonts.inter(
                    color: AppTheme.bodyText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
          ],

          // Statistics
          Text(
            'Material Statistics',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),

          const SizedBox(height: 16),

          _buildStatItem('Videos', editedFiles['video']!.length, Iconsax.video, Colors.red),
          _buildStatItem('Worksheets', editedFiles['worksheet']!.length, Iconsax.document, Colors.blue),
          _buildStatItem('Extra Questions', editedFiles['extraQuestions']!.length, Iconsax.document_text, Colors.orange),
          _buildStatItem('Solved Questions', editedFiles['solvedQuestions']!.length, Iconsax.tick_circle, Colors.green),
          _buildStatItem('Revision Notes', editedFiles['revisionNotes']!.length, Iconsax.note, Colors.purple),
          _buildStatItem('Lesson Plans', editedFiles['lessonPlans']!.length, Iconsax.note_1, Colors.teal),
          _buildStatItem('Teaching Aids', editedFiles['teachingAids']!.length, Iconsax.teacher, Colors.indigo),
          _buildStatItem('Assessment Tools', editedFiles['assessmentTools']!.length, Iconsax.task_square, Colors.pink),
          _buildStatItem('Homework Tools', editedFiles['homeworkTools']!.length, Iconsax.clipboard_text, Colors.amber),
          _buildStatItem('Practice Zone', editedFiles['practiceZone']!.length, Iconsax.activity, Colors.cyan),
          _buildStatItem('Learning Path', editedFiles['learningPath']!.length, Iconsax.map, Colors.deepOrange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon, Color color) {
    if (count == 0 && !isEditMode) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.darkText,
              ),
            ),
          ),
          Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildDocumentsSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('Video Links', Iconsax.video, Colors.red, 'video', isVideoSection: true),
        _buildSection('Worksheets', Iconsax.document, Colors.blue, 'worksheet'),
        _buildSection('Extra Questions', Iconsax.document_text, Colors.orange, 'extraQuestions'),
        _buildSection('Solved Questions', Iconsax.tick_circle, Colors.green, 'solvedQuestions'),
        _buildSection('Revision Notes', Iconsax.note, Colors.purple, 'revisionNotes'),
        _buildSection('Lesson Plans', Iconsax.note_1, Colors.teal, 'lessonPlans'),
        _buildSection('Teaching Aids', Iconsax.teacher, Colors.indigo, 'teachingAids'),
        _buildSection('Assessment Tools', Iconsax.task_square, Colors.pink, 'assessmentTools'),
        _buildSection('Homework Tools', Iconsax.clipboard_text, Colors.amber, 'homeworkTools'),
        _buildSection('Practice Zone', Iconsax.activity, Colors.cyan, 'practiceZone'),
        _buildSection('Learning Path', Iconsax.map, Colors.deepOrange, 'learningPath'),
      ],
    );
  }

  Widget _buildSection(
      String title,
      IconData icon,
      Color color,
      String fileType, {
        bool isVideoSection = false,
      }) {
    final displayFiles = editedFiles[fileType]!;

    if (!isEditMode && displayFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
              if (isEditMode)
                ElevatedButton.icon(
                  onPressed: () => _addFile(fileType, isVideoSection),
                  icon: Icon(isVideoSection ? Iconsax.link : Iconsax.document_upload, size: 16),
                  label: Text(isVideoSection ? 'Add Link' : 'Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (displayFiles.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  isEditMode ? 'No files added yet' : 'No files available',
                  style: GoogleFonts.inter(
                    color: AppTheme.bodyText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ...displayFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return _buildFileCard(file, index, fileType, isVideoSection, color);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildFileCard(Map<String, dynamic> file, int index, String fileType, bool isVideo, Color color) {
    final filePath = file['path']!;
    final fileTypeStr = file['type'] ?? 'pdf';
    final customName = file['name'] ?? (isVideo ? 'Video ${index + 1}' : _getFileName(filePath)); // ✅ USE CUSTOM NAME

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Thumbnail or Icon
          if (isVideo)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: getYoutubeThumbnail(filePath),
                width: 80,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 80,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 80,
                  height: 60,
                  color: color.withOpacity(0.1),
                  child: Icon(Iconsax.video, color: color),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Iconsax.document,
                color: color,
                size: 24,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ DISPLAY CUSTOM NAME
                Text(
                  customName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Show server filename as secondary text
                Text(
                  isVideo ? filePath : 'File: ${_getFileName(filePath)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.bodyText.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isVideo) ...  [
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      fileTypeStr.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ✅ Action buttons - View in detail mode, Delete in edit mode
          if (!isEditMode)
            IconButton(
              icon: Icon(isVideo ? Iconsax.play : Iconsax.document_download, color: color),
              onPressed: () => _openFile(filePath, isVideo),
              tooltip: isVideo ? 'Play Video' : 'Open Document',
            ),
          if (isEditMode)
            IconButton(
              icon: const Icon(Iconsax.trash, color: Colors.red),
              onPressed: () {
                setState(() {
                  editedFiles[fileType]!.removeAt(index);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${isVideo ? "Video" : "Document"} removed'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              tooltip: 'Delete',
            ),
        ],
      ),
    );
  }


  String _getFileName(String path) {
    return path.split('/').last.split('.').first;
  }

  void _openFile(String path, bool isVideo) async {
    final url = isVideo ? path : getFullDocumentUrl(path);
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file')),
        );
      }
    }
  }

  void _addFile(String fileType, bool isVideo) async {
    if (isVideo) {
      // Add video link dialog
      final controller = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Add Video Link', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'YouTube URL',
              hintText: 'https://youtube.com/watch?v=...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: const Text('Add'),
            ),
          ],
        ),
      );

      if (result != null && result.isNotEmpty) {
        // ✅ ASK FOR CUSTOM VIDEO NAME
        final videoName = await _showCustomNameDialog(context, 'Video', 'Enter a display name for this video');
        if (videoName == null) return;

        setState(() {
          editedFiles[fileType]!.add({
            'path': result,
            'type': 'video',
            'name': videoName, // ✅ CUSTOM NAME
          });
        });
      }
    } else {
      // ✅ STEP 1: FIRST OPEN FILE PICKER
      try {
        print('📂 [_addFile] Opening file picker...');

        FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.any,
        );

        if (result == null || result.files.isEmpty) {
          print('❌ [_addFile] No files selected');
          return;
        }

        print('📁 [_addFile] ${result.files.length} file(s) selected');

        // ✅ STEP 2: SHOW EXTENSION SELECTOR DIALOG
        final selectedExtension = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _buildExtensionSelectorDialog(ctx, defaultFileExtension, result.files),
        );

        if (selectedExtension == null) {
          print('❌ [_addFile] Extension selection cancelled');
          return;
        }

        print('📎 [_addFile] Selected extension: $selectedExtension');

        // ✅ STEP 3: UPLOAD FILES WITH CUSTOM NAMES
        for (var file in result.files) {
          if (file.path != null || file.bytes != null) {
            // ✅ GET FILE DETAILS
            String originalFileName = file.name;
            String originalExtension = originalFileName.split('.').last.toLowerCase();
            String baseFileName = originalFileName.contains('.')
                ? originalFileName.substring(0, originalFileName.lastIndexOf('.'))
                : originalFileName;

            print('📄 [_addFile] Original file: $originalFileName');
            print('📄 [_addFile] Original extension: $originalExtension');
            print('📄 [_addFile] Target extension: $selectedExtension');

            // ✅ ASK FOR CUSTOM FILE NAME
            final customName = await _showCustomNameDialog(
              context,
              originalFileName,
              'Enter a display name for this file',
              defaultValue: baseFileName, // Pre-fill with original name
            );

            if (customName == null) {
              print('❌ [_addFile] Custom name cancelled for: $originalFileName');
              continue; // Skip this file
            }

            // ✅ CREATE PROPER FILENAME WITH SELECTED EXTENSION
            String newFileName = '$baseFileName.$selectedExtension';
            print('🔄 [_addFile] New filename: $newFileName');
            print('📝 [_addFile] Custom display name: $customName');

            // ✅ CREATE XFILE WITH CORRECT NAME AND MIME TYPE
            XFile xFile;

            if (file.bytes != null) {
              print('🌐 [_addFile] Using bytes for web platform');
              xFile = XFile.fromData(
                file.bytes!,
                name: newFileName,
                mimeType: _getMimeTypeFromExtension(selectedExtension),
              );
            } else if (file.path != null) {
              print('📱 [_addFile] Using file path for mobile platform');
              final tempFile = File(file.path!);
              final bytes = await tempFile.readAsBytes();

              xFile = XFile.fromData(
                bytes,
                name: newFileName,
                mimeType: _getMimeTypeFromExtension(selectedExtension),
              );
            } else {
              print('❌ [_addFile] No file data available');
              continue;
            }

            print('📤 [_addFile] Uploading file: ${xFile.name}');
            print('📤 [_addFile] Expected MIME: ${_getMimeTypeFromExtension(selectedExtension)}');

            // Upload with ApiService
            final filename = await ApiService.uploadDocument(xFile, context: context);

            print('✅ [_addFile] Upload successful! Server filename: $filename');

            setState(() {
              editedFiles[fileType]!.add({
                'path': filename,
                'type': selectedExtension,
                'name': customName, // ✅ CUSTOM NAME
              });
            });
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.files.length} file(s) uploaded as $selectedExtension!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('❌ [_addFile] Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading files: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ✅ DIALOG TO ASK FOR CUSTOM FILE NAME
  Future<String?> _showCustomNameDialog(
      BuildContext context,
      String fileName,
      String message, {
        String? defaultValue,
      }) async {
    final controller = TextEditingController(text: defaultValue ?? '');

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.edit_2, color: AppTheme.primaryGreen, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Name This File',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.document, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      fileName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.bodyText,
              ),
            ),
            const SizedBox(height: 16),

            // Text field
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Display Name',
                hintText: 'e.g., Chapter 1 Worksheet',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
                ),
                prefixIcon: const Icon(Iconsax.text, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.pop(ctx, value.trim());
                }
              },
            ),
            const SizedBox(height: 12),

            // Info message
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.info_circle, size: 16, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This name will be shown to students',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppTheme.bodyText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx, name);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a name'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Iconsax.tick_circle, size: 18),
            label: Text(
              'Confirm',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }




// ✅ IMPROVED EXTENSION SELECTOR DIALOG - NOW SHOWS SELECTED FILES
  Widget _buildExtensionSelectorDialog(
      BuildContext ctx,
      String initialExtension,
      List<PlatformFile> selectedFiles,
      ) {
    String tempExtension = initialExtension;

    return StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.document_upload, color: AppTheme.primaryGreen, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Select File Type',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ SHOW SELECTED FILES
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.document_text, size: 18, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Selected Files (${selectedFiles.length})',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...selectedFiles.take(3).map((file) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              file.name,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.blue.shade900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (selectedFiles.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+ ${selectedFiles.length - 3} more file(s)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ✅ WARNING BANNER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Iconsax.warning_2, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Important Notice',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Please select the SAME file type as your actual file. Selecting the wrong type may cause upload failures.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.orange.shade900,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ✅ INSTRUCTION TEXT
              Text(
                'Choose file type for correct MIME type upload',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.bodyText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // ✅ IMPROVED DROPDOWN
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: DropdownButtonFormField<String>(
                  value: tempExtension,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Iconsax.document, color: AppTheme.primaryGreen, size: 20),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'pdf',
                      child: Row(
                        children: [
                          Icon(Iconsax.document, size: 18, color: Colors.red),
                          SizedBox(width: 10),
                          Text('PDF Document (.pdf)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'doc',
                      child: Row(
                        children: [
                          Icon(Iconsax.document_text, size: 18, color: Colors.blue),
                          SizedBox(width: 10),
                          Text('Word Document (.doc)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'docx',
                      child: Row(
                        children: [
                          Icon(Iconsax.document_text_1, size: 18, color: Colors.blue),
                          SizedBox(width: 10),
                          Text('Word Document (.docx)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'ppt',
                      child: Row(
                        children: [
                          Icon(Iconsax.document_forward, size: 18, color: Colors.orange),
                          SizedBox(width: 10),
                          Text('PowerPoint (.ppt)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'pptx',
                      child: Row(
                        children: [
                          Icon(Iconsax.document_forward, size: 18, color: Colors.deepOrange),
                          SizedBox(width: 10),
                          Text('PowerPoint (.pptx)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'xls',
                      child: Row(
                        children: [
                          Icon(Iconsax.document_text, size: 18, color: Colors.green),
                          SizedBox(width: 10),
                          Text('Excel (.xls)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'xlsx',
                      child: Row(
                        children: [
                          Icon(Iconsax.document_text, size: 18, color: Colors.green),
                          SizedBox(width: 10),
                          Text('Excel (.xlsx)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'jpg',
                      child: Row(
                        children: [
                          Icon(Iconsax.gallery, size: 18, color: Colors.purple),
                          SizedBox(width: 10),
                          Text('JPEG Image (.jpg)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'png',
                      child: Row(
                        children: [
                          Icon(Iconsax.image, size: 18, color: Colors.pink),
                          SizedBox(width: 10),
                          Text('PNG Image (.png)'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        tempExtension = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // ✅ EXAMPLE TEXT
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.info_circle, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Example: If uploading a PDF file, select "PDF Document"',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppTheme.bodyText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, tempExtension),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Iconsax.tick_circle, size: 18),
            label: Text(
              'Continue',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }


  // ✅ HELPER METHOD TO GET MIME TYPE FROM EXTENSION
  String _getMimeTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      default:
        print('⚠️ [_getMimeTypeFromExtension] Unknown extension: $extension');
        return 'application/octet-stream';
    }
  }



  void _saveChanges() async {
    if (widget.isAddMode && (selectedClassId == null || selectedSubjectId == null || selectedChapterId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Class, Subject, and Chapter'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Convert all editedFiles lists to XML format
      final videoXml = generateXmlFromFiles(editedFiles['video'] ?? []);
      final worksheetXml = generateXmlFromFiles(editedFiles['worksheet'] ?? []);
      final extraQuestionsXml = generateXmlFromFiles(editedFiles['extraQuestions'] ?? []);
      final solvedQuestionsXml = generateXmlFromFiles(editedFiles['solvedQuestions'] ?? []);
      final revisionNotesXml = generateXmlFromFiles(editedFiles['revisionNotes'] ?? []);
      final lessonPlansXml = generateXmlFromFiles(editedFiles['lessonPlans'] ?? []);
      final teachingAidsXml = generateXmlFromFiles(editedFiles['teachingAids'] ?? []);
      final assessmentToolsXml = generateXmlFromFiles(editedFiles['assessmentTools'] ?? []);
      final homeworkToolsXml = generateXmlFromFiles(editedFiles['homeworkTools'] ?? []);
      final practiceZoneXml = generateXmlFromFiles(editedFiles['practiceZone'] ?? []);
      final learningPathXml = generateXmlFromFiles(editedFiles['learningPath'] ?? []);

      if (widget.isAddMode) {
        // Add new material
        await ApiService.addMaterial(
          pubCode: userProvider.userCode ?? '0',
          chapterId: selectedChapterId!,
          videoLink: videoXml.isNotEmpty ? videoXml : null,
          worksheetPath: worksheetXml.isNotEmpty ? worksheetXml : null,
          extraQuestionsPath: extraQuestionsXml.isNotEmpty ? extraQuestionsXml : null,
          solvedQuestionsPath: solvedQuestionsXml.isNotEmpty ? solvedQuestionsXml : null,
          revisionNotesPath: revisionNotesXml.isNotEmpty ? revisionNotesXml : null,
          lessonPlansPath: lessonPlansXml.isNotEmpty ? lessonPlansXml : null,
          teachingAidsPath: teachingAidsXml.isNotEmpty ? teachingAidsXml : null,
          assessmentToolsPath: assessmentToolsXml.isNotEmpty ? assessmentToolsXml : null,
          homeworkToolsPath: homeworkToolsXml.isNotEmpty ? homeworkToolsXml : null,
          practiceZonePath: practiceZoneXml.isNotEmpty ? practiceZoneXml : null,
          learningPathPath: learningPathXml.isNotEmpty ? learningPathXml : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Material added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Update existing material
        await ApiService.updateMaterial(
          recNo: widget.material!.recNo,
          videoLink: videoXml.isNotEmpty ? videoXml : null,
          worksheetPath: worksheetXml.isNotEmpty ? worksheetXml : null,
          extraQuestionsPath: extraQuestionsXml.isNotEmpty ? extraQuestionsXml : null,
          solvedQuestionsPath: solvedQuestionsXml.isNotEmpty ? solvedQuestionsXml : null,
          revisionNotesPath: revisionNotesXml.isNotEmpty ? revisionNotesXml : null,
          lessonPlansPath: lessonPlansXml.isNotEmpty ? lessonPlansXml : null,
          teachingAidsPath: teachingAidsXml.isNotEmpty ? teachingAidsXml : null,
          assessmentToolsPath: assessmentToolsXml.isNotEmpty ? assessmentToolsXml : null,
          homeworkToolsPath: homeworkToolsXml.isNotEmpty ? homeworkToolsXml : null,
          practiceZonePath: practiceZoneXml.isNotEmpty ? practiceZoneXml : null,
          learningPathPath: learningPathXml.isNotEmpty ? learningPathXml : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Material updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          setState(() {
            isEditMode = false;
            isUploading = false;
          });

          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
