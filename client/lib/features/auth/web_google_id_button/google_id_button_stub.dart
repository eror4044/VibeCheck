import 'package:flutter/widgets.dart';


class GoogleIdButton extends StatelessWidget {
  const GoogleIdButton({
    super.key,
    required this.clientId,
    required this.disabled,
    required this.onIdToken,
    required this.onError,
  });

  final String clientId;
  final bool disabled;
  final ValueChanged<String> onIdToken;
  final ValueChanged<String> onError;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
