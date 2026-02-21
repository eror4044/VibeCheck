import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/api/api_client.dart';


class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}


class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  bool _saving = false;
  String? _selected;
  String? _error;

  Future<void> _save({required bool skipped}) async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final interests = <String, dynamic>{
      'onboarding_v1_completed': true,
      'intent': skipped ? 'unknown' : (_selected ?? 'unknown'),
    };

    try {
      await ref.read(apiProvider).putInterests(interests);
      if (!mounted) return;
      context.go('/swipe');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick setup'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Зачем вы здесь?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Это нужно только для калибровки сегментов. Можно пропустить.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  emptySelectionAllowed: true,
                  segments: const [
                    ButtonSegment(value: 'viewer', label: Text('Посмотреть идеи')),
                    ButtonSegment(value: 'creator', label: Text('Показать своё')),
                    ButtonSegment(value: 'both', label: Text('И то, и другое')),
                  ],
                  selected: _selected == null ? <String>{} : <String>{_selected!},
                  onSelectionChanged: _saving
                      ? null
                      : (selection) {
                          setState(() {
                            _selected = selection.isEmpty ? null : selection.first;
                          });
                        },
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _saving ? null : () => _save(skipped: false),
                  child: _saving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Continue'),
                ),
                TextButton(
                  onPressed: _saving ? null : () => _save(skipped: true),
                  child: const Text('Skip'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
