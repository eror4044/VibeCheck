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
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: (me.avatarUrl == null || me.avatarUrl!.isEmpty) ? null : NetworkImage(me.avatarUrl!),
                        child: (me.avatarUrl == null || me.avatarUrl!.isEmpty) ? const Icon(Icons.person, size: 32) : null,
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
                      IconButton(
                        icon: const Icon(Icons.settings),
                        tooltip: 'Settings',
                        onPressed: () => context.go('/settings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (me.about != null && me.about!.trim().isNotEmpty) ...[
                    Text(me.about!.trim(), style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 12),
                  ],

                  // Quick actions
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => context.go('/profile/edit'),
                          child: const Text('Edit profile'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => context.go('/my-ideas/create'),
                          child: const Text('New idea'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Preferences card
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
                  const SizedBox(height: 12),

                  // Navigation cards
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lightbulb_outline),
                          title: const Text('My Ideas'),
                          subtitle: const Text('Create and manage projects'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go('/my-ideas'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.bar_chart),
                          title: const Text('Statistics'),
                          subtitle: const Text('Interests & market analytics'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go('/stats'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.settings),
                          title: const Text('Settings'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go('/settings'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(tokenStoreProvider).setAccessToken('');
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Log out'),
                    style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
