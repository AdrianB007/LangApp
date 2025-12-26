import 'package:flutter/material.dart';
import '../sets_page.dart';

/// Cofanie do folderu nadrzędnego
class BackNavButton extends StatelessWidget {
  final VoidCallback onTap;
  final Function(DragItem) onAccept;

  const BackNavButton({
    super.key, 
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
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary.withAlpha(20)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
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
            subtitle: isActive
                ? const Text('Drop here to move item up')
                : null,
            onTap: onTap,
          ),
        );
      },
    );
  }
}