import 'package:flutter/material.dart';

import 'alphabet_screen.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../main.dart';
import '../services/dialogue_service.dart';
import '../widgets/spanish_decor.dart';
import 'about_screen.dart';
import 'chunk_search_screen.dart';
import 'dialogue_screen.dart';
import 'episode_screen.dart';
import 'grammar_lesson_screen.dart';
import 'profile_screen.dart';
import 'sentence_flashcard_screen.dart';
import 'speaking_practice_screen.dart';
import 'topic_vocab_screen.dart';
import 'verb_screen.dart';
import 'word_flashcard_screen.dart';
import 'word_freq_screen.dart';

/// 메인 — 탭 4개: 배우기 · 복습 · 탐색 · 프로필 (일본어앱 main_screen 구조, 2026-11-03 이 앱 시안 it-01).
/// 넓은 화면(가로 720 이상: 아이패드·태블릿·폴드 펼침) = 레일 + 왼쪽 칸(탭 목록) | 오른쪽 칸(연 화면, 첫 화면 = 회화 홈).
/// 폰 = 하단 탭 + 내용 전체 화면. 회화 리더·카드·말하기처럼 집중하는 화면은 openFull(전체 화면).
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  final _pane = GlobalKey<NavigatorState>();

  static List<(IconData, IconData, String)> get _tabs => [
        (Icons.menu_book_outlined, Icons.menu_book, tr('배우기')),
        (Icons.style_outlined, Icons.style, tr('복습')),
        (Icons.explore_outlined, Icons.explore, tr('탐색')),
        (Icons.person_outline, Icons.person, tr('프로필')),
      ];

  @override
  Widget build(BuildContext context) {
    final stack = IndexedStack(
      index: _index,
      children: const [HomeScreen(), ReviewTab(), ExploreTab(), MeTab()],
    );
    // 폰(한 화면): 하단 탭 + 내용 전체 화면
    if (!isWide(context)) {
      return Scaffold(
        body: stack,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (final t in _tabs) NavigationDestination(icon: Icon(t.$1), selectedIcon: Icon(t.$2), label: t.$3),
          ],
        ),
      );
    }
    // 넓은 화면: 레일 + 왼쪽 칸(탭 화면) | 오른쪽 칸(연 화면). 두 칸까지만.
    final w = MediaQuery.sizeOf(context).width;
    final left = (w * 0.34).clamp(300.0, 440.0); // 폴드 펼침(≈740) 은 300, 아이패드는 더 넓게
    return Pane(
      navKey: _pane,
      child: NavigatorPopHandler(
        onPopWithResult: (_) => _pane.currentState?.maybePop(),
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: w >= 900 ? NavigationRailLabelType.all : NavigationRailLabelType.selected,
                  backgroundColor: AppColors.washiDeep,
                  indicatorColor: AppColors.beni.withValues(alpha: 0.12),
                  selectedIconTheme: const IconThemeData(color: AppColors.beniDeep),
                  unselectedIconTheme: const IconThemeData(color: AppColors.muted),
                  selectedLabelTextStyle: const TextStyle(color: AppColors.beni, fontSize: 11, fontWeight: FontWeight.w600),
                  unselectedLabelTextStyle: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600),
                  // 맨 아래 「앱 소개」 — 절벽구간 설명
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () => _pane.currentState?.push(MaterialPageRoute(builder: (_) => const AboutScreen())),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.info_outline, color: AppColors.muted, size: 22),
                                const SizedBox(height: 4),
                                Text(tr('앱 소개'), style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  destinations: [
                    for (final t in _tabs)
                      NavigationRailDestination(icon: Icon(t.$1), selectedIcon: Icon(t.$2), label: Text(t.$3)),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1, color: AppColors.line),
                SizedBox(width: left, child: stack),
                const VerticalDivider(width: 1, thickness: 1, color: AppColors.line),
                Expanded(
                  child: ClipRect(
                    child: Navigator(
                      key: _pane,
                      // 시안 it-01: 오른쪽 칸 첫 화면 = 회화 홈(오늘의 컷)
                      onGenerateInitialRoutes: (_, _) => [MaterialPageRoute(builder: (_) => const DialogueHomeScreen())],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sumi, letterSpacing: 0.5)),
    );

// ────────── 배우기 ──────────

/// 배우기: 인사 → 오늘의 컷/이어서 읽기 → 회화 · 기초 · 단어 메뉴(이 앱의 기존 메뉴 13개 그대로).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      body: Stack(
        children: [
          const Positioned(top: 0, left: 0, right: 0, height: 260, child: MeshBackdrop()),
          SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
              children: [
                Row(
                  children: [
                    const GradText('Ciao!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1)),
                    const SizedBox(width: 6),
                    const Text('👋', style: TextStyle(fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tr('한국 학습자, 오늘도 시작해요'),
                  style: const TextStyle(fontSize: 13, color: AppColors.tintaLight, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                const _HomeTodayCut(),
                _section(tr('기초')),
                _MenuGrid(items: [
                  _MenuItem(label: tr('알파벳과 발음'), sub: 'Alfabeto', badge: 'Aa', color: AppColors.er,
                      builder: (_) => const AlphabetScreen()),
                  _MenuItem(label: tr('성·수'), sub: 'Genere', badge: 'il/la', color: AppColors.mar,
                      builder: (_) => _ComingSoon(title: tr('성·수 일치'))),
                ]),
                _section(tr('문법')),
                _MenuGrid(items: [
                  _MenuItem(label: tr('문법'), sub: 'Grammatica', badge: 'G', color: AppColors.rojoDeep,
                      builder: (_) => const GrammarHubScreen()),
                  _MenuItem(label: tr('동사 활용'), sub: 'Coniugazione', badge: 'V', color: AppColors.irregular,
                      builder: (_) => const VerbScreen()),
                ]),
                _section(tr('회화')),
                _MenuGrid(items: [
                  _MenuItem(label: tr('회화'), sub: 'Conversazione', badge: 'Ch', color: AppColors.beni,
                      builder: (_) => const DialogueHomeScreen()),
                  _MenuItem(label: tr('문장 말하기'), sub: 'Parlare', badge: '🎙', color: AppColors.rojoDeep, full: true,
                      builder: (_) => const SpeakingPracticeScreen()),
                  _MenuItem(label: tr('문장 카드'), sub: 'Frasi', badge: 'S', color: AppColors.tinta, full: true,
                      builder: (_) => const SentenceFlashcardScreen()),
                ]),
                _section(tr('단어')),
                _MenuGrid(items: [
                  _MenuItem(label: tr('절벽 단어'), sub: 'R1~R5', badge: 'F', color: AppColors.italia,
                      builder: (_) => const WordFreqScreen()),
                  _MenuItem(label: tr('단어'), sub: 'Vocabolario', badge: 'W', color: AppColors.oliva,
                      builder: (_) => const TopicVocabScreen()),
                  _MenuItem(label: tr('표현'), sub: 'Espressione', badge: 'E', color: AppColors.rojoLight,
                      builder: (_) => TopicVocabScreen(title: tr('주제별 표현'), asset: 'assets/data/vocab/travel_expressions.json')),
                  _MenuItem(label: tr('단어 카드'), sub: 'Carte', badge: 'R', color: AppColors.gualdaDeep, full: true,
                      builder: (_) => const WordFlashcardScreen()),
                ]),
                _section(tr('참고')),
                _MenuGrid(items: [
                  _MenuItem(label: tr('청크 검색'), sub: 'Ricerca', badge: '🔍', color: AppColors.gualdaDeep,
                      builder: (_) => const ChunkSearchScreen()),
                ]),
                const SizedBox(height: 28),
                const BandDivider(),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    tr('이탈리아어유니버스 · 2026'),
                    style: const TextStyle(color: AppColors.tintaLight, fontSize: 11, letterSpacing: 4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 홈 「오늘의 컷 / 이어서 읽기」(시안 it-01) — 회화 서비스를 불러온 뒤 그린다.
class _HomeTodayCut extends StatefulWidget {
  const _HomeTodayCut();
  @override
  State<_HomeTodayCut> createState() => _HomeTodayCutState();
}

class _HomeTodayCutState extends State<_HomeTodayCut> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    DialogueService.instance.ensureLoaded().then((_) => mounted ? setState(() => _loaded = true) : null);
  }

  // const 로 두면 불러온 뒤에도 다시 그려지지 않는다 → 불러온 상태를 키로
  @override
  Widget build(BuildContext context) => TodayCutCard(key: ValueKey(_loaded));
}

class _MenuItem {
  final String label;
  final String sub;
  final String badge;
  final Color color;
  final WidgetBuilder builder;
  final bool full; // 집중 화면(카드·말하기) — 전체 화면으로
  _MenuItem({
    required this.label,
    required this.sub,
    required this.badge,
    required this.color,
    required this.builder,
    this.full = false,
  });
}

class _MenuGrid extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 118, // 고정 높이 — 아이패드 왼쪽 좁은 칸(300~440)에서 비율로 잡으면 아래가 넘친다
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _MenuTile(item: items[i]),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => item.full ? openFull(context, item.builder) : openPane(context, item.builder),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cal,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
          boxShadow: kCardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TileBadge(text: item.badge, size: 40, color: item.color),
              const SizedBox(height: 8),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.tinta),
              ),
              const SizedBox(height: 2),
              Text(
                item.sub,
                maxLines: 1,
                style: const TextStyle(fontSize: 10, color: AppColors.tintaLight),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 탭 안의 한 줄(카드) — 배지 + 제목·부제 + 꺾쇠. 누르면 오른쪽 칸(넓은 화면) 또는 push.
class _NavRow extends StatelessWidget {
  final String badge;
  final Color? color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _NavRow({required this.badge, this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.washi,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
          boxShadow: kCardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  TileBadge(text: badge, size: 38, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                        const SizedBox(height: 2),
                        Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabTitle extends StatelessWidget {
  final String title;
  const _TabTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
        child: GradText(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      );
}

// ────────── 복습 ──────────

/// 복습: 회화 노트 이어 하기(턴 학습 진행) · 문장 카드 · 단어 카드 · 말하기 · 문법 테스트. 카드·말하기는 전체 화면.
class ReviewTab extends StatelessWidget {
  const ReviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
          children: [
            _TabTitle(tr('복습')),
            _section(tr('이어서 학습')),
            const _TodayMission(),
            _section(tr('복습')),
            _NavRow(
              badge: 'S',
              color: AppColors.tinta,
              title: tr('문장 카드'),
              subtitle: tr('회화 문장 · 학습한 턴'),
              onTap: () => openFull(context, (_) => const SentenceFlashcardScreen()),
            ),
            _NavRow(
              badge: 'R',
              color: AppColors.gualdaDeep,
              title: tr('단어 카드'),
              subtitle: 'Carte',
              onTap: () => openFull(context, (_) => const WordFlashcardScreen()),
            ),
            _NavRow(
              badge: '🎙',
              color: AppColors.rojoDeep,
              title: tr('문장 말하기'),
              subtitle: 'Parlare',
              onTap: () => openFull(context, (_) => const SpeakingPracticeScreen()),
            ),
            _NavRow(
              badge: 'G',
              color: AppColors.rojoDeep,
              title: tr('문법'),
              subtitle: tr('강의 · 테스트'),
              onTap: () => openPane(context, (_) => const GrammarHubScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

/// 복습 「이어서 학습」 — 회화 노트의 첫 미완료 에피소드와 실제 진행도(턴 학습 체크).
class _TodayMission extends StatefulWidget {
  const _TodayMission();

  @override
  State<_TodayMission> createState() => _TodayMissionState();
}

class _TodayMissionState extends State<_TodayMission> {
  EpisodeMeta? _meta;
  int _learned = 0;
  int _total = 40;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await EpisodeCatalog.instance.ensureLoaded();
    final all = EpisodeCatalog.instance.all;
    if (all.isEmpty) return;
    final turns = await appDb.select(appDb.turns).get();
    final progress = await appDb.select(appDb.userProgress).get();
    final learnedIds = progress.where((p) => p.learned).map((p) => p.turnId).toSet();
    for (final meta in all) {
      final epTurns = turns.where((t) => t.level == meta.level && t.episodeId == meta.id).toList();
      final total = epTurns.length;
      final learned = epTurns.where((t) => learnedIds.contains(t.id)).length;
      if (total == 0 || learned < total || meta == all.last) {
        if (mounted) {
          setState(() {
            _meta = meta;
            _learned = learned;
            _total = total == 0 ? 40 : total;
          });
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    if (meta == null) return const SizedBox(height: 120);
    final ratio = _total == 0 ? 0.0 : _learned / _total;
    return InkWell(
      onTap: () async {
        await openFull(context, (_) => EpisodeScreen(meta: meta));
        _load();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.beniDeep, AppColors.beni],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('회화 노트'),
              style: const TextStyle(color: AppColors.beniLight, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2),
            ),
            const SizedBox(height: 6),
            Text(
              '${meta.emoji} ${meta.level} · ${meta.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.cal, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: AppColors.beniDeep,
                color: AppColors.beniLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              trf('{0} / {1} 턴 학습', [_learned, _total]),
              style: const TextStyle(color: AppColors.cal, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────── 탐색 ──────────

/// 탐색: 청크 검색 · 단어 · 표현 · 절벽 단어 · 동사 활용 · 문법 — 참고 자료는 오른쪽 칸에.
class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
          children: [
            _TabTitle(tr('탐색')),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => openPane(context, (_) => const ChunkSearchScreen()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.washiDeep,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.beni, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr('단어·구 또는 한국어 뜻으로 검색'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _section(tr('단어')),
            _NavRow(
              badge: 'F',
              color: AppColors.italia,
              title: tr('절벽 단어'),
              subtitle: 'R1~R5',
              onTap: () => openPane(context, (_) => const WordFreqScreen()),
            ),
            _NavRow(
              badge: 'W',
              color: AppColors.oliva,
              title: tr('단어'),
              subtitle: 'Vocabolario',
              onTap: () => openPane(context, (_) => const TopicVocabScreen()),
            ),
            _NavRow(
              badge: 'E',
              color: AppColors.rojoLight,
              title: tr('표현'),
              subtitle: 'Espressione',
              onTap: () => openPane(
                  context, (_) => TopicVocabScreen(title: tr('주제별 표현'), asset: 'assets/data/vocab/travel_expressions.json')),
            ),
            _section(tr('문법')),
            _NavRow(
              badge: 'V',
              color: AppColors.irregular,
              title: tr('동사 활용'),
              subtitle: 'Coniugazione',
              onTap: () => openPane(context, (_) => const VerbScreen()),
            ),
            _NavRow(
              badge: 'G',
              color: AppColors.rojoDeep,
              title: tr('문법'),
              subtitle: 'Grammatica',
              onTap: () => openPane(context, (_) => const GrammarHubScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────── 프로필 ──────────

/// 프로필: 계정 · 성과 · 기록 · 학습자 프로필 · 설정 · 정보.
class MeTab extends StatelessWidget {
  const MeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
          children: [
            _TabTitle(tr('프로필')),
            const SizedBox(height: 12),
            const ProfileSections(),
          ],
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  final String title;
  const _ComingSoon({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          tr('Próximamente · 준비 중'),
          style: const TextStyle(color: AppColors.tintaLight, letterSpacing: 2),
        ),
      ),
    );
  }
}
