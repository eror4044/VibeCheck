import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api/api_client.dart';
import '../../shared/api/api_models.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  UserStatsDto? _userStats;
  MyIdeasStatsDto? _ideasStats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ref.read(apiProvider).getUserStats(),
        ref.read(apiProvider).getMyIdeasStats(),
      ]);
      if (!mounted) return;
      setState(() {
        _userStats = results[0] as UserStatsDto;
        _ideasStats = results[1] as MyIdeasStatsDto;
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
      appBar: AppBar(
        title: const Text('Statistics'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'My Swipes'),
            Tab(text: 'My Ideas'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)))
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _SwipeStatsTab(stats: _userStats!),
                    _IdeaStatsTab(stats: _ideasStats!),
                  ],
                ),
    );
  }
}

class _SwipeStatsTab extends StatelessWidget {
  const _SwipeStatsTab({required this.stats});
  final UserStatsDto stats;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary row
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Overview', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _BigStat(label: 'Total', value: stats.totalSwipes.toString()),
                        _BigStat(label: 'Vibes', value: stats.totalVibes.toString(), color: Colors.green),
                        _BigStat(label: 'Skips', value: stats.totalNoVibes.toString(), color: Colors.red),
                        _BigStat(label: 'Vibe %', value: '${stats.vibeRate}%'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (stats.byCategory.isEmpty)
              const Center(child: Text('No swipe data yet. Start swiping!'))
            else ...[
              Text('By Category / Market', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...stats.byCategory.map((cat) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.category, style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: cat.total > 0 ? cat.vibes / cat.total : 0,
                                    minHeight: 8,
                                    backgroundColor: Colors.red.withValues(alpha: 0.2),
                                    valueColor: const AlwaysStoppedAnimation(Colors.green),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('${cat.vibeRate}%', style: Theme.of(context).textTheme.labelLarge),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${cat.vibes} vibes · ${cat.noVibes} skips · ${cat.total} total',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _IdeaStatsTab extends StatelessWidget {
  const _IdeaStatsTab({required this.stats});
  final MyIdeasStatsDto stats;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BigStat(label: 'Total Views', value: stats.totalViews.toString()),
                    _BigStat(label: 'Total Vibes', value: stats.totalVibes.toString(), color: Colors.green),
                    _BigStat(label: 'Projects', value: stats.ideas.length.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (stats.ideas.isEmpty)
              const Center(child: Text('No ideas published yet. Create one!'))
            else ...[
              Text('Per Idea', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...stats.ideas.map((idea) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(idea.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${idea.totalViews} views · ${idea.totalVibes} vibes · ${idea.vibeRate}%'),
                      trailing: CircularProgressIndicator(
                        value: idea.totalViews > 0 ? idea.totalVibes / idea.totalViews : 0,
                        strokeWidth: 3,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
