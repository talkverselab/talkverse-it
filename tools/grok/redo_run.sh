#!/bin/zsh
# 리뷰 반영 고쳐 쓰기(11-19 사용자 지시 「니가 리뷰한대로 다시써달라고 해」). M4 크롬 9238 「빠른」, 방 하나에 15편.
#   zsh tools/grok/redo_run.sh [편id...]   (없으면 data/review/grok/review/ 의 편 전부)
# 첨부 = 지금 Grok 원문 out/<id>.md + 「## 리뷰」(review/<id>.txt) → 결과 out2/<id>.md. 뒤: 옛 out 을 out_r1/ 로, out2 를 out 으로 → it_dialogue_txt.py import
cd "$(dirname "$0")/../.."
export GROK_CDP_PORT=9238
R=data/review/grok
mkdir -p $R/redo $R/out2
ids=("$@"); (( $#ids )) || ids=($(ls $R/review | sed 's/.txt$//' | sort))
first=${TMPDIR:-/tmp}/grok_it_redo_first.txt
chat=""; n=0
for id in $ids; do
  out=$R/out2/$id.md
  [[ -s $out ]] && { echo "skip $id"; continue; }
  att=$R/redo/$id.txt
  { sed -n '/^===/,$p' $R/out/$id.md | grep -v '^```'; print; print '## 리뷰'; cat $R/review/$id.txt; } > $att
  if [[ -z $chat || $n -ge 15 ]]; then
    n=0
    print -r -- "첨부한 redo_grok_it.md 가 이 방의 규칙이다(rewrite_grok_it.md 도 함께). 앞으로는 파일 이름 한 줄만 보낸다. 첫 편: $id.txt" > $first
    r=$(python3 tools/grok/grok_text.py $first $out tools/grok/redo_grok_it.md tools/grok/rewrite_grok_it.md $att 2>&1)
  else
    r=$(python3 tools/grok/grok_text.py -m "$id.txt" $out $att --chat "$chat" 2>&1)
  fi
  rc=$?; n=$((n + 1))
  echo "$(date +%H:%M) $id rc=$rc $(echo $r | grep -E "저장|LIMIT|TIMEOUT|빠른|Error|오류" | tr '\n' ' ')"
  [[ $rc -eq 3 ]] && { echo "LIMIT — 멈춤"; exit 3; }
  c=$(echo $r | grep -o 'CHAT [^ ]*' | tail -1 | awk '{print $2}' | sed 's/?.*//'); [[ -n $c ]] && chat=$c
  sleep 20
done
echo "끝 $chat"
