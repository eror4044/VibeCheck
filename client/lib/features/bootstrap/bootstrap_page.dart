import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/api/api_client.dart';


class BootstrapPage extends ConsumerStatefulWidget {
  const BootstrapPage({super.key});

  @override
  ConsumerState<BootstrapPage> createState() => _BootstrapPageState();
}


class _BootstrapPageState extends ConsumerState<BootstrapPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final token = await ref.read(tokenStoreProvider).getAccessToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      context.go('/login');
      return;
    }

    try {
      final me = await ref.read(apiProvider).getMe();
      final interests = me.interests;
      final completed = interests != null && interests['onboarding_v1_completed'] == true;
      if (!mounted) return;
      context.go(completed ? '/swipe' : '/onboarding');
    } catch (_) {
      await ref.read(tokenStoreProvider).clear();
      if (!mounted) return;
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
