import 'package:flutter/material.dart';
import '../sets_page.dart';

/// Pasek akcji (Create folder / Add set)
class ActionsBar extends StatelessWidget {
  final VoidCallback? onCreateFolder;
  final VoidCallback onAddSet;

  const ActionsBar({
    super.key, 
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