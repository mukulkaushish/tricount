import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tricount/app.dart';
import 'package:tricount/core/core.dart';
import 'package:tricount/router/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();

  final prefs = await SharedPreferences.getInstance();
  final router = AppRouter(sl<TokenProvider>());

  runApp(
    BlocProvider(
      create: (_) => ThemeBloc(
        prefs: prefs,
        platform: defaultTargetPlatform,
      )..add(const ThemeRestored()),
      child: App(router: router),
    ),
  );
}
