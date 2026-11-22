#!/bin/zsh
# 언어감각 외울 대화 10과 Grok 재작성(11-22). M4 크롬 9238 「빠른」, 방 하나. 크롬은 이 작업 동안만(11-22 크롬 규칙).
#   python3 tools/grok/sense_txt.py export → zsh tools/grok/sense_run.sh → python3 tools/grok/sense_txt.py import
cd "$(dirname "$0")/../.."
export GROK_CDP_PORT=9238
S=data/review/grok/sense_skel; O=data/review/grok/sense_out
mkdir -p $O
first=${TMPDIR:-/tmp}/grok_it_sense_first.txt
chat=""
for f in $(ls $S | sort -V); do
  id=${f%.txt}; out=$O/$id.md
  [[ -s $out ]] && { echo "skip $id"; continue; }
  if [[ -z $chat ]]; then
    print -r -- "첨부한 sense_grok_it.md 가 이 방의 규칙이다. 앞으로는 파일 이름 한 줄만 보낸다. 첫 과: $f" > $first
    r=$(python3 tools/grok/grok_text.py $first $out tools/grok/sense_grok_it.md $S/$f 2>&1)
  else
    r=$(python3 tools/grok/grok_text.py -m "$f" $out $S/$f --chat "$chat" 2>&1)
  fi
  rc=$?
  echo "$(date +%H:%M) $id rc=$rc $(echo $r | grep -E "저장|LIMIT|TIMEOUT|빠른|Error|오류" | tr '\n' ' ')"
  [[ $rc -eq 3 ]] && { echo "LIMIT — 멈춤"; exit 3; }
  c=$(echo $r | grep -o 'CHAT [^ ]*' | tail -1 | awk '{print $2}' | sed 's/?.*//'); [[ -n $c ]] && chat=$c
  sleep 20
done
echo "끝 $chat"
