import 'dart:math';

import 'package:flutter/material.dart';
import 'package:robi_line_drawer/editor/painters/ir_read_painter.dart';
import 'package:robi_line_drawer/editor/painters/robi_painter.dart';
import 'package:robi_line_drawer/editor/painters/simulation_painter.dart';
import 'package:robi_line_drawer/robi_api/ir_read_api.dart';
import 'package:robi_line_drawer/robi_api/robi_utils.dart';
import 'package:vector_math/vector_math.dart' show Vector2;

import 'abstract_painter.dart';

const Color white = Color(0xFFFFFFFF);

class LinePainter extends CustomPainter {
  final double scale;
  final Offset offset;
  final RobiConfig robiConfig;
  final SimulationResult simulationResult;
  final IrReadPainterSettings irReadPainterSettings;
  final InstructionResult? highlightedInstruction;
  final IrCalculatorResult? irCalculatorResult;
  final List<Vector2>? irPathApproximation;
  final RobiState robiState;

  LinePainter({
    super.repaint,
    required this.scale,
    required this.robiConfig,
    required this.irReadPainterSettings,
    required this.simulationResult,
    required this.highlightedInstruction,
    this.irCalculatorResult,
    this.irPathApproximation,
    required this.offset,
    required this.robiState,
  });

  static void paintText(String text, Offset offset, Canvas canvas, Size size, {bool center = true, TextStyle? textStyle}) {
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    if (center) {
      textPainter.paint(canvas, Offset(offset.dx - textPainter.width / 2, offset.dy - textPainter.height));
    } else {
      textPainter.paint(canvas, offset);
    }
  }

  void paintGrid(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..strokeWidth = 1
      ..color = white.withAlpha(100);

    final int xLineCount = size.width ~/ scale + 1;
    final int yLineCount = size.height ~/ scale + 1;

    for (double xo = size.width / 2 + offset.dx % scale - scale * xLineCount; xo < xLineCount * scale; xo += scale) {
      canvas.drawLine(Offset(xo, 0), Offset(xo, size.height), paint);
    }

    for (double yo = size.height / 2 + offset.dy % scale - scale * yLineCount; yo < yLineCount * scale; yo += scale) {
      canvas.drawLine(Offset(0, yo), Offset(size.width, yo), paint);
    }

    paint.color = white.withAlpha(50);

    for (double xo = size.width / 2 + offset.dx % scale - scale * xLineCount + 0.5 * scale; xo < xLineCount * scale; xo += scale) {
      canvas.drawLine(Offset(xo, 0), Offset(xo, size.height), paint);
    }

    for (double yo = size.height / 2 + offset.dy % scale - scale * yLineCount + 0.5 * scale; yo < yLineCount * scale; yo += scale) {
      canvas.drawLine(Offset(0, yo), Offset(size.width, yo), paint);
    }
  }

  void paintScale(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..strokeWidth = 1
      ..color = white;

    canvas.drawLine(Offset(size.width / 2 - 49, size.height - 20), Offset(size.width / 2 + 49, size.height - 20), paint);
    canvas.drawLine(Offset(size.width / 2 - 50, size.height - 25), Offset(size.width / 2 - 50, size.height - 15), paint);
    canvas.drawLine(Offset(size.width / 2 + 50, size.height - 25), Offset(size.width / 2 + 50, size.height - 15), paint);

    LinePainter.paintText("${(100.0 / scale).toStringAsFixed(2)}m", Offset(size.width / 2, size.height - 22), canvas, size);
  }

  void paintRobiState(Canvas canvas, Size size) {
    final String xPosText = (robiState.position.x * 100).toStringAsFixed(0);
    final String innerVelText = (robiState.innerVelocity * 100).toStringAsFixed(0);
    final String innerAccelText = (robiState.innerAcceleration * 100).toStringAsFixed(0);
    final String posSpace = " " * (8 - xPosText.length);
    final String velSpace = " " * (6 - innerVelText.length);
    final String accelSpace = " " * (5 - innerAccelText.length);

    final String robiStateText = """
Rot.: ${robiState.rotation.toStringAsFixed(2)}°
Pos.: X ${xPosText}cm${posSpace}Y ${(robiState.position.y * 100).toInt()}cm
Vel.: I ${innerVelText}cm/s${velSpace}O ${(robiState.outerVelocity * 100).toInt()}cm/s
Acc.: I ${innerAccelText}cm/s²${accelSpace}O ${(robiState.outerAcceleration * 100).toInt()}cm/s²""";

    paintText(
      robiStateText,
      Offset(5, size.height - 70),
      canvas,
      size,
      center: false,
      textStyle: const TextStyle(fontFamily: "RobotoMono", fontSize: 12),
    );
  }

  void paintVelocityScale(Canvas canvas, Size size) {
    if (simulationResult.maxTargetedVelocity <= 0) return;

    List<Color> colors = [velToColor(0, simulationResult.maxTargetedVelocity), velToColor(simulationResult.maxTargetedVelocity, simulationResult.maxTargetedVelocity)];

    final lineStart = Offset(size.width - 130, size.height - 20);
    final lineEnd = Offset(size.width - 30, size.height - 20);

    final accelerationPaint = Paint()
      ..shader = RadialGradient(
        colors: colors,
        radius: 0.5 / sqrt2,
      ).createShader(Rect.fromCircle(center: lineStart, radius: lineEnd.dx - lineStart.dx))
      ..strokeWidth = 10;

    canvas.drawLine(lineStart, lineEnd, accelerationPaint);
    canvas.drawLine(
        lineStart.translate(-1, -5),
        lineStart.translate(-1, 5),
        Paint()
          ..color = white
          ..strokeWidth = 1);
    canvas.drawLine(
        lineEnd.translate(1, -5),
        lineEnd.translate(1, 5),
        Paint()
          ..color = white
          ..strokeWidth = 1);
    LinePainter.paintText("0m/s", lineStart.translate(0, -7), canvas, size);
    LinePainter.paintText("${simulationResult.maxTargetedVelocity.toStringAsFixed(2)}m/s", lineEnd.translate(0, -7), canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  @override
  void paint(Canvas canvas, Size size) {
    paintGrid(canvas, size);

    canvas.save();

    final Offset center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx + offset.dx, center.dy + offset.dy);
    canvas.scale(scale);

    if (irCalculatorResult != null) assert(irPathApproximation != null);
    final List<MyPainter> painters = [
      SimulationPainter(
        simulationResult: simulationResult,
        canvas: canvas,
        size: size,
        highlightedInstruction: highlightedInstruction,
      ),
      if (irCalculatorResult != null)
        IrReadPainter(
          robiConfig: robiConfig,
          settings: irReadPainterSettings,
          canvas: canvas,
          size: size,
          irCalculatorResult: irCalculatorResult!,
          pathApproximation: irPathApproximation!,
        ),
      RobiPainter(
        robiState: robiState,
        canvas: canvas,
        simulationResult: simulationResult,
      ),
    ];

    for (final painter in painters) {
      painter.paint();
    }

    canvas.restore();

    paintRobiState(canvas, size);
    paintScale(canvas, size);
    paintVelocityScale(canvas, size);
  }
}
