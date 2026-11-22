import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/prefs.dart';
import 'dialogue_service.dart';

/// 토크버스 커리큘럼(2026-11-22, 전 언어 공통 기준 `~/talkverse/CURRICULUM_SPEC.md`).
/// 회화 레벨에서 편을 골라 코스 → 편마다 연습(확인 문제) → 틀린 줄·연습한 줄은 간격 반복(1·3·7일) → 코스 시험 80% 이상 통과.
/// 저장 키 `curriculum_v1`(전 언어 같은 이름, 통합 앱에선 [Prefs] 가 언어 접두를 붙임). 형식은 문서 §7 + 오늘 진행 `today`.

const kCurriculumKey = 'curriculum_v1';
const kReviewSteps = [1, 3, 7]; // 간격(일)
const kPassPercent = 80;
const kCourseSizes = [3, 5, 10];
const kDailyGoals = [1, 2, 3]; // 가볍게·보통·집중 = 새 편 수

String dayOf(DateTime t) => '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
DateTime _day(String s) => DateTime.parse(s);
String addDays(String day, int n) => dayOf(DateTime(_day(day).year, _day(day).month, _day(day).day + n));

/// 점수 = 정답 수 / 문제 수, 소수점 버림.
int scorePercent(int correct, int total) => total <= 0 ? 0 : (correct * 100) ~/ total;
bool passed(int correct, int total) => scorePercent(correct, total) >= kPassPercent;

class ReviewItem {
  final String lineId; // <편id>#<턴번호>
  final String due; // yyyy-MM-dd
  final int step; // 0 = 1일 간격 단계
  const ReviewItem(this.lineId, this.due, this.step);
  Map<String, dynamic> toJson() => {'lineId': lineId, 'due': due, 'step': step};
  factory ReviewItem.fromJson(Map<String, dynamic> j) => ReviewItem('${j['lineId']}', '${j['due']}', (j['step'] as num?)?.toInt() ?? 0);
}

class Course {
  final String id;
  final List<String> dialogueIds;
  final List<String> practiced;
  final List<int> examScores;
  final String? passedAt;
  const Course({required this.id, required this.dialogueIds, this.practiced = const [], this.examScores = const [], this.passedAt});
  bool get allPracticed => dialogueIds.every(practiced.contains);
  Course copyWith({List<String>? practiced, List<int>? examScores, String? passedAt}) =>
      Course(id: id, dialogueIds: dialogueIds, practiced: practiced ?? this.practiced, examScores: examScores ?? this.examScores, passedAt: passedAt ?? this.passedAt);
  Map<String, dynamic> toJson() => {'id': id, 'dialogueIds': dialogueIds, 'practiced': practiced, 'examScores': examScores, 'passedAt': passedAt};
  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: '${j['id']}',
        dialogueIds: [for (final x in (j['dialogueIds'] as List? ?? const [])) '$x'],
        practiced: [for (final x in (j['practiced'] as List? ?? const [])) '$x'],
        examScores: [for (final x in (j['examScores'] as List? ?? const [])) (x as num).toInt()],
        passedAt: j['passedAt'] as String?,
      );
}

/// 기기에 저장되는 상태 전부.
class CurriculumState {
  String? level;
  int dailyGoal;
  Course? course;
  List<String> passedDialogues;
  List<ReviewItem> review;
  int streakCount;
  String? streakLastDay;
  // 오늘 진행(문서 §7 에 더한 칸): 날짜·오늘 끝낸 새 편 수·오늘 끝낸 복습 수
  String? todayDay;
  int todayNew;
  int todayReview;
  CurriculumState({
    this.level,
    this.dailyGoal = 2,
    this.course,
    List<String>? passedDialogues,
    List<ReviewItem>? review,
    this.streakCount = 0,
    this.streakLastDay,
    this.todayDay,
    this.todayNew = 0,
    this.todayReview = 0,
  })  : passedDialogues = passedDialogues ?? [],
        review = review ?? [];

  Map<String, dynamic> toJson() => {
        'level': level,
        'dailyGoal': dailyGoal,
        'course': course?.toJson(),
        'passedDialogues': passedDialogues,
        'review': [for (final r in review) r.toJson()],
        'streak': {'count': streakCount, 'lastDay': streakLastDay},
        'today': {'day': todayDay, 'new': todayNew, 'review': todayReview},
      };

