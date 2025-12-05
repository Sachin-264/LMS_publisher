import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Teacher_Panel/MyClass/Model/QuestionModel.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Teacher_Panel/teacher_material_service.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';

// PDF Packages
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// --- HELPER CLASSES ---
class QuestionWrapper {
  QuestionModel model;
  double marks;
  QuestionWrapper(this.model, this.marks);
}

class PaperSection {
  String title;
  String description;
  List<QuestionWrapper> questions;

  PaperSection({
    required this.title,
    this.description = '',
    required this.questions
  });

  double get totalMarks => questions.where((q) => q.model.isSelected).fold(0, (sum, q) => sum + q.marks);
}

// --- MAIN DIALOG ---
class AiGeneratorDialog extends StatefulWidget {
  final String teacherCode;
  final int chapterId;

  const AiGeneratorDialog({
    super.key,
    required this.teacherCode,
    required this.chapterId,
  });

  @override
  State<AiGeneratorDialog> createState() => _AiGeneratorDialogState();
}

class _AiGeneratorDialogState extends State<AiGeneratorDialog> with TickerProviderStateMixin {
  int _currentStep = 0; // 0: Upload, 1: Config, 2: Loading, 3: Preview/Save

  // Data State
  PlatformFile? _selectedFile;

  // Paper Meta Data
  final TextEditingController _schoolNameController = TextEditingController(text: "YOUR SCHOOL NAME");
  final TextEditingController _examNameController = TextEditingController(text: "Half Yearly Examination 2024-25");
  final TextEditingController _timeController = TextEditingController(text: "3 Hours");
  final TextEditingController _instructionsController = TextEditingController(text: "1. All questions are compulsory.\n2. Read instructions carefully.");

  // Config State (For Current Batch)
  final TextEditingController _sectionTitleController = TextEditingController(text: "Section A");
  final TextEditingController _defaultMarksController = TextEditingController(text: "1");

  String _questionType = 'Multiple Choice Questions (MCQ)';
  int _questionCount = 5;
  String _difficulty = 'Medium';

  // State Management
  final List<PaperSection> _sections = [];
  bool _isSaving = false;
  bool _isGeneratingPdf = false;

