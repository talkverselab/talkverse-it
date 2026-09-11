import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../main.dart';
import '../widgets/spanish_decor.dart';
import 'chunk_search_screen.dart';
import 'conversation_screen.dart';
import 'episode_screen.dart';
import 'grammar_lesson_screen.dart';
import 'profile_screen.dart';
import 'sentence_flashcard_screen.dart';
import 'speaking_practice_screen.dart';
import 'progress_screen.dart';
import 'topic_vocab_screen.dart';
import 'verb_screen.dart';
import 'word_flashcard_screen.dart';
import 'word_freq_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    ConversationScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  static const List<NavigationDestination> _tabs = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
    NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: '학습'),
    NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: '진행'),
    NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '프로필'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _tabs,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      body: Stack(
        children: [
          const Positioned.fill(child: AzulejoPattern(opacity: 0.06)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text(
                                '¡Hola!',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.rojo,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text('👋', style: TextStyle(fontSize: 22)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '한국 학습자, 오늘도 시작해요',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.tintaLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const StreakChip(days: 1),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.cal,
                        border: Border.all(color: AppColors.gualda),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: AppColors.rojo, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  '오늘의 학습',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tinta,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const _TodayMission(),
                const SizedBox(height: 22),
                Row(
                  children: const [
                    SolMark(size: 22),
                    SizedBox(width: 8),
                    Text(
                      '메인 메뉴',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.tinta,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _MenuGrid(),
                const SizedBox(height: 28),
                const BandDivider(),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    '이탈리아어유니버스 · 2026',
                    style: TextStyle(
                      color: AppColors.tintaLight,
                      fontSize: 11,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 홈 '오늘의 학습' — 첫 미완료 에피소드와 실제 진행도 연결.
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
      final epTurns = turns
          .where((t) => t.level == meta.level && t.episodeId == meta.id)
          .toList();
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
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EpisodeScreen(meta: meta)),
        );
        _load();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.rojoDeep, AppColors.rojo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gualda, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meta.level == 'L1' ? 'PRINCIPIANTE 1' : meta.level,
              style: const TextStyle(
                color: AppColors.gualdaBright,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${meta.level} · ${meta.title}',
              style: const TextStyle(
                color: AppColors.cal,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Minjun & Lucía 스토리 ${meta.emoji}',
              style: TextStyle(color: AppColors.cal.withValues(alpha: 0.85), fontSize: 12),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: AppColors.rojoDeep,
                color: AppColors.gualda,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$_learned / $_total turn',
              style: const TextStyle(color: AppColors.cal, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(label: '회화', sub: 'Conversazione', badge: 'Ch', color: AppColors.rojo,
        builder: (_) => const ConversationScreen()),
      _MenuItem(label: '문법', sub: 'Grammatica', badge: 'G', color: AppColors.rojoDeep,
        builder: (_) => const GrammarHubScreen()),
      _MenuItem(label: '문장 카드', sub: 'Frasi', badge: 'S', color: AppColors.tinta,
        builder: (_) => const SentenceFlashcardScreen()),
      _MenuItem(label: '말하기', sub: 'Parlare', badge: '🎙', color: AppColors.rojo,
        builder: (_) => const SpeakingPracticeScreen()),
      _MenuItem(label: '청크 검색', sub: 'Ricerca', badge: '🔍', color: AppColors.gualdaDeep,
        builder: (_) => const ChunkSearchScreen()),
      _MenuItem(label: '동사 활용', sub: 'Coniugazione', badge: 'V', color: AppColors.irregular,
        builder: (_) => const VerbScreen()),
      _MenuItem(label: '단어', sub: 'Vocabolario', badge: 'W', color: AppColors.oliva,
        builder: (_) => const TopicVocabScreen()),
      _MenuItem(label: '표현', sub: 'Espressione', badge: 'E', color: AppColors.rojoLight,
        builder: (_) => const TopicVocabScreen(
            title: '주제별 표현',
            asset: 'assets/data/vocab/travel_expressions.json')),
      _MenuItem(label: '빈도 단어', sub: 'Frequenza', badge: 'F', color: AppColors.gualda,
        builder: (_) => const WordFreqScreen()),
      _MenuItem(label: '성·수', sub: 'Genere', badge: 'el/la', color: AppColors.mar,
        builder: (_) => const _ComingSoon(title: '성·수 일치')),
      _MenuItem(label: '발음', sub: 'Pronuncia', badge: 'rr', color: AppColors.er,
        builder: (_) => const _ComingSoon(title: '발음 (rr · ñ · 강세)')),
      _MenuItem(label: '단어 카드', sub: 'Carte', badge: 'R', color: AppColors.gualdaDeep,
        builder: (_) => const WordFlashcardScreen()),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _MenuTile(item: items[i]),
    );
  }
}

class _MenuItem {
  final String label;
  final String sub;
  final String badge;
  final Color color;
  final WidgetBuilder builder;
  _MenuItem({
    required this.label,
    required this.sub,
    required this.badge,
    required this.color,
    required this.builder,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: item.builder)),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cal,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gualda.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.tinta.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TileBadge(text: item.badge, size: 44, color: item.color),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tinta,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.sub,
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

class _ComingSoon extends StatelessWidget {
  final String title;
  const _ComingSoon({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Text(
          'Próximamente · 준비 중',
          style: TextStyle(color: AppColors.tintaLight, letterSpacing: 2),
        ),
      ),
    );
  }
}
