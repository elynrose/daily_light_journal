import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/ink_storage.dart';

class HandwritingCanvas extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final double fontScale;

  const HandwritingCanvas({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.fontScale = 1.0,
  });

  @override
  State<HandwritingCanvas> createState() => _HandwritingCanvasState();
}

class _HandwritingCanvasState extends State<HandwritingCanvas> {
  late List<List<List<double>>> _strokes;
  List<List<double>> _currentStroke = [];

  @override
  void initState() {
    super.initState();
    _strokes = isInkPage(widget.initialValue)
        ? cloneStrokes(decodeInkStrokes(widget.initialValue))
        : [];
  }

  @override
  void didUpdateWidget(covariant HandwritingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        isInkPage(widget.initialValue)) {
      _strokes = cloneStrokes(decodeInkStrokes(widget.initialValue));
    }
  }

  void _notifyChanged() {
    widget.onChanged(encodeInkStrokes(_strokes));
  }

  void _startStroke(Offset position) {
    setState(() {
      _currentStroke = [
        [position.dx, position.dy],
      ];
    });
  }

  void _extendStroke(Offset position) {
    if (_currentStroke.isEmpty) return;
    setState(() {
      _currentStroke.add([position.dx, position.dy]);
    });
  }

  void _endStroke() {
    if (_currentStroke.length < 2) {
      _currentStroke = [];
      return;
    }
    setState(() {
      _strokes.add(List<List<double>>.from(_currentStroke));
      _currentStroke = [];
    });
    _notifyChanged();
  }

  void _undoStroke() {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.removeLast();
    });
    _notifyChanged();
  }

  void _clearCanvas() {
    setState(() {
      _strokes = [];
      _currentStroke = [];
    });
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    final allStrokes = [
      ..._strokes,
      if (_currentStroke.isNotEmpty) _currentStroke,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Handwriting',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 16 * widget.fontScale,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Undo stroke',
              onPressed: _strokes.isEmpty ? null : _undoStroke,
              icon: const Icon(Icons.undo, color: AppColors.text),
            ),
            IconButton(
              tooltip: 'Clear canvas',
              onPressed: _strokes.isEmpty ? null : _clearCanvas,
              icon: const Icon(Icons.delete_outline, color: AppColors.text),
            ),
          ],
        ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onPanStart: (details) => _startStroke(details.localPosition),
                    onPanUpdate: (details) => _extendStroke(details.localPosition),
                    onPanEnd: (_) => _endStroke(),
                    child: CustomPaint(
                      painter: _InkPainter(strokes: allStrokes),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InkPainter extends CustomPainter {
  final List<List<List<double>>> strokes;

  const _InkPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.text
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first[0], stroke.first[1]);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i][0], stroke[i][1]);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}
