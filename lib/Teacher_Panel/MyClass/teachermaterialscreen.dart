import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Teacher_Panel/teacher_material_service.dart';
import 'package:lms_publisher/Service/academics_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

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
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"');

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
List<Map<String, String>> parseXmlFiles(String? xmlString) {
  if (xmlString == null || xmlString.isEmpty) return [];

  final files = <Map<String, String>>[];
  final fileRegex = RegExp(r'<File\s+Sno="(\d+)"\s+Path="([^"]+)"\s+Type="([^"]+)"\s+Name="([^"]+)"\s*\/>');

  for (final match in fileRegex.allMatches(xmlString)) {
    files.add({
      'sno': match.group(1) ?? '',
      'path': match.group(2) ?? '',
      'type': match.group(3) ?? 'pdf',
      'name': match.group(4) ?? 'Unnamed File',
    });
  }

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
            Text('Delete Material?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
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
                      parseXmlFiles(material['Video_Link']), isVideo: true),
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
              _buildUploadButton('Video', Iconsax.video, Colors.red),
              _buildUploadButton('Worksheet', Iconsax.document, Colors.blue),
              _buildUploadButton('Notes', Iconsax.note, Colors.purple),
              _buildUploadButton('Assignment', Iconsax.task_square, Colors.orange),
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
      case 'notes':
        color = Colors.purple;
        icon = Iconsax.note;
        break;
      case 'assignment':
        color = Colors.orange;
        icon = Iconsax.task_square;
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
}

// Upload Material Dialog
class _UploadMaterialDialog extends StatefulWidget {
  final String materialType;

  const _UploadMaterialDialog({required this.materialType});

  @override
  State<_UploadMaterialDialog> createState() => _UploadMaterialDialogState();
}

class _UploadMaterialDialogState extends State<_UploadMaterialDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  bool _isFile = true;
  XFile? _selectedFile;
  String _selectedExtension = 'pdf';

  Future<void> _pickFile() async {
    try {
      print('📂 Opening file picker...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        print('❌ No file selected');
        return;
      }

      final file = result.files.first;
      print('📁 File selected: ${file.name}');

      // Ask for file type
      final selectedExtension = await _showExtensionDialog(file.name);
      if (selectedExtension == null) {
        print('❌ Extension selection cancelled');
        return;
      }

      _selectedExtension = selectedExtension;

      // Create XFile with proper extension
      String originalFileName = file.name;
      String baseFileName = originalFileName.contains('.')
          ? originalFileName.substring(0, originalFileName.lastIndexOf('.'))
          : originalFileName;
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

      print('✅ File prepared: $newFileName');
    } catch (e) {
      print('❌ Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<String?> _showExtensionDialog(String fileName) async {
    String tempExtension = 'pdf';

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Iconsax.document, color: AppTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Select File Type',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.document_text, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fileName,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.blue.shade900),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Iconsax.info_circle, color: Colors.orange, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Select the correct file type to ensure proper upload',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: tempExtension,
                decoration: InputDecoration(
                  labelText: 'File Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'pdf', child: Text('PDF (.pdf)')),
                  DropdownMenuItem(value: 'doc', child: Text('Word (.doc)')),
                  DropdownMenuItem(value: 'docx', child: Text('Word (.docx)')),
                  DropdownMenuItem(value: 'ppt', child: Text('PowerPoint (.ppt)')),
                  DropdownMenuItem(value: 'pptx', child: Text('PowerPoint (.pptx)')),
                  DropdownMenuItem(value: 'xls', child: Text('Excel (.xls)')),
                  DropdownMenuItem(value: 'xlsx', child: Text('Excel (.xlsx)')),
                  DropdownMenuItem(value: 'jpg', child: Text('JPEG (.jpg)')),
                  DropdownMenuItem(value: 'png', child: Text('PNG (.png)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => tempExtension = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, tempExtension),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
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
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Iconsax.document_upload, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Upload ${widget.materialType}',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.materialType.toLowerCase() == 'video')
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Video Link'),
                      selected: !_isFile,
                      onSelected: (selected) => setState(() => _isFile = !selected),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Upload File'),
                      selected: _isFile,
                      onSelected: (selected) => setState(() => _isFile = selected),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Iconsax.text),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Iconsax.note_text),
              ),
            ),
            const SizedBox(height: 12),

            if (_isFile)
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Iconsax.document_upload),
                label: Text(_selectedFile == null ? 'Select File' : 'File Selected'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            else
              TextField(
                controller: _linkController,
                decoration: InputDecoration(
                  labelText: 'Video Link',
                  hintText: 'https://youtube.com/watch?v=...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Iconsax.link),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a title')),
              );
              return;
            }

            Navigator.pop(context, {
              'title': _titleController.text,
              'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
              'isFile': _isFile,
              'file': _selectedFile,
              'link': _isFile ? null : _linkController.text,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('Upload', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
