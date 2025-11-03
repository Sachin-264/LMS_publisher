import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Teacher_Panel/MyClass/assignment_submission_screen.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Teacher_Panel/teacher_material_service.dart';
import 'package:lms_publisher/Service/academics_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

const String _documentBaseUrl = "https://storage.googleapis.com/upload-images-34/documents/LMS/";

String getFullDocumentUrl(String filename) {
  if (filename.isEmpty) return '';
  return '$_documentBaseUrl$filename';
}

// Helper to get YouTube thumbnail
String getYoutubeThumbnail(String url) {
  final videoId = extractYoutubeVideoId(url);
  if (videoId != null && videoId.isNotEmpty) {
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }
  return '';
}

String? extractYoutubeVideoId(String url) {
  final decodedUrl = url
      .replaceAll('&', '&')
      .replaceAll('<', '<')
      .replaceAll('>', '>')
      .replaceAll('"', '"');
  final patterns = [
    RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtube\.com\/watch\?.*[?&]v=([a-zA-Z0-9_-]{11})'),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(decodedUrl);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
  }
  return null;
}

// Helper to parse XML files
// Helper to parse XML files - FIXED VERSION
List<Map<String, String>> parseXmlFiles(String? xmlString) {
  if (xmlString == null || xmlString.isEmpty) return [];

  final files = <Map<String, String>>[];

  // Decode HTML entities first
  String decoded = xmlString
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"');

  print('📄 [PARSE_XML] Input XML: $decoded');

  // Correct regex pattern for XML File tags
  final fileRegex = RegExp(
      r'<File\s+Sno="([^"]*)"\s+Path="([^"]*)"\s+Type="([^"]*)"\s+Name="([^"]*)"\s*/?>'
  );

  for (final match in fileRegex.allMatches(decoded)) {
    final file = {
      'sno': match.group(1) ?? '',
      'path': match.group(2) ?? '',
      'type': match.group(3) ?? 'pdf',
      'name': match.group(4) ?? 'Unnamed File',
    };
    print('📄 [PARSE_XML] Parsed file: ${file['name']}');
    files.add(file);
  }

  print('📄 [PARSE_XML] Total files parsed: ${files.length}');
  return files;
}


class TeacherMaterialScreen extends StatefulWidget {
  final String teacherCode;
  final int chapterId;
  final String chapterName;
  final String subjectName;

  const TeacherMaterialScreen({
    super.key,
    required this.teacherCode,
    required this.chapterId,
    required this.chapterName,
    required this.subjectName,
  });

  @override
  State<TeacherMaterialScreen> createState() => _TeacherMaterialScreenState();
}

