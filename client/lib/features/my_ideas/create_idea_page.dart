import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';

import '../../shared/api/api_client.dart';
import '../../shared/api/api_models.dart';

/// Categories users can pick from when creating an idea.
const _categories = [
  'FinTech',
  'HealthTech',
  'EdTech',
  'E-Commerce',
  'SaaS',
  'AI / ML',
  'Social',
  'Gaming',
  'Climate',
  'Logistics',
  'Media',
  'Other',
];

const _stages = ['idea', 'prototype', 'beta', 'live'];

class CreateIdeaPage extends ConsumerStatefulWidget {
  const CreateIdeaPage({super.key, this.ideaId});

  /// If non-null, we are editing an existing idea.
  final String? ideaId;

  @override
  ConsumerState<CreateIdeaPage> createState() => _CreateIdeaPageState();
}

class _CreateIdeaPageState extends ConsumerState<CreateIdeaPage> {
  bool _loading = false;
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  final _titleCtrl = TextEditingController();
  final _pitchCtrl = TextEditingController();
  final _oneLinerCtrl = TextEditingController();
  final _problemCtrl = TextEditingController();
  final _solutionCtrl = TextEditingController();
  final _audienceCtrl = TextEditingController();
  final _diffCtrl = TextEditingController();
  final _demoUrlCtrl = TextEditingController();
  final _repoUrlCtrl = TextEditingController();

  String _category = _categories.first;
  String _stage = 'idea';
  List<String> _tags = [];
  final _tagCtrl = TextEditingController();

  // Media items already uploaded
  List<MediaItemDto> _media = [];
  String? _existingIdeaId;

