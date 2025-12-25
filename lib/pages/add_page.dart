import 'package:flutter/material.dart';
import './adding/manual_add.dart';

class AddPage extends StatelessWidget {
  const AddPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add new words', style: TextStyle(fontWeight: FontWeight.normal, )),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionTitle(title: 'Import'),
            const SizedBox(height: 12),

            _AddOptionTile(
              icon: Icons.camera_alt,
              title: 'Photo (OCR)',
              subtitle: 'Scan text from images or photos',
              onTap: () {
                // TODO: OCR from camera
              },
            ),

            _AddOptionTile(
              icon: Icons.insert_drive_file,
              title: 'File',
              subtitle: 'PDF, screenshot or document',
              onTap: () {
                // TODO: Import from file
              },
            ),

            _AddOptionTile(
              icon: Icons.text_snippet,
              title: 'Plain Text',
              subtitle: 'Paste or write raw text',
              onTap: () {
                // TODO: Paste plain text
              },
            ),

            const SizedBox(height: 24),
            _SectionTitle(title: 'Manual'),
            const SizedBox(height: 12),

            _AddOptionTile(
              icon: Icons.edit,
              title: 'Add manually',
              subtitle: 'Add words one by one',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                  builder: (_) => const ManualAddPage(),
                ),
              );
              },
            ),

            const SizedBox(height: 24),
            _SectionTitle(title: 'AI Companion'),
            const SizedBox(height: 12),

            _AddOptionTile(
              icon: Icons.auto_awesome,
              title: 'Generate with AI',
              subtitle: 'Create a word list with AI Companion',
              trailing: const Chip(
                label: Text('AI'),
              ),
              onTap: () {
                // TODO: AI generation
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _AddOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _AddOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
