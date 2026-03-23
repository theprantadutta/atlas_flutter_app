import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/router/app_router.dart';
import 'package:atlas_flutter_app/shared/providers/theme_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_theme.dart';

class AtlasApp extends ConsumerWidget {
  const AtlasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Atlas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
