import 'package:flutter/material.dart';

import '../../models/game.dart';
import '../../services/game_repository.dart';

class AdminGamesView extends StatefulWidget {
  const AdminGamesView({super.key});

  @override
  State<AdminGamesView> createState() => _AdminGamesViewState();
}

class _AdminGamesViewState extends State<AdminGamesView> {
  final GameRepository _repository = GameRepository();
  late Future<List<Game>> _gamesFuture;

  @override
  void initState() {
    super.initState();
    _gamesFuture = _repository.fetchAdminGames();
  }

  void _refresh() {
    setState(() => _gamesFuture = _repository.fetchAdminGames());
  }

  Future<void> _openEditor([Game? game]) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => AdminGameEditorView(game: game)),
    );
    if (saved == true && mounted) _refresh();
  }

  Future<void> _deleteGame(Game game) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove game?'),
        content: Text('“${game.name}” will be removed from the catalog.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.deleteGame(game.id);
      if (mounted) _refresh();
    } catch (error) {
      if (mounted) _showMessage('Could not remove game: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071426),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071426),
        foregroundColor: Colors.white,
        title: const Text('Games'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add game'),
      ),
      body: FutureBuilder<List<Game>>(
        future: _gamesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _AdminMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Games unavailable',
              message: 'Check Firebase setup and Firestore permissions.',
              onRetry: _refresh,
            );
          }

          final List<Game> games = snapshot.data ?? const [];
          if (games.isEmpty) {
            return _AdminMessage(
              icon: Icons.sports_esports_outlined,
              title: 'No games yet',
              message: 'Add the first game to your catalog.',
              onRetry: _refresh,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: games.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final Game game = games[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: _GameThumbnail(url: game.icon),
                    title: Text(
                      game.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${game.category} · ${game.version}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') _openEditor(game);
                        if (action == 'delete') _deleteGame(game);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Remove')),
                      ],
                    ),
                    onTap: () => _openEditor(game),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AdminGameEditorView extends StatefulWidget {
  const AdminGameEditorView({super.key, this.game});

  final Game? game;

  @override
  State<AdminGameEditorView> createState() => _AdminGameEditorViewState();
}

class _AdminGameEditorViewState extends State<AdminGameEditorView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GameRepository _repository = GameRepository();
  late final Map<String, TextEditingController> _fields;
  late final Map<String, TextEditingController> _imageFields;
  bool _isSaving = false;
  bool _isPublished = true;

  static const Map<String, String> _fieldLabels = {
    'name': 'Game name',
    'category': 'Category',
    'description': 'Description',
    'version': 'Version',
    'size': 'Download size',
    'downloadLink': 'Download link',
  };

  @override
  void initState() {
    super.initState();
    final Game? game = widget.game;
    _isPublished = game?.isPublished ?? true;
    _imageFields = {
      'icon': TextEditingController(text: game?.icon ?? ''),
      'screenshot1': TextEditingController(text: game?.screenshot1 ?? ''),
      'screenshot2': TextEditingController(text: game?.screenshot2 ?? ''),
    };
    _fields = {
      'name': TextEditingController(text: game?.name ?? ''),
      'category': TextEditingController(text: game?.category ?? ''),
      'description': TextEditingController(text: game?.description ?? ''),
      'version': TextEditingController(text: game?.version ?? ''),
      'size': TextEditingController(text: game?.size ?? ''),
      'downloadLink': TextEditingController(text: game?.downloadLink ?? ''),
    };
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _fields.values) {
      controller.dispose();
    }
    for (final TextEditingController controller in _imageFields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final Game game = Game(
        id: widget.game?.id ?? '',
        name: _fields['name']!.text.trim(),
        category: _fields['category']!.text.trim(),
        description: _fields['description']!.text.trim(),
        version: _fields['version']!.text.trim(),
        size: _fields['size']!.text.trim(),
        downloadLink: _fields['downloadLink']!.text.trim(),
        isPublished: _isPublished,
        icon: _imageFields['icon']!.text.trim(),
        screenshot1: _imageFields['screenshot1']!.text.trim(),
        screenshot2: _imageFields['screenshot2']!.text.trim(),
      );
      await _repository.saveGame(game);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save game: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071426),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071426),
        foregroundColor: Colors.white,
        title: Text(widget.game == null ? 'Add game' : 'Edit game'),
        actions: [
          IconButton(
            tooltip: 'Save game',
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
          children: [
            const Text(
              'Game details',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            for (final String key in [
              'name',
              'category',
              'description',
              'version',
              'size',
              'downloadLink',
            ]) ...[_buildField(key), const SizedBox(height: 10)],
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Published',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Published games appear in the public catalog.',
                style: TextStyle(color: Colors.white54),
              ),
              value: _isPublished,
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _isPublished = value),
            ),
            const SizedBox(height: 12),
            const Text(
              'Images',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            for (final (String key, String label) in const [
              ('icon', 'Game icon'),
              ('screenshot1', 'Screenshot 1'),
              ('screenshot2', 'Screenshot 2'),
            ]) ...[_buildImageUrlField(key, label), const SizedBox(height: 14)],
            const Text(
              'Use direct, publicly accessible image URLs. Leave a field blank to omit that image.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save game'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String key) {
    final bool required = key == 'name' || key == 'category';
    return TextFormField(
      controller: _fields[key],
      maxLines: key == 'description' ? 3 : 1,
      keyboardType:
          key.toLowerCase().contains('link') ||
              key.contains('shot') ||
              key == 'icon'
          ? TextInputType.url
          : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: _fieldLabels[key],
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      validator: required
          ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
          : null,
    );
  }

  Widget _buildImageUrlField(String key, String label) {
    final TextEditingController controller = _imageFields[key]!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            enabled: !_isSaving,
            keyboardType: TextInputType.url,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: '$label URL',
              hintText: 'https://example.com/image.jpg',
              hintStyle: const TextStyle(color: Colors.white30),
              labelStyle: const TextStyle(color: Colors.white60),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                tooltip: 'Clear image URL',
                onPressed: _isSaving ? null : controller.clear,
                icon: const Icon(Icons.clear_rounded),
              ),
            ),
            validator: (value) {
              final String url = value?.trim() ?? '';
              if (url.isEmpty) return null;
              final Uri? uri = Uri.tryParse(url);
              if (uri == null ||
                  !{'http', 'https'}.contains(uri.scheme) ||
                  uri.host.isEmpty) {
                return 'Enter a valid http or https URL';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: double.infinity,
              height: 150,
              child: controller.text.trim().isNotEmpty
                  ? Image.network(
                      controller.text.trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) =>
                          _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => ColoredBox(
    color: Colors.white.withValues(alpha: 0.06),
    child: const Center(
      child: Icon(
        Icons.add_photo_alternate_outlined,
        color: Colors.white38,
        size: 36,
      ),
    ),
  );
}

class _GameThumbnail extends StatelessWidget {
  const _GameThumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox.square(
        dimension: 48,
        child: url.startsWith('http')
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.white.withValues(alpha: 0.08),
    child: const Icon(Icons.sports_esports_outlined, color: Colors.white54),
  );
}

class _AdminMessage extends StatelessWidget {
  const _AdminMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white38, size: 38),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
