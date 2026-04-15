import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/features/auth/auth.dart';
import 'package:tricount/router/router.dart';

/// Root tab shell for the authenticated section of the app.
///
/// Hosts two tabs — Home (Feed) and Profile — via [AutoTabsScaffold].
/// The [AuthBloc] is provided here so both tabs and the profile sign-out
/// listener have access to it.
@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(final BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: const _HomeShell(),
    );
  }
}

class _HomeShell extends StatelessWidget {
  const _HomeShell();

  @override
  Widget build(final BuildContext context) {
    return AutoTabsScaffold(
      routes: const [FeedRoute(), ProfileRoute()],
      bottomNavigationBuilder: (_, tabsRouter) {
        return NavigationBar(
          selectedIndex: tabsRouter.activeIndex,
          onDestinationSelected: tabsRouter.setActiveIndex,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outlined),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        );
      },
    );
  }
}
