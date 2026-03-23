import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/services/token_service.dart';
import 'package:atlas_flutter_app/data/services/api_service.dart';
import 'package:atlas_flutter_app/data/services/auth_service.dart';

final databaseProvider = Provider<AtlasDatabase>((ref) {
  return AtlasDatabase();
});

final tokenServiceProvider = Provider<TokenService>((ref) {
  return TokenService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.read(tokenServiceProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.read(apiServiceProvider),
    ref.read(tokenServiceProvider),
  );
});
