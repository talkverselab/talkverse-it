import 'dart:math';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/curriculum_service.dart';
import '../services/dialogue_service.dart';
import '../services/tts_service.dart';
import '../widgets/spanish_decor.dart';

/// 토크버스 커리큘럼(2026-11-22, `~/talkverse/CURRICULUM_SPEC.md`) — 레벨 고르기 → 코스(편 고르기) → 편 연습 → 코스 시험.
class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});
  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  final svc = CurriculumService.instance;
  bool _ready = false;
  bool _pickLevel = false;
  bool _confirmNew = false;
  bool _building = false;
  int _size = 5;
  List<String> _picked = [];

  @override
  void initState() {
    super.initState();
    svc.addListener(_changed);
    Future.wait([DialogueService.instance.ensureLoaded(), svc.ensureLoaded()]).then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    svc.removeListener(_changed);
    super.dispose();
  }

  void _changed() => mounted ? setState(() {}) : null;

  CurriculumState get st => svc.state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: Text(tr('토크버스 커리큘럼'))),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
              children: st.level == null || _pickLevel ? _levelPicker() : _main(),
            ),
    );
  }

  // ── 레벨 고르기 ──

  List<Widget> _levelPicker() {
    final regions = DialogueService.instance.regions;
    return [
      Text(tr('회화 레벨을 고르세요'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.tinta)),
      const SizedBox(height: 4),
      Text(tr('처음이면 가장 낮은 레벨부터 권해요.'), style: const TextStyle(fontSize: 13, color: AppColors.tintaLight)),
      const SizedBox(height: 12),
      for (final r in regions)
        _Card(
          onTap: () async {
            await svc.setLevel(r);
            setState(() {
              _pickLevel = false;
              _building = false;
              _picked = [];
            });
          },
          child: Row(children: [
            TileBadge(text: r, size: 40, color: AppColors.beni),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr(DialogueService.levelKo[r] ?? r), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tinta)),
                Text(trf('{0}편 · 통과 {1}', [DialogueService.instance.count(r), _passedIn(r)]), style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
              ]),
            ),
            if (r == regions.first && st.level == null) _Chip(tr('추천'), AppColors.italia),
            if (r == st.level) _Chip(tr('지금'), AppColors.beni),
          ]),
        ),
    ];
  }

  int _passedIn(String r) => svc.dialoguesOf(r).where((d) => st.passedDialogues.contains(d.id)).length;

  // ── 코스 화면 ──

  List<Widget> _main() {
    final lv = st.level!;
    final c = st.course;
    return [
      Row(children: [
        Expanded(
          child: Text(tr(DialogueService.levelKo[lv] ?? lv), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.tinta)),
        ),
        TextButton(onPressed: () => setState(() => _pickLevel = true), child: Text(tr('레벨 바꾸기'))),
      ]),
      Text(trf('{0}편 중 {1}편 통과', [svc.dialoguesOf(lv).length, _passedIn(lv)]), style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
      const SizedBox(height: 12),
      const CurriculumTodayCard(inScreen: true),
      const SizedBox(height: 8),
      _goalPicker(),
      const SizedBox(height: 16),
      if (c == null || _building) ..._builder(lv) else ..._course(c),
    ];
  }

  Widget _goalPicker() {
    final labels = {1: tr('가볍게'), 2: tr('보통'), 3: tr('집중')};
    return Row(children: [
      Text(tr('하루 목표'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sumi)),
      const SizedBox(width: 8),
      Expanded(
        child: Wrap(spacing: 6, children: [
          for (final g in kDailyGoals)
            ChoiceChip(
              label: Text('${labels[g]} · ${trf('새 편 {0}', [g])}', style: const TextStyle(fontSize: 12)),
              selected: st.dailyGoal == g,
              onSelected: (_) => svc.setDailyGoal(g),
            ),
        ]),
      ),
    ]);
  }

  List<Widget> _builder(String lv) {
    final ds = svc.dialoguesOf(lv);
    return [
      Text(tr('새 코스 — 연습할 회화를 고르세요'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.tinta)),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        for (final n in kCourseSizes)
          ChoiceChip(
            label: Text(trf('{0}편', [n])),
            selected: _size == n,
            onSelected: (_) => setState(() {
              _size = n;
              if (_picked.length > n) _picked = _picked.take(n).toList();
            }),
          ),
        TextButton.icon(
          onPressed: () => setState(() => _picked = svc.recommend(lv, min(_size, ds.length))),
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: Text(tr('추천으로 채우기')),
        ),
      ]),
      const SizedBox(height: 4),
      for (final d in ds)
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: _picked.contains(d.id),
          onChanged: (v) => setState(() {
            if (v == true && _picked.length < _size) _picked.add(d.id);
            if (v != true) _picked.remove(d.id);
          }),
          title: Text('${d.emoji} ${d.title}', style: const TextStyle(fontSize: 14, color: AppColors.tinta)),
          subtitle: Text(
            '${tr(DialogueService.islandKo[d.island] ?? d.island)}${st.passedDialogues.contains(d.id) ? ' · ${tr('통과함')}' : ''}',
            style: const TextStyle(fontSize: 11, color: AppColors.tintaLight),
          ),
        ),
      const SizedBox(height: 8),
      Row(children: [
        if (st.course != null)
          TextButton(onPressed: () => setState(() => _building = false), child: Text(tr('취소'))),
        const Spacer(),
        FilledButton(
          onPressed: _picked.length == min(_size, ds.length) && _picked.isNotEmpty
              ? () async {
                  await svc.startCourse([..._picked]);
                  setState(() {
                    _building = false;
                    _picked = [];
                  });
                }
              : null,
          child: Text(trf('코스 시작 ({0}/{1})', [_picked.length, min(_size, ds.length)])),
        ),
      ]),
    ];
  }

  List<Widget> _course(Course c) {
    final ds = [for (final id in c.dialogueIds) DialogueService.instance.byId(id)].whereType<Dialogue>().toList();
    final done = c.passedAt != null;
    return [
      Row(children: [
        Expanded(child: Text(tr('지금 코스'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.tinta))),
        Text(trf('연습 {0}/{1}', [c.practiced.length, c.dialogueIds.length]), style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
      ]),
      const SizedBox(height: 8),
      for (final d in ds)
        _Card(
          onTap: () => openFull(context, (_) => CurriculumPracticeScreen(dialogue: d)),
          child: Row(children: [
            Text(d.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tinta)),
                Text(trf('{0}줄', [d.turns.length]), style: const TextStyle(fontSize: 11, color: AppColors.tintaLight)),
              ]),
            ),
            if (c.practiced.contains(d.id))
              _Chip(tr('연습함'), AppColors.italia)
            else
              _Chip(tr('연습하기'), AppColors.beni),
          ]),
        ),
      const SizedBox(height: 8),
      if (c.examScores.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(trf('지난 시험 {0}점 (통과 {1}점)', [c.examScores.last, kPassPercent]), style: const TextStyle(fontSize: 13, color: AppColors.sumi)),
        ),
      if (done) ...[
        _Card(
          child: Text(tr('코스 통과! 다음 코스를 만들어 보세요.'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.italia)),
        ),
        FilledButton(onPressed: () => setState(() => _building = true), child: Text(tr('다음 코스 만들기'))),
      ] else ...[
        FilledButton(
          onPressed: c.allPracticed ? () => openFull(context, (_) => const CurriculumExamScreen()) : null,
          child: Text(c.allPracticed ? tr('코스 시험 보기') : tr('모든 회화를 연습하면 시험을 볼 수 있어요')),
        ),
        const SizedBox(height: 8),
        if (!_confirmNew)
          TextButton(onPressed: () => setState(() => _confirmNew = true), child: Text(tr('새 코스 시작')))
        else
          _Card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(tr('지금 코스를 버리고 새로 시작할까요? 복습 대기열은 그대로 남아요.'), style: const TextStyle(color: AppColors.tinta)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => setState(() => _confirmNew = false), child: Text(tr('취소'))),
                FilledButton(
                  onPressed: () => setState(() {
                    _confirmNew = false;
                    _building = true;
                  }),
                  child: Text(tr('새 코스 만들기')),
                ),
              ]),
            ]),
          ),
      ],
    ];
  }
}

