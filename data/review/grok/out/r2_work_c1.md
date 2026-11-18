=== r2_work_c1
level: R2
kind: chat
title: 마르코 대신 출근
emoji: ☕
scene: 새벽 여섯 시, 감기 걸린 바리스타 마르코가 학습자에게 오늘 카페를 맡아 달라고 문자를 보낸다
cast: A: {name}(학습자, 한국인 20대, 남녀 모두) / B: Marco(남, 20대 후반 동네 카페 바리스타 — 말수 적은데 한마디가 웃김)
register: 채팅 반말
twist: 5 ignore
goal: 챗 상황 6 취소 · 4 늦음 · 7 농담 · 10 다음 약속 · 표현 Tranquillo · Mamma mia · Ti prego
expressions: Tranquillo; Mamma mia; Ti prego
steps(tags 의 step:N): 1 첫 인사 · 2 사진 · 3 약속 · 4 늦음 · 5 사과 · 6 취소 · 7 농담 · 8 오해 · 9 화해 · 10 다음 약속
B | Mamma mia, sono malato. 🤒 | 맙소사, 나 아팠어. 🤒 | Mamma mia = 맙소사 | emotion=worried | tags=step:6 | at=06:10
A | Cosa? Aprire io? Ora? | 뭐? 내가 열어? 지금? | | emotion=surprised | tags=step:6 | at=06:12
B | Sì, ti prego. Tranquillo. | 응, 제발. 진정해. | Ti prego = 제발 | emotion=neutral | tags=step:6 | at=06:13
A | Sono in ritardo. Scusa. | 나 늦었어. 미안. | | emotion=worried | tags=step:8 | at=07:30
A | Dove sei? Non rispondi. | 어디야? 답장 안 해. | | emotion=worried | tags=step:4,twist | at=07:31 | read=false
A | Ti prego, leggi i messaggi! | 제발, 메시지 읽어! | Ti prego = 제발 | emotion=flustered | tags=step:4 | at=07:36 | read=false
B | Boh, dormivo ancora. 😂 | 뭐, 아직 자고 있었어. 😂 | Boh = 뭐 | emotion=amused | tags=step:7 | at=08:02
B | Tranquillo, domani va bene. | 진정해, 내일 괜찮아. | Tranquillo = 진정해 | emotion=teasing | tags=step:10 | at=08:03
