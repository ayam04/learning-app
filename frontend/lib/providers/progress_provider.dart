import 'package:flutter/foundation.dart';
import '../models/chapter.dart';
import '../models/progress.dart';
import '../services/api_service.dart';

class ProgressProvider with ChangeNotifier {
  final ApiService _apiService;

  List<Chapter> _chapters = [];
  ResumePoint? _resumePoint;
  bool _isLoading = false;
  String? _error;

  List<Chapter> get chapters => _chapters;
  ResumePoint? get resumePoint => _resumePoint;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasResumePoint => _resumePoint != null;

  ProgressProvider(this._apiService);

  Future<void> loadProgress() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getProgress();

      _chapters = (data['chapters'] as List? ?? [])
          .map((json) => Chapter.fromJson(json))
          .toList();

      if (data['resume_point'] != null) {
        _resumePoint = ResumePoint.fromJson(data['resume_point']);
      } else {
        _resumePoint = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load progress. Please check your connection.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveVideoProgress({
    required int chapterId,
    required double timestamp,
    required double duration,
    bool completed = false,
  }) async {
    try {
      await _apiService.saveVideoProgress(
        chapterId: chapterId,
        timestamp: timestamp,
        duration: duration,
        completed: completed,
      );
    } catch (e) {
      debugPrint('Error saving video progress: $e');
    }
  }

  Future<void> saveQuizProgress({
    required int chapterId,
    required int questionIndex,
    required List<int> answers,
    bool completed = false,
  }) async {
    try {
      await _apiService.saveQuizProgress(
        chapterId: chapterId,
        questionIndex: questionIndex,
        answers: answers,
        completed: completed,
      );
    } catch (e) {
      debugPrint('Error saving quiz progress: $e');
    }
  }

  void clearProgress() {
    _chapters = [];
    _resumePoint = null;
    notifyListeners();
  }
}
