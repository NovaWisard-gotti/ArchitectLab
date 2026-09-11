import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../engine/design_advisor.dart';

/// Barra de progreso plana, con lectura numérica al costado.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.label = '',
    this.color = Blueprint.teal,
    this.height = 6,
  });

  final double value;
  final String label;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: height,
              backgroundColor: Blueprint.surfaceHigh,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Blueprint.muted,
              fontSize: 12,
              fontFamily: Blueprint.mono,
            ),
          ),
        ],
      ],
    );
  }
}

/// Botón de icono que queda marcado con un punto de color después de que
/// el usuario cierra el panel que abre, para que pueda ubicarlo de nuevo
/// fácilmente.
class AttentionIconButton extends StatelessWidget {
  const AttentionIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.attention = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: attention ? Blueprint.teal : null),
          if (attention)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: Blueprint.key,
                  shape: BoxShape.circle,
                  border: Border.all(color: Blueprint.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Blueprint.text,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class InfoPanel extends StatelessWidget {
  const InfoPanel({
    super.key,
    required this.child,
    this.accent = Blueprint.line,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final Color accent;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Blueprint.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border(
          left: BorderSide(color: accent, width: 3),
          top: const BorderSide(color: Blueprint.line),
          right: const BorderSide(color: Blueprint.line),
          bottom: const BorderSide(color: Blueprint.line),
        ),
      ),
      child: child,
    );
  }
}

class MonoText extends StatelessWidget {
  const MonoText(this.text, {super.key, this.color, this.size = 13});

  final String text;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: Blueprint.mono,
        fontSize: size,
        height: 1.45,
        color: color ?? Blueprint.text,
      ),
    );
  }
}

Color severityColor(Severity severity) {
  switch (severity) {
    case Severity.error:
      return Blueprint.danger;
    case Severity.warning:
      return Blueprint.key;
    case Severity.info:
      return Blueprint.link;
    case Severity.praise:
      return Blueprint.ok;
  }
}

IconData severityIcon(Severity severity) {
  switch (severity) {
    case Severity.error:
      return Icons.error_outline;
    case Severity.warning:
      return Icons.warning_amber_outlined;
    case Severity.info:
      return Icons.lightbulb_outline;
    case Severity.praise:
      return Icons.check_circle_outline;
  }
}

class DiagnosticCard extends StatelessWidget {
  const DiagnosticCard({super.key, required this.diagnostic});

  final Diagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    final color = severityColor(diagnostic.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InfoPanel(
        accent: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(severityIcon(diagnostic.severity), color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    diagnostic.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              diagnostic.message,
              style: const TextStyle(
                  color: Blueprint.muted, fontSize: 13, height: 1.45),
            ),
            if (diagnostic.fix.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_forward,
                      size: 14, color: Blueprint.teal),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      diagnostic.fix,
                      style: const TextStyle(
                          color: Blueprint.teal, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RubricList extends StatelessWidget {
  const RubricList({super.key, required this.items});

  final List<RubricItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        final done = item.complete;
        final partial = !done && item.earned > 0;
        final color = done
            ? Blueprint.ok
            : partial
                ? Blueprint.key
                : Blueprint.danger;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                done
                    ? Icons.check_circle
                    : partial
                        ? Icons.adjust
                        : Icons.radio_button_unchecked,
                size: 17,
                color: color,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(item.comment,
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: Blueprint.muted,
                            height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${item.earned}/${item.possible}',
                  style: const TextStyle(
                      fontFamily: Blueprint.mono,
                      fontSize: 12,
                      color: Blueprint.muted)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Hoja inferior reutilizable para resultados de evaluación.
Future<void> showResultSheet(
  BuildContext context, {
  required String title,
  required int earned,
  required int possible,
  required Widget body,
  String? footnote,
}) {
  final ratio = possible == 0 ? 0.0 : earned / possible;
  final passed = ratio >= 0.7;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Blueprint.ink,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (ctx, controller) {
          return SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Blueprint.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    Text('$earned/$possible',
                        style: TextStyle(
                          fontFamily: Blueprint.mono,
                          fontSize: 18,
                          color: passed ? Blueprint.ok : Blueprint.key,
                        )),
                  ],
                ),
                const SizedBox(height: 10),
                ProgressBar(
                  value: ratio,
                  color: passed ? Blueprint.ok : Blueprint.key,
                  label: '${(ratio * 100).round()}%',
                ),
                const SizedBox(height: 6),
                Text(
                  passed
                      ? 'Actividad superada. El puntaje quedó guardado.'
                      : 'Aún no alcanzas el 70% necesario. Corrige y vuelve a '
                          'evaluar: se conserva tu mejor intento.',
                  style: const TextStyle(
                      fontSize: 12.5, color: Blueprint.muted, height: 1.4),
                ),
                const SizedBox(height: 18),
                body,
                if (footnote != null) ...[
                  const SizedBox(height: 14),
                  Text(footnote,
                      style: const TextStyle(
                          fontSize: 12, color: Blueprint.muted, height: 1.4)),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Volver al laboratorio'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
