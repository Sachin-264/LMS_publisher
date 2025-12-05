import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Teacher_Panel/teacher_material_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';

class AiPaperGradingScreen extends StatefulWidget {
  final Map<String, dynamic> submission;
  final String teacherCode;

  const AiPaperGradingScreen({
    super.key,
    required this.submission,
    required this.teacherCode,
  });

  @override
  State<AiPaperGradingScreen> createState() => _AiPaperGradingScreenState();
}

class _AiPaperGradingScreenState extends State<AiPaperGradingScreen> {
  bool _isLoading = true;
  List<dynamic> _answers = [];
  Map<String, dynamic>? _summary;

  final Map<int, TextEditingController> _markControllers = {};
  final TextEditingController _feedbackController = TextEditingController();

  double _totalCalculatedScore = 0.0;
  double _maxTotalScore = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExamDetails();
    _feedbackController.text = widget.submission['TeacherFeedback'] ?? '';
  }

  @override
  void dispose() {
    for (var controller in _markControllers.values) {
      controller.dispose();
    }
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadExamDetails() async {
    try {
      final response = await TeacherMaterialService.getStudentExamAnswers(
        widget.submission['SubmissionRecNo'],
      );

      if (mounted) {
        setState(() {
          _summary = response['summary'];
          _answers = response['answers'] ?? [];
          _isLoading = false;

          double maxTotal = 0.0;

          for (var ans in _answers) {
            int qId = ans['QuestionID'];
            double marks = double.tryParse(ans['MarksAwarded'].toString()) ?? 0.0;
            double maxQMarks = double.tryParse(ans['MaxQuestionMarks'].toString()) ?? 1.0;

            _markControllers[qId] = TextEditingController(text: marks.toString());
            maxTotal += maxQMarks;
          }

          _maxTotalScore = maxTotal;
          _calculateTotal();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackbar.showError(context, "Error loading answers: $e");
      }
    }
  }

  void _calculateTotal() {
    double total = 0.0;
    for (var controller in _markControllers.values) {
      total += double.tryParse(controller.text) ?? 0.0;
    }
    setState(() {
      _totalCalculatedScore = total;
    });
  }

  // ✅ UPDATED: _submitGrades to use the new API logic
  Future<void> _submitGrades() async {
    setState(() => _isLoading = true);

    try {
      // 1. Build the list of graded questions
      List<Map<String, dynamic>> gradedQuestions = [];

      _markControllers.forEach((questionId, controller) {
        gradedQuestions.add({
          "question_id": questionId,
          "marks_awarded": double.tryParse(controller.text) ?? 0.0
        });
      });

      // 2. Call the Service
      await TeacherMaterialService.gradeAiPaper(
        submissionRecNo: widget.submission['SubmissionRecNo'],
        teacherFeedback: _feedbackController.text,
        gradedQuestions: gradedQuestions,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackbar.showSuccess(context, "Grading Saved & Published!");
        Navigator.pop(context, true); // Return true to refresh parent
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackbar.showError(context, "Failed to save grades: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(child: BeautifulLoader(type: LoaderType.circular, color: AppTheme.primaryGreen))
          : Column(
        children: [
          _buildScoreSummary(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
              itemCount: _answers.length,
              itemBuilder: (context, index) {
                return _buildPremiumQuestionCard(_answers[index], index + 1);
              },
            ),
          ),
        ],
      ),
      bottomSheet: _isLoading ? null : _buildBottomActionPanel(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.submission['StudentName'] ?? 'Student',
            style: GoogleFonts.outfit(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18
            ),
          ),
          Text(
            "Evaluation Mode",
            style: GoogleFonts.inter(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
    );
  }

  Widget _buildScoreSummary() {
    double percentage = (_maxTotalScore > 0) ? (_totalCalculatedScore / _maxTotalScore) : 0.0;
    Color scoreColor = percentage >= 0.7 ? Colors.green : (percentage >= 0.4 ? Colors.orange : Colors.red);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "TOTAL SCORE",
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.2
                  )
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: _totalCalculatedScore.toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                            color: scoreColor,
                            fontSize: 32,
                            fontWeight: FontWeight.bold
                        )
                    ),
                    TextSpan(
                        text: " / $_maxTotalScore",
                        style: GoogleFonts.outfit(
                            color: Colors.grey.shade400,
                            fontSize: 20,
                            fontWeight: FontWeight.w600
                        )
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Iconsax.chart_2, color: scoreColor, size: 28),
          )
        ],
      ),
    );
  }

  Widget _buildPremiumQuestionCard(Map<String, dynamic> data, int index) {
    bool isAutoCorrect = data['IsCorrect'] == true;
    double maxMarks = double.tryParse(data['MaxQuestionMarks'].toString()) ?? 1.0;
    int qId = data['QuestionID'];

    // Check if subjective
    bool isSubjective = !['Multiple Choice Questions (MCQ)', 'True or False', 'Fill in the Blanks']
        .contains(data['QuestionType']);

    // Teacher should check subjective ones OR incorrect objective ones
    bool enableManualGrading = isSubjective || !isAutoCorrect;

    // Logic to hide Correct Answer Box if null/empty
    String? correctAnswerText = data['CorrectAnswer'];
    bool showCorrectAnswer = (!isAutoCorrect || isSubjective) &&
        (correctAnswerText != null && correctAnswerText.trim().isNotEmpty);

    // Logic to determine badge status based on current marks
    double currentMarks = double.tryParse(_markControllers[qId]?.text ?? '0') ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. Question Header ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Q$index",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    data['QuestionText'] ?? "Question Text Missing",
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        color: const Color(0xFF1F2937)
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Row(
              children: [
                if (isSubjective)
                  currentMarks > 0
                      ? _buildStatusBadge("Graded", Colors.blue)
                      : _buildStatusBadge("Needs Review", Colors.amber)
                else if (isAutoCorrect)
                  _buildStatusBadge("Correct", Colors.green)
                else
                  _buildStatusBadge("Incorrect", Colors.red),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // --- 2. Answer Area ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Answer Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Iconsax.user, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                              "STUDENT ANSWER",
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.blue.shade700,
                                  letterSpacing: 0.5
                              )
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['StudentAnswer'] ?? "No Answer Provided",
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0C4A6E)
                        ),
                      ),
                    ],
                  ),
                ),

                // Correct Answer Container
                if (showCorrectAnswer) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Iconsax.verify, size: 16, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                                "CORRECT ANSWER",
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.green.shade700,
                                    letterSpacing: 0.5
                                )
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          correctAnswerText!,
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF14532D)
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // --- 3. Grading Footer ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                    "Max Marks: $maxMarks",
                    style: GoogleFonts.inter(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 13
                    )
                ),
                const SizedBox(width: 16),

                // Score Input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2)
                        )
                      ]
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          "Award:",
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey.shade700
                          )
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _markControllers[qId],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: AppTheme.primaryGreen
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (_) => _calculateTotal(),
                          readOnly: !enableManualGrading,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2))
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.5
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5)
          )
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              "Overall Feedback",
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.darkText
              )
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _feedbackController,
            decoration: InputDecoration(
              hintText: "Add a comment for the student...",
              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 14),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _submitGrades,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppTheme.primaryGreen.withOpacity(0.3),
              ),
              child: Text(
                  "Publish Results",
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5
                  )
              ),
            ),
          )
        ],
      ),
    );
  }
}