// lib/ui/screens/run_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/run_session.dart';
import '../../state/notifiers/run_session_notifier.dart';

class RunScreen extends ConsumerWidget {
  const RunScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(runSessionProvider);
    final notifier = ref.read(runSessionProvider.notifier);

    // Se finalizou, pop e invalida histórico
    ref.listen(runSessionProvider, (prev, next) {
      if (next.isFinished && (prev?.isFinished == false)) {
        ref.invalidate(runHistoryProvider);
        ref.invalidate(runStatsProvider);
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      backgroundColor: _bgColor(session.status),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: session.isIdle
              ? _IdleView(onStart: notifier.startRun)
              : _ActiveView(session: session, notifier: notifier),
        ),
      ),
    );
  }

  Color _bgColor(RunStatus status) {
    return switch (status) {
      RunStatus.running => const Color(0xFF0F172A),
      RunStatus.paused => const Color(0xFF1C1917),
      RunStatus.finished => const Color(0xFF052E16),
      RunStatus.idle => AppTheme.surface,
    };
  }
}

// ──────────────────────────────────────────────────────
// View inicial (antes de iniciar)
// ──────────────────────────────────────────────────────
class _IdleView extends StatelessWidget {
  final VoidCallback onStart;
  const _IdleView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Icon(Icons.directions_run_rounded,
              size: 64, color: AppTheme.primary),
          const SizedBox(height: 24),
          Text(
            'Pronto para\ncorrer?',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 40,
                  color: const Color(0xFF1A1A2E),
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'O app rastreia sua corrida mesmo com a\ntela bloqueada ou em background.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(height: 1.6),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onStart,
            child: const Text('Iniciar'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// View durante corrida (running / paused)
// ──────────────────────────────────────────────────────
class _ActiveView extends StatelessWidget {
  final RunSession session;
  final RunSessionNotifier notifier;

  const _ActiveView({required this.session, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final isPaused = session.isPaused;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // ── Status bar ──────────────────────────
          Row(
            children: [
              _StatusPill(isPaused: isPaused),
              const Spacer(),
              if (!isPaused)
                _LifecycleHint(text: 'Estado: running'),
              if (isPaused)
                _LifecycleHint(text: 'Estado: paused', isWarning: true),
            ],
          ),
          const Spacer(),

          // ── Timer principal ──────────────────────
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w700,
              letterSpacing: -4,
              color: isPaused
                  ? Colors.white.withOpacity(0.4)
                  : Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            child: Text(session.formattedElapsed),
          ),

          const SizedBox(height: 8),
          Text(
            'tempo decorrido',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.4),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 48),

          // ── Métricas secundárias ─────────────────
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'distância',
                  value: session.formattedDistance,
                ),
              ),
              Container(
                width: 0.5,
                height: 48,
                color: Colors.white.withOpacity(0.15),
              ),
              Expanded(
                child: _MetricTile(
                  label: 'pace atual',
                  value: session.formattedPace,
                  suffix: '/km',
                ),
              ),
            ],
          ),

          const Spacer(),

          // ── Controles ───────────────────────────
          Row(
            children: [
              // Botão finalizar
              _RoundButton(
                icon: Icons.stop_rounded,
                color: Colors.white.withOpacity(0.12),
                iconColor: Colors.white.withOpacity(0.6),
                onTap: () => _confirmFinish(context),
              ),
              const SizedBox(width: 16),

              // Botão principal: pausar / retomar
              Expanded(
                child: GestureDetector(
                  onTap: isPaused ? notifier.resumeRun : notifier.pauseRun,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 64,
                    decoration: BoxDecoration(
                      color: isPaused
                          ? AppTheme.warning
                          : AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isPaused ? 'Retomar' : 'Pausar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Nota sobre ciclo de vida ─────────────
          _LifecycleNote(isPaused: isPaused),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _confirmFinish(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Finalizar corrida?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A corrida será salva no histórico.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                          color: Colors.white.withOpacity(0.2)),
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      notifier.finishRun();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Finalizar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// Widgets auxiliares
// ──────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final bool isPaused;
  const _StatusPill({required this.isPaused});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isPaused ? AppTheme.warning : AppTheme.success)
            .withOpacity(0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isPaused)
            _PulsingDot(color: AppTheme.success),
          if (isPaused)
            const Icon(Icons.pause_circle_rounded,
                size: 12, color: AppTheme.warning),
          const SizedBox(width: 6),
          Text(
            isPaused ? 'Pausado' : 'Correndo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isPaused ? AppTheme.warning : AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;

  const _MetricTile({required this.label, required this.value, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.4),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 2),
              Text(
                suffix!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }
}

class _LifecycleHint extends StatelessWidget {
  final String text;
  final bool isWarning;
  const _LifecycleHint({required this.text, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isWarning ? AppTheme.warning : Colors.white).withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isWarning ? AppTheme.warning : Colors.white).withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: (isWarning ? AppTheme.warning : Colors.white).withOpacity(0.6),
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _LifecycleNote extends StatelessWidget {
  final bool isPaused;
  const _LifecycleNote({required this.isPaused});

  @override
  Widget build(BuildContext context) {
    final text = isPaused
        ? 'Timer pausado. Estado preservado via StateNotifier.'
        : 'Minimizar o app para o background preserva o estado.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Colors.white.withOpacity(0.3),
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
