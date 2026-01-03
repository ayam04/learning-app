class ResumePoint {
  final int chapterId;
  final String chapterTitle;
  final String contentType;
  final double videoTimestamp;
  final int quizQuestionIndex;
  final int totalQuestions;

  ResumePoint({
    required this.chapterId,
    required this.chapterTitle,
    required this.contentType,
    this.videoTimestamp = 0,
    this.quizQuestionIndex = 0,
    this.totalQuestions = 5,
  });

  factory ResumePoint.fromJson(Map<String, dynamic> json) {
    return ResumePoint(
      chapterId: json['chapter_id'] ?? 0,
      chapterTitle: json['chapter_title'] ?? '',
      contentType: json['content_type'] ?? 'video',
      videoTimestamp: (json['video_timestamp'] ?? 0).toDouble(),
      quizQuestionIndex: json['quiz_question_index'] ?? 0,
      totalQuestions: json['total_questions'] ?? 5,
    );
  }

  String get displayText {
    if (contentType == 'video') {
      final minutes = (videoTimestamp / 60).floor();
      final seconds = (videoTimestamp % 60).floor();
      return 'Video at ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return 'Quiz - Question ${quizQuestionIndex + 1} of $totalQuestions';
    }
  }
}
