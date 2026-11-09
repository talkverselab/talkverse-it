#!/usr/bin/python3
"""Grok 에 그림 1장 요청 → 생성이 끝날 때까지 기다려 jpg 로 저장(로그인된 전용 Chrome 안에서 받아 옴).
  /usr/bin/python3 tools/grok_image.py <요청문.md> <저장.jpg> [--tab 1b47fbcb] [--attach a.jpg,b.jpg] [--wait 180]
출력 마지막 줄: OK <저장.jpg> <답 글자 수> | NOIMAGE | TIMEOUT(생성 중지함)
보낸 뒤 3분(--wait)을 넘기면 그 방의 생성을 중지한다(사용자 지시 2026-11-10 "그록 3분만, 넘어가면 대화방 중지 — 토큰 낭비").
"""
import base64, os, subprocess, sys, time
sys.path.insert(0, '/Users/talkverse/Hanja/tools'); import grok_cdp as g
g.BASE = 'http://127.0.0.1:' + os.environ.get('GROK_CDP_PORT', '9238')
a = sys.argv[1:]; src, dst = a[0], a[1]
frag = a[a.index('--tab') + 1] if '--tab' in a else '1b47fbcb'
wait = int(a[a.index('--wait') + 1]) if '--wait' in a else 180
here = os.path.dirname(os.path.abspath(__file__))
GEN = "[...document.querySelectorAll('img')].filter(i=>i.src.includes('/generated/')&&i.complete&&i.naturalWidth>0).map(i=>i.src)"
before = set(g.CDP(g.tab(frag)).ev(GEN) or [])  # 보내기 전에 이미 있던 생성 이미지 — 새로 나타난 것만 받는다(같은 탭을 여러 작업이 써도 안전)
cmd = ['/usr/bin/python3', f'{here}/grok_send.py', src, dst + '.md', '--tab', frag, '--wait', '45', '--no-stop']
if '--attach' in a: cmd += ['--attach', a[a.index('--attach') + 1]]
t0 = time.time()  # 보낸 시각부터 센다
subprocess.run(cmd, capture_output=True, text=True)
while time.time() - t0 < wait:
    c = g.CDP(g.tab(frag))
    busy = c.ev("!![...document.querySelectorAll('button')].find(e=>(e.getAttribute('aria-label')||'')==='응답 중지')")
    new = [u for u in (c.ev(GEN) or []) if u not in before]
    if new and not busy:
        u = new[-1]
        r = c.call('Runtime.evaluate', expression=f"fetch('{u}',{{credentials:'include'}}).then(r=>r.blob()).then(b=>new Promise(res=>{{const f=new FileReader();f.onload=()=>res(f.result);f.readAsDataURL(b)}}))", awaitPromise=True, returnByValue=True)
        open(dst, 'wb').write(base64.b64decode(r['result']['value'].split(',', 1)[1]))
        open(dst + '.md', 'w', encoding='utf-8').write('[images]\n' + u + '\n')
        print('OK', dst, u[-50:]); sys.exit(0)
    time.sleep(8)
c = g.CDP(g.tab(frag))
hit = c.ev("""(()=>{const b=[...document.querySelectorAll('button')].find(e=>/중지|stop/i.test((e.getAttribute('aria-label')||'')+' '+e.innerText));if(b){b.click();return b.getAttribute('aria-label')||b.innerText}return ''})()""")
if not hit:
    for typ in ('keyDown', 'keyUp'):
        c.call('Input.dispatchKeyEvent', type=typ, key='Escape', code='Escape', windowsVirtualKeyCode=27, nativeVirtualKeyCode=27)
print('TIMEOUT stopped', hit or 'escape'); sys.exit(1)
