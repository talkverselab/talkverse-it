#!/usr/bin/env python3
"""초안 편 음성(MOSS): 참고 음성 → 문장 조각 → 받아쓰기 검사·재생성 → mp4·R2. 초안이라 D1 에는 넣지 않는다.
  <venv>/bin/python tools/tts/run_trial.py <작업폴더> <편id>...   venv = mlx-whisper 가 있는 파이썬.
PC 는 한 번에 한 세션 — uk 세션의 「지금 시작」을 받은 뒤에만 돌린다. 인도네시아어앱 trial.py 를 줄인 것."""
import glob, json, os, shutil, subprocess, sys, time
import numpy as np
import qa
import ttslib as L
PC = 'Administrator@100.127.143.37'; HERE = os.path.dirname(os.path.abspath(__file__))
work, eps = sys.argv[1], sys.argv[2:]
job = f'{work}/job'; wav = f'{work}/wav'; os.makedirs(job, exist_ok=True); os.makedirs(f'{wav}/retake', exist_ok=True)
log = lambda *a: print(time.strftime('%H:%M:%S'), *a, flush=True)


def sh(*a, check=True, **k):
    return subprocess.run(a, check=check, capture_output=True, text=True, **k)


def state():
    return sh('ssh', PC, "(Get-ScheduledTask -TaskName 'TTS job 2060').State", check=False).stdout


def pc_run():
    while 'Ready' not in state():
        time.sleep(30)
    for n in ('vox_jobs.json', 'moss_jobs.json'):
        if os.path.exists(f'{job}/{n}'):
            sh('scp', '-q', f'{job}/{n}', f'{PC}:D:/tts_test/job/')
        else:
            sh('ssh', PC, f'Remove-Item D:\\tts_test\\job\\{n} -ErrorAction SilentlyContinue', check=False)
    sh('ssh', PC, "Start-ScheduledTask -TaskName 'TTS job 2060'")
    time.sleep(20)
    while 'Ready' not in state():
        time.sleep(30)


def fetch(path, dst):
    os.makedirs(dst, exist_ok=True)
    sh('scp', '-q', '-r', f'{PC}:D:/tts_test/job/out/it/{path}', dst + '/', check=False)


def fetch_ref():
    sh('scp', '-q', '-r', f'{PC}:D:/tts_test/job/out/ref_it', f'{work}/ref', check=False)


def spectrum(f):
    o = subprocess.run(['ffmpeg', '-v', 'error', '-i', f, '-ac', '1', '-ar', '16000', '-f', 's16le', '-'], capture_output=True).stdout
    x = np.frombuffer(o[:len(o) // 2 * 2], dtype='<i2').astype(float)
    fr = x[:len(x) // 512 * 512].reshape(-1, 512)
    fr = fr[np.abs(fr).mean(1) > np.abs(fr).mean() * 0.5]      # 말소리 칸만
    return np.log(np.abs(np.fft.rfft(fr * np.hanning(512))).mean(0) + 1e-6)


def ref_bad():
    """잡음 바닥 > -60dB 또는 같은 목소리 기본 음성과의 음색 상관 < 0.90 인 파일 이름."""
    bad = []
    for p in sorted(glob.glob(f'{work}/ref/*.wav')):
        n = os.path.basename(p); v = n.rsplit('_', 1)[0]
        c = float(np.corrcoef(spectrum(p), spectrum(f'{work}/ref/{v}_base.wav'))[0, 1])
        if qa.floor(p) > -60 or c < 0.90:
            bad.append(n)
    return bad


for n in ('vox_jobs.json', 'moss_jobs.json'):
    if os.path.exists(f'{job}/{n}'):
        os.remove(f'{job}/{n}')
sh(sys.executable, f'{HERE}/make_plans.py', *eps)   # 회화 파일의 emotion·segs 가 원본
sh(sys.executable, f'{HERE}/make_jobs.py', job, '--refs', *eps)
refs = json.load(open(f'{job}/vox_jobs.json', encoding='utf-8'))
log(len(refs), '참고 음성'); pc_run()
for rnd in range(1, 3):        # 품질 기준 §5: 참고 음성 잡음·음색 — 미달은 PC 에서 지우고 seed 를 바꿔 다시
    shutil.rmtree(f'{work}/ref', ignore_errors=True); fetch_ref()
    bad = ref_bad()
    log('참고 음성 미달', len(bad), bad[:8])
    if not bad:
        break
    for n in bad:
        sh('ssh', PC, f'Remove-Item D:\\tts_test\\job\\out\\ref_it\\{n} -ErrorAction SilentlyContinue', check=False)
    json.dump([{**j, 'seed': 42 + 97 * rnd} for j in refs if os.path.basename(j['out']) in bad], open(f'{job}/vox_jobs.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    pc_run()
os.remove(f'{job}/vox_jobs.json')
log(sh(sys.executable, f'{HERE}/make_jobs.py', job, *eps).stdout.strip())
pc_run(); log('생성 끝')
for e in eps:
    fetch(e, wav)
for rnd in range(3):
    jobs = []
    for e in eps:
        q = f'{job}/qa_{e}.json'
        try:
            r = subprocess.run([sys.executable, f'{HERE}/qa.py', wav, e, '--jobs', q], capture_output=True, text=True, timeout=600)
            log(e, r.stdout.strip() or r.stderr.strip()[-300:])
        except subprocess.TimeoutExpired:
            log('TIMEOUT', e); continue
        if os.path.exists(q):
            jobs += json.load(open(q, encoding='utf-8')); os.remove(q)
    if not jobs:
        break
    json.dump(jobs, open(f'{job}/moss_jobs.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    if os.path.exists(f'{job}/vox_jobs.json'):
        os.remove(f'{job}/vox_jobs.json')
    pc_run()
    for e in eps:
        fetch(f'retake/{e}', f'{wav}/retake')
log('PC 끝')
for e in eps:
    r = sh(sys.executable, f'{HERE}/pack.py', wav, e, '--upload', '--no-db', check=False)
    log(r.stdout.strip() or (r.stderr or '')[-300:])
sh('zsh', f'{L.R}/tools/review_it.sh')
log('끝')
