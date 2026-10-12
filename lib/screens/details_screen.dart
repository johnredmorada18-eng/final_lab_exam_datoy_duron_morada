import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../app_theme.dart';
import '../main.dart' show favoritesBoxName;
import '../widgets/app_widgets.dart';

/// Route: '/details'  -  shows one post and saves it to Hive (Create).
class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final Box _box = Hive.box(favoritesBoxName);
  String? _message;

  void _saveToFavorites(Map<String, dynamic> post) {
    final int id = post['id'];
    if (_box.containsKey(id)) {
      setState(() => _message = 'This post is already in your favorites.');
      return;
    }
    // Create: the post id is the key, so the same post is never saved twice.
    _box.put(id, {
      'id': id,
      'title': post['title'],
      'body': post['body'],
      'note': '',
    });
    setState(() => _message = 'Saved to favorites!');
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final bool saved = _box.containsKey(args['id']);

    return Scaffold(
      appBar: const GradientAppBar(title: 'Post Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26F76B8A),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppTheme.gradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Post #${args['id']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    args['title'],
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  Container(height: 3, width: 48, color: AppTheme.orange),
                  const SizedBox(height: 14),
                  Text(
                    args['body'],
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.5, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: saved ? 'Saved' : 'Save to Favorites',
              icon: saved ? Icons.check_rounded : Icons.favorite_border_rounded,
              onPressed: saved ? null : () => _saveToFavorites(args),
            ),
            if (_message != null) ...[
              const SizedBox(height: 14),
              InfoBanner(message: _message!),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
