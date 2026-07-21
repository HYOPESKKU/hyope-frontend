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
cd C:\Users\k\Desktop\hyope-backend
Get-Content -Raw -Encoding UTF8 src\main\resources\dummy.sql | & "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe" --default-character-set=utf8mb4 -uhyope -p1234 hyope_db
```

 `Get-Content -Encoding UTF8`와 `--default-character-set=utf8mb4` **둘 다** 있어야 합니다. 하나라도 빠지면 Windows 콘솔 기본 문자셋(euckr) 때문에 한글이 깨져서 `Incorrect string value` 에러가 나거나, 에러 없이 조용히 깨진 채로 들어갈 수 있습니다.

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
Invoke-RestMethod -Uri http://localhost:8080/auth/login -Method Post -ContentType "application/json" -Body '{"loginId":"user1","password":"12345"}'
```

`token` 필드가 오면 정상입니다. (단, 한글이 포함된 응답을 이 방식으로 확인할 땐 [트러블슈팅](#트러블슈팅)의 인코딩 관련 항목을 참고하세요 — 한글 필드는 `curl.exe`로 확인하는 게 더 정확합니다: `curl.exe -s http://localhost:8080/... -H "Authorization: Bearer <token>"`)

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
