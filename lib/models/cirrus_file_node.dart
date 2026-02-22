class CirrusFileNode {
  const CirrusFileNode({
    required this.name,
    required this.size,
    required this.isDir,
    required this.deviceName,
    required this.devicePath,
    required this.fullPath,
    required this.deviceSerial,
  });

  final String name;
  final int size;
  final bool isDir;
  final String deviceName;
  final String devicePath;
  final String fullPath;
  final String deviceSerial;
}