/// 홈·코스 화면의 「오늘 분량」 카드.
class CurriculumTodayCard extends StatefulWidget {
  final bool inScreen;
  const CurriculumTodayCard({super.key, this.inScreen = false});
  @override
  State<CurriculumTodayCard> createState() => _CurriculumTodayCardState();
}

class _CurriculumTodayCardState extends State<CurriculumTodayCard> {
  final svc = CurriculumService.instance;

  @override
  void initState() {
    super.initState();
    svc.addListener(_changed);
    svc.ensureLoaded();
  }

  @override
  void dispose() {
    svc.removeListener(_changed);
    super.dispose();
  }

  void _changed() => mounted ? setState(() {}) : null;

  @override
  Widget build(BuildContext context) {
    final st = svc.state;
    final day = svc.today();
    final due = st.dueOn(day).length;
    final newDone = st.todayDay == day ? st.todayNew : 0;
    final revDone = st.todayDay == day ? st.todayReview : 0;
    final newLeft = max(0, st.dailyGoal - newDone);
    final total = st.dailyGoal + revDone + due;
    final doneN = min(newDone, st.dailyGoal) + revDone;
    final finished = st.doneToday(day);
    final streak = st.streakShown(day);
    return _Card(
      onTap: widget.inScreen
          ? (due > 0 ? () => openFull(context, (_) => const CurriculumReviewScreen()) : null)
          : () => openPane(context, (_) => const CurriculumScreen()),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (!widget.inScreen) ...[
            const TileBadge(text: 'TV', size: 34, color: AppColors.ai),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!widget.inScreen) Text(tr('토크버스 커리큘럼'), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.tinta)),
              Text(
                st.level == null ? tr('레벨을 골라 시작하세요') : (finished ? tr('오늘 분량 끝') : trf('오늘: 복습 {0} · 새 편 {1}', [due, newLeft])),
                style: TextStyle(fontSize: 13, color: finished ? AppColors.italia : AppColors.sumi, fontWeight: FontWeight.w600),
              ),
            ]),
          ),
          if (streak > 0) _Chip(trf('🔥 {0}일', [streak]), AppColors.gualdaDeep),
          if (widget.inScreen && due > 0) _Chip(tr('복습하기'), AppColors.beni),
        ]),
        if (st.level != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: total == 0 ? 0 : doneN / total, minHeight: 6, backgroundColor: AppColors.line, color: AppColors.italia),
          ),
        ],
      ]),
    );
  }
}

