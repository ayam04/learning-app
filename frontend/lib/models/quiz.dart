import 'chapter.dart';

class QuizQuestion {
  final int id;
  final int chapterId;
  final String questionText;
  final List<String> options;
  final int correctOption;
  final int orderIndex;

  QuizQuestion({
    required this.id,
    required this.chapterId,
    required this.questionText,
    required this.options,
    required this.correctOption,
    required this.orderIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] ?? 0,
      chapterId: json['chapter_id'] ?? 0,
      questionText: json['question_text'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctOption: json['correct_option'] ?? 0,
      orderIndex: json['order_index'] ?? 0,
    );
  }
}

class ChapterDetail {
  final Chapter chapter;
  final List<QuizQuestion> questions;

  ChapterDetail({required this.chapter, required this.questions});

  factory ChapterDetail.fromJson(Map<String, dynamic> json) {
    return ChapterDetail(
      chapter: Chapter.fromJson(json['chapter'] ?? {}),
      questions: (json['questions'] as List? ?? []).map((q) => QuizQuestion.fromJson(q)).toList(),
    );
  }
}
