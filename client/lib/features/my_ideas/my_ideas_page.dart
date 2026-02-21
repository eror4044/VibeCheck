import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/api/api_client.dart';
import '../../shared/api/api_models.dart';

class MyIdeasPage extends ConsumerStatefulWidget {
  const MyIdeasPage({super.key});

  @override
  ConsumerState<MyIdeasPage> createState() => _MyIdeasPageState();
}

class _MyIdeasPageState extends ConsumerState<MyIdeasPage> {
  List<MyIdeaDto>? _ideas;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ideas = await ref.read(apiProvider).listMyIdeas();
      if (!mounted) return;
      setState(() {
        _ideas = ideas;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Ideas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/my-ideas/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Idea'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)))
              : _ideas == null || _ideas!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lightbulb_outline, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text('No ideas yet', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          const Text('Tap + to create your first project!'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _ideas!.length,
                        itemBuilder: (context, index) {
                          final idea = _ideas![index];
                          return _IdeaCard(
                            idea: idea,
                            onTap: () => context.go('/my-ideas/${idea.id}'),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _IdeaCard extends StatelessWidget {
  const _IdeaCard({required this.idea, required this.onTap});

  final MyIdeaDto idea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDraft = idea.status == 'draft';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                clipBehavior: Clip.antiAlias,
                child: idea.media.isNotEmpty
                    ? Image.network(idea.media.first.url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image))
                    : idea.mediaUrl.isNotEmpty
                        ? Image.network(idea.mediaUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image))
                        : const Icon(Icons.lightbulb_outline),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(idea.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(idea.shortPitch, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDraft
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isDraft ? 'Draft' : 'Published',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDraft
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