  // UI State
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _questionTypes = [
    'Multiple Choice Questions (MCQ)',
    'True or False',
    'Fill in the Blanks',
    'Short Answer Questions',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack);
    _fadeController.forward();
  }

  double get _grandTotalMarks => _sections.fold(0, (sum, sec) => sum + sec.totalMarks);

  // --- LOGIC ---

  Future<void> _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result != null) {
        setState(() => _selectedFile = result.files.first);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _generate() async {
    if (_sectionTitleController.text.isEmpty) {
      CustomSnackbar.showError(context, 'Please enter a Section Title');
      return;
    }

    setState(() => _currentStep = 2); // Show Loading

    try {
      final response = await TeacherMaterialService.generateAiContent(
        file: _selectedFile!,
        questionType: _questionType,
        count: _questionCount,
        difficulty: _difficulty,
      );

      final rawContent = response['generated_content'];
      List<dynamic> jsonList = jsonDecode(rawContent);

      double defaultMarks = double.tryParse(_defaultMarksController.text) ?? 1.0;

      // Convert to Wrappers
      List<QuestionWrapper> newBatch = jsonList.map((e) {
        return QuestionWrapper(QuestionModel.fromJson(e), defaultMarks);
      }).toList();

      setState(() {
        _sections.add(PaperSection(
          title: _sectionTitleController.text,
          questions: newBatch,
        ));

        // Auto-increment section title (Section A -> Section B)
        String nextChar = String.fromCharCode(65 + _sections.length);
        _sectionTitleController.text = "Section $nextChar";
        _currentStep = 3; // Go to Preview
      });

    } catch (e) {
      setState(() => _currentStep = 1);
      if (mounted) CustomSnackbar.showError(context, 'Failed to generate. Try again.');
    }
  }

  Future<void> _saveToDatabase() async {
    if (_sections.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      // Calls the UPDATED service method with all professional fields
      await TeacherMaterialService.saveAiQuestionPaper(
        teacherCode: widget.teacherCode,
        chapterId: widget.chapterId,
        paperTitle: _examNameController.text, // Using Exam Name as the main title

        // New Professional Header Fields
        schoolName: _schoolNameController.text,
        examName: _examNameController.text,
        timeAllowed: _timeController.text,
        instructions: _instructionsController.text,

        totalMarks: _grandTotalMarks,
        difficulty: _difficulty,

        // Pass the hierarchical sections directly
        sections: _sections,
      );

      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Saved to Library!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) CustomSnackbar.showError(context, 'Save failed: $e');
    }
  }

  // --- PDF GENERATION ---

  Future<Uint8List> _generatePdfDocument() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoExtraLight();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontItalic = await PdfGoogleFonts.nunitoItalic();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Professional Header
            pw.Center(child: pw.Text(_schoolNameController.text.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 18))),
            pw.SizedBox(height: 4),
            pw.Center(child: pw.Text(_examNameController.text, style: pw.TextStyle(font: font, fontSize: 14))),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Time: ${_timeController.text}", style: pw.TextStyle(font: fontBold, fontSize: 12)),
                pw.Text("Max Marks: $_grandTotalMarks", style: pw.TextStyle(font: fontBold, fontSize: 12)),
              ],
            ),
            pw.Divider(),
            pw.SizedBox(height: 8),

            // Instructions
            if (_instructionsController.text.isNotEmpty) ...[
              pw.Text("General Instructions:", style: pw.TextStyle(font: fontBold, fontSize: 10)),
              pw.Text(_instructionsController.text, style: pw.TextStyle(font: fontItalic, fontSize: 10)),
              pw.SizedBox(height: 16),
            ],

            // Sections Loop
            ..._sections.asMap().entries.map((secEntry) {
              final section = secEntry.value;
              final activeQuestions = section.questions.where((q) => q.model.isSelected).toList();

              if (activeQuestions.isEmpty) return pw.SizedBox();

              return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    pw.Container(
                      alignment: pw.Alignment.center,
                      margin: const pw.EdgeInsets.symmetric(vertical: 10),
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      child: pw.Text(section.title.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 12)),
                    ),

                    // Questions
                    ...activeQuestions.asMap().entries.map((qEntry) {
                      int qIdx = qEntry.key + 1;
                      QuestionWrapper q = qEntry.value;

                      return pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 12),
                          child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text("$qIdx. ", style: pw.TextStyle(font: fontBold, fontSize: 11)),
                                      pw.Expanded(child: pw.Text(q.model.question, style: pw.TextStyle(font: font, fontSize: 11))),
                                      pw.Text(" [${q.marks}]", style: pw.TextStyle(font: fontBold, fontSize: 10)),
                                    ]
                                ),
                                if (q.model.options.isNotEmpty)
                                  pw.Padding(
                                      padding: const pw.EdgeInsets.only(top: 4, left: 15),
                                      child: pw.Wrap(
                                          spacing: 20,
                                          runSpacing: 4,
                                          children: q.model.options.asMap().entries.map((opt) {
                                            String char = String.fromCharCode(65 + opt.key);
                                            return pw.Text("($char) ${opt.value}", style: pw.TextStyle(font: font, fontSize: 10));
                                          }).toList()
                                      )
                                  )
                              ]
                          )
                      );
                    }).toList()
                  ]
              );
            }).toList()
          ];
        },
      ),
    );
    return pdf.save();
  }

  Future<void> _downloadPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final data = await _generatePdfDocument();
      await Printing.sharePdf(bytes: data, filename: 'Exam_Paper.pdf');
    } catch (e) {
      if(mounted) CustomSnackbar.showError(context, 'PDF Error: $e');
    } finally {
      if(mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  // --- PREMIUM EDIT DIALOG ---
  void _editQuestion(QuestionWrapper q) {
    final TextEditingController qCtrl = TextEditingController(text: q.model.question);
    final TextEditingController aCtrl = TextEditingController(text: q.model.answer);
    final TextEditingController mCtrl = TextEditingController(text: q.marks.toString());

    // Manage Options
    List<TextEditingController> optCtrls = q.model.options.map((e) => TextEditingController(text: e)).toList();

    showDialog(
      context: context,
      barrierDismissible: false, // Force save or cancel
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 25, offset: const Offset(0, 10))
                ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.edit_2, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      const Text("Edit Question", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(ctx)
                      )
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question Text
                        const Text("Question", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: qCtrl,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6A11CB), width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            // Marks
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Marks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: mCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Iconsax.award, size: 18, color: Colors.amber),
                                      filled: true,
                                      fillColor: const Color(0xFFF8F9FA),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Answer
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Correct Answer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: aCtrl,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Iconsax.tick_circle, size: 18, color: Colors.green),
                                      filled: true,
                                      fillColor: Colors.green.withOpacity(0.05),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green.withOpacity(0.3))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green, width: 1.5)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Options
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Options", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                            TextButton.icon(
                              icon: const Icon(Icons.add_circle, size: 16, color: Color(0xFF6A11CB)),
                              label: const Text("Add Option", style: TextStyle(color: Color(0xFF6A11CB), fontWeight: FontWeight.bold)),
                              onPressed: () {
                                setDialogState(() {
                                  optCtrls.add(TextEditingController());
                                });
                              },
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (optCtrls.isEmpty)
                          const Text("No options added for this question.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                        else
                          ...optCtrls.asMap().entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 32, height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                                  child: Text(String.fromCharCode(65 + entry.key), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: entry.value,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      filled: true, fillColor: Colors.white,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6A11CB))),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    setDialogState(() {
                                      optCtrls.removeAt(entry.key);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  ),
                                )
                              ],
                            ),
                          )),
                      ],
                    ),
                  ),
                ),

                // Footer Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      border: Border(top: BorderSide(color: Colors.grey[200]!))
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Cancel", style: TextStyle(color: Colors.grey))
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_alt, size: 18),
                        label: const Text("Save Changes"),
                        onPressed: () {
                          setState(() {
                            q.model.question = qCtrl.text;
                            q.model.answer = aCtrl.text;
                            q.marks = double.tryParse(mCtrl.text) ?? 1.0;
                            q.model.options = optCtrls.map((c) => c.text).toList();
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A11CB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- PREMIUM EXPORT SHEET ---
  void _showExportOptions() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (c) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle Bar
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),

              const Text("Export Paper", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Choose how you want to save this exam paper.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),

              // Save to DB Option
              InkWell(
                onTap: () { Navigator.pop(c); _saveToDatabase(); },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF6A11CB).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Iconsax.cloud_plus, color: Color(0xFF6A11CB)),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Save to Library", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Store in database for students", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Download PDF Option
              InkWell(
                onTap: () { Navigator.pop(c); _downloadPdf(); },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Iconsax.document_download, color: Colors.red),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Download PDF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Print or share file externally", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
    );
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 900),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 10))],
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: _buildBody(),
                  ),
                ),
              ),
              if (_currentStep != 2) _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentStep) {
      case 0: return _buildStepUpload();
      case 1: return _buildStepConfig();
      case 2: return _buildStepLoading();
      case 3: return _buildStepPreview();
      default: return const SizedBox();
    }
  }

  // --- STEPS ---

  Widget _buildStepUpload() {
    return Center(
      child: GestureDetector(
        onTap: _pickPdf,
        child: Container(
          height: 300, width: 500,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _selectedFile != null ? const Color(0xFF6A11CB) : Colors.grey[300]!, width: 2),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF6A11CB).withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(_selectedFile != null ? Iconsax.document_text : Iconsax.document_upload, size: 48, color: const Color(0xFF6A11CB)),
              ),
              const SizedBox(height: 24),
              Text(
                  _selectedFile != null ? _selectedFile!.name : "Click to Browse PDF",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
              ),
              const SizedBox(height: 8),
              Text("Supports PDF chapters up to 10MB", style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepConfig() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF6A11CB).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Iconsax.setting_2, color: Color(0xFF6A11CB)),
              ),
              const SizedBox(width: 16),
              const Text("Configure Section", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildInput("Section Title", _sectionTitleController, "e.g. Section A - Physics"),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildInput("Marks per Question", _defaultMarksController, "e.g. 1", isNum: true),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Question Type", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _questionType,
                        isExpanded: true,
                        items: _questionTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setState(() => _questionType = val!),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Count", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _questionCount,
                        isExpanded: true,
                        items: [5, 10, 15, 20, 30].map((e) => DropdownMenuItem(value: e, child: Text("$e Questions"))).toList(),
                        onChanged: (val) => setState(() => _questionCount = val!),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Difficulty Level", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: ['Easy', 'Medium', 'Hard'].map((e) {
                bool isSel = _difficulty == e;
                return ChoiceChip(
                  label: Text(e),
                  selected: isSel,
                  onSelected: (val) => setState(() => _difficulty = e),
                  selectedColor: const Color(0xFF6A11CB),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                  side: isSel ? BorderSide.none : BorderSide(color: Colors.grey[300]!),
                );
              }).toList(),
            )
          ]),
        ],
      ),
    );
  }

  Widget _buildStepPreview() {
    return Row(
      children: [
        // Left Panel: Paper Preview
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 20, offset: const Offset(0, 10))]
            ),
            child: Column(
              children: [
                // --- PROFESSIONAL HEADER EDIT BLOCK ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFBFBFB),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      border: Border(bottom: BorderSide(color: Colors.grey[200]!))
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _schoolNameController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        decoration: const InputDecoration.collapsed(hintText: "SCHOOL NAME"),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _examNameController,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                        decoration: const InputDecoration.collapsed(hintText: "Exam Name / Session"),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Iconsax.clock, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(child: TextField(controller: _timeController, decoration: const InputDecoration.collapsed(hintText: "Time"))),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text("Max Marks: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                                  child: Text("$_grandTotalMarks", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      TextField(
                        controller: _instructionsController,
                        maxLines: null,
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                        decoration: const InputDecoration.collapsed(hintText: "General Instructions..."),
                      ),
                    ],
                  ),
                ),

                // --- SECTIONS & QUESTIONS ---
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _sections.length,
                    itemBuilder: (ctx, secIdx) {
                      final section = _sections[secIdx];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            margin: const EdgeInsets.only(bottom: 16, top: 8),
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(section.title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  onPressed: () => setState(() => _sections.removeAt(secIdx)),
                                )
                              ],
                            ),
                          ),

                          // Questions
                          ...section.questions.asMap().entries.map((qEntry) {
                            int qIdx = qEntry.key + 1;
                            QuestionWrapper q = qEntry.value;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[200]!),
                                  borderRadius: BorderRadius.circular(12)
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Checkbox
                                  Transform.scale(
                                    scale: 1.1,
                                    child: Checkbox(
                                      value: q.model.isSelected,
                                      activeColor: const Color(0xFF6A11CB),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (v) => setState(() => q.model.isSelected = v!),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text.rich(
                                          TextSpan(children: [
                                            TextSpan(text: "$qIdx. ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                            TextSpan(text: q.model.question),
                                          ]),
                                          style: const TextStyle(fontSize: 15, height: 1.4),
                                        ),
                                        if (q.model.options.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 10),
                                            child: Wrap(
                                              spacing: 24, runSpacing: 8,
                                              children: q.model.options.asMap().entries.map((opt) {
                                                return Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text("(${String.fromCharCode(65+opt.key)}) ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                                                    Text(opt.value, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                                  ],
                                                );
                                              }).toList(),
                                            ),
                                          )
                                      ],
                                    ),
                                  ),
                                  // Marks & Edit
                                  Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(6)),
                                        child: Text("${q.marks} M", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green[800])),
                                      ),
                                      const SizedBox(height: 8),
                                      IconButton(
                                        icon: const Icon(Iconsax.edit, size: 18, color: Colors.blue),
                                        onPressed: () => _editQuestion(q),
                                        style: IconButton.styleFrom(backgroundColor: Colors.blue.withOpacity(0.05)),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            );
                          })
                        ],
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BeautifulLoader(type: LoaderType.circular, color: Color(0xFF6A11CB), size: 60),
          const SizedBox(height: 24),
          const Text("Creating Section...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Analyzing content and drafting questions", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- COMMON ---

  Widget _buildInput(String label, TextEditingController ctrl, String hint, {bool isNum = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6A11CB))),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Iconsax.magic_star, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          const Text("AI Exam Paper Studio", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white))
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        children: [
          if (_currentStep == 3)
            TextButton.icon(
              icon: const Icon(Iconsax.add_circle, size: 18),
              label: const Text("Add Another Section", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => setState(() => _currentStep = 1), // Back to config for new section
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF6A11CB)),
            ),

          const Spacer(),

          if (_currentStep > 0 && _currentStep != 3)
            TextButton(
              onPressed: () => setState(() => _currentStep--),
              child: const Text("Back", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 16),

          ElevatedButton.icon(
            icon: _isSaving || _isGeneratingPdf
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(_currentStep == 3 ? Iconsax.export_3 : Iconsax.arrow_right_3, size: 18),

            onPressed: (_isSaving || _isGeneratingPdf)
                ? null
                : () {
              if (_currentStep == 0) {
                if (_selectedFile == null) {
                  CustomSnackbar.showError(context, "Please select a PDF file first");
                  return;
                }
                setState(() => _currentStep = 1);
              }
              else if (_currentStep == 1) _generate();
              else if (_currentStep == 3) {
                // Show improved bottom sheet
                _showExportOptions();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A11CB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              shadowColor: const Color(0xFF6A11CB).withOpacity(0.4),
            ),
            label: Text(_currentStep == 3 ? "Finish & Export" : "Next Step", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}