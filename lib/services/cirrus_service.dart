import 'dart:convert';

import 'package:autobutler/models/cirrus_file_node.dart';
import 'package:http/http.dart' as http;

class CirrusService {
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const List<CirrusFileNode> _mockNodes = [
    CirrusFileNode(
      name: 'flipped_(1).jpg',
      size: 6501171,
      isDir: false,
      deviceName: 'Data',
      devicePath: '/flipped_(1).jpg',
      fullPath: '/flipped_(1).jpg',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'flipped_(2).jpg',
      size: 6501171,
      isDir: false,
      deviceName: 'Data',
      devicePath: '/flipped_(2).jpg',
      fullPath: '/flipped_(2).jpg',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'flipped_(3).jpg',
      size: 6501171,
      isDir: false,
      deviceName: 'Data',
      devicePath: '/flipped_(3).jpg',
      fullPath: '/flipped_(3).jpg',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'flipped_(4).jpg',
      size: 6501171,
      isDir: false,
      deviceName: 'Data',
      devicePath: '/flipped_(4).jpg',
      fullPath: '/flipped_(4).jpg',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'flipped_(5).jpg',
      size: 6501171,
      isDir: false,
      deviceName: 'Data',
      devicePath: '/flipped_(5).jpg',
      fullPath: '/flipped_(5).jpg',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'flipped_(6).jpg',
      size: 6501171,
      isDir: false,
      deviceName: 'Data',
      devicePath: '/flipped_(6).jpg',
      fullPath: '/flipped_(6).jpg',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'flipped_(7).jpg',
      size: 6501171,
      isDir: false,
      deviceName: 'Data',
      devicePath: '/flipped_(7).jpg',
      fullPath: '/flipped_(7).jpg',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'Google_Data_autobutler.org@gmail.com_1769933022.zip',
      size: 43315,
      isDir: false,
      deviceName: 'Data',
      devicePath: '/Google_Data_autobutler.org@gmail.com_1769933022.zip',
      fullPath: '/Google_Data_autobutler.org@gmail.com_1769933022.zip',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'project-assets',
      size: 0,
      isDir: true,
      deviceName: 'Data',
      devicePath: '/project-assets',
      fullPath: '/project-assets',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'screenshots',
      size: 0,
      isDir: true,
      deviceName: 'Data',
      devicePath: '/project-assets/screenshots',
      fullPath: '/project-assets/screenshots',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'changelog.md',
      size: 5320,
      isDir: false,
      deviceName: 'Data',
      devicePath: '/project-assets/changelog.md',
      fullPath: '/project-assets/changelog.md',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'capture-001.png',
      size: 384201,
      isDir: false,
      deviceName: 'Data',
      devicePath: '/project-assets/screenshots/capture-001.png',
      fullPath: '/project-assets/screenshots/capture-001.png',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'diag-report.txt',
      size: 8142,
      isDir: false,
      deviceName: 'Backup',
      devicePath: '/diag-report.txt',
      fullPath: '/diag-report.txt',
      deviceSerial: 'BACKUP-01',
    ),
  ];

  static Future<List<CirrusFileNode>> getFiles(
    String path, {
    bool useMockData = true,
    List<String>? serials,
  }) async {
    if (!useMockData) {
      return _getFilesFromApi(path, serials: serials);
    }

    await Future<void>.delayed(const Duration(milliseconds: 120));

    final normalizedPath = _normalizePath(path);
    final serialFilter = serials
        ?.where((serial) => serial.trim().isNotEmpty)
        .toSet();

    return _mockNodes
        .where((node) {
          final parentPath = _parentDirectory(node.fullPath);
          if (parentPath != normalizedPath) {
            return false;
          }

          if (serialFilter == null || serialFilter.isEmpty) {
            return true;
          }

          return serialFilter.contains(node.deviceSerial);
        })
        .toList(growable: false);
  }

  static String _parentDirectory(String path) {
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

  static Future<List<CirrusFileNode>> _getFilesFromApi(
    String path, {
    List<String>? serials,
  }) async {
    final normalizedPath = _normalizePath(path);
    final serialValues =
        serials
            ?.map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];

    final querySegments = <String>[];
    if (normalizedPath.isNotEmpty) {
      querySegments.add(
        'rootDir=${Uri.encodeQueryComponent(_toRootDir(normalizedPath))}',
      );
    }
    for (final serial in serialValues) {
      querySegments.add('serial=${Uri.encodeQueryComponent(serial)}');
    }

    final endpointUri = Uri.parse(_apiBaseUrl).resolve('/api/v1/cirrus');
    final uri = querySegments.isEmpty
        ? endpointUri
        : endpointUri.replace(query: querySegments.join('&'));

    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load cirrus files (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected cirrus response format');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(CirrusFileNode.fromJson)
        .toList(growable: false);
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

  static String _toRootDir(String normalizedPath) {
    if (normalizedPath.isEmpty) {
      return '';
    }
    return normalizedPath.substring(1);
  }
}
