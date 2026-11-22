#!/bin/zsh
# 언어감각 10과 리뷰 반영 고쳐 쓰기(11-22). 첨부 = Grok 원문 + 공통 리뷰 + 그 과 리뷰 → sense_out2/
cd "$(dirname "$0")/../.."
export GROK_CDP_PORT=9238
R=data/review/grok; mkdir -p $R/sense_redo $R/sense_out2
first=${TMPDIR:-/tmp}/grok_it_sredo_first.txt; chat=""
for f in $(ls $R/sense_skel | sort -V); do
  id=${f%.txt}; out=$R/sense_out2/$id.md; [[ -s $out ]] && continue
  att=$R/sense_redo/$f
  { grep -E '^(title|note|footnotes|marks):' $R/sense_skel/$f; sed -n '/^===/,$p' $R/sense_out/$id.md | grep -v '^```'; print; print '## 리뷰'; cat $R/sense_review/_all.txt $R/sense_review/$f 2>/dev/null; } > $att
  if [[ -z $chat ]]; then
    print -r -- "첨부한 sense_grok_it.md 가 이 방의 규칙이다. 첨부 과는 네가 전에 쓴 대화와 맨 아래 「## 리뷰」(검수자 지적, 턴1 = 첫 대사 줄)다. 리뷰가 짚은 줄을 문제가 풀리게 네 말로 새로 쓰고(흐름상 필요하면 주변 줄도), 화자·줄 수는 그대로, 리뷰 문장은 답에 옮기지 말 것. 답은 코드 블록 하나에 === 줄과 대사 줄만. 앞으로는 파일 이름 한 줄만 보낸다. 첫 과: $f" > $first
    r=$(python3 tools/grok/grok_text.py $first $out tools/grok/sense_grok_it.md $att 2>&1)
  else
    r=$(python3 tools/grok/grok_text.py -m "$f" $out $att --chat "$chat" 2>&1)
  fi
  rc=$?; echo "$(date +%H:%M) $id rc=$rc $(echo $r | grep -E "저장|LIMIT|TIMEOUT|빠른|오류" | tr '\n' ' ')"
  [[ $rc -eq 3 ]] && { echo LIMIT; exit 3; }
  c=$(echo $r | grep -o 'CHAT [^ ]*' | tail -1 | awk '{print $2}' | sed 's/?.*//'); [[ -n $c ]] && chat=$c
  sleep 20
done; echo "끝 $chat"
