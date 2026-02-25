import 'dart:io';

import 'package:autobutler/models/cirrus_file_node.dart';
import 'package:autobutler/services/cirrus_service.dart';
import 'package:autobutler/widgets/file_browser/file_actions_bar.dart';
import 'package:autobutler/widgets/file_browser/file_breadcrumb_bar.dart';
import 'package:autobutler/widgets/file_browser/file_list_header.dart';
import 'package:autobutler/widgets/file_browser/file_list_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

class FileBrowserPage extends StatefulWidget {
  const FileBrowserPage({super.key});

  @override
  State<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends State<FileBrowserPage> {
  late Future<List<CirrusFileNode>> _filesFuture;
  String _currentPath = '';
  bool _isUploading = false;
  bool _isCreatingFolder = false;

  @override
  void initState() {
    super.initState();
    _reloadFiles();
  }

  void _reloadFiles() {
    _filesFuture = CirrusService.getFiles(_currentPath);
  }

  void _refreshFiles() {
    setState(() {
      _reloadFiles();
    });
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

  Future<void> _handleCreateFolderPressed() async {
    if (_isCreatingFolder) {
      return;
    }

    final folderName = await _promptForFolderName();
    if (folderName == null) {
      return;
    }

    setState(() {
      _isCreatingFolder = true;
    });

    try {
      await CirrusService.createFolder(_toRootDir(_currentPath), folderName);

      if (!mounted) {
        return;
      }

      setState(() {
        _reloadFiles();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Created folder $folderName')));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to create folder')));
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingFolder = false;
        });
      }
    }
  }

  Future<String?> _promptForFolderName() async {
    final nameController = TextEditingController();
    final platform = Theme.of(context).platform;
    final isCupertinoPlatform =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    final String? value;
    if (isCupertinoPlatform) {
      value = await showCupertinoDialog<String>(
        context: context,
        builder: (dialogContext) {
          return CupertinoAlertDialog(
            title: const Text('New Folder'),
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: CupertinoTextField(
                controller: nameController,
                autofocus: true,
                placeholder: 'Folder name',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  Navigator.of(dialogContext).pop(nameController.text.trim());
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
                  Navigator.of(dialogContext).pop(nameController.text.trim());
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      );
    } else {
      value = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('New Folder'),
            content: TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Folder name'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                Navigator.of(dialogContext).pop(nameController.text.trim());
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(nameController.text.trim());
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      );
    }

    nameController.dispose();

    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }

    return normalized.replaceAll(RegExp(r'^/+|/+$'), '');
  }

  Future<void> _handleFileMenuAction(
    CirrusFileNode node,
    FileMenuAction action,
  ) async {
    switch (action) {
      case FileMenuAction.download:
        await _handleDownload(node);
        break;
      case FileMenuAction.moveRename:
        await _handleMoveRename(node);
        break;
      case FileMenuAction.delete:
        await _handleDelete(node);
        break;
    }
  }

  Future<void> _handleDownload(CirrusFileNode node) async {
    try {
      final filePath = _toRootDir(
        _joinPath(_currentPath, _trimTrailingSlashes(node.name)),
      );
      final savedPath = await CirrusService.downloadFile(
        filePath,
        serial: _serialOrNull(node),
        fileName: _trimTrailingSlashes(node.name),
      );

      if (!mounted) {
        return;
      }

      final message = savedPath == null
          ? 'Download canceled'
          : 'Downloaded ${_trimTrailingSlashes(node.name)}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Download failed')));
    }
  }

  Future<void> _handleMoveRename(CirrusFileNode node) async {
    final currentItemPath = _joinPath(
      _currentPath,
      _trimTrailingSlashes(node.name),
    );
    final targetInput = await _promptForMoveRenamePath();
    if (targetInput == null) {
      return;
    }

    final oldPath = currentItemPath;
    final targetPath = targetInput.startsWith('/')
        ? _normalizePath(targetInput)
        : _joinPath(_currentPath, targetInput);

    if (targetPath.isEmpty || targetPath == oldPath) {
      return;
    }

    try {
      final serial = _serialOrNull(node);
      await CirrusService.moveFile(
        oldPath,
        targetPath,
        oldDeviceSerial: serial,
        newDeviceSerial: serial,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _reloadFiles();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Move/Rename complete')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Move/Rename failed')));
    }
  }

  Future<void> _handleDelete(CirrusFileNode node) async {
    final shouldDelete = await _confirmDelete(node);
    if (shouldDelete != true) {
      return;
    }

    try {
      final rootDir = _toRootDir(_currentPath);
      await CirrusService.deleteFile(
        rootDir,
        _trimTrailingSlashes(node.name),
        deviceSerial: _serialOrNull(node),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _reloadFiles();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Deleted')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Delete failed')));
    }
  }

  Future<String?> _promptForMoveRenamePath() async {
    final pathController = TextEditingController();
    final platform = Theme.of(context).platform;
    final isCupertinoPlatform =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    final String? value;
    if (isCupertinoPlatform) {
      value = await showCupertinoDialog<String>(
        context: context,
        builder: (dialogContext) {
          return CupertinoAlertDialog(
            title: const Text('Move / Rename'),
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: CupertinoTextField(
                controller: pathController,
                autofocus: true,
                placeholder: 'New name or path',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  Navigator.of(dialogContext).pop(pathController.text.trim());
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
                  Navigator.of(dialogContext).pop(pathController.text.trim());
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    } else {
      value = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Move / Rename'),
            content: TextField(
              controller: pathController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'New name or path'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                Navigator.of(dialogContext).pop(pathController.text.trim());
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(pathController.text.trim());
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    }

    pathController.dispose();

    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  Future<bool?> _confirmDelete(CirrusFileNode node) {
    final itemName = _trimTrailingSlashes(node.name);
    return showAdaptiveDialog<bool>(
      context: context,
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

  static String _trimTrailingSlashes(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    return trimmed.replaceFirst(RegExp(r'/+$'), '');
  }

  static String? _serialOrNull(CirrusFileNode node) {
    final serial = node.deviceSerial.trim();
    if (serial.isEmpty) {
      return null;
    }
    return serial;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cirrus'),
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
          FileActionsBar(
            isUploading: _isUploading,
            isCreatingFolder: _isCreatingFolder,
            onUploadPressed: _handleUploadPressed,
            onCreateFolderPressed: _handleCreateFolderPressed,
            onRefreshPressed: _refreshFiles,
          ),
          FileBreadcrumbBar(
            currentPath: _currentPath,
            onGoHome: () => _setPath(''),
            onGoUp: _goUpOneLevel,
            onPathSelected: _setPath,
          ),
          const FileListHeader(),
          Expanded(
            child: FileListView(
              filesFuture: _filesFuture,
              onFileMenuAction: _handleFileMenuAction,
              onOpenDirectory: _openDirectory,
            ),
          ),
        ],
      ),
    );
  }
}
