import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../app_theme.dart';
import '../main.dart' show createdPostsBoxName;
import '../widgets/app_widgets.dart';

/// Route: '/'  -  fetches posts (GET) and lets the user create one (POST).
class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  static const String _url = 'https://jsonplaceholder.typicode.com/posts';

  final Box _createdBox = Hive.box(createdPostsBoxName);
  List<dynamic> _posts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  /// Posts created by the user (stored in Hive), newest first.
  List<dynamic> get _createdPosts =>
      _createdBox.values.toList().reversed.toList();

  // ---------- GET ----------
  Future<void> _fetchPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse(_url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() => _posts = data);
      } else {
        setState(() => _error =
            'Failed to load posts (status code: ${response.statusCode}).');
      }
    } catch (e) {
      setState(() => _error = 'Something went wrong: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------- POST ----------
  Future<void> _createPost(String title, String body) async {
    String message;
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'title': title, 'body': body, 'userId': 1}),
      );
      if (response.statusCode == 201) {
        // JSONPlaceholder does not really store the post (it always returns
        // id 101), so we also save it locally in Hive with our own unique id.
        final created = jsonDecode(response.body) as Map<String, dynamic>;
        int lastId = 100; // fetched posts use ids 1-100
        for (final key in _createdBox.keys) {
          if ((key as int) > lastId) lastId = key;
        }
        final newId = lastId + 1;
        await _createdBox.put(newId, {
          'id': newId,
          'title': created['title'],
          'body': created['body'],
        });
        setState(() {});
        message = 'Success! Post created (status code: 201).';
      } else {
        message = 'Failed to create post (status code: ${response.statusCode}).';
      }
    } catch (e) {
      message = 'Failed to create post: $e';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('New Post',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title cannot be empty'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: bodyCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Body'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Body cannot be empty'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final title = titleCtrl.text.trim();
                final body = bodyCtrl.text.trim();
                Navigator.pop(dialogContext);
                _createPost(title, body);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Posts',
        actions: [
          IconButton(
            tooltip: 'Favorites',
            icon: const Icon(Icons.favorite_rounded),
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: GradientFab(
        onPressed: _showCreateDialog,
        tooltip: 'New post',
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.coral),
      );
    }
    final allPosts = [..._createdPosts, ..._posts];
    if (_error != null && allPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.pad * 1.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 56, color: AppTheme.coral),
              const SizedBox(height: 16),
              InfoBanner(message: _error!, isError: true),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _fetchPosts,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final list = ListView.builder(
      padding: const EdgeInsets.only(top: 14, bottom: 100),
      itemCount: allPosts.length,
      itemBuilder: (context, index) {
        final post = allPosts[index];
        return NoteCard(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.pad, vertical: 8),
            title: Text(
              post['title'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                post['body'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.muted),
              ),
            ),
            trailing: Text(
              '#${post['id']}',
              style: const TextStyle(
                color: AppTheme.pink,
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () => Navigator.pushNamed(
              context,
              '/details',
              arguments: {
                'id': post['id'],
                'title': post['title'],
                'body': post['body'],
              },
            ),
          ),
        );
      },
    );

    if (_error == null) return list;
    // Fetch failed but the user has created posts: show the error + them.
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.pad, AppTheme.pad, AppTheme.pad, 0),
          child: InfoBanner(message: _error!, isError: true),
        ),
        Expanded(child: list),
      ],
    );
  }
}
