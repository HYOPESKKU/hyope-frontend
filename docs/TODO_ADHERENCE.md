# 복약·식사 이행 여부 (보류 — 백엔드 선행)

> 2026-08-13 조사. 팀 판단으로 **백엔드 작업을 먼저 하기로 해서 보류.**
> 재개할 때 이 문서부터 읽으면 된다.

## 요청

"복약/식사 여부를 ai-server에서 체크해서 보내야 한다."

## 현재 상태

`hyope-ai-server` `serve/assess.py:174`가 **빈 목록을 반환한다.**

```python
def _adherence(logic_data: dict) -> list:
    """...⚠ 미구현이며 팀 협의가 필요한 부분이다."""
    return []
```

감정 분류 모델은 이것과 **무관하다.** 모델은 발화의 감정을 볼 뿐이고,
이행 여부는 척도 문항의 예/아니오에서 나와야 한다.

## 구조적 문제 — 통화는 하루 한 번, 끼니는 세 번

백엔드 스키마는 끼니를 나눠 받는다.

```java
// AiCallResult.AdherenceRecordData
private AdherenceType adherenceType;  // MEAL | MEDICATION
private Slot slot;                    // BREAKFAST | LUNCH | DINNER
private boolean isNeeded;
private boolean isDone;
```

그런데 통화는 하루 한 번이다. 게다가 **통화 시각에 따라 물어볼 수 있는 끼니가
정해진다** — 오전 통화라면 그날 저녁은 아직 일어나지 않은 일이라 물어볼 수가
없다. "세 끼를 다 확인하기 어렵다"가 아니라 **일부는 물리적으로 불가능하다.**

## 결론 — 확인한 슬롯만 보내면 된다

세 끼를 뭉뚱그리거나 스키마를 바꿀 필요가 없다. 프론트가 이미 처리한다.

```dart
// utils/adherence_utils.dart:63
AdherenceRecord? findAdherence(assessment, type, slot) { ... return null; }

// :87
AdherenceStatusInfo statusFromRecord(record) {
  if (record == null) return AdherenceStatusInfo.unknown;    // "미확인"
  if (!record.isNeeded) return AdherenceStatusInfo.notNeeded; // "불필요"
  return record.isDone ? done : missed;
}

// :74 — isNeeded인 것만 모아 집계
final records = ...where((r) => r.adherenceType == type && r.isNeeded);
if (records.isEmpty) return notNeeded;
if (doneCount == records.length) return done;
```

**레코드를 안 보낸 슬롯은 "미확인"으로 뜨고, 집계는 보낸 것만으로 계산된다.**

| 보낸 것 | 화면 |
|---|---|
| 아침 `is_done: true` | 아침 = 완료, 점심·저녁 = **미확인**, 집계 = 완료 |

스키마 변경 0, 백엔드 변경 0, 프론트 변경 0.

### 하면 안 되는 것

**세 끼에 같은 값 넣기** — "밥 잘 드셨어요?" → "응" 하나로 세 끼를 완료로
찍으면, 실제로 점심을 걸렀어도 화면엔 완료로 뜬다. 돌봄 서비스에서 보호자가
놓치는 신호가 생긴다.

**안 물어본 슬롯을 `is_needed: false`로 채우기** — 그건 "불필요"로 표시되는데
"이 어르신은 점심약을 안 드심"이라는 뜻이다. "우리가 안 물어봤다"와 의미가
다르고, 프론트가 이미 두 라벨을 구분해 놨다.

## 남은 작업 — brain.py 쪽

`assess.py`가 뽑아낼 원본이 없는 것이 진짜 병목이다. 지금 `logic_data`는
카테고리 판정만 담고 문항별 예/아니오를 남기지 않는다.

1. `hyope-call-agent`의 `brain.py`가 복약·식사 문항의 답을 **슬롯별로**
   `logic_data`에 기록
2. `serve/assess.py:_adherence()`가 그것을 `AdherenceRecordData` 형식으로 변환
   (확인한 슬롯만, 안 물어본 슬롯은 아예 넣지 않음)

즉 **통화 에이전트 쪽 작업이 선행**이고, `serve`는 형식 변환만 하면 된다.
