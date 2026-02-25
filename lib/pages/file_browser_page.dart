import 'dart:io';

import 'package:autobutler/models/cirrus_file_node.dart';
import 'package:autobutler/services/file_browser_actions.dart';
import 'package:autobutler/services/cirrus_service.dart';
import 'package:autobutler/utils/file_browser_dialogs.dart';
import 'package:autobutler/utils/file_browser_path_utils.dart';
import 'package:autobutler/widgets/file_browser/file_actions_bar.dart';
import 'package:autobutler/widgets/file_browser/file_breadcrumb_bar.dart';
import 'package:autobutler/widgets/file_browser/file_list_header.dart';
import 'package:autobutler/widgets/file_browser/file_list_view.dart';
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
      await uploadFileToCurrentPath(
        currentPath: _currentPath,
        selectedFile: selectedFile,
      );

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

    final folderName = await promptForFolderName(context);
    if (folderName == null) {
      return;
    }

    setState(() {
      _isCreatingFolder = true;
    });

    try {
      await createFolderAtCurrentPath(
        currentPath: _currentPath,
        folderName: folderName,
      );

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
      final savedPath = await downloadNode(
        currentPath: _currentPath,
        node: node,
      );

      if (!mounted) {
        return;
      }

      final message = savedPath == null
          ? 'Download canceled'
          : 'Downloaded ${trimTrailingSlashes(node.name)}';
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
    final targetInput = await promptForMoveRenamePath(context);
    if (targetInput == null) {
      return;
    }

    final oldPath = joinPath(_currentPath, trimTrailingSlashes(node.name));
    final targetPath = targetInput.startsWith('/')
        ? normalizePath(targetInput)
        : joinPath(_currentPath, targetInput);

    if (targetPath.isEmpty || targetPath == oldPath) {
      return;
    }

    try {
      await moveRenameNode(
        currentPath: _currentPath,
        node: node,
        targetInput: targetInput,
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
    final shouldDelete = await confirmDelete(
      context,
      trimTrailingSlashes(node.name),
    );
    if (shouldDelete != true) {
      return;
    }

    try {
      await deleteNode(currentPath: _currentPath, node: node);

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

  void _openDirectory(CirrusFileNode node) {
    if (!node.isDir) {
      return;
    }

    _setPath(joinPath(_currentPath, node.name));
  }

  void _goUpOneLevel() {
    if (_currentPath.isEmpty) {
      return;
    }

    _setPath(parentPath(_currentPath));
  }

  void _setPath(String path) {
    final normalized = normalizePath(path);
    if (normalized == _currentPath) {
      return;
    }

    setState(() {
      _currentPath = normalized;
      _reloadFiles();
    });
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
