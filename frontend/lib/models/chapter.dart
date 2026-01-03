class Chapter {
  final int id;
  final String title;
  final String description;
  final String videoUrl;
  final int orderIndex;
  final double videoTimestamp;
  final double quizProgress;
  final bool videoCompleted;
  final bool quizCompleted;
  final int quizQuestionIndex;

  Chapter({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.orderIndex,
    this.videoTimestamp = 0,
    this.quizProgress = 0,
    this.videoCompleted = false,
    this.quizCompleted = false,
    this.quizQuestionIndex = 0,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['video_url'] ?? '',
      orderIndex: json['order_index'] ?? 0,
      videoTimestamp: (json['video_progress'] ?? 0).toDouble(),
      quizProgress: (json['quiz_progress'] ?? 0).toDouble(),
      videoCompleted: json['video_completed'] ?? false,
      quizCompleted: json['quiz_completed'] ?? false,
      quizQuestionIndex: ((json['quiz_progress'] ?? 0) / 20).round(),
    );
  }

  bool get isCompleted => videoCompleted && quizCompleted;

  double get totalProgress {
    double video = videoCompleted ? 50 : 0;
    double quiz = quizCompleted ? 50 : (quizProgress / 2);
    return video + quiz;
  }
}
