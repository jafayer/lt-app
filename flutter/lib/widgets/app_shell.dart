import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/theme.dart';

/// Responsive app shell:
/// - Mobile (< 600px): standard scaffold with a hamburger/back navigation
/// - Desktop/Tablet (≥ 900px): persistent side rail with navigation links
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= AppTheme.tabletBreakpoint) {
      return _DesktopShell(child: child);
    }
    return _MobileShell(child: child);
  }
}

// ---------------------------------------------------------------------------
// Mobile shell
// ---------------------------------------------------------------------------

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

// ---------------------------------------------------------------------------
// Desktop shell – persistent navigation rail on the left
// ---------------------------------------------------------------------------

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final isHome = location == '/';
    final isSettings = location == '/settings';

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.of(context).size.width >= AppTheme.desktopBreakpoint,
            backgroundColor: AppTheme.surfaceColor,
            selectedIndex: isHome
                ? 0
                : isSettings
                    ? 1
                    : 0,
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/');
                case 1:
                  context.go('/settings');
              }
            },
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Courses'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Icon(Icons.headphones, size: 32, color: AppTheme.primaryColor),
                  const SizedBox(height: 4),
                  if (MediaQuery.of(context).size.width >= AppTheme.desktopBreakpoint)
                    const Text(
                      'Language\nTransfer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
