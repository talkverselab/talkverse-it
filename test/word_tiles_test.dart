import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:italian_universe/data/db/app_database.dart';
import 'package:italian_universe/main.dart';
import 'package:italian_universe/screens/word_freq_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    appDb = db;
    await db.batch((b) => b.insertAll(db.words, [
          for (var i = 1; i <= 45; i++)
            WordsCompanion.insert(rank: Value(i), word: i == 1 ? 'precipitevolissimevolmente' : 'parola$i', meaningKo: const Value('아주 긴 한국어 뜻풀이가 들어가는 칸입니다')),
        ]));
  });

  testWidgets('절벽 단어 타일은 폰·폴드·아이패드 폭에서 넘치지 않고 20어 단원으로 묶인다', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(320, 640);
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: WordFreqScreen()));
    for (var i = 0; i < 40 && find.text('1단원').evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('1단원'), findsOneWidget);
    expect(find.text('#1-20'), findsOneWidget);
    for (final size in const [Size(320, 640), Size(390, 844), Size(700, 900), Size(1024, 768), Size(1366, 1024)]) {
      t.view.physicalSize = size;
      await t.pump();
      expect(t.takeException(), isNull, reason: '$size');
      await t.drag(find.byType(ListView).last, const Offset(0, -300));
      await t.pump();
      expect(t.takeException(), isNull, reason: '$size 스크롤');
    }
  });
}
