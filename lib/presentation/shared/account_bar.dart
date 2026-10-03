import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/supabase_client.dart';

/// Přihlášení přes Google / informace o účtu. Bez Supabase se nezobrazí.
class AccountBar extends ConsumerWidget {
  const AccountBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(supabaseClientProvider) == null) return const SizedBox.shrink();
    final user = ref.watch(currentUserProvider).value;
    final actions = ref.read(authActionsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          Icon(user == null ? Icons.account_circle_outlined : Icons.account_circle),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              user == null
                  ? 'Nepřihlášen'
                  : (displayNameOf(user) ?? user.email ?? 'Přihlášen'),
              overflow: TextOverflow.ellipsis,
              key: const Key('account-name'),
            ),
          ),
          user == null
              ? FilledButton.tonal(
                  key: const Key('login-button'),
                  onPressed: actions.signInWithGoogle,
                  child: const Text('Přihlásit přes Google'),
                )
              : TextButton(
                  key: const Key('logout-button'),
                  onPressed: actions.signOut,
                  child: const Text('Odhlásit'),
                ),
        ],
      ),
    );
  }
}

/// Zástěna pro funkce, které vyžadují přihlášení (např. nahrávání).
class LoginGate extends ConsumerWidget {
  const LoginGate({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('gate-login-button'),
              onPressed: ref.read(authActionsProvider).signInWithGoogle,
              icon: const Icon(Icons.login),
              label: const Text('Přihlásit přes Google'),
            ),
          ],
        ),
      ),
    );
  }
}
