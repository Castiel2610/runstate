// lib/data/models/run_model.dart

class RunModel {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceKm;
  final int durationSeconds;
  final double avgPaceMinPerKm;
  final List<GpsPoint> route;

  const RunModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.durationSeconds,
    required this.avgPaceMinPerKm,
    required this.route,
  });

  double get avgSpeedKmh =>
      durationSeconds > 0 ? (distanceKm / durationSeconds) * 3600 : 0;

  String get formattedDuration {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }

  String get formattedPace {
    if (avgPaceMinPerKm == 0 || avgPaceMinPerKm.isInfinite) return '--:--';
    final min = avgPaceMinPerKm.floor();
    final sec = ((avgPaceMinPerKm - min) * 60).round();
    return '$min:${sec.toString().padLeft(2, '0')} /km';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'distanceKm': distanceKm,
        'durationSeconds': durationSeconds,
        'avgPaceMinPerKm': avgPaceMinPerKm,
        'route': route.map((p) => p.toMap()).toList().toString(),
      };

  factory RunModel.fromMap(Map<String, dynamic> map) => RunModel(
        id: map['id'] as String,
        startTime: DateTime.parse(map['startTime'] as String),
        endTime: DateTime.parse(map['endTime'] as String),
        distanceKm: (map['distanceKm'] as num).toDouble(),
        durationSeconds: map['durationSeconds'] as int,
        avgPaceMinPerKm: (map['avgPaceMinPerKm'] as num).toDouble(),
        route: [],
      );
}

class GpsPoint {
  final double lat;
  final double lng;
  final DateTime timestamp;

  const GpsPoint({
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'timestamp': timestamp.toIso8601String(),
      };
}
