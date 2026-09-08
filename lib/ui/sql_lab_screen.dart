import 'dart:convert';

import 'package:flutter/material.dart';

import '../content/schemas.dart';
import '../core/progress_store.dart';
import '../core/theme.dart';
import '../engine/ai_tutor.dart';
import '../engine/result_comparer.dart';
import '../engine/sql_engine.dart';
import '../models/activity.dart';
import 'widgets.dart';

class SqlLabScreen extends StatefulWidget {
  const SqlLabScreen({super.key, required this.activity});

  final SqlLabActivity activity;

  @override
  State<SqlLabScreen> createState() => _SqlLabScreenState();
}

class _SqlLabScreenState extends State<SqlLabScreen> {
  final SqlEngine _student = SqlEngine('student');
  final SqlEngine _reference = SqlEngine('reference');
  final TextEditingController _editor = TextEditingController();

  Map<String, List<String>> _schema = {};
  final Map<String, String> _answers = {};
  final Set<String> _solved = {};

  int _index = 0;
  bool _busy = true;
  bool _running = false;
  SqlResult? _result;
  SqlVerdict? _verdict;
  TutorAdvice? _advice;

  SqlTask get _task => widget.activity.tasks[_index];
  String get _draftKey => 'sql_${widget.activity.id}';

  @override
  void initState() {
    super.initState();
    _restoreDraft();
    _bootstrap();
  }

  @override
  void dispose() {
    _editor.dispose();
    _student.close();
    _reference.close();
    super.dispose();
  }

  void _restoreDraft() {
    final raw = ProgressStore.instance.draft(_draftKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final answers = decoded['a'] as Map<String, dynamic>? ?? {};
      answers.forEach((k, v) => _answers[k] = v as String);
      final solved = (decoded['s'] as List<dynamic>? ?? []).cast<String>();
      _solved.addAll(solved);
    } catch (_) {
      _answers.clear();
    }
  }

  void _persist() {
    ProgressStore.instance.saveDraft(
      _draftKey,
      jsonEncode({'a': _answers, 's': _solved.toList()}),
    );
  }

  Future<void> _bootstrap() async {
    final seed = LabSchemas.byName(widget.activity.schemaName);
    try {
      await _student.reset(seed);
      final schema = await _student.describe();
      if (!mounted) return;
      setState(() {
        _schema = schema;
        _busy = false;
        _editor.text = _answers[_task.id] ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _verdict = SqlVerdict(
          passed: false,
          title: 'No se pudo iniciar el laboratorio',
          detail: e.toString(),
        );
      });
    }
  }

  void _selectTask(int index) {
    _answers[_task.id] = _editor.text;
    setState(() {
      _index = index;
      _editor.text = _answers[_task.id] ?? '';
      _result = null;
      _verdict = null;
      _advice = null;
    });
    _persist();
  }

  Future<void> _run() async {
    if (_running) return;
    final sql = _editor.text.trim();
    if (sql.isEmpty) return;
    setState(() {
      _running = true;
      _verdict = null;
      _advice = null;
    });
    final seed = LabSchemas.byName(widget.activity.schemaName);
    await _student.reset(seed);
    final result = await _student.run(sql);
    _answers[_task.id] = sql;
    _persist();
    if (!mounted) return;
    setState(() {
      _result = result;
      _running = false;
      _advice = result.hasError
          ? AiTutor.explainSqlError(sql, result.error!)
          : null;
    });
  }

