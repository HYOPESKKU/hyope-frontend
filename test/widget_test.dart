// 앱이 최초 화면까지 오류 없이 뜨는지 확인하는 스모크 테스트.
//
// 원래는 `flutter create`가 만든 카운터 예제 템플릿이 그대로 남아 있어서
// 존재하지 않는 MyApp을 참조했고, `flutter test`가 항상 실패했다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hyope_frontend/app.dart';

void main() {
  testWidgets('앱이 역할 선택 화면까지 오류 없이 뜬다', (WidgetTester tester) async {
    await tester.pumpWidget(const HyopeApp());
    await tester.pump();

    expect(find.text('HYOPE'), findsOneWidget);
    expect(find.text('보호자로 시작'), findsOneWidget);
    expect(find.text('복지사로 시작'), findsOneWidget);
  });
}
