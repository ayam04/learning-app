import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  String? _userId;
  bool _isLoading = false;
  String? _error;

  String? get userId => _userId;
  bool get isLoggedIn => _userId != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ApiService get apiService => _apiService;

  AuthProvider() {
    _loadSavedUser();
  }

  Future<void> _loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('user_id');
    if (savedUserId != null) {
      _userId = savedUserId;
      _apiService.setAuthToken(savedUserId);
      notifyListeners();
    }
  }

  Future<bool> login(String userId) async {
    if (userId.trim().isEmpty) {
      _error = 'Please enter a user ID';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.login(userId.trim());
      _userId = userId.trim();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', _userId!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Login failed. Please check if the server is running.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
    } catch (e) {
      // Ignore logout errors
    }

    _userId = null;
    _apiService.clearAuthToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
