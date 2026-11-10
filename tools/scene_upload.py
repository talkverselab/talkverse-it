#!/usr/bin/python3
"""이탈리아어 장면 컷(data/review/art/<편id>/cutN.jpg)을 Cloudflare R2(talkverse-art) + D1(talkverse-db.art_scenes)에 직접 올린다(사용자 지시 2026-11-03, uk 세션이 더는 ja 를 쓸어 올리지 않음).
규칙 = talkverse-uk tools/grok_art.py scene(): 원본 가로 1000 이상·3:2(±5%)만, webp q86 원본 크기 → scene/it/<ep>/cut<N>.webp, 가로 584 → cut<N>_584.webp,
D1 INSERT OR REPLACE(키에 ?v= 붙이지 않음 — 매니페스트가 sha1 앞 8자리로 붙인다). D1 의 sha1 과 같으면 건너뜀.
  /usr/bin/python3 tools/scene_upload.py [편id ...]   (없으면 data/review/art 의 편 폴더 전부, _old 제외)
운영 R2·D1 에 쓰므로 실행은 사용자 승인 뒤(2026-11-03 자동 모드가 막음)."""
import datetime, hashlib, json, os, re, subprocess, sys, tempfile
ART = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'data/review/art')
CWD = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W = ['npx', '-y', 'wrangler@4']


def wr(args):
    return subprocess.run(W + args, cwd=CWD, capture_output=True, text=True)


def d1_sha():
    r = wr(['d1', 'execute', 'talkverse-db', '--remote', '--json', '--command', "SELECT episode,cut,sha1 FROM art_scenes WHERE lang='it'"])
    rows = json.loads(r.stdout)[0]['results']
    return {(x['episode'], int(x['cut'])): x['sha1'] for x in rows}


def size(p):
    o = subprocess.run(['sips', '-g', 'pixelWidth', '-g', 'pixelHeight', p], capture_output=True, text=True).stdout.split()
    return int(o[o.index('pixelWidth:') + 1]), int(o[o.index('pixelHeight:') + 1])


def main():
    eps = sys.argv[1:] or sorted(x for x in os.listdir(ART) if re.fullmatch(r'r\d_[a-z]+_[a-z]\d+(_f)?', x))
    have = d1_sha()
    sql, n_up, n_skip, bad = [], 0, 0, []
    tmp = tempfile.mkdtemp()
    now = datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
    for ep in eps:
        if not re.fullmatch(r'[A-Za-z0-9_]+', ep):
            bad.append(ep); continue
        d = os.path.join(ART, ep)
        if not os.path.isdir(d):
            continue
        for fn in sorted(os.listdir(d)):
            m = re.fullmatch(r'cut(\d+)\.jpg', fn)
            if not m:
                continue
            n, src = int(m.group(1)), os.path.join(d, fn)
            sha = hashlib.sha1(open(src, 'rb').read()).hexdigest()
            if have.get((ep, n)) == sha:
                n_skip += 1; continue
            w, h = size(src)
            if w < 1000 or abs(w / h - 1.5) > 0.075:
                bad.append(f'{ep}/{fn} {w}x{h}'); continue
            big, small = os.path.join(tmp, f'{ep}_{n}.webp'), os.path.join(tmp, f'{ep}_{n}_584.webp')
            subprocess.run(['cwebp', '-quiet', '-q', '86', src, '-o', big], check=True)
            subprocess.run(['cwebp', '-quiet', '-q', '86', '-resize', '584', '0', src, '-o', small], check=True)
            k1, k2 = f'scene/it/{ep}/cut{n}.webp', f'scene/it/{ep}/cut{n}_584.webp'
            for k, f in ((k1, big), (k2, small)):
                r = wr(['r2', 'object', 'put', f'talkverse-art/{k}', '--file', f, '--content-type', 'image/webp', '--remote'])
                if r.returncode != 0:
                    print('R2 실패', k, r.stderr[-300:], flush=True); sys.exit(1)
            sql.append(f"INSERT OR REPLACE INTO art_scenes (lang, episode, cut, key_1168, key_584, w, h, sha1, created_at) "
                       f"VALUES ('it','{ep}',{n},'{k1}','{k2}',{w},{h},'{sha}','{now}');")
            n_up += 1
            print('UP', ep, n, flush=True)
    if sql:
        f = os.path.join(tmp, 'x.sql')
        open(f, 'w').write('\n'.join(sql) + '\n')
        r = wr(['d1', 'execute', 'talkverse-db', '--remote', '--file', f, '-y'])
        if r.returncode != 0:
            print('D1 실패', r.stderr[-400:], flush=True); sys.exit(1)
    print(f'DONE 올림 {n_up} · 같아서 건너뜀 {n_skip} · 규격 밖 {len(bad)}', ' '.join(bad[:10]), flush=True)


main()
