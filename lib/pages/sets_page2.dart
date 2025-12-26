
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add_page.dart';

/// =======================
/// MODELE DANYCH
/// =======================

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

class FolderNode {
  final String id;
  final String name;
  FolderNode? parent;
  final List<FolderNode> folders;
  final List<SetItem> sets;

  FolderNode({
    required this.id,
    required this.name,
    this.parent,
    List<FolderNode>? folders,
    List<SetItem>? sets,
  })  : folders = folders ?? [],
        sets = sets ?? [];

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
/// DRAG TYPES
/// =======================

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
/// NAV DIRECTION
/// =======================

enum NavigationDirection { forward, backward }

/// =======================
/// SETS PAGE
/// =======================

class SetsPage extends StatefulWidget {
  const SetsPage({super.key});

  @override
  State<SetsPage> createState() => _SetsPageState();
}

class _SetsPageState extends State<SetsPage> {
  late FolderNode root;
  late FolderNode current;

  NavigationDirection _navDirection = NavigationDirection.forward;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    root = FolderNode(
      id: 'root',
      name: '/',
      sets: [
        SetItem(id: '1', name: 'English Basics', termsCount: 20),
        SetItem(id: '2', name: 'Irregular Verbs', termsCount: 45),
      ],
    );

    final english = FolderNode(id: 'f1', name: 'English', parent: root);
    final grammar = FolderNode(id: 'f2', name: 'Grammar', parent: english);

    english.folders.add(grammar);
    root.folders.add(english);

    current = root;
  }

  /// =======================
  /// HELPERS
  /// =======================

  String _folderLabel(FolderNode folder) {
    return folder.name == '/' ? 'home' : folder.name;
  }

  void _showMoveFeedback(String message, {bool strong = false}) {
    if (strong) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  /// =======================
  /// NAVIGATION
  /// =======================

  void _openFolder(FolderNode folder) {
    setState(() {
      _navDirection = NavigationDirection.forward;
      current = folder;
    });
  }

  void _goUp() {
    if (current.parent != null) {
      setState(() {
        _navDirection = NavigationDirection.backward;
        current = current.parent!;
      });
    }
  }

  /// =======================
  /// MOVE LOGIC
  /// =======================

  void _moveSet(SetItem set, FolderNode target) {
    setState(() {
      _removeSet(root, set);
      target.sets.add(set);
    });

    _showMoveFeedback(
      'Set "${set.name}" moved to folder "${_folderLabel(target)}"',
    );
  }

  bool _removeSet(FolderNode node, SetItem set) {
    if (node.sets.remove(set)) return true;
    for (final f in node.folders) {
      if (_removeSet(f, set)) return true;
    }
    return false;
  }

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
      strong: true,
    );
  }

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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              breadcrumb: _buildBreadcrumb(current),
              onNavigate: (folder) {
                setState(() {
                  _navDirection = NavigationDirection.backward;
                  current = folder;
                });
              },
            ),
            _ActionsBar(
              onCreateFolder: current.depth < 3 ? _createFolder : null,
              onAddSet: _goToAddSet,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) {
                  final begin = _navDirection == NavigationDirection.forward
                      ? const Offset(-1, 0)
                      : const Offset(1, 0);

                  return SlideTransition(
                    position: Tween(begin: begin, end: Offset.zero)
                        .animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: ListView(
                  key: ValueKey(current.id),
                  padding: const EdgeInsets.all(12),
                  children: [
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
                    ...current.folders.map(
                      (f) => _FolderTile(
                        folder: f,
                        onTap: () => _openFolder(f),
                        onAccept: (item) {
                          if (item is DragSet) _moveSet(item.set, f);
                          if (item is DragFolder) _moveFolder(item.folder, f);
                        },
                      ),
                    ),
                    ...current.sets.map(
                      (s) => _DraggableSetTile(
                        set: s,
                      ),
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

  List<FolderNode> _buildBreadcrumb(FolderNode node) {
    final path = <FolderNode>[];
    FolderNode? n = node;
    while (n != null) {
      path.add(n);
      n = n.parent;
    }
    return path.reversed.toList();
  }

  void _createFolder() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create folder'),
        content: TextField(controller: controller),
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
      ),
    );
  }

  void _goToAddSet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPage()),
    );
  }
}

/// =======================
/// PRESSABLE TILE
/// =======================

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapCancel: () => _controller.reverse(),
      onTapUp: (_) => _controller.reverse(),
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
              separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                          ? color.withAlpha(30)
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
        final isActive = candidates.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  )
                : null,
          ),
          child: ListTile(
            leading: Icon(
              Icons.arrow_back,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: const Text('Go Back'),
            subtitle: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: isActive
                  ? const Text(
                      'Drop here to move item up',
                      key: ValueKey('hint'),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
            onTap: onTap,
          ),
        );
      },
    );
  }
}

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

class _DraggableSetTile extends StatelessWidget {
  final SetItem set;

  const _DraggableSetTile({required this.set});

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<DragSet>(
      delay: const Duration(milliseconds: 400),
      data: DragSet(set),
      hapticFeedbackOnStart: true,
      feedback: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 280,
          child: _SetTile(set: set),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.2,
        child: _SetTile(set: set),
      ),
      child: _SetTile(set: set),
    );
  }
}

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
        return LongPressDraggable<DragFolder>(
          delay: const Duration(milliseconds: 400),
          hapticFeedbackOnStart: true,
          data: DragFolder(folder),
          feedback: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 280,
              child: _FolderTileView(folder: folder),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
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