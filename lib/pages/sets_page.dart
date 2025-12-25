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
  FolderNode? parent;

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

abstract class DragItem {}

class DragSet extends DragItem {
  final SetItem set;
  DragSet(this.set);
}

class DragFolder extends DragItem {
  final FolderNode folder;
  DragFolder(this.folder);
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

  // ignore: unused_element
  void _moveFolder(FolderNode folder, FolderNode target) {
  if (folder == target) return;
  if (_isDescendant(folder, target)) return;
  if (target.depth >= 3) return;

  setState(() {
    folder.parent?.folders.remove(folder);
    folder.parent = target;
    target.folders.add(folder);
  });
}

/// Sprawdza czy target jest potomkiem folderu
bool _isDescendant(FolderNode folder, FolderNode target) {
  FolderNode? p = target.parent;
  while (p != null) {
    if (p == folder) return true;
    p = p.parent;
  }
  return false;
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
            _Header(
              breadcrumb: _buildBreadcrumb(current),
              onNavigate: (folder) {
                setState(() => current = folder);
              },
            ),

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
                    _BackTile(
                      onTap: _goUp,
                      onAccept: (item) {
                        if (item is DragSet) {
                          _moveSet(item.set, current.parent!);
                        }
                        if (item is DragFolder) {
                          _moveFolder(item.folder, current.parent!);
                        }
                      },
                    ),

                  /// Foldery (DragTarget)
                  ...current.folders.map(
                    (folder) => _FolderTile(
                      folder: folder,
                      onTap: () => _openFolder(folder),
                      onAccept: (item) {
                        if (item is DragSet) {
                          _moveSet(item.set, folder);
                        }

                        if (item is DragFolder) {
                          _moveFolder(item.folder, folder);
                          
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



  List<FolderNode> _buildBreadcrumb(FolderNode node) {
  final path = <FolderNode>[];
  FolderNode? n = node;

  while (n != null) {
    path.add(n);
    n = n.parent;
  }

  return path.reversed.toList(); // od root → current
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
    return Draggable<DragSet>(
      data: DragSet(set),
      feedback: Material(
        elevation: 6,
        child: SizedBox(
          width: 260,
          child: _SetTile(set: set),
        ),
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
  final Function(DragItem) onAccept;

  const _FolderTile({
    required this.folder,
    required this.onTap,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<DragItem>(
      onWillAcceptWithDetails: (details) {
        final item = details.data;
        if (item is DragSet) return folder.depth < 3;
        if (item is DragFolder) {
          if (item.folder == folder) return false;
          if (folder.depth >= 3) return false;
          return true;
        }
        return false;
      },
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidates, _) {
        return Draggable<DragFolder>(
          data: DragFolder(folder),
          feedback: Material(
            elevation: 6,
            child: SizedBox(
              width: 260,
              child: _FolderTileView(folder: folder),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: _FolderTileView(folder: folder),
          ),
          child: _FolderTileView(
            folder: folder,
            highlight: candidates.isNotEmpty,
            onTap: onTap,
          ),
        );
      },
    );
  }
}


      //onWillAcceptWithDetails: (_) => folder.depth < 3,
      //onAcceptWithDetails: (details) => onAcceptSet(details.data),

class _FolderTileView extends StatelessWidget {
  final FolderNode folder;
  final bool highlight;
  final VoidCallback? onTap;

  const _FolderTileView({
    required this.folder,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.folder,
        color: highlight
            ? Theme.of(context).colorScheme.primary
            : null,
      ),
      title: Text(folder.name),
      subtitle: Text(
        '${folder.folders.length} folders · ${folder.sets.length} sets',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}


/// Cofanie do folderu nadrzędnego
class _BackTile extends StatelessWidget {
  final VoidCallback onTap;
  final Function(DragItem) onAccept;

  const _BackTile({
    required this.onTap,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<DragItem>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidates, _) {
        return ListTile(
          leading: Icon(
            Icons.arrow_upward,
            color: candidates.isNotEmpty
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          title: const Text('Up'),
          onTap: onTap,
        );
      },
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
// ignore: unused_element
class _HeaderOld extends StatelessWidget {
  final String path;

  const _HeaderOld({required this.path});

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

class _Header extends StatelessWidget {
  final List<FolderNode> breadcrumb;
  final Function(FolderNode) onNavigate;

  const _Header({
    required this.breadcrumb,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Tytuł sekcji
          Text(
            'Resources',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),

          /// Scrollowalny breadcrumb
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: breadcrumb.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final folder = breadcrumb[index];
                final isLast = index == breadcrumb.length - 1;

                return GestureDetector(
                  onTap: isLast ? null : () => onNavigate(folder),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isLast
                          ? color.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isLast ? Colors.transparent : color,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          folder.name == '/' ? Icons.home : Icons.folder,
                          size: 18,
                          color: color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          folder.name == '/' ? 'Home' : folder.name,
                          style: TextStyle(
                            color: color,
                            fontWeight:
                                isLast ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        if (!isLast) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
