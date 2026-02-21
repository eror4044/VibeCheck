import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/api/api_client.dart';
import '../../shared/api/api_models.dart';


class SwipePage extends ConsumerStatefulWidget {
  const SwipePage({super.key});

  @override
  ConsumerState<SwipePage> createState() => _SwipePageState();
}


class _SwipePageState extends ConsumerState<SwipePage> {
  FeedIdeaDto? _idea;
  bool _loading = true;
  String? _error;

  Offset _drag = Offset.zero;
  DateTime? _shownAt;

  bool _detailsOpen = false;
  double _detailsDragY = 0;
  Axis? _gestureAxis;

  @override
  void initState() {
    super.initState();
    _loadNext();
  }

  Future<void> _loadNext() async {
    setState(() {
      _loading = true;
      _error = null;
      _drag = Offset.zero;
      _detailsOpen = false;
      _detailsDragY = 0;
      _gestureAxis = null;
    });

    try {
      final idea = await ref.read(apiProvider).getNextIdea();
      if (!mounted) return;
      if (idea == null) {
        context.go('/done');
        return;
      }
      setState(() {
        _idea = idea;
        _shownAt = DateTime.now();
        _loading = false;
      });
    } catch (ex) {
      setState(() {
        _error = ex.toString();
        _loading = false;
      });
    }
  }

  int? _decisionTimeMs() {
    final shownAt = _shownAt;
    if (shownAt == null) return null;
    return DateTime.now().difference(shownAt).inMilliseconds;
  }

  Future<void> _submitSwipe(String direction) async {
    final idea = _idea;
    if (idea == null) return;

    try {
      await ref.read(apiProvider).createSwipe(
            ideaId: idea.id,
            direction: direction,
            decisionTimeMs: _decisionTimeMs(),
          );
      await _loadNext();
    } catch (ex) {
      setState(() {
        _error = ex.toString();
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_detailsOpen) {
      // Only allow dragging down to close.
      setState(() {
        _detailsDragY = (_detailsDragY + details.delta.dy).clamp(0, 260);
      });
      return;
    }

    final dx = details.delta.dx;
    final dy = details.delta.dy;

    // Lock gesture axis once the user clearly commits.
    final axis = _gestureAxis;
    if (axis == null) {
      if (dx.abs() > 6 || dy.abs() > 6) {
        _gestureAxis = (dy.abs() > dx.abs()) ? Axis.vertical : Axis.horizontal;
      }
    }

    if (_gestureAxis == Axis.vertical) {
      // Drag up opens details.
      setState(() {
        _detailsDragY = (_detailsDragY - dy).clamp(0, 260);
      });
      return;
    }

    // Horizontal swipe for decisions.
    setState(() {
      _drag += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_detailsOpen) {
      if (_detailsDragY > 120) {
        setState(() {
          _detailsOpen = false;
          _detailsDragY = 0;
          _gestureAxis = null;
        });
      } else {
        setState(() {
          _detailsDragY = 0;
        });
      }
      return;
    }

    if (_gestureAxis == Axis.vertical) {
      // Decide whether to open details.
      if (_detailsDragY > 90) {
        setState(() {
          _detailsOpen = true;
          _detailsDragY = 0;
          _gestureAxis = null;
        });
      } else {
        setState(() {
          _detailsDragY = 0;
          _gestureAxis = null;
        });
      }
      return;
    }

    final dx = _drag.dx;
    if (dx > 140) {
      _submitSwipe('vibe');
      return;
    }
    if (dx < -140) {
      _submitSwipe('no_vibe');
      return;
    }

    setState(() {
      _drag = Offset.zero;
      _gestureAxis = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final idea = _idea;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    _detailsOpen
                        ? 'Swipe down to close details'
                        : 'Swipe right = Vibe • Swipe left = No Vibe • Swipe up = Details',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: idea == null
                        ? const SizedBox.shrink()
                        : Stack(
                            children: [
                              if (_detailsOpen)
                                Positioned.fill(
                                  child: _IdeaDetails(idea: idea),
                                ),
                              Positioned.fill(
                                child: GestureDetector(
                                  onPanUpdate: _onPanUpdate,
                                  onPanEnd: _onPanEnd,
                                  child: AnimatedSlide(
                                    offset: _detailsOpen
                                        ? const Offset(0, -0.55)
                                        : Offset(0, -(_detailsDragY / 480)),
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOut,
                                    child: Transform.translate(
                                      offset: Offset(_drag.dx, 0),
                                      child: Transform.rotate(
                                        angle: _detailsOpen ? 0 : (_drag.dx / 1600),
                                        child: _IdeaCard(
                                          idea: idea,
                                          showCompactHint: !_detailsOpen,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _IdeaCard extends StatelessWidget {
  const _IdeaCard({required this.idea, required this.showCompactHint});

  final FeedIdeaDto idea;
  final bool showCompactHint;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.network(
              idea.mediaUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Text('Image unavailable'));
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  idea.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  idea.shortPitch,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (showCompactHint) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Swipe up for details',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _IdeaDetails extends StatelessWidget {
  const _IdeaDetails({required this.idea});

  final FeedIdeaDto idea;

  @override
  Widget build(BuildContext context) {
    final links = idea.links ?? const <String, dynamic>{};

    Widget? linkTile(String key, String label) {
      final v = links[key];
      if (v == null) return null;
      final url = v.toString().trim();
      if (url.isEmpty) return null;
      return ListTile(
        dense: true,
        title: Text(label),
        subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
      );
    }

    final tiles = <Widget?>[
      _DetailSection(title: 'One-liner', body: idea.oneLiner),
      if (idea.problem != null && idea.problem!.trim().isNotEmpty) _DetailSection(title: 'Problem', body: idea.problem!.trim()),
      if (idea.solution != null && idea.solution!.trim().isNotEmpty) _DetailSection(title: 'Solution', body: idea.solution!.trim()),
      if (idea.audience != null && idea.audience!.trim().isNotEmpty) _DetailSection(title: 'For whom', body: idea.audience!.trim()),
      if (idea.differentiator != null && idea.differentiator!.trim().isNotEmpty)
        _DetailSection(title: 'Differentiator', body: idea.differentiator!.trim()),
      _DetailSection(title: 'Stage', body: idea.stage),
      if (idea.tags != null && idea.tags!.isNotEmpty) _DetailSection(title: 'Tags', body: idea.tags!.join(' · ')),
      const SizedBox(height: 6),
      if (links.isNotEmpty) Text('Links', style: Theme.of(context).textTheme.titleMedium),
      linkTile('demo_url', 'Demo'),
      linkTile('waitlist_url', 'Waitlist'),
      linkTile('repo_url', 'Repo'),
      const SizedBox(height: 96),
    ].where((e) => e != null).cast<Widget>().toList();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: tiles,
          ),
        ),
      ),
    );
  }
}


class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
