import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:italian_universe/core/cliff.dart';
import 'package:italian_universe/screens/about_screen.dart';
import 'package:italian_universe/services/dialogue_service.dart';
import 'package:italian_universe/services/ko_reading.dart';
import 'package:italian_universe/widgets/lemma_chips.dart';
import 'package:shared_preferences/shared_preferences.dart';

DialogueTurn _turn(List<Lemma> lemmas) => DialogueTurn(num: 1, speaker: 'A', tl: 'Vorrei un caffè, grazie.', gloss: '', rd: '', ko: '', note: '', tags: const [], lemmas: lemmas);

void main() {
  test('구간 경계는 절벽값과 2,000위 끊기를 따른다', () {
    expect(regionOfRank(1), 'R1');
    expect(regionOfRank(61), 'R1');
    expect(regionOfRank(62), 'R2');
    expect(regionOfRank(91), 'R2');
    expect(regionOfRank(211), 'R3');
    expect(regionOfRank(661), 'R4');
    expect(regionOfRank(662), 'R5');
    expect(regionOfRank(2000), 'R5');
    expect(regionOfRank(2001), isNull);
    expect(regionOfRank(0), isNull);
  });

  test('한글 독음은 기본 미표시이고 옛 설정을 따르지 않는다', () async {
    SharedPreferences.setMockInitialValues({'show_ko_reading': true});
    await KoReadingPrefs.load();
    expect(KoReadingPrefs.show.value, isFalse);
  });

  for (final size in const [Size(320, 640), Size(1024, 768)]) {
    testWidgets('앱 소개는 ${size.width} 폭에서 넘치지 않는다', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(const MaterialApp(home: AboutScreen()));
      await t.pump();
      expect(t.takeException(), isNull);
      expect(find.text('1. 단어 기준'), findsOneWidget);
      await t.drag(find.byType(ListView), const Offset(0, -900));
      await t.pump();
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('문장 레마를 누르면 기본형 단어창이 뜬다', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(body: LemmaText(turn: _turn(const [Lemma('Vorrei', 'volere', ''), Lemma('caffè', 'caffè', '')]), text: 'Vorrei un caffè, grazie.', style: const TextStyle(fontSize: 16))),
    ));
    await t.pump();
    await t.tap(find.text('Vorrei'));
    await t.pumpAndSettle();
    expect(find.text('volere'), findsOneWidget);
  });

  testWidgets('레마 주석이 없으면 글자 그대로', (t) async {
    await t.pumpWidget(MaterialApp(home: Scaffold(body: LemmaText(turn: _turn(const []), text: 'Ciao!', style: const TextStyle()))));
    expect(find.text('Ciao!'), findsOneWidget);
  });
}
