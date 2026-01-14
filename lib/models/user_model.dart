class User {
  final String id;
  final String name;
  final String phoneNumber;

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
    };
  }
}

class UserStats {
  final int totalRides;
  final int completedRides;
  final int totalSpent;
  final double avgFare;

  UserStats({
    required this.totalRides,
    required this.completedRides,
    required this.totalSpent,
    required this.avgFare,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalRides: json['total_rides'] as int? ?? 0,
      completedRides: json['completed_rides'] as int? ?? 0,
      totalSpent: json['total_spent'] as int? ?? 0,
      avgFare: (json['avg_fare'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_rides': totalRides,
      'completed_rides': completedRides,
      'total_spent': totalSpent,
      'avg_fare': avgFare,
    };
  }
}

class UserProfile {
  final String id;
  final String phoneNumber;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final UserStats stats;

  UserProfile({
    required this.id,
    required this.phoneNumber,
    required this.name,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
    required this.stats,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      stats: UserStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'name': name,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      if (lastLogin != null) 'last_login': lastLogin!.toIso8601String(),
      'stats': stats.toJson(),
    };
  }
}

class LoginResponse {
  final User user;
  final String token;

  LoginResponse({
    required this.user,
    required this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String? ?? '',
    );
  }
}
