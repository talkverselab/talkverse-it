import 'package:flutter_test/flutter_test.dart';
import 'package:italian_universe/data/db/seed_loader.dart';
import 'package:italian_universe/services/art_service.dart';
import 'package:italian_universe/services/dialogue_service.dart';
import 'package:italian_universe/services/italian_hints.dart';
import 'package:italian_universe/services/learner_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('R0~R5 편 파일을 읽는다(서버 판이 없으면 앱 안 원고)', () async {
    await DialogueService.instance.ensureLoaded();
    await DialogueService.instance.ensureLoaded(); // 두 번 불러도 한 번만 읽는다
    final svc = DialogueService.instance;
    expect(svc.all.length, greaterThanOrEqualTo(35));
    expect(svc.regions, containsAllInOrder(['R0', 'R1', 'R2', 'R3', 'R4', 'R5']));
    final d = svc.byId('r1_friends_a1')!;
    expect(d.region, 'R1');
    expect(d.island, 'friends');
    expect(d.turns.first.tl, isNotEmpty);
    expect(d.turns.first.rd, isNotEmpty);
    // A = 학습자: 이름은 프로필(없으면 「나」), 목소리는 프로필 성별. B = 인물 성별.
    expect(d.speakerName('A'), '나');
    expect(d.speakerName('B'), 'Chiara');
    await LearnerPrefs.setGender('female');
    expect(d.voiceGender('A'), 'female');
    expect(d.voiceGender('B'), 'female');
    // 여성판이 있는 턴은 여성 학습자에게 그 본문
    final ft = svc.all.expand((e) => e.turns).firstWhere((t) => t.tlF.isNotEmpty);
    expect(ft.tl, ft.tlF);
    await LearnerPrefs.setGender('male');
    expect(d.voiceGender('A'), 'male');
    expect(ft.tl, ft.tlM);
  });

  test('그림 단어는 낱말 단위로 맞춘다(라틴 문자)', () {
    final w = ArtService.wordsOf("Di dove sei? Sì, l'amico è qui.");
    expect(w.contains('di'), isTrue);
    expect(w.contains('dove'), isTrue);
    expect(w.contains('sì'), isTrue);
    expect(w.contains('si'), isFalse);
    expect(w.contains('amico'), isTrue);
    expect(w.contains('è'), isTrue);
  });

  test('동사·성·수 데이터가 없으면 이탈리아어 칸은 숨김', () async {
    await ItalianHints.instance.ensureLoaded();
    expect(ItalianHints.instance.hasVerbs, isFalse);
    expect(ItalianHints.instance.hasGender, isFalse);
  });

  test('턴마다 문장 레마(내용어)가 있고 등장인물 이름은 빠진다', () async {
    await DialogueService.instance.ensureLoaded();
    final turns = DialogueService.instance.all.expand((d) => d.turns).toList();
    expect(turns.every((t) => t.lemmas.isNotEmpty), isTrue);
    final bases = turns.expand((t) => t.lemmas.map((l) => l.base)).toSet();
        expect(bases.contains('giulia'), isFalse);
    expect(bases.contains('essere'), isTrue); // Sono → essere
    expect(bases.every((b) => b == b.toLowerCase()), isTrue);
    expect(turns.first.lemmas.first.reading, ''); // 이탈리아어는 읽기 칸 없음
  });

  test('DB 업데이트 번호는 version.json 에서 읽는다', () async {
    expect(await SeedLoader.bundledVersion(), 1);
  });
}
