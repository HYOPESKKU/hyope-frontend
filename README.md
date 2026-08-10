# 연동 버전 실행 튜토리얼 (MySQL + 백엔드 + 프론트)

IntelliJ 없이, 터미널만으로 `hyope-backend`(Spring Boot) + MySQL + `hyope-frontend`(Flutter)를
전부 붙여서 실제로 로그인/회원가입까지 되는 상태로 띄우는 절차입니다.

두 저장소가 아래처럼 같은 폴더 밑에 나란히 있다고 가정합니다.

```
C:\Users\k\Desktop\hyope-backend
C:\Users\k\Desktop\hyope-frontend
```

---

## 0. 사전 준비물

- Java 17 (`java -version`으로 확인)
- MySQL 8.x (아래 1번에서 확인/설치)
- Flutter SDK (`flutter --version`으로 확인)
- `hyope-backend/.env` 파일에 `JWT_SECRET`, `JWT_EXPIRATION`, `INTERNAL_API_KEY` 세 값이 채워져 있어야 합니다.
  `.env`는 git에 안 올라가는 파일이라(`.gitignore`), 없다면 팀원에게 값을 받아서 프로젝트 루트에 만들어야 합니다.
  `spring-dotenv` 의존성이 있어서 백엔드 실행 시 자동으로 읽어옵니다 — 따로 환경변수 export 안 해도 됩니다.

---

## 1. MySQL 준비

