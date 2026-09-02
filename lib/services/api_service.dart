import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class ApiService {
  // FOR ANDROID EMULATOR: use 10.0.2.2
  // FOR PHYSICAL DEVICE: use your computer's IP address
  // FOR iOS SIMULATOR: use localhost
  
  // Change this based on your setup
  //static const String baseUrl = 'http://10.0.2.2:3000/api';
  static const String baseUrl = 'http://192.168.200.192:3000/api'; // For physical device
  
  static const storage = FlutterSecureStorage();
  
  // Check if patient exists in tbmaster
  static Future<Map<String, dynamic>> checkPatient(String fullName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/check-patient'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullName': fullName,
        }),
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': data['success'] ?? false,
          'patients': data['patients'] ?? [],
          'message': data['message'] ?? '',
          'error': data['error'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to search patient',
          'patients': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: $e',
        'patients': [],
      };
    }
  }
  
  // Register user with optional HospNum
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    String? hospNum,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'username': username,
        'email': email,
        'password': password,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
      };
      
      if (hospNum != null && hospNum.isNotEmpty) {
        requestBody['hospNum'] = hospNum;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        await storage.write(key: 'token', value: data['token']);
        await storage.write(key: 'userData', value: json.encode(data['user']));
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
  
  // Login user
  static Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'usernameOrEmail': usernameOrEmail,
          'password': password,
        }),
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        await storage.write(key: 'token', value: data['token']);
        await storage.write(key: 'userData', value: json.encode(data['user']));
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
  
  // Get user profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await storage.read(key: 'token');
      
      if (token == null) {
        return {'success': false, 'error': 'No token found'};
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to get profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
  
  // Update profile
  static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phoneNumber,
  }) async {
    try {
      final token = await storage.read(key: 'token');
      
      if (token == null) {
        return {'success': false, 'error': 'No token found'};
      }
      
      final Map<String, dynamic> updates = {};
      if (fullName != null) updates['fullName'] = fullName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      
      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updates),
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to update profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
  
  // Change password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await storage.read(key: 'token');
      
      if (token == null) {
        return {'success': false, 'error': 'No token found'};
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to change password'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
  
  // Logout
  static Future<void> logout() async {
    final token = await storage.read(key: 'token');
    
    if (token != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (e) {
        // Ignore logout errors
      }
    }
    
    await storage.deleteAll();
  }
  
  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'token');
    return token != null;
  }
  
  // Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final userDataString = await storage.read(key: 'userData');
    if (userDataString != null) {
      return json.decode(userDataString);
    }
    return null;
  }
  
  // Get current user as User model
  static Future<User?> getCurrentUser() async {
    final userData = await getUserData();
    if (userData != null) {
      return User.fromJson(userData);
    }
    return null;
  }

  // ============== NEW METHODS FOR PATIENT DATA ==============
  // Add this method to your ApiService class in lib/services/api_service.dart

  // Get clinical summary for a patient
  static Future<Map<String, dynamic>> getClinicalSummary(String hospNum) async {
    try {
      final token = await storage.read(key: 'token');
      
      if (token == null) {
        return {'success': false, 'error': 'No token found'};
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/clinical-summary/$hospNum'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to get clinical summary',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
  // Get patient data from tbmaster by HospNum
  static Future<Map<String, dynamic>> getPatientByHospNum(String hospNum) async {
    try {
      final token = await storage.read(key: 'token');
      
      if (token == null) {
        return {'success': false, 'error': 'No token found'};
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/patient/$hospNum'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'patient': data['patient'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to get patient data',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
  
  // Get current user with patient data combined
  static Future<Map<String, dynamic>> getCurrentUserWithPatientData() async {
    try {
      // Get user data
      final userData = await getUserData();
      if (userData == null) {
        return {'success': false, 'error': 'User not logged in'};
      }
      
      // Get patient data
      final hospNum = userData['hospNum'];
      if (hospNum == null || hospNum.isEmpty) {
        return {
          'success': true,
          'user': userData,
          'patient': null,
          'message': 'No HospNum associated with this user'
        };
      }
      
      final patientResult = await getPatientByHospNum(hospNum);
      
      return {
        'success': true,
        'user': userData,
        'patient': patientResult['success'] ? patientResult['patient'] : null,
        'message': patientResult['success'] ? 'Patient data loaded' : 'Patient data not found',
      };
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Add this method to your ApiService class

  // Get latest laboratory results
  static Future<Map<String, dynamic>> getLatestResults(String hospNum) async {
    try {
      final token = await storage.read(key: 'token');
      
      if (token == null) {
        return {'success': false, 'error': 'No token found'};
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/latest-results/$hospNum'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to get latest results',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
    // Add this method to your ApiService class in lib/services/api_service.dart

// Get doctors by category
static Future<Map<String, dynamic>> getDoctorsByCategory(int categoryId) async {
  try {
    final token = await storage.read(key: 'token');
    
    if (token == null) {
      return {'success': false, 'error': 'No token found'};
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/doctors/category/$categoryId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    final data = json.decode(response.body);
    
    if (response.statusCode == 200) {
      return {
        'success': true,
        'doctors': data['doctors'] ?? [],
      };
    } else {
      return {
        'success': false,
        'error': data['error'] ?? 'Failed to get doctors',
      };
    }
  } catch (e) {
    return {'success': false, 'error': 'Connection error: $e'};
  }
}
// Get doctors with schedule by category and day
static Future<Map<String, dynamic>> getDoctorsWithSchedule(int categoryId, {int? dayOfWeek}) async {
  try {
    final token = await storage.read(key: 'token');
    
    if (token == null) {
      return {'success': false, 'error': 'No token found'};
    }
    
    String url = '$baseUrl/doctors/with-schedule/$categoryId';
    if (dayOfWeek != null) {
      url += '?dayOfWeek=$dayOfWeek';
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    final data = json.decode(response.body);
    
    if (response.statusCode == 200) {
      return {
        'success': true,
        'doctors': data['doctors'] ?? [],
      };
    } else {
      return {
        'success': false,
        'error': data['error'] ?? 'Failed to get doctors',
      };
    }
  } catch (e) {
    return {'success': false, 'error': 'Connection error: $e'};
  }
}
}