// ── 편 연습: 듣기·읽기 → 확인 문제 ──

class CurriculumPracticeScreen extends StatefulWidget {
  final Dialogue dialogue;
  const CurriculumPracticeScreen({super.key, required this.dialogue});
  @override
  State<CurriculumPracticeScreen> createState() => _CurriculumPracticeScreenState();
}

class _CurriculumPracticeScreenState extends State<CurriculumPracticeScreen> {
  final Set<int> _shown = {};
  bool _playing = false;
  int _playIdx = -1;

  Dialogue get d => widget.dialogue;

  @override
  void dispose() {
    _playing = false;
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _playAll() async {
    if (_playing) {
      setState(() => _playing = false);
      await TtsService.instance.stop();
      return;
    }
    setState(() => _playing = true);
    for (var i = 0; i < d.turns.length && _playing; i++) {
      if (!mounted) return;
      setState(() => _playIdx = i);
      final t = d.turns[i];
      await TtsService.instance.speakAsWait(t.tl, gender: d.voiceGender(t.speaker));
    }
    if (mounted) setState(() => (_playing = false, _playIdx = -1));
  }

  void _quiz() {
    final svc = CurriculumService.instance;
    final lines = svc.linesOf(d);
    final qs = QuestionMaker(svc.levelPool(d.region), DateTime.now().millisecondsSinceEpoch).forLines(lines, 10);
    TtsService.instance.stop();
    setState(() => _playing = false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CurriculumQuizScreen(
        title: tr('확인 문제'),
        questions: qs,
        dialogueOf: (_) => d,
        popCount: 2,
        onFinish: (results) async {
          await svc.finishPractice(d.id, results);
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: Text(d.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Text(d.sceneShown, style: const TextStyle(fontSize: 13, color: AppColors.tintaLight)),
          const SizedBox(height: 4),
          Text(tr('줄을 누르면 듣고 뜻을 봐요. 따라 말해 보세요.'), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 8),
          for (var i = 0; i < d.turns.length; i++)
            _Card(
              highlight: i == _playIdx,
              onTap: () {
                final t = d.turns[i];
                TtsService.instance.speakAs(t.tl, gender: d.voiceGender(t.speaker));
                setState(() => _shown.add(i));
              },
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.speakerName(d.turns[i].speaker), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.beni)),
                const SizedBox(height: 2),
                Text(d.turns[i].tl, style: const TextStyle(fontSize: 16, color: AppColors.tinta, fontWeight: FontWeight.w600)),
                if (_shown.contains(i)) ...[
                  const SizedBox(height: 4),
                  Text(d.turns[i].ko, style: const TextStyle(fontSize: 13, color: AppColors.sumi)),
                ],
              ]),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomInset(context)),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _playAll,
                icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
                label: Text(_playing ? tr('멈춤') : tr('전체 듣기')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: FilledButton(onPressed: _quiz, child: Text(tr('확인 문제')))),
          ]),
        ),
      ),
    );
  }
}