`application.properties`에 아래 접속 정보가 고정되어 있습니다.

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/hyope_db?serverTimezone=Asia/Seoul&characterEncoding=UTF-8
spring.datasource.username=hyope
spring.datasource.password=1234
```

### 1-1. 이미 MySQL이 로컬에 떠 있는지 먼저 확인하세요

Windows에 MySQL을 설치한 적이 있다면 서비스로 이미 떠 있을 수 있습니다.

```powershell
Get-Service | Where-Object { $_.DisplayName -like "*mysql*" }
```

`Running` 상태인 게 있으면 3306 포트를 이미 쓰고 있는 거라, 아래 1-2(Docker)는 건너뛰고 1-3(계정 확인)으로 가면 됩니다.

### 1-2. 로컬에 MySQL이 없다면 — Docker로 띄우기

```powershell
docker run -d --name hyope-mysql -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=hyope_db -e MYSQL_USER=hyope -e MYSQL_PASSWORD=1234 -p 3306:3306 mysql:8
docker logs -f hyope-mysql
```

`ready for connections` 로그가 뜨면 준비 완료입니다(Ctrl+C로 로그 보기 종료).

> Docker Desktop 앱이 켜져 있어야 `docker` 명령이 동작합니다. 트레이에 고래 아이콘이 뜰 때까지 기다렸다가 실행하세요.
>
> `Ports are not available: ... 3306` 에러가 나면 이미 3306번 포트를 쓰는 MySQL이 로컬에 떠 있다는 뜻입니다 — 1-1로 돌아가서 확인하세요.

### 1-3. `hyope` 계정 / `hyope_db` 존재 확인

Docker로 새로 띄웠다면 위 명령어의 환경변수로 이미 자동 생성됩니다. 기존 로컬 MySQL을 쓴다면 아래로 직접 만드세요(설치 경로는 버전에 따라 다를 수 있습니다).

```powershell
& "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe" -uroot -p -e "
CREATE DATABASE IF NOT EXISTS hyope_db DEFAULT CHARACTER SET utf8mb4;
CREATE USER IF NOT EXISTS 'hyope'@'localhost' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON hyope_db.* TO 'hyope'@'localhost';
FLUSH PRIVILEGES;
"
```

---

## 2. 백엔드 실행

```powershell
cd C:\Users\k\Desktop\hyope-backend
.\gradlew.bat bootRun
```

정상 기동 시 이런 로그가 뜹니다.

```
Tomcat started on port 8080 (http) with context path '/'
Started HyopeServerApplication in ...
```

이 창은 서버가 포그라운드로 계속 도는 상태(`EXECUTING`)라 그대로 켜두세요. 종료하려면 `Ctrl+C`.

> `ddl-auto=create`라서 **실행할 때마다 테이블이 전부 새로 생성**됩니다(기존 데이터 초기화). 재시작할 때마다 3번(더미데이터)을 다시 넣어야 합니다.

---

## 3. 더미데이터 넣기 (선택, 테스트용 계정이 바로 필요할 때)

백엔드가 뜬 상태에서, **새 터미널**을 열고:

```powershell
& "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe" --default-character-set=utf8mb4 -uhyope -p1234 hyope_db < src\main\resources\dummy.sql
```

`--default-character-set=utf8mb4`를 꼭 붙이세요 — 안 붙이면 Windows 콘솔 기본 문자셋(euckr) 때문에 한글 데이터가 깨져서 `Incorrect string value` 에러가 납니다.

다 넣으면 아래 계정으로 바로 로그인 테스트가 가능합니다.

| 로그인 ID | 비밀번호 |
|---|---|
| `user1` | `12345` |

(연결된 피보호자 "홍길동"과 통화 기록/평가 데이터도 1건씩 같이 들어갑니다.)

**재실행 시 데이터가 꼬였다면** (예: 스크립트가 중간에 실패해서 일부만 들어간 경우), 아래로 싹 지우고 다시 넣으세요.

```powershell
& "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe" --default-character-set=utf8mb4 -uhyope -p1234 hyope_db -e "
DELETE FROM adherence_record; DELETE FROM assessment; DELETE FROM call_log_entry;
DELETE FROM call_schedule; DELETE FROM call_log; DELETE FROM recipient; DELETE FROM guardian;
ALTER TABLE guardian AUTO_INCREMENT = 1; ALTER TABLE recipient AUTO_INCREMENT = 1;
ALTER TABLE call_schedule AUTO_INCREMENT = 1; ALTER TABLE call_log AUTO_INCREMENT = 1;
ALTER TABLE call_log_entry AUTO_INCREMENT = 1; ALTER TABLE assessment AUTO_INCREMENT = 1;
ALTER TABLE adherence_record AUTO_INCREMENT = 1;
"
```

### 백엔드가 잘 떠 있는지 curl로 확인 (선택)

```powershell
curl -X POST http://localhost:8080/auth/login -H "Content-Type: application/json" -d '{\"loginId\":\"user1\",\"password\":\"12345\"}'
```

`{"token":"..."}`가 오면 정상입니다.

---

## 4. 프론트 실행

**또 새 터미널**을 열고:

```powershell
cd C:\Users\k\Desktop\hyope-frontend
flutter pub get
flutter run -d windows
```

크롬(웹)으로 띄우고 싶으면 `-d chrome`을 쓰면 됩니다. 백엔드 `SecurityConfig`에 `http://localhost:*` 전체를 허용하는 CORS 설정이 이미 되어 있어서, 크롬이 어떤 포트를 잡든 상관없이 동작합니다.

```powershell
flutter run -d chrome
```

사용 가능한 디바이스 목록은 `flutter devices`로 확인할 수 있고, `windows`가 안 보이면 `flutter config --enable-windows-desktop` 한 번 실행하세요.

앱이 뜨면: 역할 선택 → 로그인 화면 → `user1`/`12345`(또는 새로 회원가입)로 로그인 → 피보호자 목록/등록/대시보드까지 확인할 수 있습니다.

---

## 트러블슈팅

