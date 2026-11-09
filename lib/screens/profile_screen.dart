import 'package:flutter/material.dart';

import 'about_screen.dart';
import 'login_screen.dart';

import '../core/theme.dart';
import '../widgets/achievement_desk.dart';
import '../widgets/spanish_decor.dart';
import '../core/l10n.dart';
import '../core/pane.dart';
import '../embed.dart';
import '../data/account.dart';
import '../data/entitlement.dart';
import '../data/purchase.dart';
import '../services/achievement_service.dart';
import '../services/ko_reading.dart';
import '../services/learner_prefs.dart';

/// 프로필 탭 내용 — 계정 · 성과 · 기록 · 학습자 프로필 · 설정 · 정보(일본어앱 2026-11-07 구조).
class ProfileSections extends StatelessWidget {
  const ProfileSections({super.key});

  Future<void> _reset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('학습 기록 초기화')),
        content: Text(tr('회화 진행·카드·성과 기록을 모두 지웁니다. 되돌릴 수 없습니다.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('취소'))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('초기화'), style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true) return;
    await appDb.delete(appDb.userProgress).go();
    await AchievementService.instance.reset();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('초기화 완료'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(tr('계정')),
        const SizedBox(height: 8),
        const _AccountSection(),
        const SizedBox(height: 16),
        _SectionTitle(tr('성과')),
        const SizedBox(height: 8),
        const AchievementDesk(),
        const SizedBox(height: 16),
        _SectionTitle(tr('기록')),
        const SizedBox(height: 8),
        _SettingsGroup(items: [
          _SettingItem(
              icon: Icons.restart_alt,
              title: tr('학습 기록 초기화'),
              subtitle: tr('회화·카드·성과 기록 삭제'),
              onTap: () => _reset(context)),
        ]),
        const SizedBox(height: 16),
        // 학습자 프로필(일본어앱 learner_prefs) — 이름 → 회화의 「나」(화자 A)·{name} 자리, 성별 → 학습자 목소리
        _SectionTitle(tr('학습자 프로필')),
        const SizedBox(height: 8),
        const _LearnerSection(),
        const SizedBox(height: 16),
        _SectionTitle(tr('설정')),
        const SizedBox(height: 8),
        ValueListenableBuilder<bool>(
          valueListenable: KoReadingPrefs.show,
          builder: (context, on, _) => _SettingsGroup(items: [
            if (switchLanguage != null)
              _SettingItem(icon: Icons.swap_horiz, title: tr('다른 언어 배우기'), subtitle: tr('Talkverse 의 다른 언어로 이동'), onTap: switchLanguage!),
            _SettingItem(
                icon: Icons.language,
                title: tr('언어 / Language'),
                subtitle: '${AppLangPrefs.lang.value.label}  →  ${AppLangPrefs.peekNext().label}',
                onTap: AppLangPrefs.next),
            _SettingItem(
                icon: Icons.record_voice_over_outlined,
                title: tr('한글 독음 표시'),
                subtitle: on ? tr('켜짐 — 탭하면 숨김') : tr('꺼짐 — 탭하면 표시'),
                onTap: () => KoReadingToggleAction.toggle(context)),
          ]),
        ),
        const SizedBox(height: 16),
        _SectionTitle(tr('정보')),
        const SizedBox(height: 8),
        _SettingsGroup(items: [
          _SettingItem(
              icon: Icons.landscape_outlined,
              title: tr('앱 소개'),
              subtitle: tr('절벽구간 — 이 앱이 단어를 나누는 기준'),
              onTap: () => openPane(context, (_) => const AboutScreen())),
          _SettingItem(icon: Icons.info_outline, title: tr('앱 버전'), subtitle: '0.1.0 · alpha'),
          _SettingItem(icon: Icons.copyright, title: tr('저작권'), subtitle: tr('이탈리아어유니버스 · 2026')),
          _SettingItem(
              icon: Icons.article_outlined,
              title: tr('라이선스'),
              subtitle: tr('그림·오픈소스 라이선스'),
              onTap: () => showLicensePage(context: context, applicationName: tr('이탈리아어유니버스'), applicationVersion: '0.1.0')),
        ]),
        const SizedBox(height: 20),
        const BandDivider(),
        const SizedBox(height: 12),
        const Center(child: SolMark(size: 28)),
        const SizedBox(height: 6),
        const Center(
          child: Text('Talkverse · Italiano', style: TextStyle(color: AppColors.tintaLight, fontSize: 11, letterSpacing: 3)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// 학습자 이름·성별(회화 화자 A = 학습자).
class _LearnerSection extends StatelessWidget {
  const _LearnerSection();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LearnerPrefs.name,
      builder: (context, name, _) => ValueListenableBuilder<String>(
        valueListenable: LearnerPrefs.gender,
        builder: (context, gender, _) => _SettingsGroup(items: [
          _SettingItem(
            icon: Icons.badge_outlined,
            title: tr('이름'),
            subtitle: name.isNotEmpty ? trf('{0} — 회화 속 「나」로 나와요', [name]) : tr('없음 — 회화에서 「나」로 보여요'),
            onTap: () => _editName(context),
          ),
          _SettingItem(
            icon: gender == 'female' ? Icons.face_3 : Icons.face,
            title: tr('성별'),
            subtitle: gender == 'female' ? tr('여성 — 탭하면 남성 · 「나」의 목소리') : tr('남성 — 탭하면 여성 · 「나」의 목소리'),
            onTap: () => LearnerPrefs.setGender(gender == 'female' ? 'male' : 'female'),
          ),
        ]),
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final c = TextEditingController(text: LearnerPrefs.name.value);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('이름')),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: tr('회화에서 불릴 이름'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('취소'))),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(tr('저장'))),
        ],
      ),
    );
    if (v != null) await LearnerPrefs.setName(v);
  }
}

