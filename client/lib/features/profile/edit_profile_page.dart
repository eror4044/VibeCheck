import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';

import '../../shared/api/api_client.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  final _nameCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();

  String _intent = 'unknown';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _aboutCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final me = await ref.read(apiProvider).getMe();
      _nameCtrl.text = me.displayName ?? '';
      _aboutCtrl.text = me.about ?? '';
      _avatarCtrl.text = me.avatarUrl ?? '';
      _intent = (me.interests?['intent'] ?? 'unknown').toString();

      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    } catch (ex) {
      setState(() {
        _error = ex.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(apiProvider).putProfile(
            displayName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
            about: _aboutCtrl.text.trim().isEmpty ? null : _aboutCtrl.text.trim(),
            avatarUrl: _avatarCtrl.text.trim().isEmpty ? null : _avatarCtrl.text.trim(),
          );

      await ref.read(apiProvider).putInterests({
        'onboarding_v1_completed': true,
        'intent': _intent,
      });

      if (!mounted) return;
      context.go('/profile');
    } catch (ex) {
      setState(() {
        _error = ex.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _uploadAvatarWeb() async {
    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _uploading = false;
        });
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        throw StateError('Failed to read selected file bytes');
      }

      final contentType = lookupMimeType(file.name, headerBytes: bytes) ?? 'application/octet-stream';
      if (!contentType.startsWith('image/')) {
        throw StateError('Please choose an image file');
      }

      final presign = await ref.read(apiProvider).createAvatarUploadUrl(contentType: contentType);
      final uploadUrl = (presign['upload_url'] ?? '').toString();
      final objectKey = (presign['object_key'] ?? '').toString();
      final headers = (presign['headers'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

      if (uploadUrl.isEmpty || objectKey.isEmpty) {
        throw StateError('Backend did not return upload_url/object_key');
      }

      await ref.read(apiProvider).uploadToPresignedUrl(
            uploadUrl: uploadUrl,
            bytes: Uint8List.fromList(bytes),
            headers: headers,
          );

      // Save object key into profile (backend will return a presigned GET url in response).
      final me = await ref.read(apiProvider).putProfile(
            displayName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
            about: _aboutCtrl.text.trim().isEmpty ? null : _aboutCtrl.text.trim(),
            avatarUrl: objectKey,
          );

      _avatarCtrl.text = me.avatarUrl ?? '';

      if (!mounted) return;
      setState(() {
        _uploading = false;
      });
    } catch (ex) {
      setState(() {
        _error = ex.toString();
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _aboutCtrl,
                  decoration: const InputDecoration(labelText: 'About'),
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 12),
                if (kIsWeb) ...[
                  FilledButton.tonal(
                    onPressed: _saving || _uploading ? null : _uploadAvatarWeb,
                    child: _uploading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Upload avatar'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Avatars are uploaded to private S3 via a presigned URL.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  TextField(
                    controller: _avatarCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Avatar URL',
                      helperText: 'Mobile picker/upload will be added. For now you can paste an image URL.',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ],
                const SizedBox(height: 16),
                Text('Intent', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  emptySelectionAllowed: false,
                  segments: const [
                    ButtonSegment(value: 'viewer', label: Text('Viewer')),
                    ButtonSegment(value: 'creator', label: Text('Creator')),
                    ButtonSegment(value: 'both', label: Text('Both')),
                  ],
                  selected: <String>{_intent},
                  onSelectionChanged: _saving
                      ? null
                      : (selection) {
                          setState(() {
                            _intent = selection.first;
                          });
                        },
                ),
                const Spacer(),
                if (_error != null) ...[
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 8),
                ],
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
