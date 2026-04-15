import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/router/router.dart';

class App extends StatelessWidget {
  const App({required this.router, super.key});

  final AppRouter router;

  @override
  Widget build(final BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp.router(
          title: 'Tricount',
          debugShowCheckedModeBanner: false,
          theme: themeState.lightTheme,
          darkTheme: themeState.darkTheme,
          themeMode: themeState.themeMode,
          routerConfig: router.config(),
        );
      },
    );
  }
}
