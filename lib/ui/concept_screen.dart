import 'package:flutter/material.dart';

import '../core/progress_store.dart';
import '../core/theme.dart';
import '../models/activity.dart';
import 'widgets.dart';

/// Actividad de criterio: una pregunta a la vez, con explicacion inmediata.
class ConceptScreen extends StatefulWidget {
  const ConceptScreen({super.key, required this.activity});

  final ConceptActivity activity;

  @override
  State<ConceptScreen> createState() => _ConceptScreenState();
}

class _ConceptScreenState extends State<ConceptScreen> {
  int _index = 0;
  int? _selected;
  bool _revealed = false;
  int _score = 0;

  Question get _question => widget.activity.questions[_index];
  bool get _isLast => _index == widget.activity.questions.length - 1;

  void _choose(int index) {
    if (_revealed) return;
    setState(() {
      _selected = index;
      _revealed = true;
      if (_question.choices[index].correct) _score++;
    });
  }

  Future<void> _next() async {
    if (_isLast) {
      await ProgressStore.instance
          .record(widget.activity.id, _score, widget.activity.maxScore);
      if (!mounted) return;
      await showResultSheet(
        context,
        title: widget.activity.title,
        earned: _score,
        possible: widget.activity.maxScore,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.activity.questions.map((q) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.prompt,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(q.takeaway,
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: Blueprint.muted,
                          height: 1.4)),
                ],
              ),
            );
          }).toList(),
        ),
        footnote: 'Estas ideas se vuelven a usar en los laboratorios de '
            'diseno y en la consola SQL.',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.activity.questions.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ProgressBar(
              value: (_index + (_revealed ? 1 : 0)) / total,
              label: '${_index + 1}/$total',
              height: 4,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          if (_question.context.isNotEmpty) ...[
            InfoPanel(
              accent: Blueprint.link,
              child: Text(_question.context,
                  style: const TextStyle(
                      fontSize: 13, color: Blueprint.muted, height: 1.45)),
            ),
            const SizedBox(height: 14),
          ],
          Text(_question.prompt,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600, height: 1.35)),
          const SizedBox(height: 18),
          ...List.generate(_question.choices.length, (i) {
            final choice = _question.choices[i];
            final isSelected = _selected == i;
            Color border = Blueprint.line;
            Color background = Blueprint.surface;
            if (_revealed) {
              if (choice.correct) {
                border = Blueprint.ok;
                background = Blueprint.ok.withOpacity(0.08);
              } else if (isSelected) {
                border = Blueprint.danger;
                background = Blueprint.danger.withOpacity(0.08);
              }
            } else if (isSelected) {
              border = Blueprint.teal;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _choose(i),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: border),
                  ),
                  child: Text(choice.text,
                      style: const TextStyle(fontSize: 14, height: 1.4)),
                ),
              ),
            );
          }),
          if (_revealed) ...[
            const SizedBox(height: 6),
            InfoPanel(
              accent: _question.choices[_selected!].correct
                  ? Blueprint.ok
                  : Blueprint.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _question.choices[_selected!].correct
                        ? 'Respuesta correcta'
                        : 'Revisa este punto',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _question.choices[_selected!].correct
                          ? Blueprint.ok
                          : Blueprint.key,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _question.choices[_question.correctIndex].why,
                    style: const TextStyle(
                        fontSize: 13, color: Blueprint.text, height: 1.5),
                  ),
                  if (_question.takeaway.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(_question.takeaway,
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: Blueprint.muted,
                            height: 1.45)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                child: Text(_isLast ? 'Ver resultado' : 'Siguiente pregunta'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
