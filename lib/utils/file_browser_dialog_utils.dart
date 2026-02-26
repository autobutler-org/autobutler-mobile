import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<String?> promptForFolderName(BuildContext context) async {
  final value = await _promptForText(
    context: context,
    title: 'New Folder',
    hintText: 'Folder name',
    confirmLabel: 'Create',
  );

  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) {
    return null;
  }

  return normalized.replaceAll(RegExp(r'^/+|/+$'), '');
}

Future<String?> promptForMoveRenamePath(BuildContext context) {
  return _promptForText(
    context: context,
    title: 'Move / Rename',
    hintText: 'New name or path',
    confirmLabel: 'Save',
  );
}

Future<bool?> confirmDelete(BuildContext context, String itemName) async {
  await Future<void>.delayed(Duration.zero);
  if (!context.mounted) {
    return null;
  }

  return showAdaptiveDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) {
      return AlertDialog.adaptive(
        title: const Text('Delete'),
        content: Text('Delete $itemName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}

Future<String?> _promptForText({
  required BuildContext context,
  required String title,
  required String hintText,
  required String confirmLabel,
}) async {
  await Future<void>.delayed(Duration.zero);
  if (!context.mounted) {
    return null;
  }

  final textController = TextEditingController();
  final platform = Theme.of(context).platform;
  final isCupertinoPlatform =
      platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

  final String? value;
  if (isCupertinoPlatform) {
    value = await showCupertinoDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: textController,
              autofocus: true,
              placeholder: hintText,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                Navigator.of(dialogContext).pop(textController.text.trim());
              },
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop(textController.text.trim());
              },
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  } else {
    value = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: InputDecoration(hintText: hintText),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              Navigator.of(dialogContext).pop(textController.text.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(textController.text.trim());
              },
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  textController.dispose();

  final normalized = (value ?? '').trim();
  if (normalized.isEmpty) {
    return null;
  }

  return normalized;
}
