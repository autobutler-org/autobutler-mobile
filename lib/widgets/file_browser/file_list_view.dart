import 'package:autobutler/models/cirrus_file_node.dart';
import 'package:flutter/material.dart';

enum FileMenuAction { download, moveRename, delete }

class FileListView extends StatelessWidget {
  const FileListView({
    required this.filesFuture,
    required this.onFileMenuAction,
    required this.onOpenDirectory,
    super.key,
  });

  final Future<List<CirrusFileNode>> filesFuture;
  final Future<void> Function(CirrusFileNode, FileMenuAction) onFileMenuAction;
  final void Function(CirrusFileNode) onOpenDirectory;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FutureBuilder<List<CirrusFileNode>>(
      future: filesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load files',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        final files = snapshot.data ?? const <CirrusFileNode>[];
        if (files.isEmpty) {
          return const Center(child: Text('No files found'));
        }

        return ListView.separated(
          itemCount: files.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
          itemBuilder: (context, index) {
            final item = files[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 2,
              ),
              leading: Icon(_iconForNode(item)),
              title: Row(
                children: [
                  Expanded(flex: 5, child: Text(item.name)),
                  Expanded(flex: 2, child: Text(item.deviceName)),
                  Expanded(
                    flex: 2,
                    child: Text(_formatSize(item.size, item.isDir)),
                  ),
                ],
              ),
              trailing: PopupMenuButton<FileMenuAction>(
                icon: const Icon(Icons.more_vert),
                onSelected: (action) => onFileMenuAction(item, action),
                itemBuilder: (context) => const [
                  PopupMenuItem<FileMenuAction>(
                    value: FileMenuAction.download,
                    child: Text('Download'),
                  ),
                  PopupMenuItem<FileMenuAction>(
                    value: FileMenuAction.moveRename,
                    child: Text('Move/Rename'),
                  ),
                  PopupMenuItem<FileMenuAction>(
                    value: FileMenuAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
              onTap: () => onOpenDirectory(item),
            );
          },
        );
      },
    );
  }

  static IconData _iconForNode(CirrusFileNode node) {
    if (node.isDir) {
      return Icons.folder_outlined;
    }

    final lowerName = node.name.toLowerCase();
    if (lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.gif') ||
        lowerName.endsWith('.webp')) {
      return Icons.image_outlined;
    }

    if (lowerName.endsWith('.zip') ||
        lowerName.endsWith('.tar') ||
        lowerName.endsWith('.gz') ||
        lowerName.endsWith('.7z')) {
      return Icons.archive_outlined;
    }

    return Icons.insert_drive_file_outlined;
  }

  static String _formatSize(int bytes, bool isDir) {
    if (isDir) {
      return '--';
    }

    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
