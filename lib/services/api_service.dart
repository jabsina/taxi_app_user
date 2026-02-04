import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ride_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../main.dart'; // navigatorKey

// 🔥 Custom exception to avoid UI error flash
class SessionExpiredException implements Exception {}

class ApiService {
  static const String baseUrl = "https://api.lenienttree.org";

  static const String _tokenKey = 'user_token';
  static const String _userIdKey = 'user_id';

  // ================= AUTH STORAGE =================

  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }

  // ================= SESSION HANDLER =================

  static Future<void> _handleSessionExpired() async {
    await clearAuthData();

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
          (route) => false,
    );
  }

  static Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    
    // Basic token validation - JWT tokens have 3 parts separated by dots
    final parts = token.split('.');
    if (parts.length != 3) {
      print('Invalid token format: $token');
      await clearAuthData();
      return false;
    }
    
    return true;
  }

  // ================= HEADERS =================

  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await getAuthToken();
      if (token != null && token.isNotEmpty) {
        // ✅ USE THIS IN PRODUCTION
        headers['Authorization'] = 'Bearer $token';



        // ❌ TESTING ONLY (uncomment to force 401)
        // headers['Authorization'] = 'Bearer INVALID_TOKEN';
      }
    }

    return headers;
  }

  // ================= CORE REQUEST =================

  static Future<http.Response> _makeRequest(
      String method,
      String endpoint, {
        Map<String, dynamic>? body,
        bool includeAuth = true,
      }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(includeAuth: includeAuth);

    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw UnsupportedError('Unsupported HTTP method');
      }

      // 🔥 SESSION EXPIRED — SILENT HANDLING
      if (response.statusCode == 401) {
        await _handleSessionExpired();
        throw SessionExpiredException();
      }

      return response;
    } on SocketException {
      throw Exception('No internet connection');
    }
  }

  // ================= AUTH =================

  static Future<LoginResponse> login(String phoneNumber, String name) async {
    final response = await _makeRequest(
      'POST',
      '/api/users/login',
      body: {
        'phone_number': phoneNumber,
        'name': name,
      },
      includeAuth: false,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final loginResponse = LoginResponse.fromJson(data['data']);
      await saveAuthToken(loginResponse.token);
      await saveUserId(loginResponse.user.id);
      return loginResponse;
    }

    throw Exception(data['message'] ?? 'Login failed');
  }

  // ================= RIDES =================

  static Future<RideRequestResponse> requestRide(
    String pickupAddress, {
    int requiredTimeHours = 2,
  }) async {
    try {
      // Check if user is authenticated before making request
      if (!await isAuthenticated()) {
        throw Exception('Please login to request a ride');
      }

      final response = await _makeRequest(
        'POST',
        '/api/users/rides/request',
        body: {
          'pickup_address': pickupAddress,
          'required_time_hours': requiredTimeHours,
        },
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return RideRequestResponse.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Ride request failed');
        }
      } else {
        throw Exception('Ride request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ride request error: $e');
    }
  }

  static Future<Ride> getRideStatus(String rideId) async {
    final response = await _makeRequest(
      'GET',
      '/api/users/rides/$rideId/status',
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Ride.fromJson(data['data']['ride']);
    }

    throw Exception(data['message'] ?? 'Failed to get ride status');
  }

  static Future<RideHistoryResponse> getRideHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _makeRequest(
      'GET',
      '/api/users/rides/history?limit=$limit&offset=$offset',
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return RideHistoryResponse.fromJson(data['data']);
    }

    throw Exception(data['message'] ?? 'Failed to get ride history');
  }

  // ================= NOTIFICATIONS =================

  static Future<NotificationsResponse> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _makeRequest(
      'GET',
      '/api/users/notifications?limit=$limit&offset=$offset',
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return NotificationsResponse.fromJson(data['data']);
    }

    throw Exception(data['message'] ?? 'Failed to get notifications');
  }

  // ================= PROFILE =================

  static Future<UserProfile> getUserProfile() async {
    final response = await _makeRequest(
      'GET',
      '/api/users/profile',
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return UserProfile.fromJson(data['data']['user']);
    }

    throw Exception(data['message'] ?? 'Failed to get user profile');
  }

  // ================= CANCEL =================

  static Future<void> cancelRide(String rideId) async {
    final response = await _makeRequest(
      'DELETE',
      '/api/users/rides/$rideId',
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to cancel ride');
    }
  }
}