  Future<void> _validate() async {
    if (_running) return;
    final sql = _editor.text.trim();
    if (sql.isEmpty) return;
    setState(() {
      _running = true;
      _advice = null;
    });

    final seed = LabSchemas.byName(widget.activity.schemaName);
    final shapeIssues = ResultComparer.checkShape(
      sql,
      mustContain: _task.mustContain,
      forbid: _task.forbid,
    );

    await _student.reset(seed);
    final studentRun = await _student.run(sql);

    SqlVerdict verdict;
    if (studentRun.hasError) {
      verdict = SqlVerdict(
        passed: false,
        title: 'La consulta no se pudo ejecutar',
        detail: studentRun.error!,
      );
    } else {
      await _reference.reset(seed);
      final referenceRun = await _reference.run(_task.solution);

      SqlResult studentFinal = studentRun;
      SqlResult referenceFinal = referenceRun;
      if (_task.verify != null) {
        studentFinal = await _student.run(_task.verify!);
        referenceFinal = await _reference.run(_task.verify!);
      }
      verdict = ResultComparer.compare(
        student: studentFinal,
        expected: referenceFinal,
        ordered: _task.ordered,
      );
      if (verdict.passed && shapeIssues.isNotEmpty) {
        verdict = SqlVerdict(
          passed: false,
          title: 'Resultado correcto, pero no con la construccion pedida',
          detail: shapeIssues.join(' '),
          hintsFailed: shapeIssues,
        );
      }
    }

    if (verdict.passed) {
      _solved.add(_task.id);
    } else {
      _solved.remove(_task.id);
    }
    _answers[_task.id] = sql;
    _persist();

    var score = 0;
    for (final t in widget.activity.tasks) {
      if (_solved.contains(t.id)) score += t.points;
    }
    await ProgressStore.instance
        .record(widget.activity.id, score, widget.activity.maxScore);

    final schema = await _student.describe();
    if (!mounted) return;
    setState(() {
      _schema = schema;
      _verdict = verdict;
      _running = false;
      _advice = verdict.passed
          ? null
          : (studentRun.hasError
              ? AiTutor.explainSqlError(sql, studentRun.error!)
              : null);
    });
  }

