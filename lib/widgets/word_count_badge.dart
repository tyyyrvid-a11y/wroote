import 'package:flutter/material.dart';

class WordCountBadge extends StatelessWidget {
  final int count;

  const WordCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.short_text, size: 14),
          const SizedBox(width: 6),
          Text(
            '$count ${count == 1 ? 'palavra' : 'palavras'}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
