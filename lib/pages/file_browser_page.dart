import 'package:autobutler/controllers/file_browser_controller.dart';
import 'package:autobutler/models/cirrus_file_node.dart';
import 'package:autobutler/utils/file_browser_path_utils.dart';
import 'package:autobutler/widgets/file_browser/file_actions_bar.dart';
import 'package:autobutler/widgets/file_browser/file_breadcrumb_bar.dart';
import 'package:autobutler/widgets/file_browser/file_list_header.dart';
import 'package:autobutler/widgets/file_browser/file_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FileBrowserPage extends StatefulWidget {
  const FileBrowserPage({super.key});

  @override
  State<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends State<FileBrowserPage> {
  final _controller = const FileBrowserController();

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
    _filesFuture = _controller.fetchFiles(_currentPath);
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

    final selectedFile = await _controller.pickUploadFile();
    if (selectedFile == null) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await _controller.uploadFile(
        currentPath: _currentPath,
        selectedFile: selectedFile,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _reloadFiles();
      });

      _showMessage('Uploaded ${selectedFile.uri.pathSegments.last}');
    } on MissingPluginException {
      if (!mounted) {
        return;
      }

      _showMessage('File picker plugin not available. Fully restart the app.');
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Upload failed');
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

    final folderName = await _controller.promptFolderName(context);
    if (folderName == null) {
      return;
    }

    setState(() {
      _isCreatingFolder = true;
    });

    try {
      await _controller.createFolder(
        currentPath: _currentPath,
        folderName: folderName,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _reloadFiles();
      });

      _showMessage('Created folder $folderName');
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Failed to create folder');
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
    try {
      final outcome = await _controller.handleFileAction(
        currentPath: _currentPath,
        node: node,
        action: action,
        context: context,
      );

      if (!mounted || outcome == null) {
        return;
      }

      _applyOutcome(outcome);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(_controller.failureMessage(action));
    }
  }

  void _applyOutcome(FileMenuActionOutcome outcome) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (outcome.shouldRefresh) {
        setState(() {
          _reloadFiles();
        });
      }

      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text(outcome.message)));
      }
    });
  }

  void _openDirectory(CirrusFileNode node) {
    if (!node.isDir) {
      return;
    }

    _setPath(
      _controller.nextPathForOpenDirectory(
        currentPath: _currentPath,
        node: node,
      ),
    );
  }

  void _goUpOneLevel() {
    if (_currentPath.isEmpty) {
      return;
    }

    _setPath(_controller.nextPathForGoUp(_currentPath));
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
