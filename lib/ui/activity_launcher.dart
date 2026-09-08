import 'package:flutter/material.dart';

import '../models/activity.dart';
import 'concept_screen.dart';
import 'er_designer_screen.dart';
import 'normalization_screen.dart';
import 'sql_lab_screen.dart';

/// Abre la pantalla que corresponde al tipo de actividad.
Future<void> openActivity(BuildContext context, Activity activity) {
  late final Widget screen;
  switch (activity.kind) {
    case ActivityKind.concept:
      screen = ConceptScreen(activity: activity as ConceptActivity);
      break;
    case ActivityKind.erDesign:
      screen = ErDesignerScreen(activity: activity as ErDesignActivity);
      break;
    case ActivityKind.normalization:
      screen =
          NormalizationScreen(activity: activity as NormalizationActivity);
      break;
    case ActivityKind.sqlLab:
      screen = SqlLabScreen(activity: activity as SqlLabActivity);
      break;
  }
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => screen),
  );
}

IconData iconFor(ActivityKind kind) {
  switch (kind) {
    case ActivityKind.concept:
      return Icons.psychology_alt_outlined;
    case ActivityKind.erDesign:
      return Icons.schema_outlined;
    case ActivityKind.normalization:
      return Icons.call_split_outlined;
    case ActivityKind.sqlLab:
      return Icons.terminal_outlined;
  }
}

String labelFor(ActivityKind kind) {
  switch (kind) {
    case ActivityKind.concept:
      return 'Criterio';
    case ActivityKind.erDesign:
      return 'Diagramador';
    case ActivityKind.normalization:
      return 'Descomposicion';
    case ActivityKind.sqlLab:
      return 'Consola SQL';
  }
}
