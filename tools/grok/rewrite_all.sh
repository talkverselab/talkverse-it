#!/bin/zsh
# 남은 편을 15편씩 방을 새로 열어 차례로(긴 방은 3분 TIMEOUT 오판 — uk 11-19, 한도 문구가 나오면 멈춤).
cd "$(dirname "$0")/../.."
ids=($(ls data/review/grok/skel | sed 's/.txt$//' | sort))
todo=(); for i in $ids; do [[ -s data/review/grok/out/$i.md ]] || todo+=$i; done
echo "남은 편 ${#todo}"
for ((k = 1; k <= ${#todo}; k += 15)); do
  zsh tools/grok/rewrite_run.sh ${todo[k,k+14]} || { echo "멈춤(한도 등)"; exit 3; }
done
echo "전부 끝"
