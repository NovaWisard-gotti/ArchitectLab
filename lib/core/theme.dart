import 'package:flutter/material.dart';

/// Identidad visual: "blueprint de base de datos".
/// Fondo de tinta azul-pizarra, superficies tipo ficha tecnica, dorado
/// reservado exclusivamente para claves y acentos de correccion.
class Blueprint {
  static const ink = Color(0xFF0E1621);
  static const surface = Color(0xFF16212E);
  static const surfaceHigh = Color(0xFF1E2C3C);
  static const line = Color(0xFF2C3E52);
  static const teal = Color(0xFF2FB6A8);
  static const key = Color(0xFFE0A64B);
  static const link = Color(0xFF6FA8DC);
  static const danger = Color(0xFFE2685E);
  static const ok = Color(0xFF57C08A);
  static const text = Color(0xFFE8EEF4);
  static const muted = Color(0xFF94A6B8);

  static const mono = 'monospace';
}

class AppTheme {
  static ThemeData build() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: Blueprint.ink,
      colorScheme: base.colorScheme.copyWith(
        primary: Blueprint.teal,
        secondary: Blueprint.key,
        surface: Blueprint.surface,
        error: Blueprint.danger,
        onPrimary: Blueprint.ink,
        onSurface: Blueprint.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Blueprint.ink,
        foregroundColor: Blueprint.text,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Blueprint.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Blueprint.line),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerColor: Blueprint.line,
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Blueprint.surfaceHigh,
        side: const BorderSide(color: Blueprint.line),
        labelStyle: const TextStyle(color: Blueprint.text, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Blueprint.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Blueprint.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Blueprint.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Blueprint.teal),
        ),
        labelStyle: const TextStyle(color: Blueprint.muted),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Blueprint.teal,
          foregroundColor: Blueprint.ink,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Blueprint.text,
          side: const BorderSide(color: Blueprint.line),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Blueprint.text,
        displayColor: Blueprint.text,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Blueprint.surfaceHigh,
        contentTextStyle: TextStyle(color: Blueprint.text),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Blueprint.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Blueprint.line),
        ),
      ),
    );
  }
}
