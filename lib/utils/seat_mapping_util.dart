import 'package:flutter/services.dart';

class SeatMappingUtil {
  static final Map<String, String> _seatMap = {};
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final String csvData = await rootBundle.loadString(
        'assets/seatIdReferenceTable.csv',
      );
      final List<String> lines = csvData.split('\n');
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isNotEmpty) {
          final parts = line.split(',');
          if (parts.length >= 3) {
            _seatMap[parts[2]] = parts[0];
          }
        }
      }
      _isInitialized = true;
    } catch (e) {
      print('加载座位数据失败: $e');
    }
  }

  static String? convertSeatNameToId(String seatName) {
    final normalizedSeatName = int.tryParse(seatName)?.toString() ?? seatName;
    return _seatMap[normalizedSeatName];
  }

  static Map<String, String> get seatMap => Map.unmodifiable(_seatMap);
}
