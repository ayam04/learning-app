import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/auth_provider.dart';
import '../providers/progress_provider.dart';
import '../models/quiz.dart';
import '../config/theme.dart';
import 'quiz_screen.dart';

class VideoScreen extends StatefulWidget {
  final int chapterId;
  final double resumeTimestamp;

  const VideoScreen({
    super.key,
    required this.chapterId,
    this.resumeTimestamp = 0,
  });

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  VideoPlayerController? _controller;
  ChapterDetail? _chapterDetail;
  bool _isLoading = true;
  String? _error;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  Timer? _saveProgressTimer;
  bool _hasResumed = false;

  @override
  void initState() {
    super.initState();
    _loadChapter();
  }

  @override
  void dispose() {
    _saveProgress(completed: false);
    _controller?.dispose();
    _hideControlsTimer?.cancel();
    _saveProgressTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChapter() async {
    try {
      final apiService = context.read<AuthProvider>().apiService;
      final detail = await apiService.getChapterDetail(widget.chapterId);
      setState(() => _chapterDetail = detail);
      await _initializeVideo(detail.chapter.videoUrl);
    } catch (e) {
      setState(() {
        _error = 'Failed to load chapter: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeVideo(String videoUrl) async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _controller!.initialize();

      if (widget.resumeTimestamp > 0 && !_hasResumed) {
        await _controller!.seekTo(Duration(seconds: widget.resumeTimestamp.toInt()));
        _hasResumed = true;
      }

      _controller!.addListener(_videoListener);

      _saveProgressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _saveProgress();
      });

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load video: $e';
        _isLoading = false;
      });
    }
  }

  void _videoListener() {
    if (_controller == null) return;

    if (_controller!.value.position >= _controller!.value.duration - const Duration(seconds: 1)) {
      _saveProgress(completed: true);
    }

    setState(() {});
  }

  Future<void> _saveProgress({bool completed = false}) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await context.read<ProgressProvider>().saveVideoProgress(
        chapterId: widget.chapterId,
        timestamp: _controller!.value.position.inSeconds.toDouble(),
        duration: _controller!.value.duration.inSeconds.toDouble(),
        completed: completed,
      );
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  void _togglePlayPause() {
    if (_controller == null) return;

    if (_controller!.value.isPlaying) {
      _controller!.pause();
      _saveProgress();
    } else {
      _controller!.play();
      _startHideControlsTimer();
    }
    setState(() {});
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (_controller?.value.isPlaying ?? false) {
        setState(() => _showControls = false);
      }
    });
  }

  void _onTapVideo() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideControlsTimer();
  }

  void _seekTo(Duration position) {
    _controller?.seekTo(position);
    _saveProgress();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _navigateToQuiz() {
    _saveProgress(completed: true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => QuizScreen(chapterId: widget.chapterId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_chapterDetail?.chapter.title ?? 'Loading...'),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Loading video...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
            ),
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

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _onTapVideo,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                ),
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 72,
                          icon: Icon(
                            _controller!.value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.white,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black,
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.primaryBlue,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: AppTheme.primaryBlue,
                  overlayColor: AppTheme.primaryBlue.withValues(alpha: 0.3),
                ),
                child: Slider(
                  value: _controller!.value.position.inSeconds.toDouble(),
                  min: 0,
                  max: _controller!.value.duration.inSeconds.toDouble(),
                  onChanged: (value) => _seekTo(Duration(seconds: value.toInt())),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_controller!.value.position), style: const TextStyle(color: Colors.white)),
                  Text(_formatDuration(_controller!.value.duration), style: const TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToQuiz,
                  icon: const Icon(Icons.quiz),
                  label: const Text('Continue to Quiz'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
