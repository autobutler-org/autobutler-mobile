import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:autobutler/models/cirrus_file_node.dart';
import 'package:autobutler/services/cirrus_service.dart';
import 'dart:io';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

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
  String _currentPath = '';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _reloadFiles();
  }

  void _reloadFiles() {
    _filesFuture = CirrusService.getFiles(_currentPath);
  }

  Future<void> _handleUploadPressed() async {
    if (_isUploading) {
      return;
    }

    final selectedPath = await FlutterFileDialog.pickFile(
      params: const OpenFileDialogParams(copyFileToCacheDir: true),
    );
    if (selectedPath == null || selectedPath.isEmpty) {
      return;
    }
    final selectedFile = File(selectedPath);

    setState(() {
      _isUploading = true;
    });

    try {
      await CirrusService.uploadFiles(_toRootDir(_currentPath), [selectedFile]);

      if (!mounted) {
        return;
      }

      setState(() {
        _reloadFiles();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploaded ${selectedFile.uri.pathSegments.last}'),
        ),
      );
    } on MissingPluginException {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'File picker plugin not available. Fully restart the app.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Upload failed')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _openDirectory(CirrusFileNode node) {
    if (!node.isDir) {
      return;
    }

    _setPath(_joinPath(_currentPath, node.name));
  }

  void _goUpOneLevel() {
    if (_currentPath.isEmpty) {
      return;
    }

    _setPath(_parentPath(_currentPath));
  }

  void _setPath(String path) {
    final normalized = _normalizePath(path);
    if (normalized == _currentPath) {
      return;
    }

    setState(() {
      _currentPath = normalized;
      _reloadFiles();
    });
  }

  static String _joinPath(String basePath, String segment) {
    final cleanBase = _normalizePath(basePath);
    final cleanSegment = segment.trim().replaceAll(RegExp(r'^/+|/+$'), '');

    if (cleanSegment.isEmpty) {
      return cleanBase;
    }

    if (cleanBase.isEmpty) {
      return '/$cleanSegment';
    }

    return '$cleanBase/$cleanSegment';
  }

  static String _normalizePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty || trimmed == '/') {
      return '';
    }

    final withLeadingSlash = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    if (withLeadingSlash.endsWith('/') && withLeadingSlash.length > 1) {
      return withLeadingSlash.substring(0, withLeadingSlash.length - 1);
    }
    return withLeadingSlash;
  }

  static String _parentPath(String path) {
    final normalized = _normalizePath(path);
    if (normalized.isEmpty) {
      return '';
    }

    final lastSlash = normalized.lastIndexOf('/');
    if (lastSlash <= 0) {
      return '';
    }

    return normalized.substring(0, lastSlash);
  }

  static String _toRootDir(String path) {
    final normalized = _normalizePath(path);
    if (normalized.isEmpty) {
      return '';
    }

    return normalized.substring(1);
  }

  List<Widget> _buildBreadcrumbs(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium;
    if (_currentPath.isEmpty) {
      return [Text('/', style: style)];
    }

    final segments = _currentPath.substring(1).split('/');
    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Text('/', style: style),
      ),
    ];

    for (var i = 0; i < segments.length; i++) {
      if (i > 0) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('/', style: style),
          ),
        );
      }

      final segment = segments[i];
      final isLast = i == segments.length - 1;

      if (isLast) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(segment, style: style),
          ),
        );
        continue;
      }

      final targetPath = '/${segments.take(i + 1).join('/')}';
      children.add(
        InkWell(
          onTap: () => _setPath(targetPath),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              segment,
              style: style?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    }

    return children;
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
                  onPressed: _isUploading ? null : _handleUploadPressed,
                  icon: const Icon(Icons.upload_rounded),
                  label: Text(_isUploading ? 'Uploading...' : 'Upload'),
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
            child: Row(
              children: [
                IconButton(
                  onPressed: _currentPath.isEmpty ? null : _goUpOneLevel,
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Up one level',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => _setPath(''),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.home_rounded,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        ..._buildBreadcrumbs(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
                      onTap: () => _openDirectory(item),
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
