import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/progress_store.dart';
import '../core/theme.dart';
import '../engine/design_advisor.dart';
import '../engine/normalization_evaluator.dart';
import '../models/activity.dart';
import 'widgets.dart';

class NormalizationScreen extends StatefulWidget {
  const NormalizationScreen({super.key, required this.activity});

  final NormalizationActivity activity;

  @override
  State<NormalizationScreen> createState() => _NormalizationScreenState();
}

class _NormalizationScreenState extends State<NormalizationScreen> {
  final List<StudentTable> _tables = [];

  String get _draftKey => 'norm_${widget.activity.id}';

  @override
  void initState() {
    super.initState();
    final raw = ProgressStore.instance.draft(_draftKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final item in decoded) {
          final map = item as Map<String, dynamic>;
          _tables.add(StudentTable(
            name: map['n'] as String,
            attributes: ((map['a'] as List<dynamic>).cast<String>()).toSet(),
            pk: ((map['k'] as List<dynamic>).cast<String>()).toSet(),
          ));
        }
      } catch (_) {
        _tables.clear();
      }
    }
  }

  void _persist() {
    final payload = _tables
        .map((t) => {
              'n': t.name,
              'a': t.attributes.toList(),
              'k': t.primaryKey.toList(),
            })
        .toList();
    ProgressStore.instance.saveDraft(_draftKey, jsonEncode(payload));
  }

  Set<String> get _assigned {
    final out = <String>{};
    for (final t in _tables) {
      out.addAll(t.attributes);
    }
    return out;
  }

  Future<void> _addTable() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva tabla'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'cliente, producto, detalle_boleta',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    setState(() => _tables.add(StudentTable(name: name)));
    _persist();
  }

  Future<void> _pickAttributes(StudentTable table) async {
    final selection = Set<String>.from(table.attributes);
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Blueprint.ink,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          builder: (ctx, controller) => Column(
            children: [
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                  children: [
                    Text('Atributos de ${table.name}',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text(
                      'Un atributo puede repetirse en otra tabla solo cuando '
                      'actua como clave foranea.',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: Blueprint.muted,
                          height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    ...widget.activity.attributes.map((attr) {
                      final usedElsewhere = _tables.any((t) =>
                          t != table && t.attributes.contains(attr));
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: Blueprint.teal,
                        value: selection.contains(attr),
                        onChanged: (v) => setSheet(() {
                          if (v == true) {
                            selection.add(attr);
                          } else {
                            selection.remove(attr);
                          }
                        }),
                        title: MonoText(attr, size: 12.5),
                        subtitle: usedElsewhere
                            ? const Text('ya usado en otra tabla',
                                style: TextStyle(
                                    fontSize: 11, color: Blueprint.key))
                            : null,
                      );
                    }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(selection),
                    child: const Text('Aplicar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      table.attributes
        ..clear()
        ..addAll(result);
      table.primaryKey.removeWhere((k) => !table.attributes.contains(k));
    });
    _persist();
  }

  void _toggleKey(StudentTable table, String attribute) {
    setState(() {
      if (table.primaryKey.contains(attribute)) {
        table.primaryKey.remove(attribute);
      } else {
        table.primaryKey.add(attribute);
      }
    });
    _persist();
  }

  Future<void> _evaluate() async {
    final report = NormalizationEvaluator.evaluate(
      activity: widget.activity,
      tables: _tables,
    );
    await ProgressStore.instance
        .record(widget.activity.id, report.earned, report.possible);
    if (!mounted) return;
    await showResultSheet(
      context,
      title: 'Descomposicion evaluada',
      earned: report.earned,
      possible: report.possible,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoPanel(
            accent: report.reachedForm == widget.activity.targetForm
                ? Blueprint.ok
                : Blueprint.key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Forma normal alcanzada: ${report.reachedForm}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  'Objetivo del ejercicio: ${widget.activity.targetForm}. '
                  'El resultado se obtiene revisando cada dependencia '
                  'funcional contra la clave que declaraste.',
                  style: const TextStyle(
                      fontSize: 12.5, color: Blueprint.muted, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Comparacion con la descomposicion esperada'),
          RubricList(items: report.items),
          const SizedBox(height: 12),
          const SectionTitle('Observaciones'),
          ...report.issues.map(
            (i) => DiagnosticCard(
              diagnostic: Diagnostic(
                rule: 'norm',
                severity: i.severity,
                title: i.title,
                message: i.message,
                fix: i.fix,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.activity.attributes
        .where((a) => !_assigned.contains(a))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.title, style: const TextStyle(fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          InfoPanel(
            accent: Blueprint.link,
            child: Text(widget.activity.brief,
                style: const TextStyle(fontSize: 13.5, height: 1.5)),
          ),
          const SizedBox(height: 18),
          const SectionTitle('Tabla original'),
          _SampleTable(rows: widget.activity.sampleRows),
          const SizedBox(height: 18),
          const SectionTitle('Dependencias funcionales declaradas'),
          ...widget.activity.fds.map(
            (fd) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: Blueprint.surface,
                  border: Border.all(color: Blueprint.line),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: MonoText(fd.display, size: 12.5),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SectionTitle(
            'Atributos sin ubicar (${pending.length})',
          ),
          if (pending.isEmpty)
            const InfoPanel(
              accent: Blueprint.ok,
              child: Text('Todos los atributos estan asignados.',
                  style: TextStyle(fontSize: 13, color: Blueprint.muted)),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: pending
                  .map((a) => Chip(
                        label: Text(a,
                            style: const TextStyle(
                                fontFamily: Blueprint.mono, fontSize: 11.5)),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          const SizedBox(height: 20),
          SectionTitle(
            'Tu descomposicion',
            trailing: TextButton.icon(
              onPressed: _addTable,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tabla'),
            ),
          ),
          if (_tables.isEmpty)
            const InfoPanel(
              child: Text(
                'Crea una tabla por cada concepto independiente que aparezca '
                'a la izquierda de una dependencia funcional.',
                style: TextStyle(
                    fontSize: 13, color: Blueprint.muted, height: 1.45),
              ),
            ),
          ..._tables.map(_buildTableCard),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Blueprint.surface,
          border: Border(top: BorderSide(color: Blueprint.line)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SafeArea(
          top: false,
          child: FilledButton.icon(
            onPressed: _tables.isEmpty ? null : _evaluate,
            icon: const Icon(Icons.rule_outlined, size: 18),
            label: const Text('Evaluar descomposicion'),
          ),
        ),
      ),
    );
  }

  Widget _buildTableCard(StudentTable table) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Blueprint.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Blueprint.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: MonoText(table.name, size: 14),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _pickAttributes(table),
                  icon: const Icon(Icons.playlist_add, size: 20),
                  tooltip: 'Asignar atributos',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() => _tables.remove(table));
                    _persist();
                  },
                  icon: const Icon(Icons.delete_outline, size: 19),
                  tooltip: 'Eliminar tabla',
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Toca un atributo para marcarlo como clave primaria.',
                style: TextStyle(fontSize: 11.5, color: Blueprint.muted)),
            const SizedBox(height: 10),
            if (table.attributes.isEmpty)
              const Text('Sin atributos asignados.',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: Blueprint.muted,
                      fontStyle: FontStyle.italic))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: table.attributes.map((attr) {
                  final isKey = table.primaryKey.contains(attr);
                  return GestureDetector(
                    onTap: () => _toggleKey(table, attr),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isKey
                            ? Blueprint.key.withOpacity(0.14)
                            : Blueprint.surfaceHigh,
                        border: Border.all(
                            color: isKey ? Blueprint.key : Blueprint.line),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isKey) ...[
                            const Icon(Icons.vpn_key,
                                size: 11, color: Blueprint.key),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            attr,
                            style: TextStyle(
                              fontFamily: Blueprint.mono,
                              fontSize: 11.5,
                              color:
                                  isKey ? Blueprint.key : Blueprint.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _SampleTable extends StatelessWidget {
  const _SampleTable({required this.rows});

  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final header = rows.first;
    final body = rows.skip(1).toList();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Blueprint.line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 38,
          dataRowMinHeight: 34,
          dataRowMaxHeight: 40,
          horizontalMargin: 12,
          columnSpacing: 20,
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
          columns: header.map((h) => DataColumn(label: Text(h))).toList(),
          rows: body
              .map((r) => DataRow(
                    cells: List.generate(
                      header.length,
                      (i) => DataCell(Text(i < r.length ? r[i] : '')),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
