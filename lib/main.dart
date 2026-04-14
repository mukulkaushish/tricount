import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tricount/app.dart';
import 'package:tricount/core/core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    BlocProvider(
      create: (_) => ThemeBloc(
        prefs: prefs,
        platform: defaultTargetPlatform,
      )..add(const ThemeRestored()),
      child: const App(),
    ),
  );
}
