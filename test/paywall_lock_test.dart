import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:italian_universe/data/entitlement.dart';
import 'package:italian_universe/services/curriculum_service.dart';
import 'package:italian_universe/services/dialogue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 이용권 잠금 경계(PAYWALL_SPEC §2·§5): 1단계 열림 · 2단계 잠김 · 이용권 있으면 열림.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('paywall');
    SharedPreferences.setMockInitialValues({});
    Entitlement.premiumOverride = false;
    CurriculumService.instance
      ..resetForTest()
      ..cacheDirOverride = dir
      ..fetchOverride = (_) async => null;
    await CurriculumService.instance.ensureLoaded();
  });
  tearDown(() {
    Entitlement.premiumOverride = null;
    dir.deleteSync(recursive: true);
  });

  test('앱 안 커리큘럼 JSON rev 2 — 1단계만 무료, freeSteps 2 · freeSenseLevels 1', () {
    final c = CurriculumService.instance;
    expect(c.configRev, greaterThanOrEqualTo(2));
    expect(c.stages.where((s) => s.free).map((s) => s.id), ['1']);
    expect(c.freeSteps, 2);
    expect(c.freeSenseLevels, 1);
  });

  test('이용권 없음: 1단계·R0·R1 회화·문법 1~2·언어감각 1급만 열림', () {
    expect(Entitlement.stageOpen('1'), isTrue);
    expect(Entitlement.stageOpen('2'), isFalse);
    expect(Entitlement.stageOpen('5'), isFalse);
    final svc = DialogueService.instance;
    expect(svc.list(region: 'R0').every(Entitlement.dialogueOpen), isTrue);
    expect(svc.list(region: 'R1').every(Entitlement.dialogueOpen), isTrue);
    expect(svc.list(region: 'R2').any(Entitlement.dialogueOpen), isFalse);
    expect(svc.list(region: 'R5').any(Entitlement.dialogueOpen), isFalse);
    expect(Entitlement.grammarStepOpen(2), isTrue);
    expect(Entitlement.grammarStepOpen(3), isFalse);
    expect(Entitlement.senseLevelOpen(1), isTrue);
    expect(Entitlement.senseLevelOpen(2), isFalse);
  });

  test('이용권 있으면 전부 열림', () {
    Entitlement.premiumOverride = true;
    expect(Entitlement.stageOpen('2'), isTrue);
    expect(DialogueService.instance.list(region: 'R5').every(Entitlement.dialogueOpen), isTrue);
    expect(Entitlement.grammarStepOpen(10), isTrue);
    expect(Entitlement.senseLevelOpen(10), isTrue);
  });
}
