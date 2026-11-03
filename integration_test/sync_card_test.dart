// 시작 로딩(그림 내려받기)·이름 묻기·그림 카드 앞면 한국어·레마 칩 확인용 스크린샷 — 2026-11-04(일본어앱 sync_card_test 를 옮김).
// 실행: python3 tools/pane_shots.py <아이패드 UDID> <출력폴더> integration_test/sync_card_test.dart
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

  testWidgets('sync + card', timeout: const Timeout(Duration(minutes: 10)), (t) async {
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
    await shot(t, '30_sync_screen');
    final later = find.textContaining('나중에 — 앱 먼저');
    if (later.evaluate().isNotEmpty) await t.tap(later);
    await wait(t, 1500);

    await t.tap(find.text('사랑').first);
    await wait(t, 1200);
    await t.tap(find.text('카페에서').first);
    await wait(t, 1500);
    await shot(t, '31_name_dialog');
    final skip = find.text('나중에');
    if (skip.evaluate().isNotEmpty) await t.tap(skip.first);
    await wait(t, 1000);
    await shot(t, '32_reader_no_bubble');

    await t.tap(find.byTooltip('그림 카드(글자 없이)'));
    await wait(t, 1500);
    await shot(t, '33_card_front_ko');
    await t.tap(find.textContaining('이탈리아어로 해 보세요'));
    await wait(t, 1200);
    await shot(t, '34_card_back_lemmas');
    await t.pageBack();
    await wait(t, 1200);
    // ignore: avoid_print
    print('SYNC progress=${ContentSync.instance.progress.value.done}/${ContentSync.instance.progress.value.total}');
    ContentSync.instance.cancel();
    await wait(t, 1000);
  });
}
