import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/bookings/presentation/bookings_screen.dart';
import 'features/destinations/presentation/destinations_screen.dart';

/// Root widget: opens directly into the main app shell (no login gate).
class TourismApp extends StatelessWidget {
  const TourismApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FarReach Tourism',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeShell(),
    );
  }
}

/// Bottom-navigation shell: Destinations + Bookings.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Keep the session provider alive (used for authenticated calls
    // such as bookings) without forcing a sign-in screen.
    context.watch<AuthProvider>();

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [DestinationsScreen(), BookingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.landscape_outlined),
            selectedIcon: Icon(Icons.landscape),
            label: 'Destinations',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_online_outlined),
            selectedIcon: Icon(Icons.book_online),
            label: 'Bookings',
          ),
        ],
      ),
    );
  }
}

