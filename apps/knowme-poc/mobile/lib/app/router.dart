// TJ-ARCH-MOB-001 compliant
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/notes/presentation/screens/notes_screen.dart';
import '../features/memory/presentation/screens/memory_screen.dart';

/// The four KnowMe-slice tabs, in shell order. Adding a destination here is the
/// only edit needed to surface a feature — labels/icons/paths stay in lockstep.
const _tabs = <(String, IconData, String)>[
  ('/chat', Icons.chat_bubble_outline, 'Chat'),
  ('/notes', Icons.note_outlined, 'Notes'),
  ('/memory', Icons.memory, 'Memory'),
];

final appRouter = GoRouter(
  initialLocation: '/chat',
  routes: [
    ShellRoute(
      builder: (context, state, child) => _Shell(child: child),
      routes: [
        GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
        GoRoute(path: '/notes', builder: (_, __) => const NotesScreen()),
        GoRoute(path: '/memory', builder: (_, __) => const MemoryScreen()),
      ],
    ),
  ],
);

class _Shell extends StatelessWidget {
  const _Shell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere((t) => location.startsWith(t.$1));
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
        destinations: [
          for (final (_, icon, label) in _tabs)
            NavigationDestination(icon: Icon(icon), label: label),
        ],
      ),
    );
  }
}
