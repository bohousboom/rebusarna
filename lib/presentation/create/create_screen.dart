import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/supabase_client.dart';
import '../shared/account_bar.dart';
import '../shared/create_help_sheet.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vytvoř rébus'),
        actions: const [HelpIconButton(size: 24)],
      ),
      body: PuzzleEditor(onSaved: () => context.go('/mine')),
    );
  }
}
