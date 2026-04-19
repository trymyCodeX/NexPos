class NotificationInfo {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String? createdAt;

  NotificationInfo({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationInfo.fromJson(Map<String, dynamic> json) => NotificationInfo(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        type: json['type'] ?? 'info',
        isRead: json['isRead'] ?? false,
        createdAt: json['createdAt'],
      );
}
