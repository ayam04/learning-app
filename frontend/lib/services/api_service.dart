import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chapter.dart';
import '../models/quiz.dart';
import '../models/progress.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';

  String? _authToken;

  void setAuthToken(String userId) => _authToken = userId;
  void clearAuthToken() => _authToken = null;

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<Map<String, dynamic>> login(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode == 200) {
      setAuthToken(userId);
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<void> logout() async {
    await http.post(Uri.parse('$baseUrl/auth/logout'), headers: _headers);
    clearAuthToken();
  }

  Future<List<Chapter>> getChapters() async {
    final response = await http.get(Uri.parse('$baseUrl/chapters'), headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Chapter.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load chapters: ${response.body}');
    }
  }

  Future<ChapterDetail> getChapterDetail(int chapterId) async {
    final response = await http.get(Uri.parse('$baseUrl/chapters/$chapterId'), headers: _headers);

    if (response.statusCode == 200) {
      return ChapterDetail.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load chapter: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getProgress() async {
    final response = await http.get(Uri.parse('$baseUrl/progress'), headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load progress: ${response.body}');
    }
  }

  Future<ResumePoint?> getResumePoint() async {
    final response = await http.get(Uri.parse('$baseUrl/progress/resume'), headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['resume_point'] != null) {
        return ResumePoint.fromJson(data['resume_point']);
      }
      return null;
    } else {
      throw Exception('Failed to load resume point: ${response.body}');
    }
  }

  Future<void> saveVideoProgress({
    required int chapterId,
    required double timestamp,
    required double duration,
    bool completed = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/progress/video'),
      headers: _headers,
      body: jsonEncode({
        'chapter_id': chapterId,
        'timestamp': timestamp,
        'duration': duration,
        'completed': completed,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save video progress: ${response.body}');
    }
  }

  Future<void> saveQuizProgress({
    required int chapterId,
    required int questionIndex,
    required List<int> answers,
    bool completed = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/progress/quiz'),
      headers: _headers,
      body: jsonEncode({
        'chapter_id': chapterId,
        'question_index': questionIndex,
        'answers': answers,
        'completed': completed,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save quiz progress: ${response.body}');
    }
  }
}
