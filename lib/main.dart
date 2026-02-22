import 'package:flutter/material.dart';

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

enum BrowserItemType { folder, image, archive }

class FileBrowserItem {
  const FileBrowserItem({
    required this.name,
    required this.device,
    required this.size,
    required this.type,
  });

  final String name;
  final String device;
  final String size;
  final BrowserItemType type;
}

const mockFileBrowserItems = <FileBrowserItem>[
  FileBrowserItem(
    name: 'flipped_(1).jpg',
    device: 'Data',
    size: '6.2 MB',
    type: BrowserItemType.image,
  ),
  FileBrowserItem(
    name: 'flipped_(2).jpg',
    device: 'Data',
    size: '6.2 MB',
    type: BrowserItemType.image,
  ),
  FileBrowserItem(
    name: 'flipped_(3).jpg',
    device: 'Data',
    size: '6.2 MB',
    type: BrowserItemType.image,
  ),
  FileBrowserItem(
    name: 'flipped_(4).jpg',
    device: 'Data',
    size: '6.2 MB',
    type: BrowserItemType.image,
  ),
  FileBrowserItem(
    name: 'flipped_(5).jpg',
    device: 'Data',
    size: '6.2 MB',
    type: BrowserItemType.image,
  ),
  FileBrowserItem(
    name: 'flipped_(6).jpg',
    device: 'Data',
    size: '6.2 MB',
    type: BrowserItemType.image,
  ),
  FileBrowserItem(
    name: 'flipped_(7).jpg',
    device: 'Data',
    size: '6.2 MB',
    type: BrowserItemType.image,
  ),
  FileBrowserItem(
    name: 'flipped.jpg',
    device: 'Data',
    size: '6.2 MB',
    type: BrowserItemType.image,
  ),
  FileBrowserItem(
    name: 'Google_Data_autobutler.org@gmail.com_1769933022.zip',
    device: 'Data',
    size: '42.3 KB',
    type: BrowserItemType.archive,
  ),
  FileBrowserItem(
    name: 'project-assets',
    device: 'Data',
    size: '--',
    type: BrowserItemType.folder,
  ),
];

class FileBrowserPage extends StatelessWidget {
  const FileBrowserPage({super.key});

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
                'cirrus / testfolder',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                top: BorderSide(color: colors.outlineVariant.withOpacity(0.6)),
                bottom: BorderSide(
                  color: colors.outlineVariant.withOpacity(0.6),
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
            child: ListView.separated(
              itemCount: mockFileBrowserItems.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: colors.outlineVariant.withOpacity(0.5),
              ),
              itemBuilder: (context, index) {
                final item = mockFileBrowserItems[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  leading: Icon(_iconForType(item.type)),
                  title: Row(
                    children: [
                      Expanded(flex: 5, child: Text(item.name)),
                      Expanded(flex: 2, child: Text(item.device)),
                      Expanded(flex: 2, child: Text(item.size)),
                    ],
                  ),
                  trailing: const Icon(Icons.more_vert),
                  onTap: () {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForType(BrowserItemType type) {
    switch (type) {
      case BrowserItemType.folder:
        return Icons.folder_outlined;
      case BrowserItemType.image:
        return Icons.image_outlined;
      case BrowserItemType.archive:
        return Icons.archive_outlined;
    }
  }
}
