import 'dart:math' as math;
import 'package:flutter/material.dart';

class SalesTrendCard extends StatefulWidget {
  final List<double> values;
  const SalesTrendCard({super.key, required this.values});
  @override
  State<SalesTrendCard> createState() => _SalesTrendCardState();
}

class _SalesTrendCardState extends State<SalesTrendCard> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final total = widget.values.fold<double>(0, (sum, value) => sum + value);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6DED2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('Sales · Last 10 Days', style: TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.w800))),
          Text(r'$' + total.toStringAsFixed(2), style: const TextStyle(color: _gold, fontSize: 17, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 4),
        Text(
          selectedIndex == null
              ? 'Tap the trend line to inspect a day'
              : _label(selectedIndex!) + '  ·  ' + r'$' + widget.values[selectedIndex!].toStringAsFixed(2),
          style: const TextStyle(color: Color(0xFF718087), fontSize: 12),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 160,
          child: LayoutBuilder(builder: (context, constraints) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              if (widget.values.isEmpty) return;
              final raw = ((details.localPosition.dx / constraints.maxWidth) * (widget.values.length - 1)).round();
              setState(() => selectedIndex = raw.clamp(0, widget.values.length - 1));
            },
            child: CustomPaint(
              size: Size(constraints.maxWidth, 160),
              painter: _SalesTrendPainter(widget.values, selectedIndex),
            ),
          )),
        ),
        if (total == 0)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('No delivered sales in the last 10 days yet.', style: TextStyle(color: Color(0xFF718087), fontSize: 12)),
          ),
      ]),
    );
  }

  String _label(int index) {
    final date = DateTime.now().subtract(Duration(days: 9 - index));
    return date.month.toString() + '/' + date.day.toString();
  }
}

class _SalesTrendPainter extends CustomPainter {
  final List<double> values;
  final int? selectedIndex;
  const _SalesTrendPainter(this.values, this.selectedIndex);
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final grid = Paint()..color = const Color(0xFFEDE7DE)..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = 12 + (size.height - 28) * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final maxValue = math.max(values.reduce(math.max), 1.0);
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? size.width / 2 : i * size.width / (values.length - 1);
      final y = size.height - 18 - (values[i] / maxValue) * (size.height - 38);
      points.add(Offset(x, y));
    }
    final fillPath = Path()..moveTo(points.first.dx, size.height - 18);
    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath.lineTo(points.last.dx, size.height - 18);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = _gold.withOpacity(.10));

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1], current = points[i];
      final midX = (previous.dx + current.dx) / 2;
      path.cubicTo(midX, previous.dy, midX, current.dy, current.dx, current.dy);
    }
    canvas.drawPath(path, Paint()..color = _gold..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    for (var i = 0; i < points.length; i++) {
      if (values[i] > 0 || selectedIndex == i) {
        canvas.drawCircle(points[i], selectedIndex == i ? 6 : 3.5, Paint()..color = selectedIndex == i ? _navy : _gold);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SalesTrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.selectedIndex != selectedIndex;
}
