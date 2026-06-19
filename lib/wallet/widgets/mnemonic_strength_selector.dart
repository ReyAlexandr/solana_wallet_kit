import 'package:flutter/material.dart';
import '../models/mnemonic_strength.dart';

class MnemonicStrengthSelector extends StatelessWidget {
  const MnemonicStrengthSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.options = MnemonicStrength.values,
  });

  final MnemonicStrength value;
  final ValueChanged<MnemonicStrength> onChanged;
  final List<MnemonicStrength> options;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MnemonicStrength>(
      segments: [
        for (final strength in options) ButtonSegment(value: strength, label: Text(strength.label)),
      ],
      selected: {value},
      onSelectionChanged: (selection) {
        onChanged(selection.first);
      },
    );
  }
}
