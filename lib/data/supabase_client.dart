import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';

bool _supabaseReady = false;

/// Zavolá se v main(). Když se nepovede (offline, špatná konfigurace), aplikace
/// běží dál jen lokálně.
Future<void> initSupabase() async {
  try {
    await Supabase.initialize(url: kSupabaseUrl, publishableKey: kSupabasePublishableKey);
    _supabaseReady = true;
  } catch (e) {
    debugPrint('Supabase se nepodařilo inicializovat: $e');
  }
}

/// null = Supabase není k dispozici (testy, chybná konfigurace).
final supabaseClientProvider = Provider<SupabaseClient?>(
  (ref) => _supabaseReady ? Supabase.instance.client : null,
);

/// Přihlášený uživatel (null = nepřihlášen nebo bez Supabase).
final currentUserProvider = StreamProvider<User?>((ref) async* {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    yield null;
    return;
  }
  yield client.auth.currentUser;
  yield* client.auth.onAuthStateChange.map((s) => s.session?.user);
});

/// Správce (smí importovat vestavěné rébusy); ověřuje databáze, ne aplikace.
final isAdminProvider = FutureProvider<bool>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider).value;
  if (client == null || user == null) return false;
  try {
    return (await client.rpc('is_admin')) == true;
  } catch (_) {
    return false;
  }
});

/// Zobrazované jméno z Google profilu.
String? displayNameOf(User? user) {
  final meta = user?.userMetadata;
  final name = (meta?['full_name'] ?? meta?['name']) as String?;
  return (name != null && name.trim().isNotEmpty) ? name.trim() : null;
}

class AuthActions {
  AuthActions(this._client);

  final SupabaseClient? _client;

  Future<void> signInWithGoogle() async {
    final c = _client;
    if (c == null) return;
    try {
      await c.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? Uri.base.origin : kMobileAuthRedirect,
        authScreenLaunchMode:
            kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
    } on PlatformException catch (e) {
      debugPrint('Přihlášení selhalo: $e');
      rethrow;
    }
  }

  Future<void> signOut() async => _client?.auth.signOut();
}

final authActionsProvider =
    Provider<AuthActions>((ref) => AuthActions(ref.watch(supabaseClientProvider)));
