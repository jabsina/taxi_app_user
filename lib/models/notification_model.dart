class NotificationModel {
  final String id;
  final String type;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? rideId;

  NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.rideId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
      message: json['message'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      rideId: json['ride_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      if (rideId != null) 'ride_id': rideId,
    };
  }
}

class NotificationsResponse {
  final List<NotificationModel> notifications;

  NotificationsResponse({
    required this.notifications,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    final notificationsList = <NotificationModel>[];
    if (json['notifications'] != null) {
      final notificationsJson = json['notifications'] as List;
      for (final notificationJson in notificationsJson) {
        notificationsList.add(NotificationModel.fromJson(notificationJson as Map<String, dynamic>));
      }
    }

    return NotificationsResponse(
      notifications: notificationsList,
    );
  }
}
