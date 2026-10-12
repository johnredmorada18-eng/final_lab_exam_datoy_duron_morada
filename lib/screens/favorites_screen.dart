import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../app_theme.dart';
import '../main.dart' show favoritesBoxName;
import '../widgets/app_widgets.dart';

/// Route: '/favorites'  -  Read, Update (note) and Delete saved posts.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final Box _box = Hive.box(favoritesBoxName);
  String? _message;

  // Update: edit the personal note and write it back with put().
  void _editNote(Map post) {
    final noteCtrl = TextEditingController(text: post['note'] ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Personal Note',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Your note'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final updated = Map<String, dynamic>.from(post);
              updated['note'] = noteCtrl.text.trim();
              _box.put(post['id'], updated);
              Navigator.pop(dialogContext);
              setState(() => _message = 'Note updated.');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Delete: remove the post using delete().
  void _delete(Map post) {
    _box.delete(post['id']);
    setState(() => _message = 'Removed "${post['title']}" from favorites.');
  }

  @override
  Widget build(BuildContext context) {
    // Read: list everything stored in the box.
    final favorites = _box.values.toList();

    return Scaffold(
      appBar: const GradientAppBar(title: 'Favorites'),
      body: Column(
        children: [
          if (_message != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.pad, AppTheme.pad, AppTheme.pad, 0),
              child: InfoBanner(message: _message!),
            ),
          Expanded(
            child: favorites.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.pad * 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_border_rounded,
                              size: 64, color: AppTheme.orange),
                          SizedBox(height: 16),
                          Text(
                            'No favorites yet.\nOpen a post and tap "Save to Favorites".',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.muted),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 14, bottom: 24),
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final post = favorites[index] as Map;
                      final note = (post['note'] ?? '') as String;
                      return NoteCard(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Text(
                                        post['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Edit note',
                                    icon: const Icon(Icons.edit_note_rounded,
                                        color: AppTheme.orange),
                                    onPressed: () => _editNote(post),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppTheme.coral),
                                    onPressed: () => _delete(post),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  post['body'],
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppTheme.muted),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.tint,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  note.isEmpty ? 'No note yet.' : 'Note: $note',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                    color: note.isEmpty
                                        ? AppTheme.muted
                                        : AppTheme.pink,
                                  ),
                                ),
                              ),
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
