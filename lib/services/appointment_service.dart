import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/seat_model.dart';

class AppointmentService {
  static const String _baseUrl =
      'https://aiot.fzu.edu.cn/api/ibs/spaceAppoint/app';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': data['code'] == '0',
        'message': data['msg'] ?? '未知错误',
        'data': data['dataList'] ?? data['data'],
      };
    } else {
      return {
        'success': false,
        'message': '网络错误(${response.statusCode})',
        'data': null,
      };
    }
  }

  Future<Map<String, dynamic>> createAppointment({
    required String spaceId,
    required String date,
    required String beginTime,
    required String endTime,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token无效，请重新登录', 'data': null};
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/addSpaceAppoint'),
        headers: {'Content-Type': 'application/json', 'token': token},
        body: jsonEncode({
          'spaceId': spaceId,
          'beginTime': beginTime,
          'endTime': endTime,
          'date': date,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': '请求失败: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> querySeatStatus({
    required String beginTime,
    required String endTime,
    required String floor,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': '请先登录', 'data': null};
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/queryStationStatusByTime'),
        headers: {'token': token, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'beginTime': beginTime,
          'endTime': endTime,
          'floorLike': floor,
          'parentId': null,
          'region': 1,
        }),
      );

      final result = _handleResponse(response);
      if (result['success'] && result['data'] != null) {
        final List<dynamic> dataList = result['data'];
        final seats =
            dataList
                .where((item) => !item['spaceName'].toString().contains('-'))
                .map((item) => SeatModel.fromJson(item))
                .toList();
        return {'success': true, 'message': '查询成功', 'data': seats};
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': '请求失败: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> queryAllFloorSeats({
    required String date,
    required String beginTime,
    required String endTime,
  }) async {
    List<SeatModel> allSeats = [];

    for (String floor in ['4', '5']) {
      final dateTime = '$date $beginTime';
      final endDateTime = '$date $endTime';

      final result = await querySeatStatus(
        beginTime: dateTime,
        endTime: endDateTime,
        floor: floor,
      );

      if (result['success'] && result['data'] != null) {
        final List<SeatModel> seats = result['data'];
        allSeats.addAll(seats);
      }
    }

    allSeats.sort(
      (a, b) => int.parse(a.spaceName).compareTo(int.parse(b.spaceName)),
    );

    if (allSeats.isNotEmpty) {
      return {'success': true, 'message': '查询成功', 'data': allSeats};
    } else {
      return {'success': false, 'message': '未查询到座位信息', 'data': null};
    }
  }
}
