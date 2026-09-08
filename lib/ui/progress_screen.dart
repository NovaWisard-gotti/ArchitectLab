import 'package:flutter/material.dart';

import '../content/catalog.dart';
import '../core/progress_store.dart';
import '../core/theme.dart';
import '../models/activity.dart';
import 'activity_launcher.dart';
import 'widgets.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ProgressStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final scores = _competencyScores(store);
        final pending = _pendingActivities(store);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Progreso'),
            actions: [
              IconButton(
                tooltip: 'Reiniciar progreso',
                onPressed: () => _confirmReset(context, store),
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              const SectionTitle('Competencias del curso'),
              const Text(
                'Cada actividad aporta a una o mas competencias. El porcentaje '
                'refleja el mejor intento registrado.',
                style: TextStyle(
                    fontSize: 13, color: Blueprint.muted, height: 1.45),
              ),
              const SizedBox(height: 16),
              ...Curriculum.competencies.map((c) {
                final data = scores[c] ?? const [0, 0];
                final earned = data[0];
                final total = data[1];
                final ratio = total == 0 ? 0.0 : earned / total;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(c,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500)),
                          ),
                          MonoText('$earned/$total',
                              color: Blueprint.muted, size: 12),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ProgressBar(
                        value: ratio,
                        color: ratio >= 0.7
                            ? Blueprint.ok
                            : ratio >= 0.4
                                ? Blueprint.key
                                : Blueprint.danger,
                        label: '${(ratio * 100).round()}%',
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),
              const SectionTitle('Siguiente paso sugerido'),
              if (pending.isEmpty)
                const InfoPanel(
                  accent: Blueprint.ok,
                  child: Text(
                    'Completaste todas las actividades con al menos 70%. '
                    'Vuelve a los laboratorios de diseno y compara tu modelo '
                    'actual con el primero que hiciste.',
                    style: TextStyle(fontSize: 13.5, height: 1.5),
                  ),
                )
              else
                ...pending.take(3).map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => openActivity(context, a),
                          child: InfoPanel(
                            accent: Blueprint.teal,
                            child: Row(
                              children: [
                                Icon(iconFor(a.kind),
                                    size: 18, color: Blueprint.teal),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(a.title,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 3),
                                      Text(
                                        Curriculum.moduleOf(a.id)?.title ?? '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Blueprint.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    size: 18, color: Blueprint.muted),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  static Map<String, List<int>> _competencyScores(ProgressStore store) {
    final map = <String, List<int>>{};
    for (final a in Curriculum.allActivities) {
      final result = store.resultFor(a.id);
      for (final c in a.competencies) {
        final current = map[c] ?? [0, 0];
        current[0] += result?.score ?? 0;
        current[1] += a.maxScore;
        map[c] = current;
      }
    }
    return map;
  }

  static List<Activity> _pendingActivities(ProgressStore store) {
    return Curriculum.allActivities.where((a) {
      final r = store.resultFor(a.id);
      return r == null || !r.passed;
    }).toList();
  }

  static Future<void> _confirmReset(
      BuildContext context, ProgressStore store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reiniciar progreso'),
        content: const Text(
          'Se borraran los puntajes y los borradores de diagramas y consultas '
          'guardados en este dispositivo. Esta accion no se puede deshacer.',
          style: TextStyle(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await store.resetAll();
    }
  }
}
