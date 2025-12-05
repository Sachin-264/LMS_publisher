import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/StudentPannel/Service/student_subject_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';

class QuestionItem {
  final Map<String, dynamic> data;
  final String sectionTitle;
  final int sectionIndex;
  final int questionIndex;
  final String uniqueKey;

  QuestionItem({
    required this.data,
    required this.sectionTitle,
    required this.sectionIndex,
    required this.questionIndex,
    required this.uniqueKey,
  });
}

class StudentAttemptPaperScreen extends StatefulWidget {
  final int paperId;
  final String studentCode;
  final String subjectName;
  final Color subjectColor;
  final int materialRecNo;
  final String teacherCode;

  const StudentAttemptPaperScreen({
    super.key,
    required this.paperId,
    required this.studentCode,
    required this.subjectName,
    required this.subjectColor,
    required this.materialRecNo,
    required this.teacherCode,
  });

  @override
  State<StudentAttemptPaperScreen> createState() => _StudentAttemptPaperScreenState();
}

class _StudentAttemptPaperScreenState extends State<StudentAttemptPaperScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _paperData;
  List<QuestionItem> _allQuestions = [];
  final PageController _pageController = PageController();
  int _currentQuestionIndex = 0;
  Timer? _timer;
  int _remainingSeconds = 0;
  final Map<String, String> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadPaperDetails();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPaperDetails() async {
    try {
      final response = await StudentSubjectService.getAiPaperDetails(
        paperId: widget.paperId,
        teacherCode: widget.teacherCode,
      );

      if (mounted) {
        setState(() {
          _paperData = response['paper_data'];
          _parseAndSetTimer(_paperData?['TimeAllowed'] ?? "0 Mins");
          _flattenQuestions();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to load exam: $e');
        Navigator.pop(context);
      }
    }
  }

  void _flattenQuestions() {
    _allQuestions.clear();
    final sections = _paperData?['SectionsJSON'] as List<dynamic>? ?? [];

    for (int sIndex = 0; sIndex < sections.length; sIndex++) {
      final section = sections[sIndex];
      final questions = section['questions'] as List<dynamic>? ?? [];
      final String secTitle = section['title'] ?? 'Section ${String.fromCharCode(65 + sIndex)}';

      for (int qIndex = 0; qIndex < questions.length; qIndex++) {
        _allQuestions.add(QuestionItem(
          data: questions[qIndex],
          sectionTitle: secTitle,
          sectionIndex: sIndex,
          questionIndex: qIndex,
          uniqueKey: "${sIndex}_$qIndex",
        ));
      }
    }
  }

  void _parseAndSetTimer(String timeString) {
    int minutes = 0;
    final lowerTime = timeString.toLowerCase();

    if (lowerTime.contains('hour')) {
      final parts = lowerTime.split('hour');
      minutes += (int.tryParse(parts[0].trim()) ?? 0) * 60;
    } else if (lowerTime.contains('min')) {
      final parts = lowerTime.split('min');
      minutes += int.tryParse(parts[0].trim()) ?? 0;
    } else {
      minutes = 60;
    }

    setState(() {
      _remainingSeconds = minutes * 60;
    });

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _autoSubmit();
      }
    });
  }

  String get _formattedTime {
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _autoSubmit() {
    CustomSnackbar.showInfo(context, "Time's up! Submitting your paper...");
    _submitPaper();
  }

  Future<void> _submitPaper() async {
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> formattedAnswers = [];

      for (var q in _allQuestions) {
        // Ensure QuestionID is captured correctly from API response keys
        int questionId = q.data['QuestionID'] ?? q.data['question_id'] ?? 0;
        String answer = _answers[q.uniqueKey] ?? "";

        if (questionId != 0) {
          formattedAnswers.add({
            "question_id": questionId,
            "answer": answer
          });
        }
      }

      // Submit to backend without assuming graded status
      await StudentSubjectService.submitAiPaper(
        studentCode: widget.studentCode,
        materialRecNo: widget.materialRecNo,
        paperId: widget.paperId,
        answers: formattedAnswers,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackbar.showSuccess(context, "Paper Submitted Successfully!");
        Navigator.pop(context, true);
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackbar.showError(context, "Submission Failed: $e");
      }
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _allQuestions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevQuestion() {
    if (_currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Exam?'),
        content: const Text(
          'If you leave now, your paper will be SUBMITTED automatically with current answers.\n\nAre you sure you want to exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              _submitPaper();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Yes, Submit & Leave'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _isLoading
            ? Center(child: BeautifulLoader(type: LoaderType.circular, color: widget.subjectColor))
            : Column(
          children: [
            _buildHeader(),
            _buildTimerBar(),
            Expanded(child: _buildQuestionPageView()),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 16, left: 20, right: 20),
      decoration: BoxDecoration(
        color: widget.subjectColor.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: widget.subjectColor.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              if (await _onWillPop()) {
              }
            },
            icon: const Icon(Iconsax.arrow_left),
            style: IconButton.styleFrom(backgroundColor: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _paperData?['ExamName'] ?? 'Exam',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                Text(
                  widget.subjectName,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    bool isUrgent = _remainingSeconds < 300;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.shade50 : AppTheme.background,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Question ${_currentQuestionIndex + 1} of ${_allQuestions.length}",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
          Row(
            children: [
              Icon(Iconsax.clock, size: 20, color: isUrgent ? Colors.red : AppTheme.darkText),
              const SizedBox(width: 8),
              Text(
                _formattedTime,
                style: GoogleFonts.robotoMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isUrgent ? Colors.red : AppTheme.darkText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPageView() {
    if (_allQuestions.isEmpty) return const Center(child: Text("No questions found"));

    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (index) {
        setState(() => _currentQuestionIndex = index);
      },
      itemCount: _allQuestions.length,
      itemBuilder: (context, index) {
        final qItem = _allQuestions[index];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.subjectColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  qItem.sectionTitle.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: widget.subjectColor),
                ),
              ),
              const SizedBox(height: 20),
              _buildSingleQuestionCard(qItem),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSingleQuestionCard(QuestionItem item) {
    final questionText = item.data['question'] ?? item.data['QuestionText'] ?? '';
    final marks = item.data['marks'] ?? item.data['Marks'] ?? 1;
    final List<dynamic> options = item.data['options'] ?? [];

    // Determine input type based on options availability
    bool isSubjective = options.isEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Q${item.questionIndex + 1}.",
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: widget.subjectColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  questionText,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5, color: AppTheme.darkText),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
              child: Text(
                "$marks Marks",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Render appropriate input type
          if (isSubjective)
            _buildSubjectiveInput(item)
          else
            _buildObjectiveInput(item, options),
        ],
      ),
    );
  }

  Widget _buildObjectiveInput(QuestionItem item, List<dynamic> options) {
    return Column(
      children: options.map((opt) {
        final isSelected = _answers[item.uniqueKey] == opt.toString();
        return GestureDetector(
          onTap: () {
            setState(() {
              _answers[item.uniqueKey] = opt.toString();
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? widget.subjectColor.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? widget.subjectColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 22, width: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? widget.subjectColor : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isSelected ? Center(child: Container(height: 12, width: 12, decoration: BoxDecoration(color: widget.subjectColor, shape: BoxShape.circle))) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    opt.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: isSelected ? AppTheme.darkText : Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubjectiveInput(QuestionItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Answer:",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        TextFormField(
          key: ValueKey(item.uniqueKey),
          initialValue: _answers[item.uniqueKey],
          maxLines: 6,
          onChanged: (val) {
            _answers[item.uniqueKey] = val;
          },
          decoration: InputDecoration(
            hintText: "Type your answer here...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.subjectColor, width: 1.5),
            ),
          ),
          style: GoogleFonts.inter(fontSize: 15, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    bool isFirst = _currentQuestionIndex == 0;
    bool isLast = _currentQuestionIndex == _allQuestions.length - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: isFirst ? null : _prevQuestion,
            icon: const Icon(Iconsax.arrow_left_2),
            label: const Text("Previous"),
            style: TextButton.styleFrom(
              foregroundColor: isFirst ? Colors.grey.shade300 : Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          ElevatedButton.icon(
            onPressed: isLast ? _submitPaper : _nextQuestion,
            icon: Icon(isLast ? Iconsax.tick_circle : Iconsax.arrow_right_3, size: 18),
            label: Text(isLast ? "Submit Paper" : "Next"),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.subjectColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}