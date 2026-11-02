import 'package:flutter/material.dart';

const Color seedColor = Color(0xFF4F46E5);

const List<Color> chartPalette = <Color>[
  Color(0xFF4F46E5),
  Color(0xFF0EA5E9),
  Color(0xFF14B8A6),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF8B5CF6),
  Color(0xFF22C55E),
  Color(0xFFF97316),
  Color(0xFFEC4899),
  Color(0xFF06B6D4),
  Color(0xFF84CC16),
  Color(0xFF6366F1),
];

ThemeData buildAppTheme(Brightness brightness) {
  final scheme =
      ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        isDark ? const Color(0xFF0C0E14) : const Color(0xFFF4F5FA),
    dividerColor: scheme.outlineVariant.withValues(alpha: 0.6),
  );
}

BoxDecoration panelDecoration(
  BuildContext context, {
  double radius = 16,
  Color? color,
}) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: color ?? scheme.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
    boxShadow: isDark
        ? null
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
  );
}

InputDecoration appInputDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool isDense = true,
  bool alignLabelWithHint = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    isDense: isDense,
    alignLabelWithHint: alignLabelWithHint,
    filled: true,
    fillColor: scheme.surfaceContainerLowest,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: border(scheme.outlineVariant),
    enabledBorder: border(scheme.outlineVariant),
    focusedBorder: border(scheme.primary, 1.6),
    errorBorder: border(scheme.error),
    focusedErrorBorder: border(scheme.error, 1.6),
  );
}
