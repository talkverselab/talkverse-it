import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 통합 앱(Talkverse, com.talkverse.app) 안에 패키지로 들어갔는지 — `embedInit()` 이 정한다(2026-11-09, EMBED_GUIDE).
/// 단독 앱(이탈리아어유니버스)에서는 false 이고 모든 동작이 예전과 같다.
bool embedded = false;

/// 이 언어의 저장 이름 접두(설정 키·기기 폴더·DB 파일). 다른 언어 패키지와 겹치지 않게.
const storePrefix = 'it_';

const _pkg = 'packages/italian_universe/';

/// 에셋 경로 — 패키지로 들어가면 Flutter 가 `packages/italian_universe/` 아래에 둔다.
String assetPath(String p) => embedded && !p.startsWith('packages/') ? '$_pkg$p' : p;

/// AssetManifest 의 키 → 앱 안 상대 경로(`assets/...`). 패키지 접두가 있으면 뗀다.
String stripAssetPrefix(String p) => p.startsWith(_pkg) ? p.substring(_pkg.length) : p;

String? _dir;

/// 이 언어 전용 기기 저장 폴더(Application Support/it). 단독 앱의 옛 위치(Application Support/art)는 처음 한 번 옮긴다.
Future<String> dataDir() async {
  if (_dir != null) return _dir!;
  final base = (await getApplicationSupportDirectory()).path;
  final d = Directory('$base/it');
  if (!d.existsSync()) d.createSync(recursive: true);
  if (!embedded) {
    for (final name in const ['art']) {
      final old = '$base/$name', now = '${d.path}/$name';
      try {
        if (FileSystemEntity.typeSync(old) != FileSystemEntityType.notFound && FileSystemEntity.typeSync(now) == FileSystemEntityType.notFound) {
          await (FileSystemEntity.isDirectorySync(old) ? Directory(old).rename(now) : File(old).rename(now));
        }
      } catch (_) {}
    }
  }
  return _dir = d.path;
}
