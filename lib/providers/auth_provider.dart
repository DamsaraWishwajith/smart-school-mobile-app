import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:narme_project/services/api_service.dart';
import '../models/user_model.dart';

import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  String? _token;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get token => _token;
  bool get isAuthenticated => _user != null && _token != null;

  Future<void> initialize() async {
    await loadToken();
    await loadUser();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.login(email, password);

      if (response['success'] == true) {
        _user = UserModel.fromJson(response['data']['user']);
        _token = response['data']['token'];

        // Store in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', jsonEncode(response['data']['user']));

        if (_user != null) {
          await NotificationService.setupUserNotifications(_user!.role);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        if (response['statusCode'] == 401 || response['statusCode'] == 422) {
          _error = 'Invalid credentials';
        } else {
          _error = response['message'] ?? 'Login failed';
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.register(userData);

      if (response['success'] == true) {
        _user = UserModel.fromJson(response['data']['user']);
        _token = response['data']['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', jsonEncode(response['data']['user']));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_token != null) {
        await ApiServices.logout();
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      // Clear storage regardless of API call success
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _user = null;
      _token = null;
      _error = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        _user = UserModel.fromJson(jsonDecode(userString));
      } else if (_token != null) {
        final response = await ApiServices.getCurrentUser();
        if (response['success'] == true) {
          _user = UserModel.fromJson(response['data']);
          await prefs.setString('user', jsonEncode(response['data']));
        }
      }
      if (_user != null) {
        await NotificationService.setupUserNotifications(_user!.role);
      }
      notifyListeners();
    } catch (e) {
      _user = null;
      debugPrint('Error loading user: $e');
    }
  }

  Future<bool> refreshUserProfile() async {
    try {
      final response = await ApiServices.getCurrentUser();
      if (response['success'] == true) {
        _user = UserModel.fromJson(response['data']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(response['data']));
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error refreshing user profile: $e');
    }
    return false;
  }

  Future<void> loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading token: $e');
    }
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
