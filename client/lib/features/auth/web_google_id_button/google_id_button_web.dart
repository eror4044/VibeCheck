// Web-only implementation.

import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:google_identity_services_web/id.dart' as gis;
import 'package:google_identity_services_web/loader.dart' as gis_loader;
import 'package:web/web.dart' as web;


class GoogleIdButton extends StatefulWidget {
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
  State<GoogleIdButton> createState() => _GoogleIdButtonState();
}


class _GoogleIdButtonState extends State<GoogleIdButton> {
  late final String _viewType;
  web.HTMLDivElement? _container;
  bool _initialized = false;
  bool _rendered = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'gsi-button-${DateTime.now().microsecondsSinceEpoch}';

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final div = web.HTMLDivElement();
      div.style.display = 'flex';
      div.style.justifyContent = 'center';
      _container = div;
      // Container becomes available only after the view is created.
      // Trigger init here to avoid missing initialization.
      Future<void>.microtask(() {
        if (mounted) {
          _tryInit();
        }
      });
      return div;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tryInit();
  }

  @override
  void didUpdateWidget(covariant GoogleIdButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientId != widget.clientId) {
      _initialized = false;
      _tryInit();
    }
  }

  void _tryInit() {
    if (_initialized) return;

    if (widget.clientId.isEmpty) {
      _initialized = true;
      widget.onError(
        'GOOGLE_CLIENT_ID is empty. Run with --dart-define=GOOGLE_CLIENT_ID=... and restart flutter run.',
      );
      return;
    }
    final container = _container;
    if (container == null) return;

    _initialized = true;

    gis_loader.loadWebSdk().then((_) {
      gis.id.initialize(
        gis.IdConfiguration(
          client_id: widget.clientId,
          callback: (gis.CredentialResponse response) {
            final credential = response.credential;
            if (credential == null || credential.isEmpty) {
              widget.onError('Google did not return an id_token (credential).');
              return;
            }
            widget.onIdToken(credential);
          },
        ),
      );

      gis.id.renderButton(
        container,
        gis.GsiButtonConfiguration(
          theme: gis.ButtonTheme.filled_blue,
          size: gis.ButtonSize.large,
          text: gis.ButtonText.continue_with,
          shape: gis.ButtonShape.pill,
        ),
      );

      if (mounted) {
        setState(() {
          _rendered = true;
        });
      }
    }).catchError((Object ex) {
      widget.onError('Failed to load Google SDK: $ex');
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.disabled,
      child: SizedBox(
        height: 44,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              HtmlElementView(viewType: _viewType),
              if (!_rendered)
                SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
