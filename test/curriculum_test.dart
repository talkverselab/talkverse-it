import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:italian_universe/screens/curriculum_screen.dart';
import 'package:italian_universe/services/curriculum_service.dart';
import 'package:italian_universe/services/dialogue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

Dialogue _d(String id, String island, int n) => Dialogue.fromJson({
      'id': id,
      'region': 'R1',
      'island': island,
      'turns': [
        for (var i = 1; i <= n; i++) {'num': i, 'speaker': i.isOdd ? 'A' : 'B', 'it': 'Frase$id$i', 'ko': '뜻$id$i'}
      ],
    });

void main() {
  group('점수 80% 경계', () {
    test('소수점 버림', () {
      expect(scorePercent(7, 9), 77);
      expect(scorePercent(2, 3), 66);
      expect(scorePercent(0, 0), 0);
    });
    test('80% 이상만 통과', () {
      expect(isPass(8, 10), isTrue);
      expect(isPass(79, 100), isFalse);
      expect(isPass(4, 5), isTrue);
      expect(isPass(23, 29), isFalse); // 79.3 → 79
      expect(isPass(24, 30), isTrue);
    });
    test('시험 기록 — 통과면 편 통과, 아니면 틀린 편 연습 다시', () {
      final st = CurriculumState(course: Course('c', ['a', 'b'], practiced: ['a', 'b']));
      expect(st.recordExam(7, 10, {'b'}, '2026-11-22'), isFalse);
      expect(st.course!.practiced, ['a']);
      expect(st.passedDialogues, isEmpty);
      st.course!.practiced.add('b');
      expect(st.recordExam(8, 10, {}, '2026-11-23'), isTrue);
      expect(st.course!.passedAt, '2026-11-23');
      expect(st.passedDialogues, ['a', 'b']);
      expect(st.course!.examScores, [70, 80]);
    });
  });

  group('간격 반복 날짜', () {
    test('1일 → 3일 → 7일 → 졸업', () {
      final st = CurriculumState();
      st.enqueue('x#1', '2026-11-22');
      expect(st.review.single.due, '2026-11-23');
      st.grade('x#1', true, '2026-11-23');
      expect(st.review.single.due, '2026-11-26');
      st.grade('x#1', true, '2026-11-26');
      expect(st.review.single.due, '2026-12-03');
      st.grade('x#1', true, '2026-12-03');
      expect(st.review, isEmpty);
    });
    test('틀리면 1일 뒤 처음 간격으로', () {
      final st = CurriculumState();
      st.enqueue('x#1', '2026-11-22');
      st.grade('x#1', true, '2026-11-23');
      st.grade('x#1', false, '2026-11-26');
      expect(st.review.single.step, 0);
      expect(st.review.single.due, '2026-11-27');
    });
    test('달·해 넘김', () {
      expect(addDays('2026-12-30', 3), '2027-01-02');
      expect(addDays('2028-02-28', 1), '2028-02-29');
    });
  });

  group('하루 분량·연속', () {
    test('새 편 목표를 채우고 복습이 없으면 끝, 연속 일수', () {
      final st = CurriculumState(dailyGoal: 1, course: Course('c', ['a', 'b']));
      expect(st.dayDone('2026-11-22'), isFalse);
      st.markPracticed('a', [1, 2], '2026-11-22');
      expect(st.dayDone('2026-11-22'), isTrue);
      expect(st.streakShown('2026-11-22'), 1);
      // 다음 날: 복습 2줄 + 새 편 1
      expect(st.dueReview('2026-11-23').length, 2);
      st.grade('a#1', true, '2026-11-23');
      st.grade('a#2', true, '2026-11-23');
      st.markPracticed('b', [1], '2026-11-23');
      expect(st.todayReview, 2);
      expect(st.streakShown('2026-11-23'), 2);
      expect(st.streakShown('2026-11-25'), 0);
    });
    test('저장 형식 왕복', () {
      final st = CurriculumState(level: 'R1', course: Course('c', ['a']));
      st.markPracticed('a', [1], '2026-11-22');
      final back = CurriculumState.fromJson(st.toJson());
      expect(back.toJson(), st.toJson());
      expect(st.toJson().keys, containsAll(['level', 'dailyGoal', 'course', 'passedDialogues', 'review', 'streak']));
    });
  });

  group('문제·추천', () {
    test('편마다 줄 수만큼, 최대 10, 보기 4개 중 정답 1', () {
      final a = _d('a', 'friends', 12), b = _d('b', 'life', 4);
      final qs = buildQuestions(a, limit: 10, pool: [b]);
      expect(qs.length, 10);
      for (final q in qs) {
        expect(q.choices.length, 4);
        expect(q.choices.toSet().length, 4);
        expect(q.choices[q.answer], '뜻a${q.turn}');
      }
      expect(buildQuestions(b, limit: 10, pool: [a]).length, 4);
    });
    test('시험 문제 수: 편당 최소 3, 전체 최대 30', () {
      expect(examPerDialogue(3), 10);
      expect(examPerDialogue(5), 6);
      expect(examPerDialogue(10), 3);
    });
    test('추천 = 안 한 편, 주제 겹치지 않게', () {
      final list = [_d('f1', 'friends', 2), _d('f2', 'friends', 2), _d('l1', 'life', 2), _d('w1', 'work', 2)];
      final r = recommend(list, {'l1'}, {}, 3);
      expect(r, ['f1', 'w1', 'f2']);
    });
  });

  testWidgets('시험 화면 — 고르고 결과까지', (t) async {
    final a = _d('a', 'friends', 5);
    final qs = buildQuestions(a, limit: 2);
    await t.pumpWidget(MaterialApp(home: CurriculumQuizScreen(title: 'T', questions: qs, mode: QuizMode.exam)));
    for (var i = 0; i < 2; i++) {
      await t.tap(find.text(qs[i].choices[qs[i].answer]));
      await t.pump();
      await t.tap(find.byType(FilledButton).last);
      await t.pump();
    }
    expect(find.textContaining('100'), findsOneWidget);
  });

  testWidgets('커리큘럼 화면(이탈리아어 실제 회화) — 폰 폭에서 넘치지 않음', (t) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(360 * 3, 780 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      await DialogueService.instance.ensureLoaded();
      await CurriculumService.instance.ensureLoaded();
    });
    await t.pumpWidget(const MaterialApp(home: CurriculumScreen()));
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(t.takeException(), isNull);
    final q = buildQuestions(DialogueService.instance.list(region: 'R0').first, limit: 10, pool: DialogueService.instance.list(region: 'R0'));
    expect(q, isNotEmpty);
    expect(q.where((x) => x.kind == 'blank'), isNotEmpty); // 레마 표면형이 있는 줄은 빈칸 문제
  });

  for (final w in [360.0, 300.0]) {
    testWidgets('코스 고르기 — 폭 ${w.toInt()}px 에서 칩·추천 줄이 넘치지 않음', (t) async {
      SharedPreferences.setMockInitialValues({});
      t.view.physicalSize = Size(w * 3, 780 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.runAsync(() async {
        await DialogueService.instance.ensureLoaded();
        await CurriculumService.instance.ensureLoaded();
      });
      CurriculumService.instance.state = CurriculumState(level: 'R0');
      await t.pumpWidget(const MaterialApp(home: CurriculumScreen()));
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('추천으로 채우기'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  group('§12 단계는 서버 JSON(앱 안 기본값)', () {
    late Directory dir;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('cur12');
      SharedPreferences.setMockInitialValues({});
      CurriculumService.instance
        ..resetForTest()
        ..cacheDirOverride = dir
        ..fetchOverride = (_) async => null;
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('서버를 못 받으면 앱 안 JSON — 5단계, 1단계 = R0+R1', () async {
      final svc = CurriculumService.instance;
      await svc.ensureLoaded();
      expect(svc.stages.map((s) => s.id), ['1', '2', '3', '4', '5']);
      expect(svc.levelList('1').map((d) => d.region).toSet(), {'R0', 'R1'});
      expect(svc.levelList('5').every((d) => d.region == 'R5'), isTrue);
      expect(svc.nextLevel('1'), '2');
      expect(svc.nextLevel('5'), isNull);
    });

    test('옛 진도 level=R2 는 2단계로 읽음', () async {
      SharedPreferences.setMockInitialValues({'it_curriculum_v1': json.encode({'level': 'R2'})});
      final svc = CurriculumService.instance;
      await svc.ensureLoaded();
      expect(svc.state.level, '2');
    });

    test('서버 rev 가 높으면 바꿔 씀 — 앱에 없는 편 건너뜀, 편 0개 단계 숨김', () async {
      final svc = CurriculumService.instance;
      await svc.ensureLoaded();
      final first = DialogueService.instance.list(region: 'R0').first.id;
      svc.fetchOverride = (_) async => json.encode({
            'rev': 99,
            'stages': [
              {'n': 1, 'title': '첫 단계', 'dialogueIds': [first, 'no_such_ep']},
              {'n': 2, 'title': '빈 단계', 'dialogueIds': ['no_such_ep']},
            ],
            'prep': [],
          });
      expect(await svc.refreshConfig(), isTrue);
      expect(svc.stages.map((s) => s.id), ['1']);
      expect(svc.levelList('1').map((d) => d.id), [first]);
      expect(svc.stageTitle('1'), '첫 단계');
      // 같은·낮은 rev 는 무시
      svc.fetchOverride = (_) async => json.encode({'rev': 1, 'stages': []});
      expect(await svc.refreshConfig(), isFalse);
      expect(File('${dir.path}/curriculum_it.json').existsSync(), isTrue);
    });
  });
}
