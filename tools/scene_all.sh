#!/bin/zsh
# 전편 장면 컷(남성 학습자판) — 편마다 새 방, 이미 있는 컷은 건너뜀. 로그 ~/tts_work/it/scene_all.log
cd "$(dirname "$0")/.."
# 한 번에 너무 많이 주지 않는다(사용자 지시 2026-11-09): 컷 사이 90초, 편 사이 5분, 한 번 실행에 최대 N편(기본 3)
N=${1:-3}; done_n=0
for f in $(ls assets/data/dialogues/R*/*/*.json | sort); do
  id=$(basename $f .json); c=$(python3 -c "import json;print((len(json.load(open('$f'))['turns'])+1)//2)")
  have=$(ls data/review/art/$id/cut*.jpg 2>/dev/null | wc -l | tr -d ' ')
  [ "$have" -ge "$c" ] && continue
  [ $done_n -ge $N ] && break
  echo "$(date +%H:%M) $f"
  zsh tools/scene_run.sh $f 2>&1 | grep -v '^있음'
  done_n=$((done_n+1)); sleep 300
done
echo "$(date +%H:%M) 끝"
