import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'update_screen.dart';

import '../core/theme.dart';
import '../widgets/spanish_decor.dart';
import '../core/l10n.dart';
import '../core/platform.dart';
import '../data/account.dart';
import '../data/entitlement.dart';
import '../data/purchase.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: Text(tr('프로필 · 설정'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!isIOS) const UpdateEntryTile(),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.rojoDeep, AppColors.rojo],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gualda, width: 1.5),
            ),
            child: Row(
              children: [
                const TileBadge(text: 'IT', size: 60, color: AppColors.italia),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('학습자'),
                        style: TextStyle(
                          color: AppColors.cal,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        tr('Día 1 · 입문 (A1)'),
                        style: TextStyle(
                          color: AppColors.gualdaBright,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(tr('계정')),
          const SizedBox(height: 8),
          const _AccountSection(),
          const SizedBox(height: 16),
          _SectionTitle(tr('설정')),
          const SizedBox(height: 8),
          _SettingsGroup(items: [
            _SettingItem(
                icon: Icons.language,
                title: tr('언어 / Language'),
                subtitle: '${AppLangPrefs.lang.value.label}  →  ${AppLangPrefs.peekNext().label}',
                onTap: AppLangPrefs.next),
            if (isIOS)
              _SettingItem(
                  icon: Icons.flight_takeoff,
                  title: tr('앱 업데이트'),
                  subtitle: tr('아이폰은 TestFlight 앱에서 새 빌드를 받습니다')),
            _SettingItem(icon: Icons.volume_up, title: tr('TTS 음성'), subtitle: tr('it-IT (시스템 보이스)')),
            _SettingItem(icon: Icons.public, title: tr('변종'), subtitle: tr('표준 이탈리아어 (Italia)')),
            _SettingItem(icon: Icons.palette, title: tr('테마'), subtitle: tr('낮 · rojo y gualda #AA151B')),
          ]),
          const SizedBox(height: 16),
          _SectionTitle(tr('정보')),
          const SizedBox(height: 8),
          _SettingsGroup(items: [
            _SettingItem(icon: Icons.info_outline, title: tr('앱 버전'), subtitle: '0.1.0 · alpha'),
            _SettingItem(icon: Icons.code, title: 'Stack', subtitle: 'Flutter 3.41 · Material 3 · Drift'),
            _SettingItem(icon: Icons.copyright, title: tr('저작권'), subtitle: tr('이탈리아어유니버스 · 2026')),
          ]),
          const SizedBox(height: 20),
          const BandDivider(),
          const SizedBox(height: 12),
          const Center(child: SolMark(size: 28)),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'El saber no ocupa lugar',
              style: TextStyle(
                color: AppColors.tintaLight,
                fontSize: 11,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
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
              title: tr('평생 이용권'),
              subtitle: Entitlement.premium ? tr('이용 중') : tr('한 번 결제 · 구독 아님'),
              onTap: () => Entitlement.showPaywall(context)),
          _SettingItem(
              icon: Icons.restore,
              title: tr('구매 복원'),
              subtitle: switch (st) {
                'pending' => tr('확인 중…'),
                'restored' => tr('복원했습니다'),
                'nothing' => tr('복원할 구매가 없습니다'),
                _ => tr('이전에 산 평생 이용권을 이 기기에서 다시 엽니다'),
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
