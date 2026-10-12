import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'comic_panel.dart';
import 'star_row.dart';

/// One stop on a trail map. Games build these from their own level models,
/// keeping all unlock/star logic in the game — this widget only draws.
class TrailNodeData {
  const TrailNodeData({
    required this.label,
    required this.title,
    required this.color,
    required this.unlocked,
    required this.stars,
    required this.isBoss,
    this.onTap,
  });

  /// What shows in the node bubble: a number for a normal stop, an emoji for a
  /// boss/guardian, or a lock when still locked (the widget picks).
  final String label;

  /// Caption under the bubble (e.g. "Stop 2" / "Guardian").
  final String title;

  /// The node's theme color when unlocked.
  final Color color;

  final bool unlocked;
  final int stars;
  final bool isBoss;

  /// Null when locked (the node is not tappable).
  final VoidCallback? onTap;

  bool get completed => stars > 0;
}

/// A polished, comic-styled winding trail shared by all six games.
///
/// Nodes alternate between the start and end sides; a dashed comic connector is
/// drawn behind them. Because sides are expressed with [AlignmentDirectional]
/// and the connector is painted using the ambient [TextDirection], the whole
/// trail mirrors naturally in Hebrew (RTL) with no per-game branching.
///
/// Sizes come from [LayoutBuilder]/`constraints.maxWidth` (never
/// `MediaQuery.size`) so it stays inside the 430px phone frame.
class TrailMapView extends StatelessWidget {
  const TrailMapView({
    super.key,
    required this.nodes,
    required this.pathColor,
    this.listenable,
  });

  final List<TrailNodeData> nodes;

  /// Color of the drawn connecting path (usually the world/habitat color).
  final Color pathColor;

  /// Optional animation to rebuild on (e.g. a game's state ChangeNotifier).
  final Listenable? listenable;

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Node column takes ~62% of the width; the connector fills the rest.
        final nodeWidth = (width * 0.62).clamp(150.0, 240.0);
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 22),
          itemCount: nodes.length,
          itemBuilder: (context, i) {
            final atStart = i.isEven;
            final isLast = i == nodes.length - 1;
            return _TrailRow(
              data: nodes[i],
              atStart: atStart,
              nodeWidth: nodeWidth,
              pathColor: pathColor,
              drawConnectorDown: !isLast,
              nextAtStart: isLast ? atStart : !atStart,
            );
          },
        );
      },
    );
    if (listenable == null) return content;
    return AnimatedBuilder(
      animation: listenable!,
      builder: (context, _) => content,
    );
  }
}

class _TrailRow extends StatelessWidget {
  const _TrailRow({
    required this.data,
    required this.atStart,
    required this.nodeWidth,
    required this.pathColor,
    required this.drawConnectorDown,
    required this.nextAtStart,
  });

  final TrailNodeData data;
  final bool atStart;
  final double nodeWidth;
  final Color pathColor;
  final bool drawConnectorDown;
  final bool nextAtStart;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return CustomPaint(
      painter: _ConnectorPainter(
        color: pathColor,
        atStart: atStart,
        nextAtStart: nextAtStart,
        drawDown: drawConnectorDown,
        rtl: rtl,
      ),
      child: Align(
        alignment:
            atStart ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: atStart ? 20 : 0,
            end: atStart ? 0 : 20,
            top: 10,
            bottom: 10,
          ),
          child: SizedBox(width: nodeWidth, child: _TrailNode(data: data)),
        ),
      ),
    );
  }
}

class _TrailNode extends StatelessWidget {
  const _TrailNode({required this.data});

  final TrailNodeData data;

  @override
  Widget build(BuildContext context) {
    final color = data.isBoss
        ? data.color
        : (data.unlocked ? data.color : Colors.grey);
    final bubble = data.isBoss
        ? data.label
        : (data.unlocked ? data.label : '🔒');

    return GestureDetector(
      onTap: data.onTap,
      child: Opacity(
        opacity: data.unlocked ? 1 : 0.55,
        child: ComicPanel(
          color: color,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // A circular medallion gives the node a nicer, badge-like look
              // and clearly separates boss nodes (bigger) from normal stops.
              Container(
                width: data.isBoss ? 60 : 48,
                height: data.isBoss ? 60 : 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: Text(
                  bubble,
                  style: TextStyle(
                    fontSize: data.isBoss ? 32 : 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: AppTheme.ink, offset: Offset(2, 2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (data.unlocked) ...[
                const SizedBox(height: 4),
                StarRow(earned: data.stars, size: 17),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints the dashed comic connector that links a node to the next one below.
/// The curve bows toward the center and swaps sides depending on which side the
/// current and next nodes sit, mirroring correctly in RTL.
class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({
    required this.color,
    required this.atStart,
    required this.nextAtStart,
    required this.drawDown,
    required this.rtl,
  });

  final Color color;
  final bool atStart;
  final bool nextAtStart;
  final bool drawDown;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (!drawDown) return;
    final paint = Paint()
      ..color = color.withOpacity(0.85)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Resolve "start"/"end" to physical left/right for the current language.
    double sideX(bool start) {
      final physicalStartLeft = !rtl;
      final onLeft = start == physicalStartLeft;
      return onLeft ? size.width * 0.28 : size.width * 0.72;
    }

    final fromX = sideX(atStart);
    final toX = sideX(nextAtStart);
    final fromY = size.height * 0.72;
    final toY = size.height + size.height * 0.28;

    final path = Path()
      ..moveTo(fromX, fromY)
      ..cubicTo(
        fromX, (fromY + toY) / 2,
        toX, (fromY + toY) / 2,
        toX, toY,
      );
    _drawDashed(canvas, path, paint);
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dash = 10.0;
    const gap = 7.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final next = dist + dash;
        canvas.drawPath(
          metric.extractPath(dist, next.clamp(0, metric.length)),
          paint,
        );
        dist = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.color != color ||
      old.atStart != atStart ||
      old.nextAtStart != nextAtStart ||
      old.drawDown != drawDown ||
      old.rtl != rtl;
}
