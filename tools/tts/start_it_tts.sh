#!/bin/zsh
# 3090 차례가 오면(앞 세션 「GPU 끝」) 실행: PC job.log·moss_jobs.json 이 5분 넘게 그대로인지 보고 회화 65편 MOSS 를 돌린다.
#   zsh tools/tts/start_it_tts.sh    → screen it-tts, 로그 ~/tts_work/it/w1123/run.log (끝나면 「끝」 줄)
set -e
ROOT=${0:A:h:h:h}; W=$HOME/tts_work/it/w1123
age=$(ssh Administrator@100.127.143.37 "[int]((Get-Date) - ((Get-Item D:\tts_test\job\job.log, D:\tts_test\job\moss_jobs.json | Sort LastWriteTime -Desc)[0].LastWriteTime)).TotalSeconds" | tr -d '\r')
echo "PC 작업 파일 마지막 변경 ${age}초 전"
[ "$age" -gt 300 ] || { echo "아직 5분 안 됨 — 시작 안 함"; exit 1; }
cd $ROOT
screen -dmS it-tts zsh -c "TTS_PASS=0.85 $HOME/tts_work/it/venv/bin/python tools/tts/run_trial.py $W \$(cat $W/eps.txt) >> $W/run.log 2>&1"
echo "시작: screen it-tts"
