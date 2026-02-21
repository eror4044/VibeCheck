import 'package:flutter/material.dart';


class SwipeDonePage extends StatelessWidget {
  const SwipeDonePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('No more ideas', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('Check back later.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
