import 'package:flutter/material.dart';

import 'account.dart';
import 'purchase.dart';
import '../screens/paywall_screen.dart';
import '../services/curriculum_service.dart';
import '../services/dialogue_service.dart';

/// 유료 이용권 — Talkverse 계정 이용권(lang 'it', auth.talkverse.uk) OR 이 기기에서 산·복원한 이용권(스토어, lang_it_*·all_*).
/// 무료/유료 범위 = `~/talkverse/PAYWALL_SPEC.md` §2(2026-11-23, uk 의 정함 — 사용자 「1 2 모두 진행」). 잠금 값은 커리큘럼 JSON(서버)이 준다.
/// 잠긴 곳은 숨기지 않고 자물쇠 → 결제 화면(애플 3.1.1·2.1).
class Entitlement {
  Entitlement._();
  static const lang = 'it';
  static bool get premium => Account.has(lang) || Purchase.owns(lang);

  /// 시험용: 이용권 상태를 바꿔 끼움.
  @visibleForTesting
  static bool? premiumOverride;
  static bool get _paid => premiumOverride ?? premium;

  static CurriculumService get _cur => CurriculumService.instance;

  /// 커리큘럼 단계가 열려 있나 — 무료 단계(서버 `free`, 기본 1단계) 또는 이용권.
  static bool stageOpen(String id) {
    final st = id.startsWith('R') ? stageOfRegion(id) : id; // 옛 진도(R 레벨)도 단계로
    return _paid || (_cur.stageById(st)?.free ?? st == '1');
  }

  /// 회화 편이 열려 있나 — 무료 단계에 든 편(커리큘럼 JSON 이 없으면 R0·R1) 또는 이용권.
  static bool dialogueOpen(Dialogue d) {
    if (_paid) return true;
    final st = _cur.stages;
    if (st.isEmpty) return d.region == 'R0' || d.region == 'R1';
    return st.any((s) => s.free && s.dialogueIds.contains(d.id));
  }

  /// 문법 스텝 n(1부터)이 열려 있나 — `freeSteps`(기본 2)까지 무료.
  static bool grammarStepOpen(int n) => _paid || n <= _cur.freeSteps;

  /// 언어감각 n급(1부터)이 열려 있나 — `freeSenseLevels`(기본 1)까지 무료.
  static bool senseLevelOpen(int n) => _paid || n <= _cur.freeSenseLevels;

  /// 열려 있으면 true, 잠겼으면 결제 화면을 띄우고 false.
  static Future<bool> gate(BuildContext context, bool open) async {
    if (open) return true;
    await showPaywall(context);
    return false;
  }

  static Future<void> showPaywall(BuildContext context) => PaywallScreen.show(context);
}

/// 잠긴 곳 표시(자물쇠).
class LockBadge extends StatelessWidget {
  final double size;
  const LockBadge({super.key, this.size = 16});
  @override
  Widget build(BuildContext context) => Icon(Icons.lock_outline, size: size, color: const Color(0xFF8A8F98));
}
