// lib/data/models/run_session.dart

enum RunStatus { idle, running, paused, finished }

class RunSession {
  final RunStatus status;
  final DateTime? startTime;
  final DateTime? pausedAt;
  final int elapsedSeconds;
  final double distanceKm;
  final List<double> paceHistory; // pace por km completado

  const RunSession({
    this.status = RunStatus.idle,
    this.startTime,
    this.pausedAt,
    this.elapsedSeconds = 0,
    this.distanceKm = 0,
    this.paceHistory = const [],
  });

  bool get isActive => status == RunStatus.running;
  bool get isPaused => status == RunStatus.paused;
  bool get isIdle => status == RunStatus.idle;
  bool get isFinished => status == RunStatus.finished;

  double get currentPaceMinPerKm {
    if (elapsedSeconds == 0 || distanceKm == 0) return 0;
    return (elapsedSeconds / 60) / distanceKm;
  }

  String get formattedElapsed {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get formattedDistance {
    if (distanceKm >= 1) return '${distanceKm.toStringAsFixed(2)} km';
    return '${(distanceKm * 1000).toStringAsFixed(0)} m';
  }

  String get formattedPace {
    final pace = currentPaceMinPerKm;
    if (pace == 0 || pace.isInfinite || pace.isNaN) return '--:--';
    final min = pace.floor();
    final sec = ((pace - min) * 60).round();
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  RunSession copyWith({
    RunStatus? status,
    DateTime? startTime,
    DateTime? pausedAt,
    int? elapsedSeconds,
    double? distanceKm,
    List<double>? paceHistory,
  }) =>
      RunSession(
        status: status ?? this.status,
        startTime: startTime ?? this.startTime,
        pausedAt: pausedAt ?? this.pausedAt,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        distanceKm: distanceKm ?? this.distanceKm,
        paceHistory: paceHistory ?? this.paceHistory,
      );
}
