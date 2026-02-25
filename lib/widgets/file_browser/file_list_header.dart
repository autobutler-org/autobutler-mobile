import 'package:flutter/material.dart';

class FileListHeader extends StatelessWidget {
  const FileListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
          bottom: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 6, child: Text('Name')),
          Expanded(flex: 2, child: Text('Device')),
          Expanded(flex: 2, child: Text('Size')),
        ],
      ),
    );
  }
}
