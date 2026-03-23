import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    // results is a List<ConnectivityResult>
    return results.any((r) => r != ConnectivityResult.none);
  });
});
