class TrafficAlert {
  final String id;
  final String location;
  final String message;
  final String status;
  final String timeAgo;
  final String timestamp;

  const TrafficAlert({
    required this.id,
    required this.location,
    required this.message,
    required this.status,
    required this.timeAgo,
    required this.timestamp,
  });

  // Maps incoming raw JSON fields safely into Dart data types
  factory TrafficAlert.fromJson(Map<String, dynamic> json) {
    return TrafficAlert(
      id: json['id'] ?? '',
      location: json['location'] ?? 'Unknown Location',
      message: json['message'] ?? '',
      status: json['status'] ?? 'Light',
      timeAgo: json['timeAgo'] ?? 'Live',
      timestamp: json['timestamp'] ?? '',
    );
  }
}