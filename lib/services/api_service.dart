import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ride_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

class ApiService {
  static const String baseUrl = 'https://api.lenienttree.org'; // Replace with actual base URL
  
  static const String _tokenKey = 'user_token';
  static const String _userIdKey = 'user_id';

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

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
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

  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(includeAuth: includeAuth);

    print('=== API REQUEST ===');
    print('Method: $method');
    print('URL: $url');
    print('Headers: $headers');
    if (body != null) {
      print('Body: ${jsonEncode(body)}');
    }
    print('Include Auth: $includeAuth');

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
          throw UnsupportedError('HTTP method $method is not supported');
      }

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==================');

      // Handle 401 Unauthorized specifically
      if (response.statusCode == 401) {
        await clearAuthData(); // Clear invalid token
        throw Exception('Authentication failed. Please login again.');
      }

      return response;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('Server error');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<LoginResponse> login(String phoneNumber, String name) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/api/users/login',
        body: {
          'phone_number': phoneNumber,
          'name': name,
        },
        includeAuth: false,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final loginResponse = LoginResponse.fromJson(responseData['data']);
          await saveAuthToken(loginResponse.token);
          await saveUserId(loginResponse.user.id);
          return loginResponse;
        } else {
          throw Exception(responseData['message'] ?? 'Login failed');
        }
      } else {
        throw Exception('Login failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  static Future<RideRequestResponse> requestRide(
    String pickupAddress,
    String dropAddress,
  ) async {
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
          'drop_address': dropAddress,
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
    try {
      final response = await _makeRequest(
        'GET',
        '/api/users/rides/$rideId/status',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Ride.fromJson(responseData['data']['ride']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to get ride status');
        }
      } else {
        throw Exception('Failed to get ride status with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get ride status error: $e');
    }
  }

  static Future<RideHistoryResponse> getRideHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _makeRequest(
        'GET',
        '/api/users/rides/history?limit=$limit&offset=$offset',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return RideHistoryResponse.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to get ride history');
        }
      } else {
        throw Exception('Failed to get ride history with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get ride history error: $e');
    }
  }

  static Future<NotificationsResponse> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _makeRequest(
        'GET',
        '/api/users/notifications?limit=$limit&offset=$offset',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return NotificationsResponse.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to get notifications');
        }
      } else {
        throw Exception('Failed to get notifications with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get notifications error: $e');
    }
  }

  static Future<UserProfile> getUserProfile() async {
    try {
      final response = await _makeRequest(
        'GET',
        '/api/users/profile',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return UserProfile.fromJson(responseData['data']['user']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to get user profile');
        }
      } else {
        throw Exception('Failed to get user profile with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get user profile error: $e');
    }
  }

  static Future<void> cancelRide(String rideId) async {
    try {
      final response = await _makeRequest(
        'DELETE',
        '/api/users/rides/$rideId',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] != true) {
          throw Exception(responseData['message'] ?? 'Failed to cancel ride');
        }
      } else {
        throw Exception('Failed to cancel ride with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Cancel ride error: $e');
    }
  }
}
