import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/supabase_client.dart';
import '../shared/account_bar.dart';
import 'puzzle_editor.dart';

class CreateScreen extends ConsumerWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // S Supabase je nahrávání jen pro přihlášené.
    final hasBackend = ref.watch(supabaseClientProvider) != null;
    final loggedIn = ref.watch(currentUserProvider).value != null;
    if (hasBackend && !loggedIn) {
      return const LoginGate(
        message: 'Vlastní rébusy mohou nahrávat jen přihlášení uživatelé.',
      );
    }
    return PuzzleEditor(
      title: 'Vytvoř rébus',
      onSaved: () => context.go('/mine'),
    );
  }
}
