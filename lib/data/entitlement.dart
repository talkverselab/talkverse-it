import 'package:flutter/material.dart';

import 'account.dart';
import 'purchase.dart';
import '../screens/paywall_screen.dart';

/// 유료 이용권 — Talkverse 계정 이용권(lang 'it', auth.talkverse.uk) OR 이 기기에서 산·복원한 평생 이용권(스토어).
/// 한자 앱 구성(2026-11-02)을 옮김. 무료/유료로 나눌 기능은 아직 정하지 않았다 — 지금은 모든 기능이 무료.
class Entitlement {
  Entitlement._();
  static const lang = 'it';
  static bool get premium => Account.has(lang) || Purchase.owns(lang);

  /// 잠금 안내 + 평생 이용권 구매·복원.
  static Future<void> showPaywall(BuildContext context) => PaywallScreen.show(context);
}
