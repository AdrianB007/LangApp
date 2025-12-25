
import 'package:flutter/material.dart';

class ManualAddPage extends StatefulWidget {
  const ManualAddPage({super.key});

  @override
  State<ManualAddPage> createState() => _ManualAddPageState();
}

class _ManualAddPageState extends State<ManualAddPage> {
  final _setNameController = TextEditingController();
  final _setDescriptionController = TextEditingController();

  final List<_WordPair> _words = [];

  void _addEmptyWord() {
    setState(() {
      _words.add(_WordPair());
    });
  }

  void _removeWord(int index) {
    setState(() {
      _words.removeAt(index);
    });
  }

  void _saveSet() {
    final setName = _setNameController.text.trim();

    if (setName.isEmpty || _words.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set name and at least one word are required'),
        ),
      );
      return;
    }

    final words = _words
        .where((w) => w.term.isNotEmpty && w.definition.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete at least one word pair'),
        ),
      );
      return;
    }

    // TODO: Save to database / backend
    debugPrint('Saving set: $setName');
    debugPrint('Words count: ${words.length}');

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _setNameController.dispose();
    _setDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create set'),
        actions: [
          TextButton(
            onPressed: _saveSet,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SetHeader(
            nameController: _setNameController,
            descriptionController: _setDescriptionController,
          ),
          const SizedBox(height: 24),

          ..._words.asMap().entries.map(
                (entry) => _WordCard(
                  index: entry.key,
                  word: entry.value,
                  onRemove: () => _removeWord(entry.key),
                ),
              ),

          const SizedBox(height: 12),
          _AddWordButton(onTap: _addEmptyWord),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final int index;
  final _WordPair word;
  final VoidCallback onRemove;

  const _WordCard({
    required this.index,
    required this.word,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Word ${index + 1}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Term',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => word.term = value,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Definition',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => word.definition = value,
            ),
          ],
        ),
      ),
    );
  }
}

class _SetHeader extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  const _SetHeader({
    required this.nameController,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Set name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _WordPair {
  String term = '';
  String definition = '';
}

class _AddWordButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddWordButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.add),
      label: const Text('Add word'),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
      ),
    );
  }
}
