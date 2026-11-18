#!/bin/zsh
# 회화 Grok 재작성 회차(M4 크롬 9238, 「빠른」 모드 — 11-18). 방 하나에 N편 — 첫 메시지만 규칙 첨부, 이후 파일 이름 한 줄(사용자 지시 11-09 프롬프트 최소화).
#   zsh tools/grok/rewrite_run.sh <편id>...     결과 data/review/grok/out/<id>.md
# 전: python3 tools/grok/it_dialogue_txt.py export(대사 칸 비운 뼈대) / 후: it_dialogue_txt.py import → check_dialogues.py --fix-rd → add_lemmas.py
cd "$(dirname "$0")/../.."
export GROK_CDP_PORT=9238
first=${TMPDIR:-/tmp}/grok_it_first.txt
mkdir -p data/review/grok/out
chat=""
for id in "$@"; do
  out=data/review/grok/out/$id.md
  [[ -s $out ]] && { echo "skip $id"; continue; }
  if [[ -z $chat ]]; then
    print -r -- "첨부한 rewrite_grok_it.md 가 이 방의 규칙이다. 앞으로는 파일 이름 한 줄만 보낸다. 첫 편: $id.txt${GROK_NOTE:+ $GROK_NOTE}" > $first
    r=$(python3 tools/grok/grok_text.py $first $out tools/grok/rewrite_grok_it.md data/review/grok/skel/$id.txt 2>&1)
  else
    r=$(python3 tools/grok/grok_text.py -m "$id.txt" $out data/review/grok/skel/$id.txt --chat "$chat" 2>&1)
  fi
  rc=$?
  echo "$(date +%H:%M) $id rc=$rc $(echo $r | grep -E "저장|LIMIT|TIMEOUT|빠른|Error|오류" | tr '\n' ' ')"
  [[ $rc -eq 3 ]] && { echo "LIMIT — 멈춤"; exit 3; }
  c=$(echo $r | grep -o 'CHAT [^ ]*' | tail -1 | awk '{print $2}' | sed 's/?.*//'); [[ -n $c ]] && chat=$c
  sleep 20
done
echo "끝 $chat"
