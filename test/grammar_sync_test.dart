import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:italian_universe/screens/grammar_lesson_screen.dart';
import 'package:italian_universe/screens/sense_course_screen.dart';
import 'package:italian_universe/services/script_sync.dart';

String sha(String s) => sha1.convert(utf8.encode(s)).toString().substring(0, 12);

/// 문법 스텝 서버 받기(2026-11-23 사용자 「스텝 10 까지 다 미리 만들어놓고 DB업데이트 하면서 업뎃되게」).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  final saved = ScriptSync.instance;
  setUp(() => dir = Directory.systemTemp.createTempSync('grammar_sync'));
  tearDown(() {
    ScriptSync.instance = saved;
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('서버 원고가 없으면 앱 안 문법 파일, 빈 스텝(2~15)은 숨김', () async {
    ScriptSync.instance = ScriptSync.forTest(dir: dir, fetch: (_) async => null, baseline: {'rev': 4, 'files': {}});
    final l = await GrammarLesson.loadAll();
    expect(l.map((e) => e.number), [1]);
    expect(l.first.patterns, isNotEmpty);
  });

  test('서버 원고가 있으면 그것 — 1 덮어씀, 2 는 비어 숨김, 3·12 는 새로 나타남', () async {
    final one = json.encode({'lesson': 1, 'title': '서버 1', 'patterns': [{'examples': []}]});
    final two = json.encode({'lesson': 2, 'title': '빈 스텝', 'patterns': []});
    final three = json.encode({'lesson': 3, 'title': '서버 3', 'stages': [{'t': 'x'}]});
    final twelve = json.encode({'lesson': 12, 'title': '서버 12', 'patterns': [{'examples': []}]});
    final files = {'grammar/lesson1.json': one, 'grammar/lesson2.json': two, 'grammar/lesson3.json': three, 'grammar/lesson12.json': twelve, 'grammar/lesson17.json': twelve.replaceAll('12', '17')};
    Future<String?> fetch(String url) async {
      if (url.endsWith('/index.json')) return json.encode({'rev': 5, 'files': {for (final e in files.entries) e.key: sha(e.value)}});
      for (final e in files.entries) {
        if (url.contains(e.key)) return e.value;
      }
      return null;
    }

    final s = ScriptSync.forTest(dir: dir, fetch: fetch, baseline: {'rev': 4, 'files': {'grammar/lesson1.json': 'old'}});
    ScriptSync.instance = s;
    expect(await s.refresh(), isTrue);
    final l = await GrammarLesson.loadAll();
    expect(l.map((e) => e.number), [1, 3, 12, 17]);
    expect(l.first.title, '서버 1');
  });

  test('서버 목록에서 빠진 스텝은 안 보임(묶음에 있어도)', () async {
    final three = json.encode({'lesson': 3, 'title': '서버 3', 'patterns': [{'examples': []}]});
    Future<String?> fetch(String url) async {
      if (url.endsWith('/index.json')) return json.encode({'rev': 5, 'files': {'grammar/lesson3.json': sha(three)}});
      if (url.contains('grammar/lesson3.json')) return three;
      return null;
    }

    final s = ScriptSync.forTest(dir: dir, fetch: fetch, baseline: {'rev': 4, 'files': {'grammar/lesson1.json': 'old'}});
    ScriptSync.instance = s;
    expect(await s.refresh(), isTrue);
    expect((await GrammarLesson.loadAll()).map((e) => e.number), [3]);
  });

  test('언어감각: 내용 없는 스텝은 숨김(서버에 문장이 오면 나타남)', () {
    final d = {
      'levels': [
        {'id': 'L1', 'lessons': [{'id': 'L1-talk', 'kind': 'memorize', 'sentences': [{'it': 'Ciao'}]}, {'id': 'L1-ref', 'kind': 'ref'}]},
        {'id': 'L2', 'lessons': [{'id': 'L2-talk', 'kind': 'memorize', 'sentences': []}, {'id': 'L2-ref', 'kind': 'ref'}]},
        {'id': 'L3', 'lessons': []},
      ],
    };
    final v = SenseCourse.visible(d);
    expect([for (final l in v['levels'] as List) (l as Map)['id']], ['L1']);
  });

  test('앱 안 언어감각 과정은 10스텝 모두 내용 있음', () async {
    ScriptSync.instance = ScriptSync.forTest(dir: dir, fetch: (_) async => null, baseline: {'rev': 4, 'files': {}});
    final d = await SenseCourse.load();
    expect((d['levels'] as List).length, 10);
  });
}
