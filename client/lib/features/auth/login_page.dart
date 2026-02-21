import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../shared/api/api_client.dart';
import '../../shared/config.dart';

import 'web_google_id_button/google_id_button.dart';


class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}


class _LoginPageState extends ConsumerState<LoginPage> {
  bool _loading = false;
  String? _error;

  Future<void> _loginWithIdToken(String idToken) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ref.read(apiProvider).loginWithGoogleIdToken(idToken: idToken);
      final accessToken = data['access_token'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        throw StateError('Backend did not return access_token');
      }

      await ref.read(tokenStoreProvider).setAccessToken(accessToken);

      if (!mounted) return;
      context.go('/');
    } catch (ex) {
      setState(() {
        _error = ex.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _login() async {
    if (googleClientId.isEmpty) {
      setState(() {
        _error = 'GOOGLE_CLIENT_ID is not set. Run with --dart-define=GOOGLE_CLIENT_ID=...';
      });
      return;
    }

    if (kIsWeb) {
      setState(() {
        _error = 'На web используем кнопку Google (GIS) ниже.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final googleSignIn = GoogleSignIn(clientId: googleClientId);
      final account = await googleSignIn.signIn();
      if (account == null) {
        setState(() {
          _loading = false;
          _error = 'Login cancelled';
        });
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google id_token is missing');
      }
      await _loginWithIdToken(idToken);
    } catch (ex) {
      final msg = ex.toString();
      setState(() {
        if (msg.contains('redirect_uri_mismatch')) {
          _error = 'Google OAuth настроен неверно (redirect_uri_mismatch). В Google Cloud Console → APIs & Services → Credentials → OAuth Client (Web) добавь:\n- Authorized JavaScript origins: http://localhost:5173\n- Authorized redirect URIs: http://localhost:5173\nПосле этого перезапусти и попробуй снова.';
        } else if (msg.contains('popup_closed')) {
          _error = 'Окно входа Google было закрыто/заблокировано. Разреши pop-ups для localhost и попробуй снова. Если в popup написано redirect_uri_mismatch — нужно добавить localhost:5173 в OAuth настройки.';
        } else {
          _error = msg;
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'VibeCheck',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Continue with Google to start swiping.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                if (kIsWeb) ...[
                  if (googleClientId.isEmpty) ...[
                    Text(
                      'GOOGLE_CLIENT_ID is not set. Run with --dart-define=GOOGLE_CLIENT_ID=...'
                      '\n\nExample:'
                      '\nflutter run -d chrome --web-port=5173 --dart-define=GOOGLE_CLIENT_ID=...'
                      '\n\n(If you changed it, do a full restart of flutter run.)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ] else ...[
                    GoogleIdButton(
                      clientId: googleClientId,
                      disabled: _loading,
                      onIdToken: (token) => _loginWithIdToken(token),
                      onError: (message) {
                        setState(() {
                          _error = message;
                        });
                      },
                    ),
                  ],
                ] else ...[
                  FilledButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue with Google'),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
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

