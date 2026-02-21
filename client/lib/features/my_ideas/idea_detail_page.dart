import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/api/api_client.dart';
import '../../shared/api/api_models.dart';

class IdeaDetailPage extends ConsumerStatefulWidget {
  const IdeaDetailPage({super.key, required this.ideaId});

  final String ideaId;

  @override
  ConsumerState<IdeaDetailPage> createState() => _IdeaDetailPageState();
}

class _IdeaDetailPageState extends ConsumerState<IdeaDetailPage> {
  MyIdeaDto? _idea;
  IdeaStatDto? _stats;
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
      final idea = await ref.read(apiProvider).getMyIdea(widget.ideaId);
      // Also fetch stats for this idea
      IdeaStatDto? stats;
      try {
        final allStats = await ref.read(apiProvider).getMyIdeasStats();
        stats = allStats.ideas.where((s) => s.ideaId == widget.ideaId).firstOrNull;
      } catch (_) {
        // stats aren't critical
      }
      if (!mounted) return;
      setState(() {
        _idea = idea;
        _stats = stats;
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

  Future<void> _publish() async {
    try {
      await ref.read(apiProvider).publishMyIdea(widget.ideaId);
      await _load();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete idea?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(apiProvider).deleteMyIdea(widget.ideaId);
      if (mounted) context.go('/my-ideas');
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Idea')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _idea == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Idea')),
        body: Center(child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      );
    }

    final idea = _idea!;
    final isDraft = idea.status == 'draft';

    return Scaffold(
      appBar: AppBar(
        title: Text(idea.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/my-ideas'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => context.go('/my-ideas/${idea.id}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: _delete,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDraft
                            ? Theme.of(context).colorScheme.surfaceContainerHighest
                            : Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isDraft ? 'Draft' : 'Published',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${idea.category} · ${idea.stage}', style: Theme.of(context).textTheme.bodySmall),
                    const Spacer(),
                    if (isDraft)
                      FilledButton(
                        onPressed: _publish,
                        child: const Text('Publish'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Media gallery
                if (idea.media.isNotEmpty) ...[
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: idea.media.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = idea.media[index];
                        return Container(
                          width: 280,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: item.mediaType == 'video'
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.play_circle_outline, size: 48),
                                      const SizedBox(height: 8),
                                      Text('Video ${index + 1}', style: Theme.of(context).textTheme.bodyMedium),
                                    ],
                                  ),
                                )
                              : Image.network(
                                  item.url,
                                  fit: BoxFit.cover,
                                  width: 280,
                                  height: 220,
                                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 48)),
                                ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (idea.mediaUrl.isNotEmpty) ...[
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      idea.mediaUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 48)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Pitch
                Text(idea.shortPitch, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),

                // Stats card
                if (_stats != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Statistics', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _StatChip(label: 'Views', value: _stats!.totalViews.toString()),
                              const SizedBox(width: 16),
                              _StatChip(label: 'Vibes', value: _stats!.totalVibes.toString()),
                              const SizedBox(width: 16),
                              _StatChip(label: 'Skips', value: _stats!.totalNoVibes.toString()),
                              const SizedBox(width: 16),
                              _StatChip(label: 'Vibe %', value: '${_stats!.vibeRate}%'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Details
                if (idea.oneLiner.isNotEmpty) _Section(title: 'One-liner', body: idea.oneLiner),
                if (idea.problem != null && idea.problem!.isNotEmpty) _Section(title: 'Problem', body: idea.problem!),
                if (idea.solution != null && idea.solution!.isNotEmpty) _Section(title: 'Solution', body: idea.solution!),
                if (idea.audience != null && idea.audience!.isNotEmpty) _Section(title: 'For whom', body: idea.audience!),
                if (idea.differentiator != null && idea.differentiator!.isNotEmpty) _Section(title: 'Differentiator', body: idea.differentiator!),

                // Tags
                if (idea.tags != null && idea.tags!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: idea.tags!.map((t) => Chip(label: Text(t))).toList(),
                  ),
                ],

                // Links
                if (idea.links != null && idea.links!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Links', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...idea.links!.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text('${e.key}: ', style: Theme.of(context).textTheme.bodySmall),
                            Expanded(child: Text(e.value.toString(), style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      )),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
