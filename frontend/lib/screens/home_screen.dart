import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/progress_provider.dart';
import '../models/chapter.dart';
import '../config/theme.dart';
import 'login_screen.dart';
import 'video_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProgress());
  }

  Future<void> _loadProgress() async {
    await context.read<ProgressProvider>().loadProgress();
  }

  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    final progressProvider = context.read<ProgressProvider>();
    await authProvider.logout();
    progressProvider.clearProgress();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _navigateToResume() {
    final resumePoint = context.read<ProgressProvider>().resumePoint;
    if (resumePoint == null) return;

    if (resumePoint.contentType == 'video') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoScreen(
            chapterId: resumePoint.chapterId,
            resumeTimestamp: resumePoint.videoTimestamp,
          ),
        ),
      ).then((_) => _loadProgress());
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            chapterId: resumePoint.chapterId,
            startQuestionIndex: resumePoint.quizQuestionIndex,
          ),
        ),
      ).then((_) => _loadProgress());
    }
  }

  void _navigateToChapter(Chapter chapter) {
    if (!chapter.videoCompleted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoScreen(
            chapterId: chapter.id,
            resumeTimestamp: chapter.videoTimestamp,
          ),
        ),
      ).then((_) => _loadProgress());
    } else if (!chapter.quizCompleted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            chapterId: chapter.id,
            startQuestionIndex: chapter.quizQuestionIndex,
          ),
        ),
      ).then((_) => _loadProgress());
    } else {
      _showCompletedChapterOptions(chapter);
    }
  }

  void _showCompletedChapterOptions(Chapter chapter) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(chapter.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('This chapter is completed!'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VideoScreen(chapterId: chapter.id),
                        ),
                      ).then((_) => _loadProgress());
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Watch Video'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(chapterId: chapter.id),
                        ),
                      ).then((_) => _loadProgress());
                    },
                    icon: const Icon(Icons.quiz),
                    label: const Text('Take Quiz'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Learning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProgress,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProgress,
        child: Consumer<ProgressProvider>(
          builder: (context, progressProvider, child) {
            if (progressProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (progressProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppTheme.error.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        progressProvider.error!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadProgress, child: const Text('Retry')),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Welcome, ${authProvider.userId ?? 'User'}!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                if (progressProvider.hasResumePoint)
                  _buildResumeCard(progressProvider),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Chapters', style: Theme.of(context).textTheme.titleLarge),
                ),
                ...progressProvider.chapters.map((chapter) => _buildChapterCard(chapter)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResumeCard(ProgressProvider progressProvider) {
    final resumePoint = progressProvider.resumePoint!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      resumePoint.contentType == 'video'
                          ? Icons.play_circle_outline
                          : Icons.quiz_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Continue Learning',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          resumePoint.chapterTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    resumePoint.contentType == 'video'
                        ? Icons.access_time
                        : Icons.format_list_numbered,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(resumePoint.displayText, style: const TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _navigateToResume,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.darkBlue,
                  ),
                  child: const Text('Resume'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterCard(Chapter chapter) {
    final isCompleted = chapter.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToChapter(chapter),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: AppTheme.success)
                      : Text(
                          '${chapter.orderIndex}',
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chapter.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      chapter.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildProgressChip(Icons.play_arrow, 'Video', chapter.videoCompleted),
                        const SizedBox(width: 8),
                        _buildProgressChip(Icons.quiz, 'Quiz', chapter.quizCompleted),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressChip(IconData icon, String label, bool completed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: completed
            ? AppTheme.success.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.check : icon,
            size: 14,
            color: completed ? AppTheme.success : AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: completed ? AppTheme.success : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
