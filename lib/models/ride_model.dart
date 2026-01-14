class Ride {
  final String id;
  final String status;
  final String pickupAddress;
  final String? dropAddress;
  final DateTime requestedAt;
  final DateTime? assignedAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationMinutes;
  final String totalFare;

  Ride({
    required this.id,
    required this.status,
    required this.pickupAddress,
    this.dropAddress,
    required this.requestedAt,
    this.assignedAt,
    this.startedAt,
    this.endedAt,
    this.durationMinutes,
    required this.totalFare,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      pickupAddress: json['pickup_address'] as String? ?? '',
      dropAddress: json['drop_address'] as String?,
      requestedAt: DateTime.parse(json['requested_at'] as String? ?? DateTime.now().toIso8601String()),
      assignedAt: json['assigned_at'] != null ? DateTime.parse(json['assigned_at']) : null,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      durationMinutes: json['duration_minutes'] as int?,
      totalFare: json['total_fare'] as String? ?? '0.00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'pickup_address': pickupAddress,
      if (dropAddress != null) 'drop_address': dropAddress,
      'requested_at': requestedAt.toIso8601String(),
      if (assignedAt != null) 'assigned_at': assignedAt!.toIso8601String(),
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (endedAt != null) 'ended_at': endedAt!.toIso8601String(),
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      'total_fare': totalFare,
    };
  }
}

class RideHistoryResponse {
  final List<Ride> rides;
  final int total;
  final int limit;
  final int offset;

  RideHistoryResponse({
    required this.rides,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory RideHistoryResponse.fromJson(Map<String, dynamic> json) {
    final ridesList = <Ride>[];
    if (json['rides'] != null) {
      final ridesJson = json['rides'] as List;
      for (final rideJson in ridesJson) {
        ridesList.add(Ride.fromJson(rideJson as Map<String, dynamic>));
      }
    }

    return RideHistoryResponse(
      rides: ridesList,
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 20,
      offset: json['offset'] as int? ?? 0,
    );
  }
}

class RideRequestResponse {
  final Ride ride;
  final String message;

  RideRequestResponse({
    required this.ride,
    required this.message,
  });

  factory RideRequestResponse.fromJson(Map<String, dynamic> json) {
    return RideRequestResponse(
      ride: Ride.fromJson(json['ride'] as Map<String, dynamic>),
      message: json['message'] as String? ?? '',
    );
  }
}
