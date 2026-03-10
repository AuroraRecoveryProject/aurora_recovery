import 'package:flutter/material.dart';

import '../theme.dart';
import 'package:flutter/material.dart';

class ThemePreviewPage extends StatefulWidget {
  const ThemePreviewPage({super.key});

  @override
  State<ThemePreviewPage> createState() => _ThemePreviewPageState();
}

class _ThemePreviewPageState extends State<ThemePreviewPage> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: ThemePreview(theme: darkTheme)),
        Expanded(child: ThemePreview(theme: lightTheme)),
      ],
    );
  }
}

class ThemePreview extends StatelessWidget {
  const ThemePreview({super.key, required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;

          return Material(
            color: cs.surface,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle("Brand Colors"),
                _colorTile("primary", cs.primary, cs.onPrimary),
                _colorTile("secondary", cs.secondary, cs.onSecondary),
                _colorTile("error", cs.error, cs.onError),
                const SizedBox(height: 24),
                _sectionTitle("Surface Hierarchy"),
                _colorTile("surface", cs.surface, cs.onSurface),
                _colorTile("surfaceContainerHighest", cs.surfaceContainerHighest, cs.onSurface),
                _colorTile("surfaceContainerHigh", cs.surfaceContainerHigh, cs.onSurface),
                _colorTile("surfaceContainer", cs.surfaceContainer, cs.onSurface),
                _colorTile("surfaceContainerLow", cs.surfaceContainerLow, cs.onSurface),
                _colorTile("surfaceContainerLowest", cs.surfaceContainerLowest, cs.onSurface),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _colorTile(String name, Color color, Color textColor) {
    final hex = '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        "$name   $hex",
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
