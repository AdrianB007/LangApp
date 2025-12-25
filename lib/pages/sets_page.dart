import 'package:flutter/material.dart';
import 'add_page.dart';

/// =======================
/// MODELE DANYCH
/// =======================

/// Reprezentuje pojedynczy zestaw słówek
class SetItem {
  final String id;
  final String name;
  final int termsCount;

  SetItem({
    required this.id,
    required this.name,
    required this.termsCount,
  });
}

/// Reprezentuje folder w drzewie folderów
class FolderNode {
  final String id;
  final String name;

  /// Folder nadrzędny (null tylko dla root)
  final FolderNode? parent;

  /// Foldery zagnieżdżone
  final List<FolderNode> folders;

  /// Zestawy znajdujące się w tym folderze
  final List<SetItem> sets;

  FolderNode({
    required this.id,
    required this.name,
    this.parent,
    List<FolderNode>? folders,
    List<SetItem>? sets,
  })  : folders = folders ?? [],
        sets = sets ?? [];

  /// Oblicza głębokość folderu w drzewie
  /// root = 0, pierwszy poziom = 1 itd.
  int get depth {
    int d = 0;
    FolderNode? p = parent;
    while (p != null) {
      d++;
      p = p.parent;
    }
    return d;
  }
}

/// =======================
/// GŁÓWNA STRONA SETS
/// =======================

class SetsPage extends StatefulWidget {
  const SetsPage({super.key});

  @override
  State<SetsPage> createState() => _SetsPageState();
}

class _SetsPageState extends State<SetsPage> {
  /// Root systemu plików
  late FolderNode root;

  /// Aktualnie otwarty folder
  late FolderNode current;

  @override
  void initState() {
    super.initState();

    /// Inicjalizacja root folderu "/"
    root = FolderNode(
      id: 'root',
      name: '/',
      sets: [
        SetItem(id: '1', name: 'English Basics', termsCount: 20),
        SetItem(id: '2', name: 'Irregular Verbs', termsCount: 45),
      ],
    );

    /// Przykładowa struktura startowa
    final english = FolderNode(
      id: 'f1',
      name: 'English',
      parent: root,
    );

    final grammar = FolderNode(
      id: 'f2',
      name: 'Grammar',
      parent: english,
    );

    english.folders.add(grammar);
    root.folders.add(english);

    /// Startujemy w root
    current = root;
  }

  /// =======================
  /// NAWIGACJA PO FOLDERACH
  /// =======================

  /// Otwiera folder
  void _openFolder(FolderNode folder) {
    setState(() => current = folder);
  }

  /// Przechodzi do folderu nadrzędnego
  void _goUp() {
    if (current.parent != null) {
      setState(() => current = current.parent!);
    }
  }

  /// =======================
  /// PRZENOSZENIE ZESTAWÓW
  /// =======================

  /// Przenosi zestaw do wskazanego folderu
  void _moveSet(SetItem set, FolderNode target) {
    setState(() {
      _removeSet(root, set); // usuwamy z poprzedniego miejsca
      target.sets.add(set); // dodajemy do nowego folderu
    });
  }

  /// Rekurencyjnie usuwa zestaw z całego drzewa
  bool _removeSet(FolderNode node, SetItem set) {
    if (node.sets.remove(set)) return true;
    for (final f in node.folders) {
      if (_removeSet(f, set)) return true;
    }
    return false;
  }

  /// =======================
  /// TWORZENIE FOLDERU
  /// =======================

  void _createFolder() {
    /// BLOKADA: max 3 poziomy zagnieżdżenia
    if (current.depth >= 3) return;

    showDialog(
      context: context,
      builder: (_) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Create folder'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Folder name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  current.folders.add(
                    FolderNode(
                      id: UniqueKey().toString(),
                      name: controller.text,
                      parent: current,
                    ),
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  /// Przejście do AddPage
  void _goToAddSet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPage()),
    );
  }

  /// =======================
  /// UI
  /// =======================

  @override
  Widget build(BuildContext context) {
    final canCreateFolder = current.depth < 3;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(path: _buildPath(current)),

            /// Pasek akcji
            _ActionsBar(
              onCreateFolder: canCreateFolder ? _createFolder : null,
              onAddSet: _goToAddSet,
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  /// Przycisk cofania
                  if (current.parent != null)
                    _BackTile(onTap: _goUp),

                  /// Foldery (DragTarget)
                  ...current.folders.map(
                    (folder) => _FolderTile(
                      folder: folder,
                      onTap: () => _openFolder(folder),
                      onAcceptSet: (set) {
                        if (folder.depth < 3) {
                          _moveSet(set, folder);
                        }
                      },
                    ),
                  ),

                  /// Zestawy (Draggable)
                  ...current.sets.map(
                    (set) => _DraggableSetTile(set: set),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Buduje ścieżkę typu /English/Grammar
  String _buildPath(FolderNode node) {
    final names = <String>[];
    FolderNode? n = node;
    while (n != null && n.name != '/') {
      names.add(n.name);
      n = n.parent;
    }
    return '/${names.reversed.join('/')}';
  }
}

/// =======================
/// KOMPONENTY UI
/// =======================

/// Draggable zestaw
class _DraggableSetTile extends StatelessWidget {
  final SetItem set;

  const _DraggableSetTile({required this.set});

  @override
  Widget build(BuildContext context) {
    return Draggable<SetItem>(
      data: set,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(width: 260, child: _SetTile(set: set)),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _SetTile(set: set),
      ),
      child: _SetTile(set: set),
    );
  }
}

/// Folder jako DragTarget
class _FolderTile extends StatelessWidget {
  final FolderNode folder;
  final VoidCallback onTap;
  final Function(SetItem) onAcceptSet;

  const _FolderTile({
    required this.folder,
    required this.onTap,
    required this.onAcceptSet,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<SetItem>(
      onWillAcceptWithDetails: (_) => folder.depth < 3,
      onAcceptWithDetails: (details) => onAcceptSet(details.data),
      builder: (context, candidates, rejected) {
        return ListTile(
          leading: Icon(
            Icons.folder,
            color: candidates.isNotEmpty
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          title: Text(folder.name),
          subtitle: Text('${folder.sets.length} sets'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        );
      },
    );
  }
}

/// Cofanie do folderu nadrzędnego
class _BackTile extends StatelessWidget {
  final VoidCallback onTap;

  const _BackTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.arrow_upward),
      title: const Text('Up'),
      onTap: onTap,
    );
  }
}

/// Pojedynczy zestaw
class _SetTile extends StatelessWidget {
  final SetItem set;

  const _SetTile({required this.set});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.style),
        title: Text(set.name),
        subtitle: Text('${set.termsCount} terms'),
      ),
    );
  }
}

/// Nagłówek strony
class _Header extends StatelessWidget {
  final String path;

  const _Header({required this.path});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Resources',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(path, style: Theme.of(context).textTheme.bodyMedium ),
        ],
      ),
    );
  }
}

/// Pasek akcji (Create folder / Add set)
class _ActionsBar extends StatelessWidget {
  final VoidCallback? onCreateFolder;
  final VoidCallback onAddSet;

  const _ActionsBar({
    required this.onCreateFolder,
    required this.onAddSet,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Create folder'),
              onPressed: onCreateFolder, // null = disabled
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add set'),
              onPressed: onAddSet,
            ),
          ),
        ],
      ),
    );
  }
}
