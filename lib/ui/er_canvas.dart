import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/er_model.dart';

/// Geometría compartida entre el lienzo y las tarjetas de entidad.
class ErLayout {
  static const double cardWidth = 186;
  static const double headerHeight = 34;
  static const double rowHeight = 19;
  static const double verticalPadding = 8;
  static const int maxVisibleAttributes = 6;
  static const double canvasWidth = 1500;
  static const double canvasHeight = 1200;

  static double heightOf(ErEntity entity) {
    final visible = entity.attributes.length > maxVisibleAttributes
        ? maxVisibleAttributes + 1
        : entity.attributes.length;
    final rows = visible == 0 ? 1 : visible;
    return headerHeight + rows * rowHeight + verticalPadding * 2;
  }

  static Rect rectOf(ErEntity entity) =>
      Rect.fromLTWH(entity.x, entity.y, cardWidth, heightOf(entity));
}

/// Dibuja las relaciones del modelo por debajo de las tarjetas.
class ErCanvasPainter extends CustomPainter {
  ErCanvasPainter({
    required this.model,
    required this.selectedRelationId,
  });

  final ErModel model;
  final String? selectedRelationId;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);

    for (final relation in model.relationships) {
      final from = model.entityById(relation.fromId);
      final to = model.entityById(relation.toId);
      if (from == null || to == null) continue;

      final selected = relation.id == selectedRelationId;
      final color = selected
          ? Blueprint.teal
          : relation.identifying
              ? Blueprint.key
              : Blueprint.link;

      if (from.id == to.id) {
        _paintSelfLoop(canvas, ErLayout.rectOf(from), color, relation);
        continue;
      }

      final rectA = ErLayout.rectOf(from);
      final rectB = ErLayout.rectOf(to);
      final a = _edgePoint(rectA, rectB.center);
      final b = _edgePoint(rectB, rectA.center);

      final paint = Paint()
        ..color = color
        ..strokeWidth = selected ? 2.6 : 1.6
        ..style = PaintingStyle.stroke;
      canvas.drawLine(a, b, paint);

      if (relation.identifying) {
        final inset = Paint()
          ..color = color.withOpacity(0.5)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        final normal = _normal(a, b) * 3.0;
        canvas.drawLine(a + normal, b + normal, inset);
      }

      final direction = (b - a);
      final length = direction.distance;
      if (length < 1) continue;
      final unit = direction / length;

      _paintLabel(canvas, a + unit * 16, relation.fromCard.symbol, color);
      _paintLabel(canvas, b - unit * 16, relation.toCard.symbol, color);

      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      _paintDiamond(canvas, mid, color, relation.name);
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Blueprint.line.withOpacity(0.35)
      ..strokeWidth = 0.6;
    const step = 40.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintSelfLoop(
      Canvas canvas, Rect rect, Color color, ErRelationship relation) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(rect.right, rect.top + 12)
      ..cubicTo(rect.right + 60, rect.top - 30, rect.right + 60,
          rect.bottom + 30, rect.right, rect.bottom - 12);
    canvas.drawPath(path, paint);
    _paintDiamond(
        canvas, Offset(rect.right + 42, rect.center.dy), color, relation.name);
  }

  void _paintDiamond(
      Canvas canvas, Offset center, Color color, String label) {
    const r = 6.0;
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r, center.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = Blueprint.ink);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    if (label.trim().isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
            color: color, fontSize: 10.5, fontFamily: Blueprint.mono),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final bg = Rect.fromCenter(
      center: Offset(center.dx, center.dy + 15),
      width: painter.width + 8,
      height: painter.height + 3,
    );
    canvas.drawRect(bg, Paint()..color = Blueprint.ink);
    painter.paint(
        canvas, Offset(center.dx - painter.width / 2, center.dy + 15 - painter.height / 2));
  }

  void _paintLabel(Canvas canvas, Offset at, String text, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontFamily: Blueprint.mono,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.drawCircle(at, 8.5, Paint()..color = Blueprint.ink);
    painter.paint(
        canvas, Offset(at.dx - painter.width / 2, at.dy - painter.height / 2));
  }

  static Offset _edgePoint(Rect rect, Offset target) {
    final center = rect.center;
    final d = target - center;
    if (d.distance < 0.001) return center;
    final sx = d.dx.abs() < 0.001 ? double.infinity : (rect.width / 2) / d.dx.abs();
    final sy = d.dy.abs() < 0.001 ? double.infinity : (rect.height / 2) / d.dy.abs();
    final s = sx < sy ? sx : sy;
    return center + d * s;
  }

  static Offset _normal(Offset a, Offset b) {
    final d = b - a;
    final len = d.distance;
    if (len < 0.001) return Offset.zero;
    return Offset(-d.dy / len, d.dx / len);
  }

  @override
  bool shouldRepaint(covariant ErCanvasPainter oldDelegate) => true;
}

/// Tarjeta de entidad: cabecera con el nombre y filas de atributos.
class ErEntityCard extends StatelessWidget {
  const ErEntityCard({
    super.key,
    required this.entity,
    required this.selected,
    required this.connecting,
  });

  final ErEntity entity;
  final bool selected;
  final bool connecting;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Blueprint.teal
        : connecting
            ? Blueprint.key
            : Blueprint.line;
    final visible =
        entity.attributes.take(ErLayout.maxVisibleAttributes).toList();
    final hidden = entity.attributes.length - visible.length;

    return Container(
      width: ErLayout.cardWidth,
      height: ErLayout.heightOf(entity),
      decoration: BoxDecoration(
        color: Blueprint.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: selected ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: ErLayout.headerHeight,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Blueprint.surfaceHigh,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              border: entity.isWeak
                  ? const Border(
                      bottom: BorderSide(color: Blueprint.key, width: 2))
                  : const Border(
                      bottom: BorderSide(color: Blueprint.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entity.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
                if (entity.isWeak)
                  const Text('débil',
                      style: TextStyle(fontSize: 10, color: Blueprint.key)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: ErLayout.verticalPadding, horizontal: 10),
              child: entity.attributes.isEmpty
                  ? const Text('sin atributos',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: Blueprint.muted,
                          fontStyle: FontStyle.italic))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...visible.map((a) => SizedBox(
                              height: ErLayout.rowHeight,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      a.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontFamily: Blueprint.mono,
                                        color: a.kind == AttrKind.primaryKey
                                            ? Blueprint.key
                                            : Blueprint.text,
                                      ),
                                    ),
                                  ),
                                  if (a.kind != AttrKind.normal)
                                    Text(
                                      a.kind.badge,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontFamily: Blueprint.mono,
                                        color: a.kind == AttrKind.primaryKey
                                            ? Blueprint.key
                                            : Blueprint.muted,
                                      ),
                                    ),
                                ],
                              ),
                            )),
                        if (hidden > 0)
                          SizedBox(
                            height: ErLayout.rowHeight,
                            child: Text('+ $hidden más',
                                style: const TextStyle(
                                    fontSize: 11, color: Blueprint.muted)),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