class _TeacherMaterialScreenState extends State<TeacherMaterialScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _publisherMaterials = [];
  List<Map<String, dynamic>> _teacherMaterials = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() => _isLoading = true);
    try {
      final response = await TeacherMaterialService.getChapterMaterials(
        teacherCode: widget.teacherCode,
        chapterId: widget.chapterId,
      );
      setState(() {
        _publisherMaterials = List<Map<String, dynamic>>.from(response['publisher_materials'] ?? []);
        _teacherMaterials = List<Map<String, dynamic>>.from(response['teacher_materials'] ?? []);
        _isLoading = false;
      });
      print('✅ [SCREEN] Materials loaded successfully');
    } catch (e) {
      print('❌ [SCREEN] Error loading materials: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading materials: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadMaterial(String materialType) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UploadMaterialDialog(materialType: materialType),
    );

    if (result == null) return;

    setState(() => _isUploading = true);
    try {
      String? uploadedPath;
      String? uploadedLink;

      if (result['isFile'] == true && result['file'] != null) {
        XFile file = result['file'];
        uploadedPath = await ApiService.uploadDocument(file, context: context);
        print('📤 Uploaded file: $uploadedPath');
      } else if (result['link'] != null) {
        uploadedLink = result['link'];
      }

      final response = await TeacherMaterialService.uploadMaterial(
        teacherCode: widget.teacherCode,
        chapterId: widget.chapterId,
        materialType: materialType,
        title: result['title'] ?? 'Untitled',
        description: result['description'],
        materialPath: uploadedPath,
        materialLink: uploadedLink,
        // Assignment fields
        dueDate: result['dueDate'],
        totalMarks: result['totalMarks'],
        passingMarks: result['passingMarks'],
        maxAttempts: result['maxAttempts'],
        allowLateSubmission: result['allowLateSubmission'],
      );

      if (response['status'] == 'success') {
        await _loadMaterials();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Material uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteMaterial(int materialRecNo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.warning_2, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Delete Material?',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
          ],
        ),
        content: Text(
          'This action cannot be undone. Are you sure you want to delete this material?',
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.bodyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await TeacherMaterialService.deleteMaterial(
        teacherCode: widget.teacherCode,
        materialRecNo: materialRecNo,
      );

      if (response['status'] == 'success') {
        await _loadMaterials();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Material deleted successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Delete error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppTheme.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chapterName,
              style: GoogleFonts.poppins(
                color: AppTheme.darkText,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              widget.subjectName,
              style: GoogleFonts.inter(
                color: AppTheme.bodyText,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Iconsax.refresh, color: AppTheme.primaryGreen),
            onPressed: _isLoading ? null : _loadMaterials,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    if (isMobile) {
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildPublisherSection(),
            const SizedBox(height: 16),
            _buildTeacherSection(),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade200, width: 1)),
            ),
            child: _buildPublisherSection(),
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: _buildTeacherSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildPublisherSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.book, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Publisher Materials',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                    Text(
                      'Official curriculum resources',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_publisherMaterials.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Iconsax.document, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No publisher materials available',
                      style: GoogleFonts.inter(
                        color: AppTheme.bodyText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._publisherMaterials.map((material) {
              return Column(
                children: [
                  _buildMaterialCategory('Video Links', Iconsax.video, Colors.red,
                      parseXmlFiles(material['Video_Link']),
                      isVideo: true),
                  _buildMaterialCategory('Worksheets', Iconsax.document, Colors.blue,
                      parseXmlFiles(material['Worksheet_Path'])),
                  _buildMaterialCategory('Extra Questions', Iconsax.document_text, Colors.orange,
                      parseXmlFiles(material['Extra_Questions_Path'])),
                  _buildMaterialCategory('Solved Questions', Iconsax.tick_circle, Colors.green,
                      parseXmlFiles(material['Solved_Questions_Path'])),
                  _buildMaterialCategory('Revision Notes', Iconsax.note, Colors.purple,
                      parseXmlFiles(material['Revision_Notes_Path'])),
                  _buildMaterialCategory('Lesson Plans', Iconsax.note_1, Colors.teal,
                      parseXmlFiles(material['Lesson_Plans_Path'])),
                  _buildMaterialCategory('Teaching Aids', Iconsax.teacher, Colors.indigo,
                      parseXmlFiles(material['Teaching_Aids_Path'])),
                  _buildMaterialCategory('Assessment Tools', Iconsax.task_square, Colors.pink,
                      parseXmlFiles(material['Assessment_Tools_Path'])),
                  _buildMaterialCategory('Homework Tools', Iconsax.clipboard_text, Colors.amber,
                      parseXmlFiles(material['Homework_Tools_Path'])),
                  _buildMaterialCategory('Practice Zone', Iconsax.activity, Colors.cyan,
                      parseXmlFiles(material['Practice_Zone_Path'])),
                  _buildMaterialCategory('Learning Path', Iconsax.map, Colors.deepOrange,
                      parseXmlFiles(material['Learning_Path_Path'])),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildTeacherSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.teacher, color: AppTheme.primaryGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Materials',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                    Text(
                      'Your uploaded resources',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildUploadButton('Assignment', Iconsax.task_square, Colors.orange),
              _buildUploadButton('Worksheet', Iconsax.document, Colors.blue),
              _buildUploadButton('Video', Iconsax.video, Colors.red),
              _buildUploadButton('Document', Iconsax.document_download, Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          if (_teacherMaterials.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Iconsax.document_upload, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No materials uploaded yet',
                      style: GoogleFonts.inter(
                        color: AppTheme.bodyText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click the buttons above to add materials',
                      style: GoogleFonts.inter(
                        color: AppTheme.bodyText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._teacherMaterials.map((material) {
              return _buildTeacherMaterialCard(material);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildUploadButton(String label, IconData icon, Color color) {
    return ElevatedButton.icon(
      onPressed: _isUploading ? null : () => _uploadMaterial(label),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildMaterialCategory(
      String title,
      IconData icon,
      Color color,
      List<Map<String, String>> files, {
        bool isVideo = false,
      }) {
    if (files.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${files.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...files.map((file) => _buildFileItem(file, color, isVideo)).toList(),
        ],
      ),
    );
  }

  Widget _buildFileItem(Map<String, String> file, Color color, bool isVideo) {
    final path = file['path'] ?? '';
    final name = file['name'] ?? 'Unnamed File';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          if (isVideo)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: getYoutubeThumbnail(path),
                width: 60,
                height: 45,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 60,
                  height: 45,
                  color: Colors.grey[300],
                ),
                errorWidget: (context, url, error) => Container(
                  width: 60,
                  height: 45,
                  color: color.withOpacity(0.1),
                  child: Icon(Iconsax.video, color: color, size: 20),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Iconsax.document, color: color, size: 20),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(isVideo ? Iconsax.play : Iconsax.document_download, color: color),
            onPressed: () => _openFile(path, isVideo),
            tooltip: isVideo ? 'Play' : 'Open',
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherMaterialCard(Map<String, dynamic> material) {
    final materialType = material['MaterialType'] ?? 'Document';
    final title = material['MaterialTitle'] ?? 'Untitled';
    final description = material['Description'];
    final materialRecNo = material['RecNo'];
    final uploadedOn = material['Created_Date'] ?? '';
    final materialPath = material['MaterialPath'];
    final materialLink = material['MaterialLink'];

    Color color;
    IconData icon;

    switch (materialType.toLowerCase()) {
      case 'video':
        color = Colors.red;
        icon = Iconsax.video;
        break;
      case 'worksheet':
        color = Colors.blue;
        icon = Iconsax.document;
        break;
      case 'assignment':
        color = Colors.orange;
        icon = Iconsax.task_square;
        break;
      case 'document':
        color = Colors.green;
        icon = Iconsax.document_download;
        break;
      default:
        color = Colors.grey;
        icon = Iconsax.document_text;
    }

    final isVideo = materialLink != null && materialLink.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.darkText,
                      ),
                    ),
                    if (description != null && description.isNotEmpty)
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.bodyText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (materialType.toLowerCase() == 'assignment')
                Tooltip(
                  message: 'View Submissions',
                  child: IconButton(
                    icon: Icon(Iconsax.eye, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignmentSubmissionsScreen(
                            teacherCode: widget.teacherCode,
                            materialRecNo: materialRecNo ?? 0,
                            materialTitle: title,
                            totalMarks: material['TotalMarks'] ?? 0,
                            color: color,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              IconButton(
                icon: Icon(isVideo ? Iconsax.play : Iconsax.document_download, color: color),
                onPressed: () => _openFile(isVideo ? materialLink : materialPath, isVideo),
                tooltip: isVideo ? 'Play' : 'Open',
              ),
              IconButton(
                icon: const Icon(Iconsax.trash, color: Colors.red),
                onPressed: () => _deleteMaterial(materialRecNo),
                tooltip: 'Delete',
              ),
            ],
          ),
          if (uploadedOn.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Iconsax.clock, size: 14, color: AppTheme.bodyText),
                const SizedBox(width: 6),
                Text(
                  'Uploaded: $uploadedOn',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.bodyText,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _openFile(String? path, bool isVideo) async {
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File path not available')),
      );
      return;
    }

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
}

// ======================== UPLOAD DIALOG WIDGET ========================

class _UploadMaterialDialog extends StatefulWidget {
  final String materialType;
  const _UploadMaterialDialog({required this.materialType});

  @override
  State<_UploadMaterialDialog> createState() => _UploadMaterialDialogState();
}

class _UploadMaterialDialogState extends State<_UploadMaterialDialog>
    with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _totalMarksController = TextEditingController();
  final _passingMarksController = TextEditingController();
  final _maxAttemptsController = TextEditingController(text: '1');

  int _currentStep = 0;
  bool _isFile = true;
  XFile? _selectedFile;
  String _selectedExtension = 'pdf';
  DateTime? _selectedDueDate;
  bool _allowLateSubmission = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool get _isAssignment => widget.materialType.toLowerCase() == 'assignment';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  Future<void> _pickFile() async {
    try {
      print('📂 Opening file picker...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final selectedExtension = await _showExtensionDialog(file.name);
      if (selectedExtension == null) return;

      _selectedExtension = selectedExtension;
      String baseFileName = file.name.contains('.')
          ? file.name.substring(0, file.name.lastIndexOf('.'))
          : file.name;
      String newFileName = '$baseFileName.$selectedExtension';

      if (file.bytes != null) {
        setState(() {
          _selectedFile = XFile.fromData(
            file.bytes!,
            name: newFileName,
            mimeType: _getMimeTypeFromExtension(selectedExtension),
          );
          _titleController.text = baseFileName;
        });
      } else if (file.path != null) {
        final tempFile = File(file.path!);
        final bytes = await tempFile.readAsBytes();
        setState(() {
          _selectedFile = XFile.fromData(
            bytes,
            name: newFileName,
            mimeType: _getMimeTypeFromExtension(selectedExtension),
          );
          _titleController.text = baseFileName;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String?> _showExtensionDialog(String fileName) async {
    String tempExtension = 'pdf';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Premium Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.primaryGreen.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Iconsax.document,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'File Format',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Select the correct file type',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // File Info Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Iconsax.document_text,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current File',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.blue.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      fileName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.blue.shade900,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Format Selection
                        Text(
                          'Choose Format',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: tempExtension,
                          isExpanded: true,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.file_present,
                              color: AppTheme.primaryGreen,
                              size: 22,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryGreen,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: [
                            _buildDropdownItem('pdf', '📄 PDF Document', Icons.picture_as_pdf),
                            _buildDropdownItem('docx', '📝 Word Document', Icons.description),
                            _buildDropdownItem('pptx', '🎯 PowerPoint', Icons.slideshow),
                            _buildDropdownItem('xlsx', '📊 Excel Sheet', Icons.table_chart),
                            _buildDropdownItem('jpg', '🖼️ JPEG Image', Icons.image),
                            _buildDropdownItem('png', '🖼️ PNG Image', Icons.image),
                            _buildDropdownItem('txt', '📋 Text File', Icons.text_fields),
                          ],
                          onChanged: (value) {
                            if (value != null) setDialogState(() => tempExtension = value);
                          },
                        ),
                        const SizedBox(height: 20),

                        // Info Box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.amber.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Iconsax.info_circle,
                                  color: Colors.amber.shade700,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Ensure file format matches your actual file',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppTheme.bodyText,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryGreen,
                                      AppTheme.primaryGreen.withOpacity(0.85),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryGreen.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Navigator.pop(ctx, tempExtension),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Iconsax.arrow_right_3,
                                              color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Continue',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(String value, String label, IconData icon) {
    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
        ],
      ),
    );
  }

  String _getMimeTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
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
        return 'application/pdf';
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.darkText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
        _deadlineController.text = DateFormat('MMM dd, yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 650),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                // Premium Header with Gradient
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryGreen,
                        AppTheme.primaryGreen.withOpacity(0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Iconsax.document_upload,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload ${widget.materialType}',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Step ${_currentStep + 1} of ${_isAssignment ? 3 : 2}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white, size: 24),
                          splashRadius: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // Enhanced Progress Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: (_currentStep + 1) / (_isAssignment ? 3 : 2),
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${((_currentStep + 1) / (_isAssignment ? 3 : 2) * 100).toStringAsFixed(0)}% Complete',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.bodyText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildStepContent(),
                    ),
                  ),
                ),

                // Footer Buttons
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
                  ),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => setState(() => _currentStep--),
                            icon: const Icon(Iconsax.arrow_left, size: 18),
                            label: Text(
                              'Back',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: AppTheme.bodyText,
                            ),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: _currentStep > 0 ? 2 : 1,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryGreen,
                                AppTheme.primaryGreen.withOpacity(0.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _canProceedToNext()
                                  ? () {
                                if (_currentStep == (_isAssignment ? 2 : 1)) {
                                  _submitUpload();
                                } else {
                                  setState(() => _currentStep++);
                                }
                              }
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _currentStep == (_isAssignment ? 2 : 1)
                                          ? Iconsax.document_upload
                                          : Iconsax.arrow_right_3,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _currentStep == (_isAssignment ? 2 : 1)
                                          ? 'Upload'
                                          : 'Next Step',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ... [Rest of the methods remain the same - _buildStepContent, _buildStep1Material, etc.]

  Widget _buildStepContent() {
    if (_isAssignment) {
      return _buildAssignmentSteps();
    } else {
      return _buildMaterialSteps();
    }
  }

  Widget _buildMaterialSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_currentStep == 0) ..._buildStep1Material(),
        if (_currentStep == 1) ..._buildStep2Common(),
      ],
    );
  }

  Widget _buildAssignmentSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_currentStep == 0) ..._buildStep1Material(),
        if (_currentStep == 1) ..._buildStep2Assignment(),
        if (_currentStep == 2) ..._buildStep3Review(),
      ],
    );
  }

  List<Widget> _buildStep1Material() {
    return [
      _buildStepHeader('Upload Content', 'Select your ${widget.materialType.toLowerCase()} file or link'),
      const SizedBox(height: 28),
      if (widget.materialType.toLowerCase() == 'video')
        Row(
          children: [
            Expanded(child: _buildChoiceChip('🔗 Video Link', !_isFile)),
            const SizedBox(width: 12),
            Expanded(child: _buildChoiceChip('📤 Upload File', _isFile)),
          ],
        ),
      const SizedBox(height: 16),
      if (!_isFile)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Video URL',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _linkController,
              decoration: InputDecoration(
                hintText: 'https://youtube.com/watch?v=...',
                prefixIcon: const Icon(Iconsax.link, size: 20),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                ),
              ),
            ),
          ],
        ),
      if (_isFile || widget.materialType.toLowerCase() == 'video')
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _selectedFile != null ? Colors.green.shade50 : Colors.grey.shade50,
                    _selectedFile != null ? Colors.green.shade100 : Colors.grey.shade100,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedFile != null ? Colors.green.shade300 : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickFile,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Column(
                      children: [
                        Icon(
                          _selectedFile != null ? Iconsax.verify : Iconsax.document_upload,
                          size: 32,
                          color: _selectedFile != null ? Colors.green.shade700 : AppTheme.primaryGreen,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFile == null ? 'Select File' : '✓ File Selected',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: _selectedFile != null ? Colors.green.shade700 : AppTheme.darkText,
                          ),
                        ),
                        if (_selectedFile != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _selectedFile!.name,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.green.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
    ];
  }

  List<Widget> _buildStep2Common() {
    final isWorksheet = widget.materialType.toLowerCase() == 'worksheet';

    return [
      _buildStepHeader(
        'Material Details',
        isWorksheet
            ? 'Add title, description, and grading info'
            : 'Add title and description',
      ),
      const SizedBox(height: 28),
      _buildFormField('Title', _titleController, 'Enter title', Iconsax.text),
      const SizedBox(height: 18),
      _buildFormField(
        'Description',
        _descriptionController,
        isWorksheet ? 'Worksheet instructions...' : 'Add optional description...',
        Iconsax.note_text,
        maxLines: isWorksheet ? 3 : 4,
      ),
      if (isWorksheet) ...[
        const SizedBox(height: 18),
        // Deadline Picker for Worksheet
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Due Date (Optional)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedDueDate != null ? AppTheme.primaryGreen : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  color: _selectedDueDate != null ? AppTheme.primaryGreen.withOpacity(0.05) : Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.calendar_1,
                      size: 22,
                      color: _selectedDueDate != null ? AppTheme.primaryGreen : AppTheme.bodyText,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _deadlineController.text.isEmpty ? 'Select deadline (optional)' : _deadlineController.text,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: _deadlineController.text.isEmpty ? AppTheme.bodyText : AppTheme.darkText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_selectedDueDate != null)
                      Icon(Iconsax.verify, color: Colors.green.shade600, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Marks for Worksheet
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                'Total Marks',
                _totalMarksController,
                '50',
                Iconsax.chart,
                isNumeric: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormField(
                'Pass Marks',
                _passingMarksController,
                '20',
                Iconsax.chart,
                isNumeric: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Max Attempts for Worksheet
        _buildFormField(
          'Max Attempts',
          _maxAttemptsController,
          '1',
          Iconsax.repeat,
          isNumeric: true,
        ),
      ],
    ];
  }


  List<Widget> _buildStep2Assignment() {
    return [
      _buildStepHeader('Assignment Details', 'Configure deadline and marking'),
      const SizedBox(height: 28),
      _buildFormField('Title', _titleController, 'Enter title', Iconsax.text),
      const SizedBox(height: 18),
      _buildFormField(
        'Description',
        _descriptionController,
        'Assignment instructions...',
        Iconsax.note_text,
        maxLines: 3,
      ),
      const SizedBox(height: 18),
      // Date Picker
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Due Date',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedDueDate != null ? AppTheme.primaryGreen : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(14),
                color: _selectedDueDate != null ? AppTheme.primaryGreen.withOpacity(0.05) : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.calendar_1,
                    size: 22,
                    color: _selectedDueDate != null ? AppTheme.primaryGreen : AppTheme.bodyText,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _deadlineController.text.isEmpty ? 'Select deadline' : _deadlineController.text,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: _deadlineController.text.isEmpty ? AppTheme.bodyText : AppTheme.darkText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_selectedDueDate != null)
                    Icon(Iconsax.verify, color: Colors.green.shade600, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      // Marks Row
      Row(
        children: [
          Expanded(
            child: _buildFormField(
              'Total Marks',
              _totalMarksController,
              '50',
              Iconsax.chart,
              isNumeric: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFormField(
              'Pass Marks',
              _passingMarksController,
              '20',
              Iconsax.chart,
              isNumeric: true,
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      _buildFormField(
        'Max Attempts',
        _maxAttemptsController,
        '1',
        Iconsax.repeat,
        isNumeric: true,
      ),
      const SizedBox(height: 18),
      // Late Submission Toggle
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _allowLateSubmission
              ? AppTheme.primaryGreen.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _allowLateSubmission
                ? AppTheme.primaryGreen.withOpacity(0.4)
                : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _allowLateSubmission
                    ? AppTheme.primaryGreen.withOpacity(0.15)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Iconsax.clock,
                size: 22,
                color: _allowLateSubmission ? AppTheme.primaryGreen : AppTheme.bodyText,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Allow Late Submission',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Students can submit after deadline with penalty',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.bodyText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: _allowLateSubmission,
              onChanged: (value) => setState(() => _allowLateSubmission = value),
              activeColor: AppTheme.primaryGreen,
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildStep3Review() {
    return [
      _buildStepHeader('Review & Confirm', 'Check all details before uploading'),
      const SizedBox(height: 24),
      ...[
        ('Title', _titleController.text, AppTheme.primaryGreen),
        ('Description', _descriptionController.text, Colors.blue),
        ('Due Date', _deadlineController.text, Colors.orange),
      ].map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildReviewCard(item.$1, item.$2, color: item.$3),
        );
      }).toList(),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildReviewCard('Total Marks', _totalMarksController.text, color: Colors.purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildReviewCard('Pass Marks', _passingMarksController.text, color: Colors.pink),
          ),
        ],
      ),
    ];
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.bodyText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  Widget _buildFormField(
      String label,
      TextEditingController controller,
      String hint,
      IconData icon, {
        int maxLines = 1,
        bool isNumeric = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade400, // Shaded hint text
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryGreen),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppTheme.primaryGreen,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            alignLabelWithHint: true,
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.darkText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }


  Widget _buildChoiceChip(String label, bool selected) {
    return Container(
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primaryGreen.withOpacity(0.15)
            : Colors.grey.shade100,
        border: Border.all(
          color: selected ? AppTheme.primaryGreen : Colors.grey.shade300,
          width: selected ? 2.5 : 1.5,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _isFile = label.contains('Upload'));
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? Iconsax.tick_circle : Iconsax.civic_cvc,
                  size: 20,
                  color: selected ? AppTheme.primaryGreen : Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppTheme.primaryGreen : AppTheme.bodyText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primaryGreen).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (color ?? AppTheme.primaryGreen).withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.bodyText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? '—' : value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color ?? AppTheme.primaryGreen,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  bool _canProceedToNext() {
    final isWorksheet = widget.materialType.toLowerCase() == 'worksheet';

    if (_currentStep == 0) {
      if (widget.materialType.toLowerCase() == 'video' && !_isFile) {
        return _linkController.text.isNotEmpty;
      }
      return _selectedFile != null;
    }
    else if (_currentStep == 1 && _isAssignment) {
      return _titleController.text.isNotEmpty &&
          _deadlineController.text.isNotEmpty &&
          _totalMarksController.text.isNotEmpty;
    }
    else if (_currentStep == 1 && isWorksheet) {
      // Worksheet: only title required, others optional
      return _titleController.text.isNotEmpty;
    }
    else if (_currentStep == 1) {
      // Other materials: only title required
      return _titleController.text.isNotEmpty;
    }
    return true;
  }


  void _submitUpload() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final isWorksheet = widget.materialType.toLowerCase() == 'worksheet';

    Navigator.pop(context, {
      'title': _titleController.text,
      'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
      'isFile': _isFile,
      'file': _selectedFile,
      'link': _isFile ? null : _linkController.text,
      if (_isAssignment) ...{
        'dueDate': _deadlineController.text,
        'totalMarks': int.tryParse(_totalMarksController.text) ?? 0,
        'passingMarks': int.tryParse(_passingMarksController.text) ?? 0,
        'maxAttempts': int.tryParse(_maxAttemptsController.text) ?? 1,
        'allowLateSubmission': _allowLateSubmission,
      },
      if (isWorksheet) ...{
        // Only send worksheet details if they're filled in
        if (_deadlineController.text.isNotEmpty)
          'dueDate': _deadlineController.text,
        if (_totalMarksController.text.isNotEmpty)
          'totalMarks': int.tryParse(_totalMarksController.text),
        if (_passingMarksController.text.isNotEmpty)
          'passingMarks': int.tryParse(_passingMarksController.text),
        if (_maxAttemptsController.text.isNotEmpty && _maxAttemptsController.text != '1')
          'maxAttempts': int.tryParse(_maxAttemptsController.text),
      },
    });
  }


  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _deadlineController.dispose();
    _totalMarksController.dispose();
    _passingMarksController.dispose();
    _maxAttemptsController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}