  factory CurriculumState.fromJson(Map<String, dynamic> j) {
    final s = (j['streak'] as Map?) ?? const {};
    final t = (j['today'] as Map?) ?? const {};
    return CurriculumState(
      level: j['level'] as String?,
      dailyGoal: (j['dailyGoal'] as num?)?.toInt() ?? 2,
      course: j['course'] is Map ? Course.fromJson((j['course'] as Map).cast<String, dynamic>()) : null,
      passedDialogues: [for (final x in (j['passedDialogues'] as List? ?? const [])) '$x'],
      review: [for (final x in (j['review'] as List? ?? const [])) if (x is Map) ReviewItem.fromJson(x.cast<String, dynamic>())],
      streakCount: (s['count'] as num?)?.toInt() ?? 0,
      streakLastDay: s['lastDay'] as String?,
      todayDay: t['day'] as String?,
      todayNew: (t['new'] as num?)?.toInt() ?? 0,
      todayReview: (t['review'] as num?)?.toInt() ?? 0,
    );
  }

  // ── 간격 반복 ──

  /// 줄을 대기열에 넣는다(이미 있으면 그대로, wrong 이면 1일 단계로 되돌림).
  void enqueue(String lineId, String today, {bool wrong = false}) {
    final i = review.indexWhere((r) => r.lineId == lineId);
    final item = ReviewItem(lineId, addDays(today, kReviewSteps[0]), 0);
    if (i < 0) {
      review.add(item);
    } else if (wrong) {
      review[i] = item;
    }
  }

  /// 복습 답: 맞히면 다음 간격(7일 단계까지 맞히면 졸업 = 대기열에서 뺌), 틀리면 1일로.
  void answerReview(String lineId, bool correct, String today) {
    final i = review.indexWhere((r) => r.lineId == lineId);
    if (i < 0) return;
    final cur = review[i];
    if (!correct) {
      review[i] = ReviewItem(lineId, addDays(today, kReviewSteps[0]), 0);
    } else if (cur.step + 1 >= kReviewSteps.length) {
      review.removeAt(i);
    } else {
      final next = cur.step + 1;
      review[i] = ReviewItem(lineId, addDays(today, kReviewSteps[next]), next);
    }
  }

  List<ReviewItem> dueOn(String today) => review.where((r) => r.due.compareTo(today) <= 0).toList();

  // ── 오늘 분량 ──

  void rollDay(String today) {
    if (todayDay == today) return;
    todayDay = today;
    todayNew = 0;
    todayReview = 0;
  }

  bool doneToday(String today) => todayDay == today && todayNew >= dailyGoal && dueOn(today).isEmpty;

  /// 오늘 분량을 다 했으면 연속 일수를 한 번만 올린다.
  void touchStreak(String today) {
    if (!doneToday(today) || streakLastDay == today) return;
    streakCount = streakLastDay == addDays(today, -1) ? streakCount + 1 : 1;
    streakLastDay = today;
  }

  /// 표시용 연속 일수(어제·오늘 끊기지 않았을 때만).
  int streakShown(String today) => (streakLastDay == today || streakLastDay == addDays(today, -1)) ? streakCount : 0;
}

/// 확인 문제 한 개 — 뜻 고르기(4지선다) 또는 빈칸 낱말 고르기.
class CQuestion {
  final String lineId;
  final String kind; // meaning | blank
  final String prompt; // 문제 글(빈칸이면 ____ 포함)
  final String hint; // 빈칸 문제의 한국어 뜻
  final String answer;
  final List<String> options;
  final String speaker;
  final String tl; // 원문(듣기용)
  const CQuestion({required this.lineId, required this.kind, required this.prompt, required this.hint, required this.answer, required this.options, required this.speaker, required this.tl});
}

/// 회화 줄 한 개(문제 재료).
class CLine {
  final String id;
  final Dialogue d;
  final DialogueTurn t;
  const CLine(this.id, this.d, this.t);
}

String lineIdOf(Dialogue d, DialogueTurn t) => '${d.id}#${t.num}';

final _wordRe = RegExp(r"[A-Za-zÀ-ÿ]+(?:'[A-Za-zÀ-ÿ]+)?");

