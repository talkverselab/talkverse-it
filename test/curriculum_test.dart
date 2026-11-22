import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:italian_universe/screens/curriculum_screen.dart';
import 'package:italian_universe/services/curriculum_service.dart';
import 'package:italian_universe/services/dialogue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('점수 80% 경계 — 소수점 버림', () {
    expect(scorePercent(8, 10), 80);
    expect(passed(8, 10), isTrue);
    expect(scorePercent(79, 100), 79);
    expect(passed(79, 100), isFalse);
    expect(scorePercent(23, 29), 79); // 79.3 → 79
    expect(passed(23, 29), isFalse);
    expect(scorePercent(24, 30), 80);
    expect(passed(24, 30), isTrue);
    expect(scorePercent(0, 0), 0);
  });

  test('간격 반복 1 → 3 → 7일, 틀리면 1일로, 7일 단계를 맞히면 졸업', () {
    final s = CurriculumState();
    s.enqueue('d#1', '2026-11-22');
    expect(s.review.single.due, '2026-11-23');
    expect(s.review.single.step, 0);
    s.answerReview('d#1', true, '2026-11-23');
    expect(s.review.single.due, '2026-11-26');
    expect(s.review.single.step, 1);
    s.answerReview('d#1', false, '2026-11-26');
    expect(s.review.single.due, '2026-11-27');
    expect(s.review.single.step, 0);
    s.answerReview('d#1', true, '2026-11-27'); // → 3일
    s.answerReview('d#1', true, '2026-11-30'); // → 7일
    expect(s.review.single.due, '2026-12-07'); // 달이 넘어감
    expect(s.review.single.step, 2);
    s.answerReview('d#1', true, '2026-12-07');
    expect(s.review, isEmpty);
    // 이미 있는 줄을 다시 넣으면 그대로, 틀린 줄이면 1일로
    s.enqueue('d#2', '2026-11-22');
    s.answerReview('d#2', true, '2026-11-23');
    s.enqueue('d#2', '2026-11-24');
    expect(s.review.single.step, 1);
    s.enqueue('d#2', '2026-11-24', wrong: true);
    expect(s.review.single.due, '2026-11-25');
    expect(s.dueOn('2026-11-24'), isEmpty);
    expect(s.dueOn('2026-11-25').length, 1);
  });

  test('오늘 분량·연속 일수', () {
    final s = CurriculumState(dailyGoal: 1);
    s.rollDay('2026-11-22');
    s.todayNew = 1;
    s.touchStreak('2026-11-22');
    expect(s.streakCount, 1);
    s.touchStreak('2026-11-22');
    expect(s.streakCount, 1);
    s.rollDay('2026-11-23');
    expect(s.todayNew, 0);
    s.todayNew = 1;
    s.touchStreak('2026-11-23');
    expect(s.streakCount, 2);
    expect(s.streakShown('2026-11-24'), 2);
    expect(s.streakShown('2026-11-25'), 0);
    // 복습이 남아 있으면 끝이 아님
    s.enqueue('d#1', '2026-11-22');
    expect(s.doneToday('2026-11-23'), isFalse);
  });

  test('저장 형식 curriculum_v1 왕복', () {
    final s = CurriculumState(level: 'R1', dailyGoal: 3, course: const Course(id: 'c', dialogueIds: ['a', 'b'], practiced: ['a'], examScores: [70]));
    s.enqueue('a#1', '2026-11-22');
    final j = json.decode(json.encode(s.toJson())) as Map<String, dynamic>;
    expect(j.keys, containsAll(['level', 'dailyGoal', 'course', 'passedDialogues', 'review', 'streak']));
    final t = CurriculumState.fromJson(j);
    expect(t.level, 'R1');
    expect(t.course!.practiced, ['a']);
    expect(t.course!.allPracticed, isFalse);
    expect(t.review.single.lineId, 'a#1');
    expect(examPerDialogue(3), 10);
    expect(examPerDialogue(5), 6);
    expect(examPerDialogue(10), 3);
  });

  test('실제 회화로 문제·코스·시험 흐름', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = CurriculumService.instance..resetForTest();
    await DialogueService.instance.ensureLoaded();
    await svc.ensureLoaded();
    await svc.setLevel('R0');
    final ids = svc.recommend('R0', 3);
    expect(ids.length, 3);
    expect({for (final id in ids) DialogueService.instance.byId(id)!.island}.length, greaterThan(1));
    await svc.startCourse(ids);
    final d = DialogueService.instance.byId(ids.first)!;
    final qs = QuestionMaker(svc.levelPool('R0'), 1).forLines(svc.linesOf(d), 10);
    expect(qs, isNotEmpty);
    expect(qs.length, lessThanOrEqualTo(10));
    for (final q in qs) {
      expect(q.options.length, 4);
      expect(q.options, contains(q.answer));
      expect(q.options.toSet().length, 4);
    }
    final now = DateTime(2026, 11, 22, 9);
    for (final id in ids) {
      await svc.finishPractice(id, {}, now);
    }
    expect(svc.state.course!.allPracticed, isTrue);
    expect(svc.state.todayNew, 3);
    expect(svc.state.dueOn('2026-11-23'), isNotEmpty);
    // 79% → 틀린 편만 다시 연습
    await svc.finishExam(23, 29, {ids.first}, now);
    expect(svc.state.course!.practiced, isNot(contains(ids.first)));
    expect(svc.state.passedDialogues, isEmpty);
    // 80% → 통과
    await svc.finishPractice(ids.first, {}, now);
    await svc.finishExam(8, 10, {}, now);
    expect(svc.state.course!.passedAt, '2026-11-22');
    expect(svc.state.passedDialogues, containsAll(ids));
    final saved = (await SharedPreferences.getInstance()).getString('it_curriculum_v1');
    expect(saved, isNotNull);
  });

  testWidgets('커리큘럼 화면: 폰 폭에서 레벨 고르기 → 코스 만들기가 넘치지 않는다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    CurriculumService.instance.resetForTest();
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await DialogueService.instance.ensureLoaded();
      await CurriculumService.instance.ensureLoaded();
    });
    await tester.pumpWidget(const MaterialApp(home: CurriculumScreen()));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('회화 레벨을 고르세요'), findsOneWidget);
    await tester.tap(find.text('레벨 0 · 첫걸음'));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(find.textContaining('새 코스'), findsWidgets);
    await tester.tap(find.text('추천으로 채우기'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('코스 시작 (5/5)'), 300);
    expect(find.text('코스 시작 (5/5)'), findsOneWidget);
    await tester.tap(find.text('코스 시작 (5/5)'));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(find.text('지금 코스'), findsOneWidget);
    expect(find.text('연습하기'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