// ── 복습 ──

class CurriculumReviewScreen extends StatelessWidget {
  const CurriculumReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = CurriculumService.instance;
    final due = svc.state.dueOn(svc.today());
    final qs = <CQuestion>[];
    final seed = DateTime.now().millisecondsSinceEpoch;
    for (final r in due.take(20)) {
      final l = svc.lineById(r.lineId);
      if (l == null) continue;
      final q = QuestionMaker(svc.levelPool(l.d.region), seed + qs.length).make(l);
      if (q != null) qs.add(q);
    }
    return CurriculumQuizScreen(
      title: tr('복습'),
      questions: qs,
      dialogueOf: (q) => svc.lineById(q.lineId)?.d,
      onAnswer: (q, ok) => svc.answerReview(q.lineId, ok),
      onFinish: (_) async {
        // 재료가 사라진 줄(원고에서 빠진 턴)은 대기열에서 정리
        for (final r in svc.state.dueOn(svc.today())) {
          if (svc.lineById(r.lineId) == null) svc.state.review.removeWhere((x) => x.lineId == r.lineId);
        }
        await svc.save();
      },
    );
  }
}

// ── 코스 시험 ──

class CurriculumExamScreen extends StatelessWidget {
  const CurriculumExamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = CurriculumService.instance;
    final c = svc.state.course!;
    final per = examPerDialogue(c.dialogueIds.length);
    final qs = <CQuestion>[];
    final seed = DateTime.now().millisecondsSinceEpoch;
    for (final id in c.dialogueIds) {
      final d = DialogueService.instance.byId(id);
      if (d == null) continue;
      qs.addAll(QuestionMaker(svc.levelPool(d.region), seed + qs.length).forLines(svc.linesOf(d), per));
    }
    qs.shuffle(Random(seed));
    return CurriculumQuizScreen(
      title: tr('코스 시험'),
      questions: qs.take(30).toList(),
      exam: true,
      dialogueOf: (q) => svc.lineById(q.lineId)?.d,
      onFinish: (results) async {
        final wrong = {for (final e in results.entries) if (!e.value) e.key.substring(0, e.key.lastIndexOf('#'))};
        final correct = results.values.where((v) => v).length;
        await svc.finishExam(correct, results.length, wrong);
      },
    );
  }
}

// ── 문제 풀기(연습·복습·시험 공용) ──

class CurriculumQuizScreen extends StatefulWidget {
  final String title;
  final List<CQuestion> questions;
  final Dialogue? Function(CQuestion) dialogueOf;
  final void Function(CQuestion, bool)? onAnswer;
  final Future<void> Function(Map<String, bool> results) onFinish;
  final bool exam;
  final int popCount; // 「확인」에서 닫을 화면 수 — 연습은 연습 화면 위에 쌓여 있어 2
  const CurriculumQuizScreen({super.key, required this.title, required this.questions, required this.dialogueOf, required this.onFinish, this.onAnswer, this.exam = false, this.popCount = 1});
  @override
  State<CurriculumQuizScreen> createState() => _CurriculumQuizScreenState();
}

class _CurriculumQuizScreenState extends State<CurriculumQuizScreen> {
  int _i = 0;
  String? _chosen;
  final Map<String, bool> _results = {};
  bool _finished = false;

  List<CQuestion> get qs => widget.questions;

