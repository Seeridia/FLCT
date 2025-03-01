import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://aiot.fzu.edu.cn/api/ibs';

  // 获取预约历史记录
  static Future<Map<String, dynamic>> fetchAppointments({
    required int currentPage,
    required int pageSize,
    String? auditStatus,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token无效，请重新登录');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/spaceAppoint/app/queryMyAppoint'),
      headers: {'Content-Type': 'application/json', 'token': token},
      body: jsonEncode({
        'currentPage': currentPage,
        'pageSize': pageSize,
        'auditStatus': auditStatus,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('获取预约记录失败');
    }
  }

  // 签到
  static Future<Map<String, dynamic>> signIn(String appointmentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token无效，请重新登录');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/station/app/signIn'),
      headers: {'Content-Type': 'application/json', 'token': token},
      body: jsonEncode({'id': appointmentId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('签到失败，请稍后重试');
    }
  }

  // 签退
  static Future<Map<String, dynamic>> signOut(String appointmentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token无效，请重新登录');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/station/app/signOut'),
      headers: {'Content-Type': 'application/json', 'token': token},
      body: jsonEncode({'id': appointmentId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('签退失败，请稍后重试');
    }
  }

  // 取消预约
  static Future<Map<String, dynamic>> cancelAppointment(
    dynamic appointmentId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token无效，请重新登录');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/spaceAppoint/app/revocationAppointApp'),
      headers: {'Content-Type': 'application/json', 'token': token},
      body: jsonEncode({'id': appointmentId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('取消预约失败，请稍后重试');
    }
  }
}
