import 'package:flutter_test/flutter_test.dart';
import 'package:italian_universe/services/art_service.dart';
import 'package:italian_universe/services/dialogue_service.dart';
import 'package:italian_universe/services/italian_hints.dart';
import 'package:italian_universe/services/learner_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('옛 L1.json 을 회화 리더 모델로 읽는다(데이터는 그대로)', () async {
    await DialogueService.instance.ensureLoaded();
    await DialogueService.instance.ensureLoaded(); // 두 번 불러도 한 번만 채운다
    final all = DialogueService.instance.all;
    expect(all.length, 5);
    expect(all.every((d) => d.turns.length == 8), isTrue);
    final d = all.first;
    expect(d.id, 'L1_ep1');
    expect(d.region, 'L1');
    expect(d.turns.first.tl, isNotEmpty);
    expect(d.turns.first.rd, isNotEmpty);
    // A = 학습자: 이름은 프로필(없으면 「나」), 목소리는 프로필 성별. B = 데이터 성별.
    expect(d.speakerName('A'), '나');
    await LearnerPrefs.setGender('female');
    expect(d.voiceGender('A'), 'female');
    expect(d.voiceGender('B'), 'female');
    await LearnerPrefs.setGender('male');
    expect(d.voiceGender('A'), 'male');
    expect(d.speakerName('B'), 'Giulia');
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
}
