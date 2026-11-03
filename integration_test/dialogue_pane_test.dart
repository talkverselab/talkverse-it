// 아이패드 두 화면 + 만화책 읽기형 회화 확인용 스크린샷 흐름 — 2026-11-03(일본어앱 dialogue_pane_test 를 옮김).
// 2026-11-04: 시작 로딩 화면(그림 내려받기) · 「오늘의 컷」 아래 대사 띠 · 말풍선 없는 리더 · 이름 묻는 창 · 카드 앞면 한국어 · 뒷면 레마 칩 추가.
// 실행: python3 tools/pane_shots.py <아이패드 UDID> <출력폴더> integration_test/dialogue_pane_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:italian_universe/core/l10n.dart';
import 'package:italian_universe/data/db/app_database.dart';
import 'package:italian_universe/data/db/seed_loader.dart';
import 'package:italian_universe/main.dart';
import 'package:italian_universe/services/achievement_service.dart';
import 'package:italian_universe/services/content_sync.dart';
import 'package:italian_universe/services/ko_reading.dart';
import 'package:italian_universe/services/learner_prefs.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> wait(WidgetTester t, int ms) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester t, String name) async {
    await wait(t, 2000);
    // ignore: avoid_print
    print('SHOT:$name');
    await wait(t, 3000);
  }

  // 레일 라벨은 앱바 제목과 겹칠 수 있어 레일 안에서만 찾는다
  Finder rail(String label) => find.descendant(of: find.byType(NavigationRail), matching: find.text(label));

  testWidgets('dialogue pane', timeout: const Timeout(Duration(minutes: 10)), (t) async {
    // main() 과 같은 시작 순서
    appDb = AppDatabase();
    await SeedLoader(appDb).seedIfNeeded();
    await KoReadingPrefs.load();
    await AppLangPrefs.load();
    await LearnerPrefs.load();
    await LearnerPrefs.setName(''); // 이름 묻는 창을 보기 위해 비운다(확인용)
    await AchievementService.instance.load();
    final need = await ContentSync.instance.init(large: true);
    // ignore: avoid_print
    print('SYNC need=$need estimate=${ContentSync.instance.estimate}');
    await t.pumpWidget(const ItalianUniverseApp(syncFirst: true));
    await wait(t, 2500);
    await shot(t, '00_sync_screen');
    final later = find.textContaining('나중에 — 앱 먼저');
    if (later.evaluate().isNotEmpty) await t.tap(later);
    await wait(t, 1500);
    await shot(t, '01_home_wide');

    // 오른쪽 칸 첫 화면 = 회화 홈. 왼쪽 메뉴의 「회화」 타일로 다시 열어 본다.
    await t.tap(find.text('Conversazione').first);
    await wait(t, 2000);
    await shot(t, '02_dialogue_home_today_cut_strip'); // 「오늘의 컷」 = 그림 + 아래 대사 띠(말풍선 없음)

    await t.tap(find.text('사랑').first);
    await wait(t, 1200);
    await shot(t, '03_topic_list');

    await t.tap(find.text('카페에서').first);
    await wait(t, 1500);
    await shot(t, '04_name_dialog'); // 이름이 비어 있으면 이름·성별 창(앱 켠 뒤 한 번)
    final skip = find.text('나중에');
    if (skip.evaluate().isNotEmpty) await t.tap(skip.first);
    await wait(t, 1000);
    await shot(t, '04b_reader_no_bubble'); // 컷에 말풍선 없음, 문장은 아래 캡션 + 레마 칩

    await t.tap(find.byIcon(Icons.play_arrow_rounded).first); // ▶ 는 둥근 버튼(글자 「재생」은 라벨)
    await wait(t, 6000);
    await shot(t, '05_reader_playing');
    final pause = find.byIcon(Icons.pause_rounded);
    if (pause.evaluate().isNotEmpty) await t.tap(pause.first);
    await wait(t, 500);
    // 편 끝 연출이 떠 있으면 닫는다
    final close = find.text('닫기');
    if (close.evaluate().isNotEmpty) await t.tap(close.first);
    await wait(t, 500);

    await t.tap(find.byTooltip('그림 카드(글자 없이)'));
    await wait(t, 1500);
    await shot(t, '06_card_front_ko'); // 앞면 = 그림 + 한국어 뜻 + 「이 말을 이탈리아어로 해 보세요」
    await t.tap(find.textContaining('이탈리아어로 해 보세요'));
    await wait(t, 1200);
    await shot(t, '07_card_back_lemmas'); // 뒷면 = 이탈리아어·독음·뜻·레마 칩(단어장 비어 있어 회색)
    await t.pageBack();
    await wait(t, 1200);
    await t.pageBack(); // 리더 닫기
    await wait(t, 1200);

    await t.tap(rail('나'));
    await wait(t, 1500);
    await shot(t, '08_me_achievements');

    await t.tap(find.text('학습자 프로필 · 계정'));
    await wait(t, 1500);
    await shot(t, '09_profile');
    // ignore: avoid_print
    print('SYNC progress=${ContentSync.instance.progress.value.done}/${ContentSync.instance.progress.value.total}');
    ContentSync.instance.cancel();
    await wait(t, 500);
  });
}
