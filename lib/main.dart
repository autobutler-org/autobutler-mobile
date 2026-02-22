import 'package:flutter/material.dart';

import 'package:autobutler/models/cirrus_file_node.dart';
import 'package:autobutler/services/cirrus_service.dart';

void main() {
  runApp(const AutobutlerApp());
}

class AutobutlerApp extends StatelessWidget {
  const AutobutlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Autobutler Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF070D19),
        useMaterial3: true,
      ),
      home: const FileBrowserPage(),
    );
  }
}

class FileBrowserPage extends StatefulWidget {
  const FileBrowserPage({super.key});

  @override
  State<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends State<FileBrowserPage> {
  late Future<List<CirrusFileNode>> _filesFuture;
  bool _useMockData = true;

  @override
  void initState() {
    super.initState();
    _reloadFiles();
  }

  void _reloadFiles() {
    _filesFuture = CirrusService.getFiles('', useMockData: _useMockData);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photos'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.grid_view_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload_rounded),
                  label: const Text('Upload'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: const Text('New Folder'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'cirrus',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          CheckboxListTile(
            value: _useMockData,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('Use mock data'),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _useMockData = value;
                _reloadFiles();
              });
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                top: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.6),
                ),
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
          ),
          Expanded(
            child: FutureBuilder<List<CirrusFileNode>>(
              future: _filesFuture,
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
                      trailing: const Icon(Icons.more_vert),
                      onTap: () {},
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
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
