import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../data/account.dart';

/// 로그인 — Talkverse 공용 계정(한자 앱 login_screen 을 옮김, 2026-11-02). 로그인은 선택.
/// 네 버튼을 늘 같은 순서로(구글·네이버·카카오·애플), 서버 `/providers` 에 없는 건 누르면 '준비 중'.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static Future<bool?> open(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).push<bool>(MaterialPageRoute(builder: (_) => const LoginScreen()));
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  List<String>? providers;
  String? busy;
  String? error;
  bool emailOpen = false; // 이메일(심사·테스트용 데모 계정) 로그인 칸
  final emailCtl = TextEditingController();
  final pwCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Account.providers().then((p) => mounted ? setState(() => providers = p) : null);
  }

  bool _ready(String p) => p == 'apple' ? (providers?.contains('apple') ?? true) : (providers?.contains(p) ?? false);

  Future<void> _go(String p) async {
    if (!_ready(p)) {
      setState(() => error = trf('{0} 로그인은 준비 중입니다. 지금은 Apple 로그인이나 이메일 로그인을 써 주세요.', [_name(p)]));
      return;
    }
    setState(() { busy = p; error = null; });
    try {
      final ok = await Account.signIn(p);
      if (ok && mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = tr('로그인하지 못했습니다. 잠시 후 다시 시도해 주세요.'));
    } finally {
      if (mounted) setState(() => busy = null);
    }
  }

  Future<void> _goEmail() async {
    if (emailCtl.text.trim().isEmpty || pwCtl.text.isEmpty) return;
    setState(() { busy = 'password'; error = null; });
    try {
      final ok = await Account.signInPassword(emailCtl.text, pwCtl.text);
      if (ok && mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = tr('이메일 또는 비밀번호가 맞지 않습니다.'));
    } finally {
      if (mounted) setState(() => busy = null);
    }
  }

  @override
  void dispose() {
    emailCtl.dispose();
    pwCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.cal,
        appBar: AppBar(title: Text(tr('로그인'))),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListView(
                padding: EdgeInsets.fromLTRB(24, 32, 24, 24 + bottomInset(context)),
                shrinkWrap: true,
                children: [
                  Text(tr('Talkverse 계정'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.tinta)),
                  const SizedBox(height: 10),
                  Text(
                    tr('로그인은 선택입니다. 계정 하나로 Talkverse 언어 앱과 talkverse.uk 를 함께 씁니다.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppColors.tintaLight, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  if (providers == null)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else
                    for (final p in const ['google', 'naver', 'kakao', 'apple'])
                      Padding(padding: const EdgeInsets.only(bottom: 12), child: _button(p)),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],
                  // 이메일 로그인 — 서버가 허용한 데모 계정(App Store 심사자용)만. 항상 작게 둔다.
                  const SizedBox(height: 18),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => emailOpen = !emailOpen),
                      child: Text(tr('이메일로 로그인 (심사·테스트용)'),
                          style: const TextStyle(fontSize: 12.5, color: AppColors.tintaLight)),
                    ),
                  ),
                  if (emailOpen) ...[
                    TextField(
                        controller: emailCtl,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: InputDecoration(hintText: tr('이메일'))),
                    const SizedBox(height: 8),
                    TextField(
                        controller: pwCtl,
                        obscureText: true,
                        decoration: InputDecoration(hintText: tr('비밀번호')),
                        onSubmitted: (_) => _goEmail()),
                    const SizedBox(height: 10),
                    FilledButton(onPressed: busy != null ? null : _goEmail, child: Text(tr('로그인'))),
                  ],
                ],
              ),
            ),
          ),
        ),
      );

  String _name(String p) => switch (p) {
        'google' => 'Google',
        'naver' => tr('네이버'),
        'kakao' => tr('카카오'),
        'apple' => 'Apple',
        _ => p,
      };

  Widget _button(String p) {
    final disabled = busy != null;
    if (p == 'apple') {
      return SizedBox(
        height: 50,
        child: AbsorbPointer(
          absorbing: disabled,
          child: SignInWithAppleButton(
            text: tr('Apple로 로그인'),
            height: 50,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            onPressed: () => _go('apple'),
          ),
        ),
      );
    }
    final (label, bg, fg, mark) = switch (p) {
      'google' => (tr('Google로 로그인'), Colors.white, const Color(0xFF1F1F1F), 'G'),
      'kakao' => (tr('카카오 로그인'), const Color(0xFFFEE500), const Color(0xD9000000), 'K'),
      'naver' => (tr('네이버 로그인'), const Color(0xFF03C75A), Colors.white, 'N'),
      _ => (p, AppColors.calDeep, Colors.black, '·'),
    };
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: BorderSide(color: p == 'google' ? const Color(0xFF747775) : bg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: disabled ? null : () => _go(p),
        child: Row(children: [
          SizedBox(
              width: 24,
              child: Text(mark,
                  textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: fg))),
          Expanded(
              child: Text(label,
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg))),
          SizedBox(
              width: 24,
              child: busy == p
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
                  : null),
        ]),
      ),
    );
  }
}
