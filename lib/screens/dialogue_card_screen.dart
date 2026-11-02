import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/achievement_service.dart';
import '../services/art_service.dart';
import '../services/dialogue_service.dart';
import '../services/learner_prefs.dart';
import '../services/tts_service.dart';

/// 편의 문장 플래시카드 — 일본어앱에서 옮김(2026-11-03). 앞면은 **그림만**(글자 없음), 탭하면 이탈리아어·독음·한국어.
/// 그림 = 장면 컷 → 턴 장면 그림(`art`) → 문장 속 단어 그림 → 장면 카드. 틀림/맞음 2단계, 틀린 카드는 끝에 다시.
class DialogueCardScreen extends StatefulWidget {
  final Dialogue dialogue;
  const DialogueCardScreen({super.key, required this.dialogue});
  @override
  State<DialogueCardScreen> createState() => _DialogueCardScreenState();
}

class _DialogueCardScreenState extends State<DialogueCardScreen> {
  late final List<int> _order = List.generate(widget.dialogue.turns.length, (i) => i);
  int _pos = 0;
  bool _flipped = false;
  final List<int> _retry = [];
  int _right = 0;

  Dialogue get d => widget.dialogue;
  DialogueTurn get t => d.turns[_order[_pos]];

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  void _mark(bool ok) {
    if (ok) {
      _right++;
    } else if (!_retry.contains(_order[_pos])) {
      _retry.add(_order[_pos]);
    }
    if (_pos < _order.length - 1) {
      setState(() {
        _pos++;
        _flipped = false;
      });
    } else if (_retry.isNotEmpty) {
      setState(() {
        _order.addAll(_retry);
        _retry.clear();
        _pos++;
        _flipped = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('틀린 카드를 다시 봅니다')), backgroundColor: AppColors.beni, duration: const Duration(seconds: 1)));
    } else {
      AchievementService.instance.markCards(d.id, _right, d.turns.length); // 성과: 핵심 표현 맞음
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trf('끝! 맞음 {0} / {1}', [_right, d.turns.length])), backgroundColor: AppColors.matcha));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final art = _CardArt(key: ValueKey('${d.id}:${t.num}:art'), d: d, t: t);
    final text = _CardText(d: d, t: t, flipped: _flipped);
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${d.emoji} ${d.title}', style: const TextStyle(color: AppColors.sumi, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 2),
          Text('${_pos + 1} / ${_order.length}', style: const TextStyle(color: AppColors.muted, fontSize: 10, letterSpacing: 2)),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _flipped = !_flipped),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: wide
                  ? Row(children: [
                      Expanded(flex: 5, child: art),
                      const SizedBox(width: 16),
                      Expanded(flex: 6, child: text),
                    ])
                  : Column(children: [
                      Expanded(flex: 5, child: art),
                      const SizedBox(height: 12),
                      Expanded(flex: 6, child: text),
                    ]),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 6, 16, 20 + bottomInset(context)),
          child: Row(children: [
            _Btn(icon: Icons.close, label: tr('틀렸어요'), color: AppColors.beni, filled: true, onTap: () => _mark(false)),
            _Btn(icon: Icons.volume_up, label: tr('듣기'), color: AppColors.sumi, filled: true, onTap: () => TtsService.instance.speakAs(t.tl.replaceAll(RegExp(r'\([^)]*\)'), '').replaceAll(RegExp(r'\{[a-z_]+\}'), ''), gender: d.voiceGender(t.speaker))),
            _Btn(icon: Icons.check, label: tr('맞았어요'), color: AppColors.beni, filled: true, onTap: () => _mark(true)),
          ]),
        ),
      ]),
    );
  }
}

class _CardArt extends StatelessWidget {
  final Dialogue d;
  final DialogueTurn t;
  const _CardArt({super.key, required this.d, required this.t});

  Future<String?> _url() async {
    final scene = await ArtService.instance.sceneCut(d.id, t.num, large: true);
    if (scene != null) return scene;
    if (t.art != null) return t.art;
    for (final w in t.pictureWords) {
      final u = await ArtService.instance.urlFor(w);
      if (u != null) return u;
    }
    final inText = await ArtService.instance.urlInText(t.tl);
    if (inText != null) return inText.value;
    return d.art;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
        future: _url(),
        builder: (context, snap) => Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: AppColors.washiDeep, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(18), boxShadow: kCardShadow),
          child: snap.data == null
              ? Center(child: Text(d.emoji, style: const TextStyle(fontSize: 72)))
              : Image.network(snap.data!, fit: BoxFit.contain, errorBuilder: (_, _, _) => Center(child: Text(d.emoji, style: const TextStyle(fontSize: 72)))),
        ),
      );
}

class _CardText extends StatelessWidget {
  final Dialogue d;
  final DialogueTurn t;
  final bool flipped;
  const _CardText({required this.d, required this.t, required this.flipped});

  @override
  Widget build(BuildContext context) {
    final name = d.speakerName(t.speaker);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: flipped ? AppColors.washi : AppColors.washiDeep, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(18)),
      child: flipped
          ? SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$name · ${t.num}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                const SizedBox(height: 8),
                Text(LearnerPrefs.fill(t.tl), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.sumi, height: 1.3)),
                if (t.rd.isNotEmpty) Text(LearnerPrefs.fill(t.rd, ko: true), style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                // 시안 02-3: 단어 뜻(gloss `kata=뜻`) 줄 목록 → 번역 → 메모 상자
                if (_glossRows(t.gloss).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _section(tr('단어 뜻')),
                  for (final (w, m) in _glossRows(t.gloss))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SizedBox(width: 120, child: Text(w, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.sumi))),
                        Expanded(child: Text(m, style: const TextStyle(fontSize: 14, color: AppColors.sumiLight))),
                      ]),
                    ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.line),
                const SizedBox(height: 10),
                _section(tr('번역')),
                Text(LearnerPrefs.fill(t.ko, ko: true), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi, height: 1.4)),
                if (t.note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFFF8EE), border: Border.all(color: const Color(0xFFF1E1C6)), borderRadius: BorderRadius.circular(12)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('💡', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t.note, style: const TextStyle(fontSize: 13, color: AppColors.beniDeep, height: 1.45))),
                    ]),
                  ),
                ],
              ]),
            )
          : Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                const SizedBox(height: 8),
                Text(tr('그림을 보고 이탈리아어로 말해 보세요'), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 4),
                Text(tr('탭해서 확인'), style: const TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: 2)),
              ]),
            ),
    );
  }
}

/// gloss `halo=안녕 apa=무엇 ber-kenal-an=서로 알게 되다` → [(halo, 안녕), …] — 표제어는 라틴 문자, 뜻은 다음 표제어 앞까지.
List<(String, String)> _glossRows(String gloss) => [
      for (final m in RegExp(r'([A-Za-z][A-Za-z\- ]*?)=(.*?)(?=\s[A-Za-z][A-Za-z\- ]*=|$)').allMatches(gloss))
        (m.group(1)!.trim(), m.group(2)!.trim()),
    ];

Widget _section(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ai, letterSpacing: 1)),
    );

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled; // 시안 02-3: 채운 알약 버튼
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.label, required this.color, required this.onTap, this.filled = false});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Material(
            color: filled ? color : Colors.transparent,
            shape: StadiumBorder(side: BorderSide(color: color, width: 1.5)),
            child: InkWell(
              onTap: onTap,
              customBorder: const StadiumBorder(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icon, color: filled ? Colors.white : color, size: 20),
                  const SizedBox(width: 8),
                  Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: filled ? Colors.white : AppColors.sumi)),
                ]),
              ),
            ),
          ),
        ),
      );
}
