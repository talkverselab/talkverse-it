#!/usr/bin/env python3
"""이탈리아어 → 한글 독음(rd) 변환기. 표기는 옛 L1 회화의 독음을 따른다(된소리 ㄲ·ㄸ·ㅃ, 어두 s = ㅆ, 모음 사이 s = ㅈ).

  python3 tools/rd_it.py "Ciao, mi chiamo Giulia."
틀린 곳은 턴에 손 독음 + rd_manual: true.
"""
import re
import sys
import unicodedata

CHO = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ'
JUNG = 'ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ'
JONG = ['', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ']
VOW = {'a': 'ㅏ', 'e': 'ㅔ', 'i': 'ㅣ', 'o': 'ㅗ', 'u': 'ㅜ'}
YV = {'a': 'ㅑ', 'o': 'ㅛ', 'u': 'ㅠ', 'e': 'ㅔ'}
SIMPLE = {'b': 'ㅂ', 'c': 'ㄲ', 'd': 'ㄷ', 'f': 'ㅍ', 'g': 'ㄱ', 'j': 'ㅈ', 'k': 'ㅋ', 'l': 'ㄹ', 'm': 'ㅁ', 'n': 'ㄴ',
          'p': 'ㅃ', 'r': 'ㄹ', 't': 'ㄸ', 'v': 'ㅂ', 'w': 'ㅂ', 'z': 'ㅉ'}
LOOSE = {'b': '브', 'c': '크', 'd': '드', 'f': '프', 'g': '그', 'j': '즈', 'k': '크', 'p': '프', 'r': '르', 's': '스', 't': '트', 'v': '브', 'w': '브', 'z': '츠'}


def syl(o, v, c=''):
    return chr(0xAC00 + CHO.index(o) * 588 + JUNG.index(v) * 28 + JONG.index(c))


def strip(w):
    return ''.join(ch for ch in unicodedata.normalize('NFD', w) if not unicodedata.combining(ch))


def word(w):
    w = strip(w.lower()).replace("'", '').replace('’', '')
    w = re.sub(r'(?<![cg])h', '', w)
    out = []  # [초성, 중성, 종성]
    i, n = 0, len(w)
    isv = lambda k: k < n and w[k] in 'aeiouy'

    def add(o, v):
        out.append([o, v, ''])

    def coda(c):
        if out and not out[-1][2]:
            out[-1][2] = c
        else:
            out.append(['ㅇ', 'ㅡ', '']); out[-1][0] = {'ㄴ': 'ㄴ', 'ㅁ': 'ㅁ', 'ㄹ': 'ㄹ'}[c]

    def palatal(o, k):
        """c·g·sc + e/i 뒤. k = e/i 자리. 돌려주는 값 = 다음 위치."""
        if w[k] == 'i' and k + 1 < n and w[k + 1] in 'aou':
            add(o, YV[w[k + 1]] if o != 'ㅈ' or w[k + 1] == 'a' else VOW[w[k + 1]])
            return k + 2
        add(o, VOW[w[k]])
        return k + 1

    while i < n:
        c = w[i]
        nx = w[i + 1] if i + 1 < n else ''
        if c in 'aeiou':
            add('ㅇ', VOW[c]); i += 1; continue
        if c == 'y':
            add('ㅇ', 'ㅣ'); i += 1; continue
        if c == 'h':
            i += 1; continue
        if c == 'x':
            out.append(['ㅋ', 'ㅡ', '']); out.append(['ㅅ', 'ㅡ', '']); i += 1; continue
        if c == 'q' or (c == 'c' and nx == 'q'):
            i += 1 if c == 'q' else 2
            if c == 'c':
                i += 0
            if i < n and w[i] == 'u':
                i += 1
            v = w[i] if i < n else ''
            if v in ('a', 'e', 'i'):
                add('ㄲ', {'a': 'ㅘ', 'e': 'ㅞ', 'i': 'ㅟ'}[v]); i += 1
            else:
                add('ㄲ', 'ㅜ')
            continue
        if c == 's' and nx == 'c' and i + 2 < n and w[i + 2] in 'ei':
            k = i + 2
            if w[k] == 'e':
                add('ㅅ', 'ㅖ'); i = k + 1
            elif k + 1 < n and w[k + 1] in 'aou':
                add('ㅅ', YV[w[k + 1]]); i = k + 2
            else:
                add('ㅅ', 'ㅣ'); i = k + 1
            continue
        if c in 'cg':
            dbl = nx == c
            j = i + 2 if dbl else i + 1
            if j < n and w[j] == 'h':  # ch·gh
                j += 1
                o = 'ㄲ' if c == 'c' else 'ㄱ'
                if j < n and w[j] == 'i' and j + 1 < n and w[j + 1] in 'aou':   # chia = 끼아(꺄 아님)
                    add(o, 'ㅣ'); i = j + 1
                elif j < n and w[j] in 'ei':
                    add(o, VOW[w[j]]); i = j + 1
                else:
                    out.append(['ㅋ' if c == 'c' else 'ㄱ', 'ㅡ', '']); i = j
                continue
            if j < n and w[j] in 'ei':
                glide = w[j] == 'i' and j + 1 < n and w[j + 1] in 'aou'
                i = palatal('ㅊ' if c == 'c' else ('ㅉ' if dbl and not glide else 'ㅈ'), j)
                continue
            if c == 'g' and nx == 'n' and i + 2 < n and w[i + 2] in 'aeiou':   # gn = 냐·녜·니·뇨·뉴
                v = w[i + 2]
                if v == 'i' and i + 3 < n and w[i + 3] in 'aeou':
                    i += 1; v = w[i + 2]
                add('ㄴ', {'a': 'ㅑ', 'e': 'ㅖ', 'i': 'ㅣ', 'o': 'ㅛ', 'u': 'ㅠ'}[v]); i += 3; continue
            if c == 'g' and nx == 'l' and i + 2 < n and w[i + 2] == 'i':
                if out:
                    coda('ㄹ')
                add('ㄹ', 'ㅣ'); i += 3; continue
            if isv(j):
                add(SIMPLE[c], VOW[w[j]]); i = j + 1
            else:
                out.append([('ㅋ' if c == 'c' else 'ㄱ'), 'ㅡ', '']); i = j
            continue
        if c == 's':
            if nx == 's':
                if isv(i + 2):
                    add('ㅆ', VOW[w[i + 2]]); i += 3
                else:
                    out.append(['ㅅ', 'ㅡ', '']); i += 2
                continue
            if isv(i + 1):
                o = 'ㅈ' if i > 0 and w[i - 1] in 'aeiou' else 'ㅆ'
                add(o, VOW[w[i + 1]]); i += 2
            else:
                out.append(['ㅅ', 'ㅡ', '']); i += 1
            continue
        if c in 'lmn' and nx == c:
            coda(SIMPLE[c])
            if isv(i + 2):
                add(SIMPLE[c], VOW[w[i + 2]]); i += 3
            else:
                i += 2
            continue
        if c == nx:  # 그 밖의 겹자음은 하나로
            i += 1
            continue
        if isv(i + 1):
            if c == 'l' and out and not out[-1][2] and i > 0 and (w[i - 1] in 'aeiou' or w[i - 1] == 'r' or out[-1][1] == 'ㅡ'):   # bl·pl·cl = 블·쁠·끌
                out[-1][2] = 'ㄹ'
            add(SIMPLE.get(c, 'ㅇ'), VOW[w[i + 1]] if w[i + 1] != 'y' else 'ㅣ'); i += 2
            continue
        if c == 'm' and i == n - 1 and out and out[-1][2] == 'ㄹ':
            out.append(['ㄹ', 'ㅡ', 'ㅁ'])
            i += 1
            continue
        if c == 'n' and nx == 'g' and i + 2 < n and w[i + 2] in 'aou' and out and not out[-1][2]:
            out[-1][2] = 'ㅇ'; i += 1
            continue
        if c in 'lmn':
            if out:
                coda(SIMPLE[c])
            else:
                out.append([SIMPLE[c], 'ㅡ', ''])
            i += 1
            continue
        if c in LOOSE:
            o = {'b': 'ㅂ', 'c': 'ㅋ', 'd': 'ㄷ', 'f': 'ㅍ', 'g': 'ㄱ', 'j': 'ㅈ', 'k': 'ㅋ', 'p': 'ㅍ', 'r': 'ㄹ', 't': 'ㅌ', 'v': 'ㅂ', 'w': 'ㅂ', 'z': 'ㅊ'}[c]
            out.append([o, 'ㅡ', '']); i += 1
            continue
        i += 1
    return ''.join(syl(*s) for s in out)


TOK = re.compile(r"\{[a-z_]+\}|[A-Za-zÀ-ÿ’']+")


def to_rd(text):
    return TOK.sub(lambda m: m.group(0) if m.group(0).startswith('{') else word(m.group(0)), text).replace('«', '"').replace('»', '"').replace('—', '-').replace('–', '-')


if __name__ == '__main__':
    print(to_rd(' '.join(sys.argv[1:])))
