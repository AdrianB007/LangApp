import 'package:flutter/material.dart';
import '../sets_page.dart';

class Header extends StatelessWidget {
  final List<FolderNode> breadcrumb;
  final Function(FolderNode) onNavigate;

  const Header({
    super.key, 
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