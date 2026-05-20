// lib/state/notifiers/run_session_notifier.dart
//
// Este é o componente central do projeto:
// demonstra como o estado de uma sessão de corrida
// é gerenciado e preservado ao longo do ciclo de vida do app.

import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/run_model.dart';
import '../../data/models/run_session.dart';
import '../../data/repositories/run_repository.dart';

// ──────────────────────────────────────────────
// Providers
// ──────────────────────────────────────────────

final runRepositoryProvider = Provider<RunRepository>((ref) {
  final repo = RunRepository();
  ref.onDispose(repo.close);
  return repo;
});

final runSessionProvider =
    StateNotifierProvider<RunSessionNotifier, RunSession>((ref) {
  final repo = ref.watch(runRepositoryProvider);
  return RunSessionNotifier(repo);
});

final runHistoryProvider =
    FutureProvider<List<RunModel>>((ref) async {
  final repo = ref.watch(runRepositoryProvider);
  return repo.getAllRuns();
});

final runStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(runHistoryProvider); // recomputa quando histórico muda
  final repo = ref.watch(runRepositoryProvider);
  return repo.getStats();
});

// ──────────────────────────────────────────────
// Notifier principal
// ──────────────────────────────────────────────

class RunSessionNotifier extends StateNotifier<RunSession>
    with WidgetsBindingObserver {
  final RunRepository _repository;
  Timer? _ticker;
  Timer? _gpsTicker;

  // Simula incremento de GPS a cada 2 segundos
  // Em produção: substituir por stream do geolocator
  final _rng = Random();

  RunSessionNotifier(this._repository) : super(const RunSession()) {
    // CICLO DE VIDA: registra o observer para receber
    // notificações de mudança de estado do app
    WidgetsBinding.instance.addObserver(this);
  }

  // ──────────────────────────────────────────────
  // CICLO DE VIDA — AppLifecycleState
  // Este método é chamado automaticamente pelo Flutter
  // quando o app muda de estado (background, foreground, etc.)
  // ──────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    switch (appState) {
      // App voltou ao foreground
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;

      // App foi para background (tela bloqueada, outro app, etc.)
      case AppLifecycleState.paused:
        _onAppPaused();
        break;

      // App está sendo encerrado
      case AppLifecycleState.detached:
        _onAppDetached();
        break;

      // App está parcialmente visível (notificação, split screen)
      case AppLifecycleState.inactive:
        // Mantém estado — transição temporária
        break;

      case AppLifecycleState.hidden:
        break;
    }
  }

  void _onAppResumed() {
    // Se havia corrida ativa antes de ir pro background,
    // retoma os timers — o tempo acumulado é preservado no state
    if (state.isActive) {
      _startTicker();
      _startGpsTicker();
    }
  }

  void _onAppPaused() {
    // Para os timers para economizar bateria,
    // mas NÃO muda o status da corrida — ela continua "running"
    // O tempo acumulado já está salvo no state
    if (state.isActive) {
      _stopTicker();
      _stopGpsTicker();
      // Nota acadêmica: em produção, um ForegroundService
      // continuaria incrementando o tempo em background
    }
  }

  void _onAppDetached() {
    _stopTicker();
    _stopGpsTicker();
  }

  // ──────────────────────────────────────────────
  // Ações do usuário
  // ──────────────────────────────────────────────

  void startRun() {
    if (!state.isIdle) return;
    state = state.copyWith(
      status: RunStatus.running,
      startTime: DateTime.now(),
      elapsedSeconds: 0,
      distanceKm: 0,
      paceHistory: [],
    );
    _startTicker();
    _startGpsTicker();
  }

  void pauseRun() {
    if (!state.isActive) return;
    _stopTicker();
    _stopGpsTicker();
    state = state.copyWith(
      status: RunStatus.paused,
      pausedAt: DateTime.now(),
    );
  }

  void resumeRun() {
    if (!state.isPaused) return;
    state = state.copyWith(
      status: RunStatus.running,
      pausedAt: null,
    );
    _startTicker();
    _startGpsTicker();
  }

  Future<void> finishRun() async {
    if (state.isIdle || state.isFinished) return;
    _stopTicker();
    _stopGpsTicker();

    final run = RunModel(
      id: const Uuid().v4(),
      startTime: state.startTime ?? DateTime.now(),
      endTime: DateTime.now(),
      distanceKm: state.distanceKm,
      durationSeconds: state.elapsedSeconds,
      avgPaceMinPerKm: state.currentPaceMinPerKm,
      route: [],
    );

    await _repository.saveRun(run);

    state = state.copyWith(status: RunStatus.finished);
  }

  void resetRun() {
    state = const RunSession();
  }

  // ──────────────────────────────────────────────
  // Timers internos
  // ──────────────────────────────────────────────

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isActive) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _startGpsTicker() {
    _gpsTicker?.cancel();
    // Simula atualização de GPS a cada 2 segundos
    // Incremento aleatório entre 15m e 35m por tick (corrida ~5-6min/km)
    _gpsTicker = Timer.periodic(const Duration(seconds: 2), (_) {
      if (state.isActive) {
        final increment = (0.015 + _rng.nextDouble() * 0.020); // km
        final newDistance = state.distanceKm + increment;

        // Registra pace ao completar cada km
        final prevKm = state.distanceKm.floor();
        final newKm = newDistance.floor();
        List<double> newPaceHistory = List.from(state.paceHistory);
        if (newKm > prevKm && state.elapsedSeconds > 0) {
          final pace = (state.elapsedSeconds / 60) / newDistance;
          newPaceHistory.add(pace);
        }

        state = state.copyWith(
          distanceKm: newDistance,
          paceHistory: newPaceHistory,
        );
      }
    });
  }

  void _stopGpsTicker() {
    _gpsTicker?.cancel();
    _gpsTicker = null;
  }

  // ──────────────────────────────────────────────
  // Dispose
  // ──────────────────────────────────────────────

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTicker();
    _stopGpsTicker();
    super.dispose();
  }
}
