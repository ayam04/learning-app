import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/progress_provider.dart';
import '../models/quiz.dart';
import '../config/theme.dart';

class QuizScreen extends StatefulWidget {
  final int chapterId;
  final int startQuestionIndex;

  const QuizScreen({
    super.key,
    required this.chapterId,
    this.startQuestionIndex = 0,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  ChapterDetail? _chapterDetail;
  bool _isLoading = true;
  String? _error;

  int _currentQuestionIndex = 0;
  List<int> _answers = [];
  int? _selectedOption;
  bool _showResult = false;
  bool _quizCompleted = false;

  @override
  void initState() {
    super.initState();
    _currentQuestionIndex = widget.startQuestionIndex;
    _loadChapter();
  }

  @override
  void dispose() {
    if (!_quizCompleted && _chapterDetail != null) {
      _saveProgress(completed: false);
    }
    super.dispose();
  }

  Future<void> _loadChapter() async {
    try {
      final apiService = context.read<AuthProvider>().apiService;
      final detail = await apiService.getChapterDetail(widget.chapterId);
      setState(() {
        _chapterDetail = detail;
        _answers = List.filled(detail.questions.length, -1);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load quiz: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProgress({bool completed = false}) async {
    try {
      await context.read<ProgressProvider>().saveQuizProgress(
        chapterId: widget.chapterId,
        questionIndex: _currentQuestionIndex,
        answers: _answers,
        completed: completed,
      );
    } catch (e) {
      debugPrint('Error saving quiz progress: $e');
    }
  }

  void _selectOption(int optionIndex) {
    setState(() => _selectedOption = optionIndex);
  }

  void _submitAnswer() {
    if (_selectedOption == null) return;

    setState(() {
      _answers[_currentQuestionIndex] = _selectedOption!;
      _showResult = true;
    });

    _saveProgress();
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _chapterDetail!.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = _answers[_currentQuestionIndex] >= 0 ? _answers[_currentQuestionIndex] : null;
        _showResult = false;
      });
      _saveProgress();
    } else {
      _quizCompleted = true;
      _saveProgress(completed: true);
      _showCompletionDialog();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedOption = _answers[_currentQuestionIndex] >= 0 ? _answers[_currentQuestionIndex] : null;
        _showResult = _selectedOption != null;
      });
    }
  }

  void _showCompletionDialog() {
    final questions = _chapterDetail!.questions;
    int correctCount = 0;

    for (int i = 0; i < questions.length; i++) {
      if (_answers[i] == questions[i].correctOption) {
        correctCount++;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: correctCount >= questions.length / 2
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : AppTheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                correctCount >= questions.length / 2 ? Icons.celebration : Icons.sentiment_satisfied,
                size: 48,
                color: correctCount >= questions.length / 2 ? AppTheme.success : AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              correctCount >= questions.length / 2 ? 'Great Job!' : 'Quiz Completed!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'You got $correctCount out of ${questions.length} correct',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${(correctCount / questions.length * 100).round()}%',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: correctCount >= questions.length / 2 ? AppTheme.success : AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Back to Home'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_chapterDetail?.chapter.title ?? 'Quiz')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.error.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadChapter();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final questions = _chapterDetail!.questions;
    final currentQuestion = questions[_currentQuestionIndex];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primaryBlue),
                  ),
                  Text(
                    '${((_currentQuestionIndex + 1) / questions.length * 100).round()}%',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / questions.length,
                  backgroundColor: AppTheme.lightBlue,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(currentQuestion.questionText, style: Theme.of(context).textTheme.titleLarge),
                  ),
                ),
                const SizedBox(height: 24),
                ...List.generate(
                  currentQuestion.options.length,
                  (index) => _buildOptionCard(index, currentQuestion.options[index], currentQuestion.correctOption),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton(onPressed: _previousQuestion, child: const Text('Previous')),
                ),
              if (_currentQuestionIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _showResult
                      ? _nextQuestion
                      : (_selectedOption != null ? _submitAnswer : null),
                  child: Text(
                    _showResult
                        ? (_currentQuestionIndex < questions.length - 1 ? 'Next Question' : 'Finish Quiz')
                        : 'Submit Answer',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(int index, String option, int correctOption) {
    final isSelected = _selectedOption == index;
    final isCorrect = index == correctOption;
    final showCorrectness = _showResult;

    Color? backgroundColor;
    Color? borderColor;
    IconData? icon;

    if (showCorrectness) {
      if (isCorrect) {
        backgroundColor = AppTheme.success.withValues(alpha: 0.1);
        borderColor = AppTheme.success;
        icon = Icons.check_circle;
      } else if (isSelected && !isCorrect) {
        backgroundColor = AppTheme.error.withValues(alpha: 0.1);
        borderColor = AppTheme.error;
        icon = Icons.cancel;
      }
    } else if (isSelected) {
      borderColor = AppTheme.primaryBlue;
      backgroundColor = AppTheme.primaryBlue.withValues(alpha: 0.05);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: showCorrectness ? null : () => _selectOption(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor ?? Colors.grey.shade300,
              width: isSelected || (showCorrectness && isCorrect) ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (showCorrectness ? (isCorrect ? AppTheme.success : AppTheme.error) : AppTheme.primaryBlue)
                      : (showCorrectness && isCorrect ? AppTheme.success : Colors.grey.shade200),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: icon != null
                      ? Icon(icon, size: 18, color: Colors.white)
                      : Text(
                          String.fromCharCode(65 + index),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected || (showCorrectness && isCorrect) ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(option, style: Theme.of(context).textTheme.bodyLarge)),
            ],
          ),
        ),
      ),
    );
  }
}
