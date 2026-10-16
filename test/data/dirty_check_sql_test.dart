import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';

/// The table names the sync engine's "edited during a sync?" check uses must
/// exist, or the check silently fails and edits wait for the periodic sync.
void main() {
  test('every synced table has is_dirty and updated_at', () async {
    final db = AtlasDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    const tables = [
      'tasks', 'habits', 'goals', 'avatars', 'world_tiles',
      'achievements', 'progress_entries', 'notifications',
    ];
    for (final t in tables) {
      await db.customSelect('SELECT 1 FROM $t WHERE is_dirty = 1 AND updated_at >= ? LIMIT 1',
          variables: [Variable.withDateTime(DateTime.now())]).get();
    }
  });
}
