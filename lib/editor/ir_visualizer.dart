import 'package:flutter/material.dart';
import 'package:robi_line_drawer/editor/painters/ir_read_painter.dart';
import 'package:vector_math/vector_math.dart';

import '../robi_api/ir_read_api.dart';
import '../robi_api/robi_utils.dart';
import 'interactable_visualizer.dart';
import 'ir_line_approximation/approximation_settings_widget.dart';
import 'ir_line_approximation/ir_reading_info.dart';

class IrVisualizerWidget extends StatefulWidget {
  final IrReadResult? irReadResult;
  final RobiConfig robiConfig;
  final double time;
  final bool enableTimeInput;

  const IrVisualizerWidget({
    super.key,
    required this.robiConfig,
    required this.irReadResult,
    this.time = 0,
    this.enableTimeInput = true,
  });

  @override
  State<IrVisualizerWidget> createState() => _IrVisualizerWidgetState();
}

class _IrVisualizerWidgetState extends State<IrVisualizerWidget> {
  double ramerDouglasPeuckerTolerance = 0.5;
  IrReadPainterSettings irReadPainterSettings = defaultIrReadPainterSettings();
  int irInclusionThreshold = 100;

  List<Vector2>? irPathApproximation;

  @override
  Widget build(BuildContext context) {
    late final IrCalculatorResult? irCalculatorResult;
    if (widget.irReadResult != null) {
      irCalculatorResult = IrCalculator.calculate(widget.irReadResult!, widget.robiConfig);
      approximateIrPath(irCalculatorResult);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.irReadResult != null) ...[
          Flexible(
            child: InteractableIrVisualizer(
              enableTimeInput: widget.enableTimeInput,
              robiConfig: widget.robiConfig,
              totalTime: widget.irReadResult!.totalTime,
              irCalculatorResult: irCalculatorResult!,
              irPathApproximation: irPathApproximation,
              irReadPainterSettings: irReadPainterSettings,
              irReadResult: widget.irReadResult!,
            ),
          ),
        ] else ...[
          const Center(),
        ],
        const VerticalDivider(width: 0),
        Expanded(
          child: ListView(
            children: [
              IrPathApproximationSettingsWidget(
                onSettingsChange: (
                  settings,
                  irInclusionThreshold,
                  ramerDouglasPeuckerTolerance,
                ) {
                  setState(() {
                    irReadPainterSettings = settings;
                    this.irInclusionThreshold = irInclusionThreshold;
                    this.ramerDouglasPeuckerTolerance = ramerDouglasPeuckerTolerance;
                    if (irCalculatorResult != null) approximateIrPath(irCalculatorResult);
                  });
                },
              ),
              if (widget.irReadResult != null)
                IrReadingInfoWidget(
                  selectedRobiConfig: widget.robiConfig,
                  irReadResult: widget.irReadResult!,
                  irCalculatorResult: irCalculatorResult!,
                ),
            ],
          ),
        ),
      ],
    );
  }

  void approximateIrPath(IrCalculatorResult irCalculatorResult) {
    irPathApproximation = IrCalculator.pathApproximation(
      irCalculatorResult,
      irInclusionThreshold,
      ramerDouglasPeuckerTolerance,
    );
  }

}
