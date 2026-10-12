import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/comic_panel.dart';

/// A friendly "build-the-fact" visual for a multiplication level: `a` rows by
/// `b` columns of comic dots, with the equation `a × b = ?` shown as an
/// LTR island above the grid.
///
/// The whole widget is wrapped in [Directionality] LTR so the equation and the
/// grid read correctly even under Hebrew (RTL). Sizes come from
/// [LayoutBuilder]/`constraints.maxWidth` (never `MediaQuery.of(context).size`)
/// so it stays inside the 430px phone frame; cells shrink to a floor and the
/// grid scrolls if a large product (up to 12×12) still would not fit.
class MultArrayView extends StatelessWidget {
  const MultArrayView({
    super.key,
    required this.a,
    required this.b,
    required this.hint,
  });

  /// Number of rows (first factor).
  final int a;

  /// Number of columns (second factor).
  final int b;

  /// Localized "count the dots" style hint shown under the grid.
  final String hint;

  static const double _spacing = 5;
  static const double _minCell = 10;
  static const double _maxCell = 26;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ComicPanel(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$a × $b = ?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink,
                shadows: [Shadow(color: AppTheme.accent, offset: Offset(2, 2))],
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth;
                // Fit `b` columns across the available width.
                var cell =
                    ((maxW - (b - 1) * _spacing) / b).clamp(_minCell, _maxCell);
                final gridW = b * cell + (b - 1) * _spacing;
                final gridH = a * cell + (a - 1) * _spacing;
                // Cap the drawn height so even 12×12 never pushes the choices
                // off-screen; scroll inside this box if the grid is taller.
                const maxGridH = 240.0;

                final grid = SizedBox(
                  width: gridW,
                  height: gridH,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var r = 0; r < a; r++) ...[
                        if (r > 0) const SizedBox(height: _spacing),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var c = 0; c < b; c++) ...[
                              if (c > 0) const SizedBox(width: _spacing),
                              _Dot(size: cell, row: r),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                );

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: maxGridH),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Center(child: grid),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One comic dot. Rows alternate between two friendly colors so the array is
/// easy to count by row.
class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.row});

  final double size;
  final int row;

  @override
  Widget build(BuildContext context) {
    final color = row.isEven ? AppTheme.primary : AppTheme.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.ink, width: 1.5),
      ),
    );
  }
}
