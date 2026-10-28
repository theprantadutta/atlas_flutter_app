import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/aurora_memory_dao.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_memory_repository.dart';

void main() {
  late AtlasDatabase db;
  late AuroraMemoryRepository repo;
  var t = DateTime(2026, 10, 1);

  setUp(() {
    db = AtlasDatabase.forTesting(NativeDatabase.memory());
    t = DateTime(2026, 10, 1);
    repo = AuroraMemoryRepository(AuroraMemoryDao(db), clock: () {
      t = t.add(const Duration(minutes: 1));
      return t;
    });
  });

  tearDown(() => db.close());

  test('add stores newest first with its source', () async {
    await repo.add('u1', 'Training for a 10k in December');
    await repo.add('u1', 'Prefers mornings', source: AuroraMemorySource.aurora);
    final all = await repo.watch('u1').first;
    expect(all.map((m) => m.content),
        ['Prefers mornings', 'Training for a 10k in December']);
    expect(all.first.source, 'aurora');
    expect(all.last.source, 'you');
  });

  test('blank is ignored, duplicates are not repeated, long text is capped',
      () async {
    expect(await repo.add('u1', '   '), isNull);
    final a = await repo.add('u1', 'Loves tea');
    final b = await repo.add('u1', 'loves TEA');
    expect(b!.id, a!.id);
    final long = await repo.add('u1', 'x' * 260);
    expect(long!.content, hasLength(200));
    expect(await repo.list('u1'), hasLength(2));
  });

  test('delete removes one; restore puts it back', () async {
    final a = await repo.add('u1', 'A');
    await repo.add('u1', 'B');
    await repo.delete(a!.id);
    expect((await repo.list('u1')).map((m) => m.content), ['B']);
    await repo.restore(a);
    expect(await repo.list('u1'), hasLength(2));
  });

  test('clear removes only this user\'s memories', () async {
    await repo.add('u1', 'A');
    await repo.add('u1', 'B');
    await repo.add('u2', 'C');
    await repo.clear('u1');
    expect(await repo.list('u1'), isEmpty);
    expect(await repo.list('u2'), hasLength(1));
  });
}
