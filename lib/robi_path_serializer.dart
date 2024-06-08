import 'dart:convert';
import 'dart:io';

import 'package:robi_line_drawer/robi_utils.dart';

class InstructionContainer {
  late final AvailableInstruction type;
  late final MissionInstruction instruction;

  static AvailableInstruction getInstructionTypeFromString(String s) {
    for (AvailableInstruction element in AvailableInstruction.values) {
      if (element.name == s) return element;
    }
    throw UnsupportedError("");
  }

  InstructionContainer(this.type, this.instruction);

  InstructionContainer.fromJson(Map<String, dynamic> json) {
    type = getInstructionTypeFromString(json["type"]);
    if (type == AvailableInstruction.driveInstruction) {
      instruction = DriveInstruction.fromJson(json["instruction"]);
    } else if (type == AvailableInstruction.turnInstruction) {
      instruction = TurnInstruction.fromJson(json["instruction"]);
    }
  }

  Map<String, dynamic> toJson() => {
        "type": type.name,
        "instruction": instruction.toJson(),
      };
}

class RobiPathSerializer {
  static Future<File> saveToFile(
          File file, List<MissionInstruction> instructions) =>
      file.writeAsString(encoding: ascii, encode(instructions));

  static String encode(List<MissionInstruction> instructions) {
    final List<InstructionContainer> containers = [];
    for (final inst in instructions) {
      AvailableInstruction type;
      if (inst is DriveInstruction) {
        type = AvailableInstruction.driveInstruction;
      } else if (inst is TurnInstruction) {
        type = AvailableInstruction.turnInstruction;
      } else {
        throw UnsupportedError("");
      }
      containers.add(InstructionContainer(type, inst));
    }
    return jsonEncode(containers.map((e) => e.toJson()).toList());
  }

  static Iterable<MissionInstruction>? decode(String json) {
    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((e) => InstructionContainer.fromJson(e).instruction);
    } on Exception {
      return null;
    }
  }
}