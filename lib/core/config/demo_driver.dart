import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/config/demo_config.dart';

/// A VM-service hook for driving the app from outside during a demo run.
///
/// Capturing store screenshots means putting twenty-odd screens on two device
/// sizes in a known state. Doing that on a timer guesses at how long each
/// screen takes to settle and produces a half-drawn chart often enough to be
/// worth avoiding; doing it by hand is an afternoon per rebuild.
///
/// So the driver exposes one extension, `ext.atlas.goto`, which navigates and
/// returns once the frame after the navigation has rendered. The capture script
/// calls it over the VM service and screenshots only after it answers.
///
/// It registers only when [DemoConfig.enabled] and only in debug builds, and
/// the VM service does not exist in a release build at all, so there are three
/// separate reasons this cannot reach the App Store. Note it keys off `enabled`
/// rather than `isUsable`: driving the screens is useful whether or not demo
/// credentials were supplied, since the account may sign in with Google.
void registerDemoDriver(GoRouter router) {
  if (!kDebugMode || !DemoConfig.enabled) return;

  developer.registerExtension('ext.atlas.goto', (method, parameters) async {
    final route = parameters['route'];
    if (route == null || route.isEmpty) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.invalidParams,
        '{"error":"route is required"}',
      );
    }

    // `go` rather than `push`, so each screen is reached the same way whatever
    // was on screen before it and nothing accumulates a back stack.
    router.go(route);

    // Wait for the frame that actually draws the new screen. Without this the
    // caller can screenshot the outgoing route.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    return developer.ServiceExtensionResponse.result('{"route":"$route"}');
  });
}
