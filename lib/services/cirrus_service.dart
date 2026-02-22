import 'package:autobutler/models/cirrus_file_node.dart';

class CirrusService {
  static const List<CirrusFileNode> _mockNodes = [
    CirrusFileNode(
      name: 'flipped_(1).jpg',
      size: 6501171,
      isDir: false,
      deviceName: 'Data',
      devicePath: '/cirrus/flipped_(1).jpg',
      fullPath: '/cirrus/flipped_(1).jpg',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'flipped_(2).jpg',
      size: 6501171,
      isDir: false,
      deviceName: 'Data',
      devicePath: '/cirrus/flipped_(2).jpg',
      fullPath: '/cirrus/flipped_(2).jpg',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'flipped_(3).jpg',
      size: 6501171,
      isDir: false,
      deviceName: 'Data',
      devicePath: '/cirrus/flipped_(3).jpg',
      fullPath: '/cirrus/flipped_(3).jpg',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'flipped_(4).jpg',
      size: 6501171,
      isDir: false,
      deviceName: 'Data',
      devicePath: '/cirrus/flipped_(4).jpg',
      fullPath: '/cirrus/flipped_(4).jpg',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'flipped_(5).jpg',
      size: 6501171,
      isDir: false,
      deviceName: 'Data',
      devicePath: '/cirrus/flipped_(5).jpg',
      fullPath: '/cirrus/flipped_(5).jpg',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'flipped_(6).jpg',
      size: 6501171,
      isDir: false,
      deviceName: 'Data',
      devicePath: '/cirrus/flipped_(6).jpg',
      fullPath: '/cirrus/flipped_(6).jpg',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'flipped_(7).jpg',
      size: 6501171,
      isDir: false,
      deviceName: 'Data',
      devicePath: '/cirrus/flipped_(7).jpg',
      fullPath: '/cirrus/flipped_(7).jpg',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'Google_Data_autobutler.org@gmail.com_1769933022.zip',
      size: 43315,
      isDir: false,
      deviceName: 'Data',
      devicePath: '/cirrus/Google_Data_autobutler.org@gmail.com_1769933022.zip',
      fullPath: '/cirrus/Google_Data_autobutler.org@gmail.com_1769933022.zip',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'project-assets',
      size: 0,
      isDir: true,
      deviceName: 'Data',
      devicePath: '/cirrus/project-assets',
      fullPath: '/cirrus/project-assets',
      deviceSerial: '',
    ),
    CirrusFileNode(
      name: 'diag-report.txt',
      size: 8142,
      isDir: false,
      deviceName: 'Backup',
      devicePath: '/cirrus/diag-report.txt',
      fullPath: '/cirrus/diag-report.txt',
      deviceSerial: 'BACKUP-01',
    ),
  ];

  static Future<List<CirrusFileNode>> getFiles(
    String path, [
    List<String>? serials,
  ]) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final normalizedPath = path.trim().isEmpty ? '/' : path.trim();
    final serialFilter = serials
        ?.where((serial) => serial.trim().isNotEmpty)
        .toSet();

    return _mockNodes
        .where((node) {
          final isInPath = node.fullPath.startsWith(normalizedPath);
          if (!isInPath) {
            return false;
          }

          if (serialFilter == null || serialFilter.isEmpty) {
            return true;
          }

          return serialFilter.contains(node.deviceSerial);
        })
        .toList(growable: false);
  }
}