/// 문제 만들기 — seed 가 같으면 같은 문제. pool = 오답 재료(같은 레벨 줄들).
class QuestionMaker {
  final List<CLine> pool;
  final Random _r;
  QuestionMaker(this.pool, int seed) : _r = Random(seed);

  List<String> _blankWords(String tl) => _wordRe.allMatches(tl).map((m) => m.group(0)!).where((w) => w.length >= 3).toList();

  CQuestion? make(CLine l, {String? kind}) {
    final k = kind ?? (_r.nextBool() ? 'meaning' : 'blank');
    final words = _blankWords(l.t.tl);
    if (k == 'blank' && words.isNotEmpty) {
      final w = words[_r.nextInt(words.length)];
      final others = <String>{};
      for (final o in [...pool]..shuffle(_r)) {
        for (final x in _blankWords(o.t.tl)) {
          if (x.toLowerCase() != w.toLowerCase() && others.every((y) => y.toLowerCase() != x.toLowerCase())) others.add(x);
        }
        if (others.length >= 12) break;
      }
      if (others.length >= 3) {
        final opts = [w, ...(others.toList()..shuffle(_r)).take(3)]..shuffle(_r);
        final idx = l.t.tl.indexOf(w);
        final prompt = '${l.t.tl.substring(0, idx)}____${l.t.tl.substring(idx + w.length)}';
        return CQuestion(lineId: l.id, kind: 'blank', prompt: prompt, hint: l.t.ko, answer: w, options: opts, speaker: l.t.speaker, tl: l.t.tl);
      }
    }
    // 뜻 고르기: 같은 편 다른 줄을 먼저, 모자라면 같은 레벨에서
    final same = pool.where((o) => o.d.id == l.d.id && o.id != l.id).toList()..shuffle(_r);
    final rest = pool.where((o) => o.d.id != l.d.id).toList()..shuffle(_r);
    final wrong = <String>[];
    for (final o in [...same, ...rest]) {
      if (o.t.ko != l.t.ko && !wrong.contains(o.t.ko) && o.t.ko.isNotEmpty) wrong.add(o.t.ko);
      if (wrong.length == 3) break;
    }
    if (wrong.length < 3 || l.t.ko.isEmpty) return null;
    final opts = [l.t.ko, ...wrong]..shuffle(_r);
    return CQuestion(lineId: l.id, kind: 'meaning', prompt: l.t.tl, hint: '', answer: l.t.ko, options: opts, speaker: l.t.speaker, tl: l.t.tl);
  }

  /// 줄들에서 최대 max 문제(줄마다 하나).
  List<CQuestion> forLines(List<CLine> lines, int max) {
    final ls = [...lines]..shuffle(_r);
    final out = <CQuestion>[];
    for (final l in ls) {
      if (out.length >= max) break;
      final q = make(l);
      if (q != null) out.add(q);
    }
    return out;
  }
}

/// 코스 시험 편당 문제 수: 편당 최소 3, 전체 최대 30.
int examPerDialogue(int dialogues) => dialogues <= 0 ? 0 : max(3, 30 ~/ dialogues);

class CurriculumService extends ChangeNotifier {
  CurriculumService._();
  static final CurriculumService instance = CurriculumService._();

  CurriculumState state = CurriculumState();
  bool loaded = false;
  Future<void>? _loading;
  Future<void> ensureLoaded() => _loading ??= _load();

  /// 시험용: 저장을 다시 읽게.
  @visibleForTesting
  void resetForTest() {
    _loading = null;
    loaded = false;
    state = CurriculumState();
  }

  Future<void> _load() async {
    try {
      final s = (await Prefs.getInstance()).getString(kCurriculumKey);
      if (s != null) state = CurriculumState.fromJson(json.decode(s) as Map<String, dynamic>);
    } catch (_) {}
    loaded = true;
    notifyListeners();
  }

  Future<void> save() async {
    await (await Prefs.getInstance()).setString(kCurriculumKey, json.encode(state.toJson()));
    notifyListeners();
  }

  String today([DateTime? now]) => dayOf(now ?? DateTime.now());

  // ── 재료 ──

  List<Dialogue> dialoguesOf(String level) => DialogueService.instance.list(region: level);

  List<CLine> linesOf(Dialogue d) => [for (final t in d.turns) if (t.tl.isNotEmpty && t.ko.isNotEmpty) CLine(lineIdOf(d, t), d, t)];

