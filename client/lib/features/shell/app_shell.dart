import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String location) {
    if (location.startsWith('/my-ideas')) return 1;
    if (location.startsWith('/stats')) return 2;
    if (location.startsWith('/profile') || location.startsWith('/settings')) return 3;
    return 0; // default: swipe / explore
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/swipe');
        return;
      case 1:
        context.go('/my-ideas');
        return;
      case 2:
        context.go('/stats');
        return;
      case 3:
        context.go('/profile');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.lightbulb_outline), label: 'My Ideas'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
