class Appointment {
  final String id;
  final String floor;
  final String spaceName;
  final String date;
  final String beginTime;
  final String endTime;
  final int auditStatus;
  final bool sign;

  Appointment({
    required this.id,
    required this.floor,
    required this.spaceName,
    required this.date,
    required this.beginTime,
    required this.endTime,
    required this.auditStatus,
    required this.sign,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id']?.toString() ?? '',
      floor: json['floor']?.toString() ?? '',
      spaceName: json['spaceName'] ?? '未知',
      date: json['date'] ?? '',
      beginTime: json['beginTime'] ?? '',
      endTime: json['endTime'] ?? '',
      auditStatus: json['auditStatus'] ?? 0,
      sign: json['sign'] ?? false,
    );
  }

  bool get canSignIn {
    if (auditStatus != 2 || sign) return false;

    final now = DateTime.now();
    final dateParts = date.split('-');
    final beginTimeParts = beginTime.split(':');
    final endTimeParts = endTime.split(':');

    if (dateParts.length != 3 ||
        beginTimeParts.length != 2 ||
        endTimeParts.length != 2) {
      return false;
    }

    try {
      final appointmentDate = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(beginTimeParts[0]),
        int.parse(beginTimeParts[1]),
      );

      final appointmentEndDate = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(endTimeParts[0]),
        int.parse(endTimeParts[1]),
      );

      final checkInTime = appointmentDate.subtract(const Duration(minutes: 15));

      return now.isAfter(checkInTime) && now.isBefore(appointmentEndDate);
    } catch (e) {
      return false;
    }
  }

  bool get isUpcoming {
    if (auditStatus != 2) return false;

    final now = DateTime.now();
    final dateParts = date.split('-');
    final beginTimeParts = beginTime.split(':');

    if (dateParts.length != 3 || beginTimeParts.length != 2) {
      return false;
    }

    try {
      final appointmentDate = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(beginTimeParts[0]),
        int.parse(beginTimeParts[1]),
      );

      final checkInTime = appointmentDate.subtract(const Duration(minutes: 15));

      return now.isBefore(checkInTime);
    } catch (e) {
      return false;
    }
  }

  bool get isExpired {
    if (auditStatus != 2 || sign) return false;

    final now = DateTime.now();
    final dateParts = date.split('-');
    final endTimeParts = endTime.split(':');

    if (dateParts.length != 3 || endTimeParts.length != 2) {
      return false;
    }

    try {
      final appointmentEndDate = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(endTimeParts[0]),
        int.parse(endTimeParts[1]),
      );

      return now.isAfter(appointmentEndDate);
    } catch (e) {
      return false;
    }
  }

  String getStatusText() {
    if (auditStatus == 3) {
      return '已取消';
    } else if (auditStatus == 4) {
      return '已完成';
    } else if (auditStatus == 2) {
      if (!sign) {
        if (isUpcoming) {
          return '未开始';
        } else if (isExpired) {
          return '未签到';
        } else {
          return '待签到';
        }
      } else {
        return '已签到';
      }
    } else {
      return '未知状态';
    }
  }
}
