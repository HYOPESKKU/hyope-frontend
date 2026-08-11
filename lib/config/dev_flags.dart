/// 개발용 스위치.
///
/// 백엔드에 테스트 데이터를 넣지 않고도 화면을 확인하기 위한 장치다.
/// 팀 DB는 공유 자원이라 임의로 더미를 넣으면 다른 사람 작업과 엉킨다.
///
/// 켜는 법 (코드를 고치지 않는다):
/// ```
/// flutter run --dart-define=USE_MOCK=true
/// flutter build apk --debug --dart-define=USE_MOCK=true
/// ```
///
/// 기본값이 false이므로 그냥 빌드하면 평소대로 실제 백엔드를 본다.
/// 릴리스 빌드에 실수로 섞일 일이 없다.
const bool kUseMockData = bool.fromEnvironment('USE_MOCK', defaultValue: false);

/// 목 모드에서 통화 실패·무응답 같은 극단 케이스를 섞을지 여부.
///
/// 정상 데이터만으로는 "통화가 실패했을 때 화면이 깨지지 않는가"를 확인할 수
/// 없다. 이 값을 켜면 최근 며칠에 분석 실패·무응답 기록이 끼어든다.
///
/// ```
/// flutter run --dart-define=USE_MOCK=true --dart-define=MOCK_FAIL_CASES=true
/// ```
const bool kMockFailCases =
    bool.fromEnvironment('MOCK_FAIL_CASES', defaultValue: false);
