import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MnemonicInputGrid extends StatelessWidget {
  const MnemonicInputGrid({
    super.key,
    required this.controllers,
    this.columns = 2,
    this.enabled = true,
    this.minimumTileWidth = 220,
  }) : assert(columns > 0),
       assert(minimumTileWidth > 0);

  final List<TextEditingController> controllers;
  final int columns;
  final bool enabled;
  final double minimumTileWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableColumns = (constraints.maxWidth / minimumTileWidth).floor().clamp(
          1,
          columns,
        );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controllers.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: availableColumns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 64,
          ),
          itemBuilder: (context, index) {
            return _MnemonicWordInput(
              number: index + 1,
              controller: controllers[index],
              enabled: enabled,
              textInputAction: index == controllers.length - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
            );
          },
        );
      },
    );
  }
}

class _MnemonicWordInput extends StatelessWidget {
  const _MnemonicWordInput({
    required this.number,
    required this.controller,
    required this.enabled,
    required this.textInputAction,
  });

  final int number;
  final TextEditingController controller;
  final bool enabled;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            key: ValueKey('mnemonicWordInput$number'),
            controller: controller,
            enabled: enabled,
            autocorrect: false,
            enableSuggestions: false,
            enableIMEPersonalizedLearning: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            keyboardType: TextInputType.visiblePassword,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                return newValue.copyWith(text: newValue.text.toLowerCase());
              }),
            ],
            textInputAction: textInputAction,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'Word',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
