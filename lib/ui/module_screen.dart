import 'package:flutter/material.dart';

import '../core/progress_store.dart';
import '../core/theme.dart';
import '../models/activity.dart';
import 'activity_launcher.dart';
import 'widgets.dart';

class ModuleScreen extends StatelessWidget {
  const ModuleScreen({super.key, required this.module});

  final LabModule module;

  @override
  Widget build(BuildContext context) {
    final store = ProgressStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(module.title)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              InfoPanel(
                accent: Blueprint.link,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Objetivo del módulo',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(module.goal,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Blueprint.muted,
                            height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionTitle('Actividades'),
              ...module.activities.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ActivityTile(activity: a, store: store),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, required this.store});

  final Activity activity;
  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    final result = store.resultFor(activity.id);
    final ratio = result?.ratio ?? 0;
    final passed = result?.passed ?? false;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => openActivity(context, activity),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Blueprint.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: passed ? Blueprint.ok.withOpacity(0.5) : Blueprint.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(iconFor(activity.kind),
                    size: 19,
                    color: passed ? Blueprint.ok : Blueprint.teal),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.title,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(activity.summary,
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: Blueprint.muted,
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Tag(labelFor(activity.kind)),
                const SizedBox(width: 6),
                _Tag('${activity.minutes} min'),
                const Spacer(),
                if (result != null)
                  MonoText('${result.score}/${result.max}',
                      color: passed ? Blueprint.ok : Blueprint.key, size: 12)
                else
                  const Text('Sin intentos',
                      style: TextStyle(fontSize: 12, color: Blueprint.muted)),
              ],
            ),
            if (result != null) ...[
              const SizedBox(height: 10),
              ProgressBar(
                value: ratio,
                height: 4,
                color: passed ? Blueprint.ok : Blueprint.key,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Blueprint.surfaceHigh,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Blueprint.line),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 11, color: Blueprint.muted)),
    );
  }
}
