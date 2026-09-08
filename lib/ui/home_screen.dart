import 'package:flutter/material.dart';

import '../content/catalog.dart';
import '../core/progress_store.dart';
import '../core/theme.dart';
import '../models/activity.dart';
import 'module_screen.dart';
import 'progress_screen.dart';
import 'widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ProgressStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final earned = _earnedPoints(store);
        final total = Curriculum.totalPoints;
        final ratio = total == 0 ? 0.0 : earned / total;
        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header(ratio: ratio, earned: earned, total: total)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final module = Curriculum.modules[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ModuleCard(
                            module: module,
                            index: index + 1,
                            store: store,
                          ),
                        );
                      },
                      childCount: Curriculum.modules.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static int _earnedPoints(ProgressStore store) {
    var sum = 0;
    for (final a in Curriculum.allActivities) {
      final r = store.resultFor(a.id);
      if (r != null) sum += r.score;
    }
    return sum;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.ratio, required this.earned, required this.total});

  final double ratio;
  final int earned;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Database Architect Lab',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w700, height: 1.1),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Disena, descompon y consulta. Cada ejercicio se corrige '
                      'contra la estructura, no contra un texto.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Blueprint.muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Progreso por competencia',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const ProgressScreen()),
                ),
                icon: const Icon(Icons.insights_outlined),
              ),
            ],
          ),
          const SizedBox(height: 18),
          InfoPanel(
            accent: Blueprint.teal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Avance del laboratorio',
                          style: TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w600)),
                    ),
                    MonoText('$earned / $total pts', color: Blueprint.muted, size: 12),
                  ],
                ),
                const SizedBox(height: 10),
                ProgressBar(value: ratio, label: '${(ratio * 100).round()}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.index,
    required this.store,
  });

  final LabModule module;
  final int index;
  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    var earned = 0;
    var total = 0;
    var done = 0;
    for (final a in module.activities) {
      total += a.maxScore;
      final r = store.resultFor(a.id);
      if (r != null) {
        earned += r.score;
        if (r.passed) done++;
      }
    }
    final ratio = total == 0 ? 0.0 : earned / total;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ModuleScreen(module: module)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Blueprint.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Blueprint.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Blueprint.surfaceHigh,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Blueprint.line),
                  ),
                  child: MonoText('$index',
                      color: done == module.activities.length
                          ? Blueprint.ok
                          : Blueprint.muted,
                      size: 13),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(module.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(module.subtitle,
                          style: const TextStyle(
                              fontSize: 13, color: Blueprint.muted)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Blueprint.muted, size: 20),
              ],
            ),
            const SizedBox(height: 14),
            ProgressBar(
              value: ratio,
              color: ratio >= 0.7 ? Blueprint.ok : Blueprint.teal,
              label: '$done/${module.activities.length}',
            ),
          ],
        ),
      ),
    );
  }
}
