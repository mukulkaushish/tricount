import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/l10n/app_localizations.dart';
import 'package:tricount/router/router.dart';
import 'package:tricount/shared/shared.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<ThemeBloc>()..add(const ThemeRestored()),
        ),
        BlocProvider(
          create: (_) => sl<SessionBloc>()..add(const SessionStarted()),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            onGenerateTitle: (context) => context.l10n.appName,
            debugShowCheckedModeBanner: false,
            theme: themeState.lightTheme,
            darkTheme: themeState.darkTheme,
            themeMode: themeState.themeMode,
            routerConfig: sl<AppRouter>().config(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) {
              return KeyboardDismisser(
                gestures: const [
                  GestureType.onTap,
                  GestureType.onPanUpdateDownDirection,
                  GestureType.onPanUpdateUpDirection,
                ],
                child: child,
              );
            },
          );
        },
      ),
    );
  }
}
