#!/bin/zsh
# 리뷰 페이지 다시 만들기. uk 세션이 tools/publish_review.sh it 로 게시한다.
cd "$(dirname "$0")/.."
python3 tools/review_html.py data/review/REVIEW_it.html assets/data/dialogues/R*/*/*.json
