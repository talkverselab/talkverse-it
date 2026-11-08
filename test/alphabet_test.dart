import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:italian_universe/screens/alphabet_screen.dart';
import 'package:italian_universe/services/it_phonetics.dart';
import 'package:italian_universe/widgets/it_sound_sheet.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('묶음마다 소리가 있고 칸 이름이 겹치지 않는다', () {
    final labels = <String>{};
    for (final g in kItSoundGroups) {
      expect(g.sounds, isNotEmpty, reason: g.name);
      for (final s in g.sounds) {
        expect(labels.add(s.label), isTrue, reason: '겹침 ${s.label}');
        expect(s.ipa, isNotEmpty);
        expect(s.say, isNotEmpty);
      }
    }
    expect(itSoundOf('gn')?.ipa, 'ɲ');
  });

  for (final size in const [Size(360, 740), Size(1024, 1366)]) {
    testWidgets('알파벳 화면 — 묶음 전환·넘침 없음 ${size.width}', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(const MaterialApp(home: AlphabetScreen()));
      await t.pumpAndSettle();
      expect(find.text('a'), findsOneWidget);
      for (final g in kItSoundGroups) {
        await t.ensureVisible(find.text(g.name));
        await t.pumpAndSettle();
        await t.tap(find.text(g.name));
        await t.pumpAndSettle();
        expect(find.text(g.sounds.first.label), findsWidgets);
      }
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('발음 시트 — IPA·한국어 비교·그림 펼치기', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final s = itSoundOf('gn')!;
    await t.pumpWidget(MaterialApp(home: Scaffold(body: ItSoundSheet(sound: s, color: Colors.green))));
    await t.pump();
    expect(find.text('IPA [ɲ]'), findsOneWidget);
    expect(find.textContaining('비슷한 소리'), findsOneWidget);
    await t.tap(find.text('자음 조음 위치 그림 보기'));
    await t.pump();
    expect(find.byType(Image), findsOneWidget);
    await t.pump(const Duration(seconds: 2)); // 자동 재생 타이머
    expect(t.takeException(), isNull);
  });
}
