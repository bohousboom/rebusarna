import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: shell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.extension), label: 'Hrát'),
          NavigationDestination(icon: Icon(Icons.edit), label: 'Tvořit'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Knihovna'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Moje'),
        ],
      ),
    );
  }
}
