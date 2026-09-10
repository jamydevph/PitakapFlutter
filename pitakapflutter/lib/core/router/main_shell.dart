import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Hosts the stateful branches.
///
/// Navigation itself lives in [AppDrawer], which every branch page attaches to
/// its own [Scaffold] — a drawer on this outer Scaffold would be shadowed by
/// those nested Scaffolds and would never render a menu button.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return navigationShell;
  }
}