/// Talkverse 계정·평생 이용권(한자 앱 me_screen 의 계정 칸을 옮김, 2026-11-02).
/// 로그인 전: 로그인 / 로그인 후: 이름·이메일, 로그아웃, 계정 삭제(스토어 심사 요구). 이용권 구매·복원은 로그인 없이도 된다.
class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: Account.user,
      builder: (context, u, _) => ValueListenableBuilder<String?>(
        valueListenable: Purchase.status,
        builder: (context, st, _) => _SettingsGroup(items: [
          if (u == null)
            _SettingItem(
                icon: Icons.account_circle_outlined,
                title: tr('로그인'),
                subtitle: tr('Talkverse 계정 하나로 모든 앱에서 (선택)'),
                onTap: () => LoginScreen.open(context))
          else ...[
            _SettingItem(
                icon: Icons.account_circle,
                title: (u['display_name'] as String?) ?? tr('이름 없음'),
                subtitle: (u['email'] as String?) ?? ''),
            _SettingItem(icon: Icons.logout, title: tr('로그아웃'), subtitle: '', onTap: () => Account.signOut()),
            _SettingItem(
                icon: Icons.person_remove_outlined,
                title: tr('계정 삭제'),
                subtitle: tr('계정과 로그인 정보를 지웁니다'),
                onTap: () => _confirmDelete(context)),
          ],
          _SettingItem(
              icon: Icons.workspace_premium_outlined,
              title: tr('이용권'),
              subtitle: Entitlement.premium ? tr('이용 중') : tr('1개월 · 3개월 · 1년 · 평생'),
              onTap: () => Entitlement.showPaywall(context)),
          _SettingItem(
              icon: Icons.restore,
              title: tr('구매 복원'),
              subtitle: switch (st) {
                'pending' => tr('확인 중…'),
                'restored' => tr('복원했습니다'),
                'nothing' => tr('복원할 구매가 없습니다'),
                _ => tr('이전에 산 이용권을 이 기기에서 다시 엽니다'),
              },
              onTap: () => Purchase.restore()),
        ]),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('계정을 삭제할까요?')),
        content: Text(tr(
            'Talkverse 계정과 이름·이메일·로그인 정보가 지워지고 모든 기기에서 로그아웃됩니다. 이 기기의 학습 기록은 그대로 남습니다. 되돌릴 수 없습니다.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('취소'))),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(tr('삭제'), style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Account.deleteAccount();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('삭제하지 못했습니다. 네트워크를 확인하고 다시 시도해 주세요.'))));
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 15,
        color: AppColors.tinta,
        letterSpacing: 2,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cal,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gualda.withValues(alpha: 0.5)),
      ),
      // ListTile 은 가장 가까운 Material 에 물결을 그린다 — 색 있는 상자 안에 투명 Material(디버그 단언 방지)
      child: Material(
        type: MaterialType.transparency,
        child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              onTap: items[i].onTap,
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.rojo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.rojo, width: 0.8),
                ),
                child: Icon(items[i].icon, color: AppColors.rojo, size: 18),
              ),
              title: Text(items[i].title,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tinta)),
              subtitle: Text(items[i].subtitle,
                  style: const TextStyle(color: AppColors.tintaLight, fontSize: 11)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.rojo, size: 18),
            ),
            if (i < items.length - 1)
              Container(height: 0.5, color: AppColors.gualda.withValues(alpha: 0.3)),
          ],
        ],
      ),
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  _SettingItem({required this.icon, required this.title, required this.subtitle, this.onTap});
}