  @override
  void initState() {
    super.initState();
    if (widget.ideaId != null) {
      _loadExisting();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _pitchCtrl.dispose();
    _oneLinerCtrl.dispose();
    _problemCtrl.dispose();
    _solutionCtrl.dispose();
    _audienceCtrl.dispose();
    _diffCtrl.dispose();
    _demoUrlCtrl.dispose();
    _repoUrlCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final idea = await ref.read(apiProvider).getMyIdea(widget.ideaId!);
      _existingIdeaId = idea.id;
      _titleCtrl.text = idea.title;
      _pitchCtrl.text = idea.shortPitch;
      _oneLinerCtrl.text = idea.oneLiner;
      _problemCtrl.text = idea.problem ?? '';
      _solutionCtrl.text = idea.solution ?? '';
      _audienceCtrl.text = idea.audience ?? '';
      _diffCtrl.text = idea.differentiator ?? '';
      _demoUrlCtrl.text = (idea.links?['demo_url'] ?? '').toString();
      _repoUrlCtrl.text = (idea.links?['repo_url'] ?? '').toString();
      _category = idea.category;
      _stage = idea.stage;
      _tags = idea.tags ?? [];
      _media = idea.media;
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _buildLinks() {
    final links = <String, dynamic>{};
    if (_demoUrlCtrl.text.trim().isNotEmpty) links['demo_url'] = _demoUrlCtrl.text.trim();
    if (_repoUrlCtrl.text.trim().isNotEmpty) links['repo_url'] = _repoUrlCtrl.text.trim();
    return links.isEmpty ? {} : links;
  }

  Future<void> _save({required String status}) async {
    if (_titleCtrl.text.trim().isEmpty || _pitchCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Title and pitch are required');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final body = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'short_pitch': _pitchCtrl.text.trim(),
        'category': _category,
        'tags': _tags.isEmpty ? null : _tags,
        'media_url': _media.isNotEmpty ? _media.first.url : '',
        'one_liner': _oneLinerCtrl.text.trim().isEmpty ? null : _oneLinerCtrl.text.trim(),
        'problem': _problemCtrl.text.trim().isEmpty ? null : _problemCtrl.text.trim(),
        'solution': _solutionCtrl.text.trim().isEmpty ? null : _solutionCtrl.text.trim(),
        'audience': _audienceCtrl.text.trim().isEmpty ? null : _audienceCtrl.text.trim(),
        'differentiator': _diffCtrl.text.trim().isEmpty ? null : _diffCtrl.text.trim(),
        'stage': _stage,
        'links': _buildLinks(),
        'status': status,
      };

      if (_existingIdeaId != null) {
        await ref.read(apiProvider).updateMyIdea(_existingIdeaId!, body);
      } else {
        final created = await ref.read(apiProvider).createMyIdea(body);
        _existingIdeaId = created.id;
      }

      if (!mounted) return;
      context.go('/my-ideas');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadMedia() async {
    // First ensure we have an idea in DB (need idea_id for media upload)
    if (_existingIdeaId == null) {
      if (_titleCtrl.text.trim().isEmpty || _pitchCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Fill title & pitch before uploading media');
        return;
      }
      setState(() => _uploading = true);
      try {
        final created = await ref.read(apiProvider).createMyIdea({
          'title': _titleCtrl.text.trim(),
          'short_pitch': _pitchCtrl.text.trim(),
          'category': _category,
          'tags': _tags.isEmpty ? null : _tags,
          'media_url': '',
          'stage': _stage,
          'status': 'draft',
        });
        _existingIdeaId = created.id;
      } catch (e) {
        setState(() {
          _error = e.toString();
          _uploading = false;
        });
        return;
      }
    }

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        withData: true,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _uploading = false);
        return;
      }

      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes == null) continue;

        final contentType = lookupMimeType(file.name, headerBytes: bytes) ?? 'application/octet-stream';
        final isVideo = contentType.startsWith('video/');
        final mediaType = isVideo ? 'video' : 'image';

        // 1. Get presigned upload URL
        final presign = await ref.read(apiProvider).createIdeaMediaUploadUrl(
              ideaId: _existingIdeaId!,
              contentType: contentType,
              mediaType: mediaType,
            );
        final uploadUrl = (presign['upload_url'] ?? '').toString();
        final objectKey = (presign['object_key'] ?? '').toString();
        final headers = (presign['headers'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

        if (uploadUrl.isEmpty || objectKey.isEmpty) continue;

        // 2. Upload to S3
        await ref.read(apiProvider).uploadToPresignedUrl(
              uploadUrl: uploadUrl,
              bytes: Uint8List.fromList(bytes),
              headers: headers,
            );

        // 3. Register in DB
        final media = await ref.read(apiProvider).registerIdeaMedia(
              ideaId: _existingIdeaId!,
              s3Key: objectKey,
              mediaType: mediaType,
            );

        setState(() => _media.add(media));
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteMedia(MediaItemDto item) async {
    if (_existingIdeaId == null) return;
    try {
      await ref.read(apiProvider).deleteIdeaMedia(ideaId: _existingIdeaId!, mediaId: item.id);
      setState(() => _media.removeWhere((m) => m.id == item.id));
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _addTag() {
    final tag = _tagCtrl.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
      _tagCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.ideaId != null;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(isEditing ? 'Edit Idea' : 'New Idea')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Idea' : 'New Idea'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/my-ideas'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Basic info ──
                Text('Basic Info', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Project title *', border: OutlineInputBorder()),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pitchCtrl,
                  decoration: const InputDecoration(labelText: 'Short pitch *', border: OutlineInputBorder(), helperText: 'One sentence that hooks the reader'),
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _oneLinerCtrl,
                  decoration: const InputDecoration(labelText: 'One-liner', border: OutlineInputBorder()),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // ── Category & Stage ──
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _category = v ?? _categories.first),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _stage,
                        decoration: const InputDecoration(labelText: 'Stage', border: OutlineInputBorder()),
                        items: _stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _stage = v ?? 'idea'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Tags ──
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagCtrl,
                        decoration: const InputDecoration(labelText: 'Add tag', border: OutlineInputBorder()),
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(onPressed: _addTag, icon: const Icon(Icons.add)),
                  ],
                ),
                if (_tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _tags
                          .map((t) => Chip(
                                label: Text(t),
                                onDeleted: () => setState(() => _tags.remove(t)),
                              ))
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 24),

                // ── Details ──
                Text('Details', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _problemCtrl,
                  decoration: const InputDecoration(labelText: 'Problem', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _solutionCtrl,
                  decoration: const InputDecoration(labelText: 'Solution', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _audienceCtrl,
                  decoration: const InputDecoration(labelText: 'Target audience', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _diffCtrl,
                  decoration: const InputDecoration(labelText: 'Differentiator', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),

                // ── Links ──
                Text('Links', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _demoUrlCtrl,
                  decoration: const InputDecoration(labelText: 'Demo / Landing URL', border: OutlineInputBorder()),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _repoUrlCtrl,
                  decoration: const InputDecoration(labelText: 'Repository URL', border: OutlineInputBorder()),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 24),

                // ── Media gallery ──
                Text('Media', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Upload photos and videos for your project', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),

                // Uploaded items grid
                if (_media.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _media.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = _media[index];
                        return Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: item.mediaType == 'video'
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.videocam, size: 32),
                                          Text('Video', style: Theme.of(context).textTheme.bodySmall),
                                        ],
                                      ),
                                    )
                                  : Image.network(
                                      item.url,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                    ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _deleteMedia(item),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                if (kIsWeb)
                  FilledButton.tonal(
                    onPressed: _saving || _uploading ? null : _uploadMedia,
                    child: _uploading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Upload photos / videos'),
                  ),
                if (!kIsWeb)
                  FilledButton.tonal(
                    onPressed: _saving || _uploading ? null : _uploadMedia,
                    child: _uploading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Upload photos / videos'),
                  ),
                const SizedBox(height: 24),

                // ── Error ──
                if (_error != null) ...[
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 12),
                ],

                // ── Action buttons ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => _save(status: 'draft'),
                        child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save draft'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : () => _save(status: 'published'),
                        child: _saving
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Publish'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