  @override
  void initState() {
    super.initState();
    if (qs.isEmpty) _finish();
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  void _speak(CQuestion q) {
    final d = widget.dialogueOf(q);
    TtsService.instance.speakAs(q.tl, gender: d?.voiceGender(q.speaker) ?? 'female');
  }

  void _choose(String o) {
    if (_chosen != null) return;
    final q = qs[_i];
    final ok = o == q.answer;
    setState(() => _chosen = o);
    // 같은 줄이 두 번 나오면 하나라도 틀리면 틀림
    _results[q.lineId] = (_results[q.lineId] ?? true) && ok;
    widget.onAnswer?.call(q, ok);
    if (q.kind == 'blank') _speak(q);
  }

  Future<void> _next() async {
    if (_i + 1 < qs.length) {
      setState(() {
        _i++;
        _chosen = null;
      });
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    await widget.onFinish(_results);
    if (mounted) setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(child: _finished ? _result() : (qs.isEmpty ? const SizedBox() : _question(qs[_i]))),
    );
  }

  Widget _result() {
    final correct = _results.values.where((v) => v).length;
    final total = _results.length;
    final score = scorePercent(correct, total);
    final ok = score >= kPassPercent;
    final st = CurriculumService.instance.state;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset(context)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (total == 0)
          Text(tr('지금 풀 문제가 없어요.'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: AppColors.tinta))
        else ...[
          Text('$score', textAlign: TextAlign.center, style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: widget.exam ? (ok ? AppColors.italia : AppColors.rojoDeep) : AppColors.tinta)),
          Text(trf('{0}문제 중 {1}개 맞힘', [total, correct]), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.sumi)),
          const SizedBox(height: 12),
          if (widget.exam)
            Text(
              ok
                  ? (st.course?.passedAt != null && st.level != null ? tr('통과! 코스를 마쳤어요.') : tr('통과!'))
                  : trf('{0}점 이상이면 통과예요. 틀린 회화만 다시 연습하고 시험을 다시 봐요.', [kPassPercent]),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.tinta),
            ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            final nav = Navigator.of(context);
            for (var k = 0; k < widget.popCount && nav.canPop(); k++) {
              nav.pop();
            }
          },
          child: Text(tr('확인')),
        ),
      ]),
    );
  }

  Widget _question(CQuestion q) {
    final d = widget.dialogueOf(q);
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
      children: [
        LinearProgressIndicator(value: (_i + 1) / qs.length, backgroundColor: AppColors.line, color: AppColors.beni),
        const SizedBox(height: 6),
        Text('${_i + 1} / ${qs.length}', style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
        const SizedBox(height: 12),
        Text(q.kind == 'meaning' ? tr('알맞은 뜻을 고르세요') : tr('빈칸에 들어갈 낱말을 고르세요'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sumi)),
        const SizedBox(height: 8),
        _Card(
          onTap: q.kind == 'meaning' ? () => _speak(q) : null,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (d != null) Text('${d.emoji} ${d.speakerName(q.speaker)}', style: const TextStyle(fontSize: 11, color: AppColors.beni, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: Text(q.prompt, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.tinta))),
              if (q.kind == 'meaning') const Icon(Icons.volume_up, color: AppColors.beni, size: 20),
            ]),
            if (q.hint.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(q.hint, style: const TextStyle(fontSize: 13, color: AppColors.sumi)),
            ],
          ]),
        ),
        const SizedBox(height: 8),
        for (final o in q.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                backgroundColor: _chosen == null
                    ? null
                    : o == q.answer
                        ? AppColors.italia.withValues(alpha: 0.15)
                        : (o == _chosen ? AppColors.rojo.withValues(alpha: 0.12) : null),
              ),
              onPressed: () => _choose(o),
              child: Text(o, style: const TextStyle(fontSize: 15, color: AppColors.tinta)),
            ),
          ),
        if (_chosen != null) ...[
          const SizedBox(height: 4),
          Text(_chosen == q.answer ? tr('맞았어요') : tr('아쉬워요'), style: TextStyle(fontWeight: FontWeight.w700, color: _chosen == q.answer ? AppColors.italia : AppColors.rojoDeep)),
          const SizedBox(height: 8),
          FilledButton(onPressed: _next, child: Text(_i + 1 < qs.length ? tr('다음') : tr('결과 보기'))),
        ],
      ],
    );
  }
}

// ── 작은 부품 ──

class _Card extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool highlight;
  const _Card({required this.child, this.onTap, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: highlight ? AppColors.beniLight.withValues(alpha: 0.25) : AppColors.cal,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: highlight ? AppColors.beni : AppColors.line),
            boxShadow: kCardShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      );
}
