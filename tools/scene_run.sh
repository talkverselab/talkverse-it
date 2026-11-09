#!/bin/zsh
# 편 하나의 장면 컷을 Grok 새 방에서 만든다(프롬프트 최소화). 사용: tools/scene_run.sh <편.json> [--female]
# 첫 메시지 = 첨부 4개(인물 그림·화면 톤·규칙·컷 목록) + 한 줄, 그다음 컷은 「cutN」 한 줄. 결과 data/review/art/<편id>[_f]/cutN.jpg
cd "$(dirname "$0")/.."
out=$(python3 tools/scene_doc.py "$@" | tail -1); dir=$(dirname ${out% *}); n=${out##* }
/usr/bin/python3 - <<'P'
import sys; sys.path.insert(0,'/Users/talkverse/Hanja/tools'); import grok_cdp as g, time
g.BASE='http://127.0.0.1:9238'; c=g.CDP(g.tab('grok.com')); c.call('Page.navigate', url='https://grok.com/'); time.sleep(6)
P
R=$PWD; A="$R/data/review/art/chars_it_v2.jpg,$R/data/review/uxui/sian_it_01.jpg,$R/data/review/art/scene_rules_it.md,$R/$dir/scenes.md"
first=1
for k in $(seq 1 $n); do
  [ -s $dir/cut$k.jpg ] && { echo "있음 cut$k"; continue; }
  if [ $first -eq 1 ]; then echo "첨부 규칙 파일과 컷 목록 파일대로 그린다. 앞으로 cutN 한 줄만 보낸다. cut$k" > $dir/cut${k}_msg.txt; att=(--attach $A); first=0
  else echo "cut$k" > $dir/cut${k}_msg.txt; att=(); fi
  /usr/bin/python3 tools/grok_image.py $dir/cut${k}_msg.txt $dir/cut$k.jpg --tab grok.com $att --wait 180 2>&1 | tail -1
  sleep 90   # 한 번에 몰아 보내지 않는다(사용자 지시 2026-11-09)
done
