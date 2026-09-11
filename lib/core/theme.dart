import 'package:flutter/material.dart';

/// Identidad visual: "blueprint de base de datos", sobre papel claro.
/// Fondo tipo papel de plano, superficies tipo ficha técnica, dorado
/// reservado exclusivamente para claves y acentos de corrección.
/// Esta paleta es fija: no cambia con el modo claro/oscuro del sistema.
class Blueprint {
  static const ink = Color(0xFFF2F5F9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceHigh = Color(0xFFE7ECF2);
  static const line = Color(0xFFCBD5E0);
  static const teal = Color(0xFF0F7A6C);
  static const key = Color(0xFFA8660B);
  static const link = Color(0xFF2A5DB0);
  static const danger = Color(0xFFB03A2E);
  static const ok = Color(0xFF1E8449);
  static const text = Color(0xFF16212E);
  static const muted = Color(0xFF57667A);

  static const mono = 'monospace';
}

class AppTheme {
  static ThemeData build() {
    final base = ThemeData.light(useMaterial3: true);
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
        backgroundColor: Blueprint.text,
        contentTextStyle: TextStyle(color: Blueprint.ink),
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
