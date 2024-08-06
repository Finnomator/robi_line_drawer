import 'dart:math';

import 'package:flutter/material.dart';
import 'package:robi_line_drawer/editor/instructions/abstract.dart';

import '../../robi_api/robi_utils.dart';
import '../add_instruction_dialog.dart';
import '../editor.dart';

class DecelerateOverTimeEditor extends AbstractEditor {
  @override
  final AccelerateOverTimeInstruction instruction;

  DecelerateOverTimeEditor({
    super.key,
    required this.instruction,
    required super.simulationResult,
    required super.instructionIndex,
    required super.change,
    required super.removed,
    required super.entered,
    required super.exited,
  }) : super(instruction: instruction) {
    DriveResult inst = instructionResult as DriveResult;
    double decelerationTime = sqrt(2 *
        (inst.decelerationStartPoint.distanceTo(inst.endPosition)) /
        instruction.acceleration.abs());
    if (instruction.acceleration >= 0 || instruction.time <= 0) {
      warningMessage = "Pointless";
    } else if (prevInstructionResult.maxVelocity <= 0) {
      warningMessage = "Cannot decelerate further";
    } else if (decelerationTime < instruction.time) {
      warningMessage =
          "Robi will already stop within ${decelerationTime.toStringAsFixed(2)}s";
    }
  }

  @override
  Widget build(BuildContext context) {
    return RemovableWarningCard(
      instruction: instruction,
      warningMessage: warningMessage,
      removed: removed,
      entered: entered,
      exited: exited,
      prevResult: prevInstructionResult,
      instructionResult: instructionResult,
      children: [
        Icon(userInstructionToIcon[UserInstruction.decelerateOverTime]),
        const SizedBox(width: 10),
        const Text("Decelerate for "),
        IntrinsicWidth(
          child: TextFormField(
            style: const TextStyle(fontSize: 14),
            initialValue: instruction.time.toString(),
            onChanged: (String? value) {
              if (value == null || value.isEmpty) return;
              final tried = double.tryParse(value);
              if (tried == null) return;
              instruction.time = tried;
              change(instruction);
            },
            inputFormatters: inputFormatters,
          ),
        ),
        const Text("s, at "),
        IntrinsicWidth(
          child: TextFormField(
            style: const TextStyle(fontSize: 14),
            initialValue: "${instruction.acceleration.abs() * 100}",
            onChanged: (String? value) {
              if (value == null || value.isEmpty) return;
              final tried = double.tryParse(value);
              if (tried == null) return;
              instruction.acceleration = -tried / 100;
              change(instruction);
            },
            inputFormatters: inputFormatters,
          ),
        ),
        const Text("cm/s²"),
      ],
    );
  }
}
