import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/api/api_client.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(apiProvider).getMe(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SafeArea(child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load profile: ${snapshot.error}'),
              ),
            ),
          );
        }

        final me = snapshot.data;
        if (me == null) {
          return const SafeArea(child: Center(child: Text('No profile')));
        }

        final title = (me.displayName != null && me.displayName!.trim().isNotEmpty) ? me.displayName!.trim() : 'Your profile';

        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: (me.avatarUrl == null || me.avatarUrl!.isEmpty) ? null : NetworkImage(me.avatarUrl!),
                          child: (me.avatarUrl == null || me.avatarUrl!.isEmpty) ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 2),
                              Text('Signed in with ${me.authProvider}', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: () => context.go('/profile/edit'),
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (me.about != null && me.about!.trim().isNotEmpty) ...[
                      Text(me.about!.trim(), style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                    ],
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Preferences', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text('Intent: ${(me.interests?['intent'] ?? 'unknown').toString()}'),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () async {
                        await ref.read(tokenStoreProvider).setAccessToken('');
                        if (context.mounted) context.go('/login');
                      },
                      child: const Text('Log out'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
