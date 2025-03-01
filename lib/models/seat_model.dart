class SeatModel {
  final String id;
  final String spaceCode;
  final String spaceName;
  final String floor;
  final int spaceStatus;

  SeatModel({
    required this.id,
    required this.spaceCode,
    required this.spaceName,
    required this.floor,
    required this.spaceStatus,
  });

  factory SeatModel.fromJson(Map<String, dynamic> json) {
    return SeatModel(
      id: json['id']?.toString() ?? '',
      spaceCode: json['spaceCode']?.toString() ?? '',
      spaceName: json['spaceName']?.toString() ?? '',
      floor: json['floor']?.toString() ?? '',
      spaceStatus: json['spaceStatus'] ?? 1,
    );
  }

  bool get isFree => spaceStatus == 0;

  bool get isSingleSeat {
    final seatNum = int.tryParse(spaceName) ?? 0;
    return seatNum >= 205 && seatNum <= 476;
  }
}
