class QuestionModel {
  String id;
  String question;
  List<String> options;
  String answer;
  String explanation;
  bool isSelected; // ⭐ New field for selection

  QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
    this.isSelected = true, // Default to selected
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'].toString(),
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      answer: json['answer'] ?? '',
      explanation: json['explanation'] ?? '',
    );
  }
}