  List<CLine> levelPool(String level) => [for (final d in dialoguesOf(level)) ...linesOf(d)];

  CLine? lineById(String id) {
    final i = id.lastIndexOf('#');
    if (i < 0) return null;
    final d = DialogueService.instance.byId(id.substring(0, i));
    final n = int.tryParse(id.substring(i + 1));
    if (d == null || n == null) return null;
    for (final t in d.turns) {
      if (t.num == n) return CLine(id, d, t);
    }
    return null;
  }

  /// 추천으로 채우기: 아직 통과 안 한 편에서 주제가 겹치지 않게(모자라면 겹쳐도), 순서대로.
  List<String> recommend(String level, int n, {List<String> keep = const []}) {
    final out = [...keep];
    final left = dialoguesOf(level).where((d) => !state.passedDialogues.contains(d.id) && !out.contains(d.id)).toList();
    final usedIsland = {for (final id in out) DialogueService.instance.byId(id)?.island};
    for (final d in left) {
      if (out.length >= n) break;
      if (!usedIsland.contains(d.island)) {
        out.add(d.id);
        usedIsland.add(d.island);
      }
    }
    for (final d in left) {
      if (out.length >= n) break;
      if (!out.contains(d.id)) out.add(d.id);
    }
    return out.take(n).toList();
  }

  // ── 동작 ──

  Future<void> setLevel(String level) async {
    state.level = level;
    await save();
  }

  Future<void> setDailyGoal(int g) async {
    state.dailyGoal = g;
    await save();
  }

  Future<void> startCourse(List<String> ids, [DateTime? now]) async {
    state.course = Course(id: '${state.level}_${(now ?? DateTime.now()).millisecondsSinceEpoch}', dialogueIds: ids);
    await save();
  }

  Future<void> dropCourse() async {
    state.course = null;
    await save();
  }

  /// 편 연습 끝: 연습한 줄은 모두 대기열(틀린 줄은 1일로 되돌림), 오늘 새 편 +1(같은 날 같은 편은 한 번).
  Future<void> finishPractice(String dialogueId, Map<String, bool> results, [DateTime? now]) async {
    final day = today(now);
    state.rollDay(day);
    final d = DialogueService.instance.byId(dialogueId);
    if (d != null) {
      for (final l in linesOf(d)) {
        state.enqueue(l.id, day, wrong: results[l.id] == false);
      }
    }
    final c = state.course;
    if (c != null && c.dialogueIds.contains(dialogueId) && !c.practiced.contains(dialogueId)) {
      state.course = c.copyWith(practiced: [...c.practiced, dialogueId]);
      state.todayNew++;
    }
    state.touchStreak(day);
    await save();
  }

  Future<void> answerReview(String lineId, bool correct, [DateTime? now]) async {
    final day = today(now);
    state.rollDay(day);
    state.answerReview(lineId, correct, day);
    state.todayReview++;
    state.touchStreak(day);
    await save();
  }

  /// 코스 시험 결과. 통과면 편들을 통과로, 레벨 편을 다 통과하면 다음 레벨로. 아니면 틀린 편만 다시 연습.
  /// 돌려주는 값: 다음 레벨로 넘어갔으면 그 레벨.
  Future<String?> finishExam(int correct, int total, Set<String> wrongDialogues, [DateTime? now]) async {
    final c = state.course;
    if (c == null) return null;
    final score = scorePercent(correct, total);
    String? next;
    if (score >= kPassPercent) {
      state.course = c.copyWith(examScores: [...c.examScores, score], passedAt: today(now));
      for (final id in c.dialogueIds) {
        if (!state.passedDialogues.contains(id)) state.passedDialogues.add(id);
      }
      final lv = state.level;
      if (lv != null && dialoguesOf(lv).every((d) => state.passedDialogues.contains(d.id))) {
        final rs = DialogueService.instance.regions;
        final i = rs.indexOf(lv);
        if (i >= 0 && i + 1 < rs.length) next = state.level = rs[i + 1];
      }
    } else {
      state.course = c.copyWith(examScores: [...c.examScores, score], practiced: c.practiced.where((id) => !wrongDialogues.contains(id)).toList());
    }
    await save();
    return next;
  }
}
