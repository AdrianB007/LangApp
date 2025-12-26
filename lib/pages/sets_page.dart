import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './sets_page_cmps/header.dart';
import './sets_page_cmps/actions_bar.dart';
import './sets_page_cmps/back_nav_button.dart';
import 'add_page.dart';

/////// SETY mają podwójny padding a FOLDERY mają pojedynczy, napraw to by oba mialy pojedynczy


/// =======================
/// GŁÓWNA STRONA SETS
/// =======================

class SetsPage extends StatefulWidget {
  const SetsPage({super.key});

  @override
  State<SetsPage> createState() => _SetsPageState();
}

enum NavigationDirection { forward, backward } // <- do animacji przejścia

class _SetsPageState extends State<SetsPage> {
  /// Root systemu plików
  late FolderNode root;

  /// Aktualnie otwarty folder
  late FolderNode current;


  NavigationDirection _navDirection = NavigationDirection.forward;
  
  void _showMoveFeedback(String message) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 2000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
    setState(() {
      _navDirection = NavigationDirection.forward;
      current = folder;
    });
  }

  /// Przechodzi do folderu nadrzędnego
  void _goUp() {
    if (current.parent != null) {
      setState(() {
        _navDirection = NavigationDirection.backward;
        current = current.parent!;
      });
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

    _showMoveFeedback(
  '   Set "${set.name}" moved to folder "${_folderLabel(target)}"',
    );
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

  // Przenosi folder do wskazanego folderu
  void _moveFolder(FolderNode folder, FolderNode target) {
  if (folder == target) return;
  if (_isDescendant(folder, target)) return;
  if (target.depth >= 3) return;

  setState(() {
    folder.parent?.folders.remove(folder);
    folder.parent = target;
    target.folders.add(folder);
  });

  _showMoveFeedback(
    'Folder "${folder.name}" moved to folder "${_folderLabel(target)}"',
  );
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
  
    /// Buduje breadcrumb do aktualnego folderu
  List<FolderNode> _buildBreadcrumb(FolderNode node) {

    final path = <FolderNode>[];
    FolderNode? n = node;

    while (n != null) {
      path.add(n);
      n = n.parent;
    }

    return path.reversed.toList(); // od root → current
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
            Header(
              breadcrumb: _buildBreadcrumb(current),
              onNavigate: (folder) {
                setState(() {
                  _navDirection = folder.depth > current.depth
                      ? NavigationDirection.forward
                      : NavigationDirection.backward;
                  current = folder;
                });
              },
            ),

            /// Pasek akcji
            ActionsBar(
              onCreateFolder:
                  canCreateFolder ? _createFolder : null, // null = disabled
              onAddSet: _goToAddSet,
            ),

            

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                transitionBuilder: (child, animation) {
                  final beginOffset = _navDirection == NavigationDirection.forward
                      ? const Offset(1, 0) // wjazd z lewej
                      : const Offset(-1, 0); // wjazd z prawej

                  final slide = Tween<Offset>(
                    begin: beginOffset,
                    end: Offset.zero,
                  ).animate(animation);

                  return SlideTransition(
                    position: slide,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: ListView(
                  key: ValueKey(current.id),
                  padding: const EdgeInsets.all(20),
                  
                  children: [
                    /// Przycisk cofania
                    if (current.parent != null)
                      BackNavButton(
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
            ),
          ],
        ),
      ),
    );
  }
}



/// =======================
/// KOMPONENTY UI
/// =======================

/// Draggable zestaw
/// Dodaje logikę drag&drop do SetTileView
class _DraggableSetTile extends StatelessWidget {
  final SetItem set;

  const _DraggableSetTile({required this.set});

  @override
  Widget build(BuildContext context) {
    return PressableTile(
      onLongPress: () {},
      child: LongPressDraggable<DragSet>(
        delay: const Duration(milliseconds: 400),
        data: DragSet(set),
        hapticFeedbackOnStart: true,
        feedback: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 280,
            child: SetTileView(set: set),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.2,
          child: SetTileView(set: set),
        ),
        child: SetTileView(set: set),
      ),
    );
  }
}



/// Folder jako DragTarget
/// Dodaje logikę drag&drop do FolderTileView
/// jest równocześnie DragTarget i Draggable
/// deleguje wygląd do FolderTileView
/// decyduje czy można upuścić dany element,
/// lub czy podświetlić folder jako aktywny
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
        return PressableTile(
          onLongPress: () {},
          child: LongPressDraggable<DragFolder>(
            delay: const Duration(milliseconds: 400),
            hapticFeedbackOnStart: true,
            data: DragFolder(folder),
            feedback: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(100),
              child: SizedBox(
                width: 280,
                child: FolderTileView(folder: folder),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: FolderTileView(folder: folder),
            ),
            child: FolderTileView(
              folder: folder,
              highlight: candidates.isNotEmpty,
              onTap: onTap,
            ),
          ),
        );
      },
    );
  }
}


/// Widok pojedynczego folderu
/// /// Rysuje pojedyńczą kartę folderu, bez logiki drag&drop
class FolderTileView extends StatelessWidget {
  final FolderNode folder;
  final bool highlight;
  final VoidCallback? onTap;

  const FolderTileView({
    super.key, 
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





/// Pojedynczy zestaw 
/// Rysuje pojedyńczą kartę zestawu, Bez logiki drag&drop
class SetTileView extends StatelessWidget {
  final SetItem set;

  const SetTileView({super.key, required this.set});

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

/// Tile reagujący na przyciskanie i długie przytrzymanie
/// daje tylko wizualny feedback przyciemniania
/// przygotowuje użytkownika na long press
/// nie ma własnej logiki drag&drop
class PressableTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onLongPress;

  const PressableTile({
    super.key,
    required this.child,
    required this.onLongPress,
  });

  @override
  State<PressableTile> createState() => _PressableTileState();
}


class _PressableTileState extends State<PressableTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() => _controller.forward();
  void _cancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _start(),
      onTapCancel: _cancel,
      onTapUp: (_) => _cancel(),
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.08 * _controller.value),
              borderRadius: BorderRadius.circular(12),
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

String _folderLabel(FolderNode folder) {
  return folder.name == '/' ? 'home' : folder.name;
}


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

/// Typ elementu przeciąganego
abstract class DragItem {}

class DragSet extends DragItem {
  final SetItem set;
  DragSet(this.set);
}

class DragFolder extends DragItem {
  final FolderNode folder;
  DragFolder(this.folder);
}
