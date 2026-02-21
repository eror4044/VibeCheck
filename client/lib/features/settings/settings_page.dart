import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/api/api_client.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Account section
              Text('Account', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Edit profile'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/profile/edit'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.tune),
                      title: const Text('Preferences'),
                      subtitle: const Text('Intent, interests, feed calibration'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/onboarding'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Content section
              Text('Content', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lightbulb_outline),
                      title: const Text('My ideas'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/my-ideas'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.bar_chart),
                      title: const Text('Statistics'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/stats'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // About section
              Text('About', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Version'),
                      trailing: Text('1.0.0'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(tokenStoreProvider).setAccessToken('');
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
                style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
