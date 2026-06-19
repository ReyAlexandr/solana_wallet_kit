import 'package:flutter/material.dart';

class MnemonicGrid extends StatelessWidget {
  const MnemonicGrid({
    super.key,
    required this.words,
    this.columns = 2,
    this.minimumTileWidth = 220,
  }) : assert(columns > 0),
       assert(minimumTileWidth > 0);

  final List<String> words;
  final int columns;
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
          itemCount: words.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: availableColumns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 56,
          ),
          itemBuilder: (context, index) {
            return _MnemonicWord(number: index + 1, word: words[index]);
          },
        );
      },
    );
  }
}

class _MnemonicWord extends StatelessWidget {
  const _MnemonicWord({required this.number, required this.word});

  final int number;
  final String word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
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
              child: Text(
                word,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