| 증상 | 원인 / 해결 |
|---|---|
| 로그인 시 "네트워크 오류가 발생했습니다" | `lib/services/api_client.dart`의 `kApiBaseUrl`이 `http://localhost:8080`인지 확인. 다른 포트(예: 8000)로 되어 있으면 요청이 아예 백엔드에 도달 못 함. 값 고친 뒤엔 핫 리로드(`r`)가 아니라 **완전 재시작**(`R` 또는 `flutter run` 다시)이 필요할 수 있음(`const` 값이라 핫 리로드로 안 바뀔 때가 있음) |
| 로그인은 되는데 다음 화면으로 안 넘어감 | 방금 가입한 계정은 등록된 피보호자가 0명이라 그럴 수 있음 — 지금은 `RecipientListScreen`이 빈 상태를 보여주고 "피보호자 등록" 버튼으로 바로 등록할 수 있게 되어 있음 |
| `docker run` 시 `Ports are not available: ... 3306` | 로컬에 MySQL이 이미 서비스로 떠서 3306을 쓰고 있는 경우. `Get-Service *mysql*`로 확인하고, 있으면 Docker는 건너뛰고 그 MySQL을 그대로 쓰면 됨 |
| `dummy.sql` 삽입 시 `Incorrect string value` | mysql 클라이언트 접속 시 `--default-character-set=utf8mb4`를 안 붙여서 발생. Windows 콘솔 기본 문자셋(euckr) 때문 |
| `dummy.sql` 삽입 시 `Unknown column 'recipient_id'` | `assessment` 테이블은 `Recipient`가 아니라 `CallLog`에만 연결됨(스키마 변경 반영됨). 저장소에 있는 `dummy.sql`은 이미 이 문제를 고쳐뒀음 — 혹시 옛날 버전을 갖고 있다면 `assessment` INSERT에서 `recipient_id` 컬럼/값을 빼면 됨 |
| 크롬(웹)에서 API 호출이 막힘 | 백엔드 `SecurityConfig.java`에 CORS(`http://localhost:*` 허용) 설정이 없던 버전이면 발생. 최신 코드엔 반영되어 있음 — 백엔드를 재시작했는지 확인 |
| `dummy.sql`의 `user1` 계정으로 로그인 실패 | `password_hash`가 BCrypt 해시가 아니라 평문(`'12345'`)으로 들어간 옛날 버전일 수 있음. 최신 `dummy.sql`은 `12345`의 실제 BCrypt 해시로 되어 있음 |
| 백엔드 컴파일 에러 (`GuardianController`) | `/guardians/me` 엔드포인트의 `Authentication` import가 `org.apache.tomcat...` 같은 엉뚱한 클래스로 잘못 잡힌 경우. `import org.springframework.security.core.Authentication;`이어야 함 |

---

## 참고: 알려진 제약사항

- `AssessmentResponse`(백엔드)에 `id` 필드가 없어서, 복약/식사 이행 기록(`adherence_record`)을 assessment별로 프론트에서 못 가져옵니다. 대시보드 캘린더의 이행 표시가 항상 "미확인"으로 나오는 게 정상입니다.
- `GuardianService.findMyProfile`은 "내 정보 조회(me)" 전용 엔드포인트(`/guardians/me`)를 씁니다. 이미 백엔드에 반영되어 있어야 정상 동작합니다.

---

## Android Emulator 실행 방법

위의 **연동 버전 실행 튜토리얼 0~4번**을 그대로 진행해 MySQL, 백엔드, 더미데이터가 준비된 상태에서
Flutter 프론트엔드를 Android Emulator로 실행하는 방법입니다.

### 1. Android 개발 환경 준비

Android Studio를 설치한 뒤 SDK Manager에서 다음 항목이 설치되어 있는지 확인합니다.

- Android SDK
- Android SDK Platform-Tools
- Android SDK Build-Tools
- Android SDK Command-line Tools (latest)
- Android Emulator

설치 후 PowerShell에서 Flutter가 Android 환경을 정상적으로 인식하는지 확인합니다.

```powershell
flutter doctor -v
```

`cmdline-tools component is missing` 또는 Android 라이선스 관련 오류가 나오면
Android Studio의 **SDK Manager → SDK Tools**에서 `Android SDK Command-line Tools (latest)`를 설치한 뒤 아래 명령을 실행합니다.

```powershell
flutter doctor --android-licenses
```

라이선스 질문에는 `y`를 입력합니다.

> `Visual Studio - develop Windows apps` 항목에 오류가 있어도 Android Emulator 실행과는 관계없습니다.

### 2. Android Emulator 생성 및 실행

Android Studio에서:

```text
Tools → Device Manager → Create Device
```

로 들어가 Android 가상 기기를 생성합니다.

테스트 시 사용한 환경 예시는 다음과 같습니다.

```text
Device: Pixel 6
Android: Android 17 (API 37)
```

생성한 Emulator의 ▶ 버튼을 눌러 실행한 뒤 PowerShell에서 연결 여부를 확인합니다.

```powershell
flutter devices
```

