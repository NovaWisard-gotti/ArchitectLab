import 'package:flutter/material.dart';

import '../core/progress_store.dart';
import '../core/theme.dart';
import '../engine/ai_tutor.dart';
import '../engine/design_advisor.dart';
import '../models/activity.dart';
import '../models/er_model.dart';
import 'er_canvas.dart';
import 'widgets.dart';

class ErDesignerScreen extends StatefulWidget {
  const ErDesignerScreen({super.key, required this.activity});

  final ErDesignActivity activity;

  @override
  State<ErDesignerScreen> createState() => _ErDesignerScreenState();
}

class _ErDesignerScreenState extends State<ErDesignerScreen> {
  late ErModel _model;
  String? _selectedEntityId;
  String? _selectedRelationId;
  String? _connectFromId;
  bool _connecting = false;
  double _scale = 1;

  String get _draftKey => 'er_${widget.activity.id}';

  @override
  void initState() {
    super.initState();
    final raw = ProgressStore.instance.draft(_draftKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _model = ErModel.decode(raw);
      } catch (_) {
        _model = ErModel();
      }
    } else {
      _model = ErModel();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_model.isEmpty) _showBrief();
    });
  }

  void _persist() {
    ProgressStore.instance.saveDraft(_draftKey, _model.encode());
  }

  String _newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

  // -------------------------------------------------------------------------
  // Acciones
  // -------------------------------------------------------------------------

  void _addEntity() {
    final index = _model.entities.length;
    final entity = ErEntity(
      id: _newId('e'),
      name: 'Entidad ${index + 1}',
      x: 60 + (index % 3) * 230,
      y: 60 + (index ~/ 3) * 190,
    );
    setState(() {
      _model.entities.add(entity);
      _selectedEntityId = entity.id;
      _selectedRelationId = null;
    });
    _persist();
    _editEntity(entity);
  }

  Future<void> _editEntity(ErEntity entity) async {
    final result = await Navigator.of(context).push<_EntityEditResult>(
      MaterialPageRoute<_EntityEditResult>(
        fullscreenDialog: true,
        builder: (_) => _EntityEditorScreen(entity: entity.copy()),
      ),
    );
    if (result == null) return;
    setState(() {
      if (result.deleted) {
        _model.entities.removeWhere((e) => e.id == entity.id);
        _model.relationships.removeWhere(
            (r) => r.fromId == entity.id || r.toId == entity.id);
        _selectedEntityId = null;
      } else {
        final index = _model.entities.indexWhere((e) => e.id == entity.id);
        if (index >= 0) {
          final updated = result.entity;
          updated.x = _model.entities[index].x;
          updated.y = _model.entities[index].y;
          _model.entities[index] = updated;
        }
      }
    });
    _persist();
  }

  void _onEntityTap(ErEntity entity) {
    if (_connecting) {
      if (_connectFromId == null) {
        setState(() => _connectFromId = entity.id);
        return;
      }
      if (_connectFromId == entity.id) {
        setState(() => _connectFromId = null);
        return;
      }
      final relation = ErRelationship(
        id: _newId('r'),
        name: '',
        fromId: _connectFromId!,
        toId: entity.id,
      );
      setState(() {
        _model.relationships.add(relation);
        _connecting = false;
        _connectFromId = null;
        _selectedRelationId = relation.id;
      });
      _persist();
      _editRelation(relation);
      return;
    }
    setState(() {
      _selectedEntityId = entity.id;
      _selectedRelationId = null;
    });
  }

  Future<void> _editRelation(ErRelationship relation) async {
    final from = _model.entityById(relation.fromId);
    final to = _model.entityById(relation.toId);
    if (from == null || to == null) return;

    var name = relation.name;
    var fromCard = relation.fromCard;
    var toCard = relation.toCard;
    var identifying = relation.identifying;
    final controller = TextEditingController(text: name);

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Blueprint.ink,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${from.name} - ${to.name}',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la relación (un verbo)',
                      hintText: 'matrícula, contiene, atiende',
                    ),
                    onChanged: (v) => name = v,
                  ),
                  const SizedBox(height: 18),
                  Text('Cardinalidad',
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _CardinalitySelector(
                          label: from.name,
                          value: fromCard,
                          onChanged: (v) => setSheet(() => fromCard = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CardinalitySelector(
                          label: to.name,
                          value: toCard,
                          onChanged: (v) => setSheet(() => toCard = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _cardinalityPhrase(from.name, to.name, fromCard, toCard),
                    style: const TextStyle(
                        fontSize: 12.5, color: Blueprint.muted, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: identifying,
                    activeColor: Blueprint.key,
                    onChanged: (v) => setSheet(() => identifying = v),
                    title: const Text('Relación identificadora',
                        style: TextStyle(fontSize: 14)),
                    subtitle: const Text(
                        'La entidad débil completa su clave con la clave de '
                        'la entidad fuerte.',
                        style: TextStyle(fontSize: 12, color: Blueprint.muted)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(ctx).pop('delete'),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Eliminar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(ctx).pop('save'),
                          child: const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (action == 'delete') {
      setState(() {
        _model.relationships.removeWhere((r) => r.id == relation.id);
        _selectedRelationId = null;
      });
      _persist();
      return;
    }
    if (action == 'save') {
      setState(() {
        relation.name = name.trim();
        relation.fromCard = fromCard;
        relation.toCard = toCard;
        relation.identifying = identifying;
      });
      _persist();
    }
  }

  static String _cardinalityPhrase(
      String a, String b, Cardinality ca, Cardinality cb) {
    final left = ca == Cardinality.one ? 'un' : 'varios';
    final right = cb == Cardinality.one ? 'un' : 'varios';
    return 'Se lee: $left $a se relaciona con $right $b.';
  }

  // -------------------------------------------------------------------------
  // Paneles
  // -------------------------------------------------------------------------

  Future<void> _showBrief() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Blueprint.ink,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (ctx, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.activity.title,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(widget.activity.brief,
                  style: const TextStyle(fontSize: 14, height: 1.55)),
              const SizedBox(height: 18),
              const SectionTitle('Lo que debe quedar modelado'),
              ...widget.activity.requirements.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Icon(Icons.circle,
                            size: 6, color: Blueprint.teal),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(r,
                            style: const TextStyle(
                                fontSize: 13.5, height: 1.45)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Empezar a modelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showHints() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Blueprint.ink,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Pistas'),
            ...widget.activity.hints.map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InfoPanel(
                  accent: Blueprint.key,
                  child: Text(h,
                      style: const TextStyle(fontSize: 13.5, height: 1.45)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAnalysis() async {
    final advice = AiTutor.reviewDesign(_model);
    final diagnostics = DesignAdvisor.analyze(_model);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Blueprint.ink,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (ctx, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Revisión del modelo'),
              InfoPanel(
                accent: Blueprint.teal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            size: 16, color: Blueprint.teal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(advice.title,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(advice.explanation,
                        style: const TextStyle(fontSize: 13, height: 1.5)),
                    if (advice.nextStep.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('Siguiente paso: ${advice.nextStep}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: Blueprint.teal,
                              height: 1.45)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionTitle('Detalle por regla'),
              ...diagnostics.map((d) => DiagnosticCard(diagnostic: d)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDdl() {
    final ddl = _model.isEmpty
        ? '-- Agrega entidades para generar el esquema.'
        : _model.toDdl();
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
              const SectionTitle('Tu modelo traducido a tablas'),
              const Text(
                'Así quedaría tu diagrama en SQL. Las relaciones N:M y los '
                'atributos multivaluados se convierten en tablas propias.',
                style: TextStyle(
                    fontSize: 13, color: Blueprint.muted, height: 1.45),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Blueprint.surface,
                  border: Border.all(color: Blueprint.line),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: MonoText(ddl, size: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _evaluate() async {
    final report = DesignAdvisor.evaluate(_model, widget.activity.rubric);
    await ProgressStore.instance
        .record(widget.activity.id, report.earned, report.possible);
    if (!mounted) return;
    await showResultSheet(
      context,
      title: 'Evaluación del modelo',
      earned: report.earned,
      possible: report.possible,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Rúbrica'),
          RubricList(items: report.items),
          const SizedBox(height: 16),
          const SectionTitle('Análisis estructural'),
          ...report.diagnostics
              .where((d) => d.severity != Severity.info)
              .map((d) => DiagnosticCard(diagnostic: d)),
        ],
      ),
      footnote: 'Tu diagrama queda guardado: puedes corregirlo y volver a '
          'evaluarlo cuantas veces necesites.',
    );
  }

  void _clear() {
    setState(() {
      _model.entities.clear();
      _model.relationships.clear();
      _selectedEntityId = null;
      _selectedRelationId = null;
    });
    _persist();
  }

  // -------------------------------------------------------------------------
  // Construcción
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.title, style: const TextStyle(fontSize: 17)),
        actions: [
          IconButton(
            tooltip: 'Enunciado',
            onPressed: _showBrief,
            icon: const Icon(Icons.description_outlined),
          ),
          PopupMenuButton<String>(
            color: Blueprint.surface,
            onSelected: (value) {
              switch (value) {
                case 'hints':
                  _showHints();
                  break;
                case 'ddl':
                  _showDdl();
                  break;
                case 'zoom_in':
                  setState(() => _scale = (_scale + 0.15).clamp(0.5, 1.6));
                  break;
                case 'zoom_out':
                  setState(() => _scale = (_scale - 0.15).clamp(0.5, 1.6));
                  break;
                case 'clear':
                  _clear();
                  break;
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'hints', child: Text('Ver pistas')),
              PopupMenuItem(value: 'ddl', child: Text('Ver esquema SQL')),
              PopupMenuItem(value: 'zoom_in', child: Text('Acercar')),
              PopupMenuItem(value: 'zoom_out', child: Text('Alejar')),
              PopupMenuItem(value: 'clear', child: Text('Vaciar lienzo')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_connecting)
            Container(
              width: double.infinity,
              color: Blueprint.key.withOpacity(0.14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.timeline, size: 16, color: Blueprint.key),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _connectFromId == null
                          ? 'Toca la primera entidad de la relación.'
                          : 'Ahora toca la segunda entidad.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _connecting = false;
                      _connectFromId = null;
                    }),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildCanvas()),
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return ClipRect(
      child: InteractiveViewer(
        constrained: false,
        minScale: 0.5,
        maxScale: 1.8,
        boundaryMargin: const EdgeInsets.all(80),
        child: Transform.scale(
          scale: _scale,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: ErLayout.canvasWidth,
            height: ErLayout.canvasHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedEntityId = null;
                      _selectedRelationId = null;
                    }),
                    child: CustomPaint(
                      painter: ErCanvasPainter(
                        model: _model,
                        selectedRelationId: _selectedRelationId,
                      ),
                    ),
                  ),
                ),
                ..._model.relationships.map(_relationHitBox),
                ..._model.entities.map(_entityWidget),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _relationHitBox(ErRelationship relation) {
    final from = _model.entityById(relation.fromId);
    final to = _model.entityById(relation.toId);
    if (from == null || to == null) return const SizedBox.shrink();
    final a = ErLayout.rectOf(from).center;
    final b = ErLayout.rectOf(to).center;
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    return Positioned(
      left: mid.dx - 22,
      top: mid.dy - 22,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          setState(() {
            _selectedRelationId = relation.id;
            _selectedEntityId = null;
          });
          _editRelation(relation);
        },
        child: const SizedBox(width: 44, height: 44),
      ),
    );
  }

  Widget _entityWidget(ErEntity entity) {
    return Positioned(
      left: entity.x,
      top: entity.y,
      child: GestureDetector(
        onTap: () => _onEntityTap(entity),
        onDoubleTap: () => _editEntity(entity),
        onLongPress: () => _editEntity(entity),
        onPanUpdate: (details) {
          setState(() {
            entity.x = (entity.x + details.delta.dx / _scale)
                .clamp(0.0, ErLayout.canvasWidth - ErLayout.cardWidth);
            entity.y = (entity.y + details.delta.dy / _scale)
                .clamp(0.0, ErLayout.canvasHeight - 120);
          });
        },
        onPanEnd: (_) => _persist(),
        child: ErEntityCard(
          entity: entity,
          selected: entity.id == _selectedEntityId,
          connecting: entity.id == _connectFromId,
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final selected = _selectedEntityId == null
        ? null
        : _model.entityById(_selectedEntityId!);
    return Container(
      decoration: const BoxDecoration(
        color: Blueprint.surface,
        border: Border(top: BorderSide(color: Blueprint.line)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (selected != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Seleccionada: ${selected.name}. Mantén pulsado para '
                        'editar sus atributos.',
                        style: const TextStyle(
                            fontSize: 12, color: Blueprint.muted),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _editEntity(selected),
                      child: const Text('Editar'),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addEntity,
                    icon: const Icon(Icons.add_box_outlined, size: 18),
                    label: const Text('Entidad'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _model.entities.length < 2
                        ? null
                        : () => setState(() {
                              _connecting = true;
                              _connectFromId = null;
                            }),
                    icon: const Icon(Icons.timeline, size: 18),
                    label: const Text('Relación'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showAnalysis,
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: const Text('Revisar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _model.isEmpty ? null : _evaluate,
                icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
                label: const Text('Evaluar modelo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardinalitySelector extends StatelessWidget {
  const _CardinalitySelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final Cardinality value;
  final ValueChanged<Cardinality> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Blueprint.muted)),
        const SizedBox(height: 6),
        Row(
          children: Cardinality.values.map((c) {
            final active = c == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(c),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        active ? Blueprint.teal.withOpacity(0.16) : Blueprint.surface,
                    border: Border.all(
                        color: active ? Blueprint.teal : Blueprint.line),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    c.symbol,
                    style: TextStyle(
                      fontFamily: Blueprint.mono,
                      fontSize: 14,
                      color: active ? Blueprint.teal : Blueprint.muted,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _EntityEditResult {
  const _EntityEditResult({required this.entity, this.deleted = false});
  final ErEntity entity;
  final bool deleted;
}

class _EntityEditorScreen extends StatefulWidget {
  const _EntityEditorScreen({required this.entity});
  final ErEntity entity;

  @override
  State<_EntityEditorScreen> createState() => _EntityEditorScreenState();
}

class _EntityEditorScreenState extends State<_EntityEditorScreen> {
  late TextEditingController _nameController;
  late ErEntity _entity;

  static const _types = ['INTEGER', 'TEXT', 'REAL', 'DATE', 'BOOLEAN'];

  @override
  void initState() {
    super.initState();
    _entity = widget.entity;
    _nameController = TextEditingController(text: _entity.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _editAttribute({ErAttribute? existing}) async {
    final attribute = existing?.copy() ?? ErAttribute(name: '');
    final controller = TextEditingController(text: attribute.name);

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Blueprint.ink,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? 'Nuevo atributo' : 'Editar atributo',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nombre'),
                onChanged: (v) => attribute.name = v,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<AttrKind>(
                value: attribute.kind,
                dropdownColor: Blueprint.surface,
                decoration: const InputDecoration(labelText: 'Tipo de atributo'),
                items: AttrKind.values
                    .map((k) => DropdownMenuItem<AttrKind>(
                          value: k,
                          child: Text(k.label,
                              style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (v) => setSheet(() {
                  attribute.kind = v ?? AttrKind.normal;
                  if (attribute.kind == AttrKind.primaryKey) {
                    attribute.nullable = false;
                  }
                }),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _types.contains(attribute.type) ? attribute.type : 'TEXT',
                dropdownColor: Blueprint.surface,
                decoration: const InputDecoration(labelText: 'Tipo de dato'),
                items: _types
                    .map((t) => DropdownMenuItem<String>(
                          value: t,
                          child: Text(t,
                              style: const TextStyle(
                                  fontSize: 14, fontFamily: Blueprint.mono)),
                        ))
                    .toList(),
                onChanged: (v) => setSheet(() => attribute.type = v ?? 'TEXT'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: attribute.nullable,
                activeColor: Blueprint.teal,
                onChanged: attribute.kind == AttrKind.primaryKey
                    ? null
                    : (v) => setSheet(() => attribute.nullable = v),
                title: const Text('Acepta nulos',
                    style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (existing != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop('delete'),
                        child: const Text('Eliminar'),
                      ),
                    ),
                  if (existing != null) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop('save'),
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (action == 'delete' && existing != null) {
      setState(() => _entity.attributes.remove(existing));
      return;
    }
    if (action == 'save') {
      if (attribute.name.trim().isEmpty) return;
      setState(() {
        if (existing == null) {
          _entity.attributes.add(attribute);
        } else {
          final index = _entity.attributes.indexOf(existing);
          if (index >= 0) _entity.attributes[index] = attribute;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entidad'),
        actions: [
          IconButton(
            tooltip: 'Eliminar entidad',
            onPressed: () => Navigator.of(context).pop(
              _EntityEditResult(entity: _entity, deleted: true),
            ),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la entidad',
              hintText: 'Estudiante, Préstamo, Pedido',
            ),
            onChanged: (v) => _entity.name = v,
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _entity.isWeak,
            activeColor: Blueprint.key,
            onChanged: (v) => setState(() => _entity.isWeak = v),
            title: const Text('Entidad débil', style: TextStyle(fontSize: 14)),
            subtitle: const Text(
                'No se identifica por sí sola: necesita la clave de otra '
                'entidad.',
                style: TextStyle(fontSize: 12, color: Blueprint.muted)),
          ),
          const SizedBox(height: 10),
          SectionTitle(
            'Atributos (${_entity.attributes.length})',
            trailing: TextButton.icon(
              onPressed: () => _editAttribute(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
          ),
          if (_entity.attributes.isEmpty)
            const InfoPanel(
              child: Text(
                'Agrega primero el identificador y márcalo como clave '
                'primaria; luego los datos descriptivos.',
                style: TextStyle(
                    fontSize: 13, color: Blueprint.muted, height: 1.45),
              ),
            ),
          ..._entity.attributes.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _editAttribute(existing: a),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Blueprint.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: a.kind == AttrKind.primaryKey
                            ? Blueprint.key.withOpacity(0.6)
                            : Blueprint.line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MonoText(a.name,
                                color: a.kind == AttrKind.primaryKey
                                    ? Blueprint.key
                                    : Blueprint.text),
                            const SizedBox(height: 2),
                            Text(
                              '${a.kind.label} - ${a.type}'
                              '${a.nullable ? '' : ' - NOT NULL'}',
                              style: const TextStyle(
                                  fontSize: 11.5, color: Blueprint.muted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_outlined,
                          size: 16, color: Blueprint.muted),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                _entity.name = _nameController.text.trim().isEmpty
                    ? _entity.name
                    : _nameController.text.trim();
                Navigator.of(context).pop(_EntityEditResult(entity: _entity));
              },
              child: const Text('Guardar entidad'),
            ),
          ),
        ],
      ),
    );
  }
}
