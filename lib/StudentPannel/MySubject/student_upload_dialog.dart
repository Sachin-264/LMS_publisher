import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Service/academics_service.dart'; // For ApiService.uploadDocument
import 'package:lms_publisher/StudentPannel/Service/StudentAssignmentService.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';
import 'package:image_picker/image_picker.dart'; // For XFile

class StudentUploadDialog extends StatefulWidget {
  final int materialRecNo;
  final String studentCode;
  final Color subjectColor;
  final String assignmentTitle;

  const StudentUploadDialog({
    super.key,
    required this.materialRecNo,
    required this.studentCode,
    required this.subjectColor,
    required this.assignmentTitle,
  });

  @override
  State<StudentUploadDialog> createState() => _StudentUploadDialogState();
}

class _StudentUploadDialogState extends State<StudentUploadDialog> {
  final _commentsController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
      );

      if (result != null && result.files.first.path != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
      } else {
        // User canceled the picker
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Error picking file: $e');
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedFile == null) {
      CustomSnackbar.showError(context, 'Please select a file to upload');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Step 1: Upload the file using ApiService.uploadDocument
      CustomSnackbar.showInfo(context, 'Uploading file...');

      // Convert PlatformFile to XFile for ApiService
      final xFile = XFile(_selectedFile!.path!, name: _selectedFile!.name);

      final uploadedPath = await ApiService.uploadDocument(xFile, context: context);

      // Step 2: Submit the assignment details
      CustomSnackbar.showInfo(context, 'Submitting assignment...');
      await StudentAssignmentService.submitAssignment(
        studentCode: widget.studentCode,
        materialRecNo: widget.materialRecNo,
        submissionType: 'File', // As per your API
        submissionFilePath: uploadedPath,
        studentComments: _commentsController.text.isEmpty ? null : _commentsController.text,
      );

      if (mounted) {
        CustomSnackbar.showSuccess(
          context,
          'Assignment submitted successfully!',
          title: 'Success',
        );
        Navigator.pop(context, true); // Return true to signal success
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context,
          'Failed to submit: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the primaryGreen from AppTheme if subjectColor is too light
    final Color themeColor = widget.subjectColor.computeLuminance() > 0.5
        ? AppTheme.primaryGreen
        : widget.subjectColor;

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeColor,
                      themeColor.withOpacity(0.75),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(Iconsax.document_upload, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Submit Assignment',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.assignmentTitle,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                        onPressed: _isUploading ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white, size: 22),
                        splashRadius: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File Picker
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
                          onTap: _isUploading ? null : _pickFile,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            child: Column(
                              children: [
                                Icon(
                                  _selectedFile != null ? Iconsax.verify : Iconsax.document_upload,
                                  size: 32,
                                  color: _selectedFile != null ? Colors.green.shade700 : themeColor,
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
                    const SizedBox(height: 20),
                    // Comments
                    Text(
                      'Comments (Optional)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _commentsController,
                      maxLines: 3,
                      readOnly: _isUploading,
                      decoration: InputDecoration(
                        hintText: 'Add any notes for your teacher...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: Icon(Iconsax.note_text, size: 20, color: themeColor),
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
                          borderSide: BorderSide(
                            color: themeColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.darkText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Footer Button
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        themeColor,
                        themeColor.withOpacity(0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _isUploading ? Colors.transparent : themeColor.withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isUploading ? null : _submit,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: _isUploading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.document_upload, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Submit Assignment',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