  Future<void> _showSchema() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Blueprint.ink,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (ctx, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Esquema disponible'),
              Text(LabSchemas.describe(widget.activity.schemaName),
                  style: const TextStyle(
                      fontSize: 13, color: Blueprint.muted, height: 1.45)),
              const SizedBox(height: 14),
              ..._schema.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InfoPanel(
                    accent: Blueprint.teal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MonoText(entry.key, color: Blueprint.teal, size: 13.5),
                        const SizedBox(height: 6),
                        MonoText(entry.value.join(', '),
                            color: Blueprint.muted, size: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHint() {
    if (_task.hint.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Blueprint.ink,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Pista'),
            InfoPanel(
              accent: Blueprint.key,
              child: Text(_task.hint,
                  style: const TextStyle(fontSize: 13.5, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.activity.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.title, style: const TextStyle(fontSize: 17)),
        actions: [
          IconButton(
            tooltip: 'Ver esquema',
            onPressed: _showSchema,
            icon: const Icon(Icons.table_chart_outlined),
          ),
          if (_task.hint.isNotEmpty)
            IconButton(
              tooltip: 'Pista',
              onPressed: _showHint,
              icon: const Icon(Icons.lightbulb_outline),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTaskSelector(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                InfoPanel(
                  accent: _solved.contains(_task.id)
                      ? Blueprint.ok
                      : Blueprint.link,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Consulta ${_index + 1}',
                              style: const TextStyle(
                                  fontSize: 12, color: Blueprint.muted)),
                          const Spacer(),
                          MonoText('${_task.points} pts',
                              color: Blueprint.muted, size: 11.5),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_task.prompt,
                          style: const TextStyle(fontSize: 14.5, height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: Blueprint.surface,
                    border: Border.all(color: Blueprint.line),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: const BoxDecoration(
                          color: Blueprint.surfaceHigh,
                          border:
                              Border(bottom: BorderSide(color: Blueprint.line)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.terminal,
                                size: 15, color: Blueprint.teal),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('consola sql',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      fontFamily: Blueprint.mono,
                                      color: Blueprint.muted)),
                            ),
                            GestureDetector(
                              onTap: () => setState(() {
                                _editor.clear();
                                _result = null;
                                _verdict = null;
                                _advice = null;
                              }),
                              child: const Text('limpiar',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      fontFamily: Blueprint.mono,
                                      color: Blueprint.muted)),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: TextField(
                          controller: _editor,
                          maxLines: 7,
                          minLines: 5,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.none,
                          autocorrect: false,
                          enableSuggestions: false,
                          style: const TextStyle(
                              fontFamily: Blueprint.mono,
                              fontSize: 13,
                              height: 1.5),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            hintText: 'SELECT ...',
                            hintStyle: TextStyle(
                                fontFamily: Blueprint.mono,
                                color: Blueprint.muted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _running ? null : _run,
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Ejecutar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _running ? null : _validate,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Validar'),
                      ),
                    ),
                  ],
                ),
                if (_running) ...[
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(minHeight: 3),
                ],
                if (_verdict != null) ...[
                  const SizedBox(height: 16),
                  InfoPanel(
                    accent:
                        _verdict!.passed ? Blueprint.ok : Blueprint.danger,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _verdict!.passed
                                  ? Icons.check_circle_outline
                                  : Icons.error_outline,
                              size: 17,
                              color: _verdict!.passed
                                  ? Blueprint.ok
                                  : Blueprint.danger,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_verdict!.title,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(_verdict!.detail,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Blueprint.muted,
                                height: 1.5)),
                      ],
                    ),
                  ),
                ],
                if (_advice != null) ...[
                  const SizedBox(height: 12),
                  InfoPanel(
                    accent: Blueprint.teal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome,
                                size: 15, color: Blueprint.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_advice!.title,
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(_advice!.explanation,
                            style: const TextStyle(
                                fontSize: 13, height: 1.5)),
                        const SizedBox(height: 8),
                        Text(_advice!.nextStep,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Blueprint.teal,
                                height: 1.45)),
                      ],
                    ),
                  ),
                ],
                if (_result != null && !_result!.hasError) ...[
                  const SizedBox(height: 16),
                  SectionTitle('Resultado (${_result!.rows.length} filas)'),
                  _ResultTable(result: _result!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSelector() {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Blueprint.line)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        itemCount: widget.activity.tasks.length,
        itemBuilder: (context, i) {
          final task = widget.activity.tasks[i];
          final active = i == _index;
          final solved = _solved.contains(task.id);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _selectTask(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? Blueprint.teal.withOpacity(0.16)
                      : Blueprint.surface,
                  border: Border.all(
                      color: active
                          ? Blueprint.teal
                          : solved
                              ? Blueprint.ok
                              : Blueprint.line),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    if (solved) ...[
                      const Icon(Icons.check, size: 13, color: Blueprint.ok),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontFamily: Blueprint.mono,
                        fontSize: 13,
                        color: active ? Blueprint.teal : Blueprint.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResultTable extends StatelessWidget {
  const _ResultTable({required this.result});

  final SqlResult result;

  @override
  Widget build(BuildContext context) {
    if (result.columns.isEmpty) {
      return const InfoPanel(
        child: Text(
          'La sentencia se ejecuto sin devolver filas. Para ver datos, usa '
          'un SELECT.',
          style: TextStyle(fontSize: 13, color: Blueprint.muted),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Blueprint.line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 38,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 38,
          horizontalMargin: 12,
          columnSpacing: 22,
          headingTextStyle: const TextStyle(
            fontFamily: Blueprint.mono,
            fontSize: 11.5,
            color: Blueprint.teal,
          ),
          dataTextStyle: const TextStyle(
            fontFamily: Blueprint.mono,
            fontSize: 11.5,
            color: Blueprint.text,
          ),
          columns:
              result.columns.map((c) => DataColumn(label: Text(c))).toList(),
          rows: result.rows
              .take(40)
              .map((row) => DataRow(
                    cells: row
                        .map((value) =>
                            DataCell(Text(value == null ? 'NULL' : '$value')))
                        .toList(),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
