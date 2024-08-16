import 'package:flutter/material.dart';
import 'package:robi_line_drawer/editor/instructions/abstract.dart';

import '../../robi_api/robi_utils.dart';
import '../editor.dart';

class RapidTurnInstructionEditor extends AbstractEditor {
  @override
  final RapidTurnInstruction instruction;

  RapidTurnInstructionEditor({
    super.key,
    required this.instruction,
    required super.simulationResult,
    required super.instructionIndex,
    required super.change,
    required super.removed,
    required super.entered,
    required super.exited,
  }) : super(instruction: instruction);

  @override
  Widget build(BuildContext context) {
    return RemovableWarningCard(
      change: change,
      entered: entered,
      exited: exited,
      instruction: instruction,
      warningMessage: warningMessage,
      removed: removed,
      instructionResult: instructionResult,
      header: Card.filled(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(
                  instruction.left ? Icons.turn_left : Icons.turn_right, size: 18),
              const SizedBox(width: 8),
              Text("${instruction.left? "Left" : "Right"} Rapid Turn"),
            ],
          ),
        ),
      ),
      children: [
        Row(
          children: [
            const Text("Turn Degree"),
            Slider(
              value: instruction.turnDegree,
              onChanged: (value) {
                instruction.turnDegree = value;
                change(instruction);
              },
              min: 0,
              max: 720,
            ),
            Text("${roundToDigits(instruction.turnDegree, 2)}°"),
          ],
        ),
        Row(
          children: [
            const Text("Turn Left "),
            Checkbox(
              value: instruction.left,
              onChanged: (value) {
                instruction.left = value!;
                change(instruction);
              },
            ),
          ],
        ),
      ],
    );
  }
}