정상적으로 인식되면 다음과 비슷하게 표시됩니다.

```text
sdk gphone16k x86 64 • emulator-5554 • android-x64
```

`emulator-5554`는 환경에 따라 다른 ID가 표시될 수 있습니다.

### 3. Android Emulator에서 백엔드 연결

Android Emulator 안에서 `localhost`는 개발 PC가 아니라 **Emulator 자기 자신**을 의미합니다.

따라서 PC에서 `localhost:8080`으로 실행 중인 Spring Boot 백엔드에 접근하려면
Android Emulator에서는 다음 주소를 사용합니다.

```text
http://10.0.2.2:8080
```

현재 저장소의 `lib/services/api_client.dart`는 Android Emulator 테스트를 위해 다음 주소를 사용하도록 설정되어 있습니다.

```dart
const String kApiBaseUrl = 'http://10.0.2.2:8080';
```

또한 `android/app/src/main/AndroidManifest.xml`에는 로컬 개발용 HTTP 통신을 위해
인터넷 권한과 cleartext HTTP 허용 설정이 포함되어 있습니다.

> 웹(Chrome)에서 실행할 경우에는 `10.0.2.2`가 아니라 PC의 `localhost:8080`을 사용해야 합니다.
> 현재 코드가 `10.0.2.2`로 설정되어 있다면 웹 실행 전 API 주소를 확인하세요.

### 4. Emulator에서 Flutter 실행

Emulator가 켜져 있고 백엔드가 실행 중인 상태에서 프론트엔드 프로젝트 루트로 이동합니다.

```powershell
cd C:\Users\k\Desktop\hyope-frontend
flutter pub get
flutter devices
```

`flutter devices`에 표시된 Android Emulator ID를 지정하여 실행합니다.

```powershell
flutter run -d emulator-5554
```

첫 Android 빌드는 Gradle 관련 파일을 다운로드하고 APK를 생성하므로 시간이 오래 걸릴 수 있습니다.

아래와 같은 Java 경고가 나오더라도 `FAILURE: Build failed with an exception`이 나오지 않았다면
빌드 실패를 의미하는 것은 아닙니다.

```text
WARNING: A restricted method in java.lang.System has been called
```

정상적으로 빌드되면 APK가 Emulator에 설치되고 HYOPE 앱이 자동으로 실행됩니다.

### 5. 동작 확인

앱이 실행되면 다음 순서로 확인합니다.

```text
역할 선택
→ 로그인
→ 피보호자 목록
→ 대시보드
```

더미데이터를 넣었다면 아래 계정으로 로그인할 수 있습니다.

| 로그인 ID | 비밀번호 |
|---|---|
| `user1` | `12345` |

로그인 후 피보호자 및 대시보드 데이터가 정상적으로 표시되면
**MySQL → Spring Boot 백엔드 → Flutter Android Emulator 연동이 정상적으로 완료된 상태**입니다.

### Android Emulator 트러블슈팅

| 증상 | 원인 / 해결 |
|---|---|
| `flutter devices`에 Android 기기가 없음 | Android Studio의 Device Manager에서 Emulator가 실제로 실행 중인지 확인 |
| `Android sdkmanager not found` | SDK Manager → SDK Tools에서 `Android SDK Command-line Tools (latest)` 설치 |
| Android 라이선스 오류 | `flutter doctor --android-licenses` 실행 후 모두 동의 |
| 앱은 뜨지만 로그인 시 네트워크 오류 | 백엔드가 `8080` 포트에서 실행 중인지 확인하고 `kApiBaseUrl`이 `http://10.0.2.2:8080`인지 확인 |
| `Cleartext HTTP traffic not permitted` | `android/app/src/main/AndroidManifest.xml`의 `android:usesCleartextTraffic="true"` 설정 확인 |
| `Running Gradle task 'assembleDebug'...`에서 오래 걸림 | 첫 실행 시 Gradle/Android 빌드 파일을 준비하므로 시간이 걸릴 수 있음. 명확한 실패 메시지가 나오기 전까지 기다림 |
| PC 재부팅 후 Android 기기가 안 잡힘 | Emulator도 종료된 상태이므로 Android Studio Device Manager에서 다시 실행 |

