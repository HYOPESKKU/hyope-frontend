# 수정/삭제 기능 전수 조사

> 2026-08-12 조사, 백엔드 `9d3ef34` 기준. 할 일 필수 5번 *"피보호자 삭제기능 → 이거 이외에도 전반적으로 수정
> 가능한 정보들은 다 수정/삭제 기능이 들어가야 하는데 선택적으로 들어가있어요.
> 수정되는 건지 헷갈리는 것들은 공유해가면서 반영해주세요."* 에 대한 조사 결과.

프론트 화면·서비스와 백엔드 컨트롤러를 대조했다.

---

## 요약

| 대상 | 생성 | 조회 | 수정 | 삭제 | 비고 |
|---|---|---|---|---|---|
| 피보호자 | ✅ | ✅ | ✅ | **❌** | 백엔드 API는 있으나 **cascade 미비**(아래 참고) |
| ├ 취미 | AI | ✅ | AI | AI | **설계상 AI 전용.** 보호자 수정 불가가 의도 |
| └ 최근 근황 | AI | ✅ | AI | AI | 위와 동일 |
| 통화 예약 | ✅ | ✅ | ✅ | ✅ | 유일하게 완전함 |
| 내 프로필(보호자) | ✅ 가입 | ✅ | ✅ | **❌** | 백엔드 API는 있는데 프론트 미연결 |
| 알림 | — | ✅ | ✅ 읽음 | ❌ | 백엔드에도 삭제 API 없음 |

---

## 1. 피보호자 삭제 — 프론트만 없음 🔴

백엔드에 이미 있다.

```java
// RecipientController.java:41
@DeleteMapping("/recipients/{id}")
public ResponseEntity<RecipientResponse> delete(@PathVariable Long id)
```

프론트 `RecipientService`에는 `findByGuardian` / `readRecipient` /
`createRecipient` / `updateRecipient`만 있고 `delete`가 없다. UI에도 진입점이 없다.

### ⚠ 그런데 그냥 붙이면 안 된다 — cascade가 빠져 있다

`RecipientService`의 두 삭제 경로가 다르게 동작한다.

```java
// 개별 삭제 — 딸린 데이터 정리 없음
public RecipientResponse delete(Long id){
    Recipient target = recipientRepository.findById(id)...;
    recipientRepository.delete(target);          // 이게 전부
}

// 계정 탈퇴 시 — 자식들을 먼저 지운다
public void deleteAllByGuardianId(Long guardianId){
    for (Recipient recipient : recipients) {
        callLogService.deleteAllByRecipientId(...);
        callScheduleService.deleteAllByRecipientId(...);
        assessmentService.deleteAllByRecipientId(...);
    }
    ...
}
```

`Recipient` 엔티티에는 자식 컬렉션이 없어(`@ManyToOne`만 있음) JPA cascade도
걸려 있지 않다. 반면 `CallLog`·`Assessment`·`Hobby` 등은 `recipient_id`를
`nullable = false` 외래키로 들고 있다.

**→ 통화 기록이 있는 피보호자를 지우면 외래키 제약 위반으로 실패할 가능성이
높다.** 데이터가 없는 신규 피보호자만 지워지고, 정작 지우고 싶은 대상은
500이 난다.

**백엔드 수정이 선행돼야 한다.** `delete(id)`도 `deleteAllByGuardianId`처럼
자식을 먼저 정리하거나(프로필/취미/근황 포함), 엔티티에 cascade를 걸어야 한다.

프론트만 먼저 붙이면 "삭제 버튼을 눌렀는데 오류가 난다"가 되므로, 백엔드
담당자와 맞춘 뒤 진행하는 편이 낫다.

---

## 2. 취미 / 최근 근황 — 설계상 AI 전용 ✅

처음에는 "백엔드에 필드가 없다 = 누락"으로 봤으나, 최신 코드를 보니 **의도된
설계**였다.

`Hobby`, `RecentEvent`가 별도 엔티티로 존재하고 `RecipientProfileService`가
관리한다. 그래서 `RecipientRequest` DTO에 없었던 것이다.

```java
public ProfileDto readProfile(Long recipientId)                 // 읽기
public void applyUpdates(Long recipientId,
                         List<AiCallResult.ProfileUpdateData>)  // AI 통화 결과로만
public void deleteAllByRecipientId(Long recipientId)            // 정리용
```

`applyUpdates`의 파라미터 타입이 `AiCallResult.ProfileUpdateData`라 **통화 결과
경로 외에는 들어올 수 없다.** 어느 컨트롤러에도 노출돼 있지 않다.
`hyope-call-agent`의 `agent/brain.py`에 있는 `update_recipient_profile` 툴이
이 값을 채운다.

**→ 보호자가 못 고치는 게 맞다. 수정 기능을 만들면 안 된다.**

다만 화면에는 그냥 "취미: 없음"으로만 뜬다. 보호자 입장에서는 입력란을 찾다가
못 찾는 상황이라, **"통화 중 자동으로 수집됩니다" 같은 안내 한 줄**이 있으면
오해가 없다. 이건 프론트에서 처리 가능하다.

## 3. 계정 탈퇴 — 프론트만 없음 🟡

```java
// GuardianController.java:52
@DeleteMapping("/{id}")
public ResponseEntity<Void> delete(@PathVariable Long id)
```

`user_settings_screen`에는 로그아웃만 있다. 탈퇴는 되돌릴 수 없는 동작이라
확인 절차를 더 엄격하게 둬야 한다(비밀번호 재입력 등).

**→ 공모전 시연 범위에 필요한지 판단 필요.** 필요 없으면 안 넣는 게 낫다.

---

## 4. 알림 삭제 — 양쪽 다 없음 🟢

`NotificationController`에 `readMine`과 `markRead`만 있다. 삭제·전체읽음이 없다.
알림이 쌓이기만 하는 구조인데, 시연 규모에서는 문제되지 않는다.

---

## 5. 조사 중 발견한 별건

`GuardianController`에 `GET /guardians/me`가 있는데, 프론트
`GuardianService.findMyProfile`은 `GET /guardians`로 **전체 목록을 받아
loginId로 필터링**하고 있다.

```dart
final list = await _client.get('/guardians') as List<dynamic>;
```

보호자가 늘면 남의 계정 정보까지 앱으로 내려온다. 개인정보 문제이기도 하고,
`/guardians/me`로 바꾸면 한 줄로 해결된다.

---

## 제안 순서

1. **`/guardians/me` 교체** — 프론트 한 줄. 개인정보 관련이라 가장 확실한 개선
2. **취미/근황 안내 문구** — 프론트만. "통화 중 자동 수집" 안내로 오해 방지
3. **피보호자 삭제** — **백엔드 cascade 수정이 선행돼야 함.** 그 뒤 프론트 연결
4. **계정 탈퇴** — 시연 범위 판단 후. 이쪽은 cascade가 이미 구현돼 있음
5. 알림 삭제 — 후순위

1·2번은 백엔드 의존 없이 지금 할 수 있고, 3번은 협의가 필요하다.
