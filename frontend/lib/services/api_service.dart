import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reminder.dart';

class ApiService {
  String baseUrl;

  ApiService({this.baseUrl = 'https://eazzio-reminder.onrender.com/api'});

  // Fetch all reminders
  Future<List<Reminder>> getReminders({int? userId}) async {
    final uri = userId != null
        ? Uri.parse('$baseUrl/reminders?userId=$userId')
        : Uri.parse('$baseUrl/reminders');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => Reminder.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reminders: ${response.body}');
    }
  }

  // Create a reminder
  Future<Reminder> createReminder(Reminder reminder) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reminders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(reminder.toJson()),
    );
    if (response.statusCode == 201) {
      return Reminder.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create reminder: ${response.body}');
    }
  }

  // Update a reminder
  Future<Reminder> updateReminder(Reminder reminder) async {
    if (reminder.id == null) throw Exception('Reminder ID is required for update');
    final response = await http.put(
      Uri.parse('$baseUrl/reminders/${reminder.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(reminder.toJson()),
    );
    if (response.statusCode == 200) {
      return Reminder.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update reminder: ${response.body}');
    }
  }

  // Delete a reminder
  Future<void> deleteReminder(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/reminders/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete reminder: ${response.body}');
    }
  }

  // Fetch pending approvals
  Future<List<Reminder>> getApprovals() async {
    final response = await http.get(Uri.parse('$baseUrl/approvals'));
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => Reminder.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load approvals: ${response.body}');
    }
  }

  // Approve a reminder
  Future<Map<String, dynamic>> approveReminder(int id) async {
    final response = await http.post(Uri.parse('$baseUrl/approvals/$id/approve'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to approve reminder: ${response.body}');
    }
  }

  // Reject a reminder
  Future<void> rejectReminder(int id) async {
    final response = await http.post(Uri.parse('$baseUrl/approvals/$id/reject'));
    if (response.statusCode != 200) {
      throw Exception('Failed to reject reminder: ${response.body}');
    }
  }

  // Fetch history logs
  Future<List<ReminderLog>> getHistory() async {
    final response = await http.get(Uri.parse('$baseUrl/history'));
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => ReminderLog.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load history logs: ${response.body}');
    }
  }

  // Trigger background scheduler check manually (for quick testing)
  Future<void> triggerScheduler() async {
    final response = await http.post(Uri.parse('$baseUrl/test-trigger-scheduler'));
    if (response.statusCode != 200) {
      throw Exception('Failed to trigger scheduler check: ${response.body}');
    }
  }

  // Force test send a reminder immediately
  Future<void> testSendReminder(int id) async {
    final response = await http.post(Uri.parse('$baseUrl/reminders/$id/test-send'));
    if (response.statusCode != 200) {
      throw Exception('Failed to test send reminder: ${response.body}');
    }
  }

  // Login/Register
  Future<Map<String, dynamic>> login(String name, String? email, String? phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'phone': phone}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  // Password sign-in (email or phone)
  Future<Map<String, dynamic>> loginWithPassword(String identifier, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier, 'password': password}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Sign in failed');
    }
  }

  // Password sign-up
  Future<Map<String, dynamic>> signupWithPassword(String name, String phone, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'phone': phone, 'password': password}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Sign up failed');
    }
  }

  // Reset Password
  Future<void> resetPassword(String identifier, String name, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier, 'name': name, 'newPassword': newPassword}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Reset password failed');
    }
  }


  // Search users
  Future<List<dynamic>> searchUsers(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/users/search?query=${Uri.encodeComponent(query)}'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Search failed: ${response.body}');
    }
  }

  // Send team request
  Future<void> sendTeamRequest(int senderId, String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/teams/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'senderId': senderId, 'email': email}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to send team request');
    }
  }

  // Get team requests
  Future<Map<String, dynamic>> getTeamRequests(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/teams/requests?userId=$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch team requests');
    }
  }

  // Respond to request
  Future<void> respondToTeamRequest(int requestId, String status) async {
    final response = await http.post(
      Uri.parse('$baseUrl/teams/requests/$requestId/respond'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to respond to team request');
    }
  }

  // Get team members
  Future<List<dynamic>> getTeamMembers(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/teams/members?userId=$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to fetch team members');
    }
  }
}
