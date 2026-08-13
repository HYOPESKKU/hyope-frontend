import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 아래에서 올라오는 iOS 스타일 휠 피커.
///
/// 머티리얼 기본 피커(달력 격자, 시계 다이얼)는 어르신 정보를 다루는 화면에서
/// 두 가지가 불편했다. 생년월일은 1940년대까지 거슬러 가야 하는데 달력을 월 단위로
/// 넘겨야 하고, 시계 다이얼은 분침을 정확히 찍기 어렵다. 휠은 연/월/일과 시/분을
/// 각각 굴려서 맞추므로 먼 과거로 가거나 분을 조정하는 데 손이 덜 간다.
///
/// 두 함수 모두 취소하면 null을 반환한다. 호출부는 null이면 아무것도 바꾸지
/// 않으면 된다(기존 showDatePicker/showTimePicker와 같은 계약).

const double _kPickerHeight = 240;
const Color _kAccent = Color(0xFF4F80FF);

/// 시트 상단 툴바. 취소는 회색, 완료는 강조색으로 둔다.
///
/// 휠은 굴리는 즉시 값이 바뀌지만 확정은 "완료"를 눌러야 한다. 굴리는 도중
/// 시트를 닫아 원치 않는 값이 저장되는 일을 막기 위해서다.
Widget _toolbar({
  required BuildContext context,
  required String title,
  required VoidCallback onConfirm,
}) {
  return Container(
    height: 48,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFE6EAF2))),
    ),
    child: Row(
      children: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '취소',
            style: TextStyle(fontSize: 15, color: Color(0xFF7A8294)),
          ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF182033),
            ),
          ),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onPressed: onConfirm,
          child: const Text(
            '완료',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _kAccent,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _sheet({required Widget toolbar, required Widget picker}) {
  return Container(
    decoration: const BoxDecoration(
      color: CupertinoColors.systemBackground,
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          toolbar,
          SizedBox(height: _kPickerHeight, child: picker),
        ],
      ),
    ),
  );
}

/// 생년월일처럼 날짜만 고르는 경우.
Future<DateTime?> showKoDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = '날짜 선택',
}) {
  // initialDate가 범위를 벗어나면 CupertinoDatePicker가 예외를 던진다.
  // 호출부에서 계산한 기본값(예: 70년 전)이 범위 밖일 수 있어 여기서 조인다.
  var initial = initialDate;
  if (initial.isBefore(firstDate)) initial = firstDate;
  if (initial.isAfter(lastDate)) initial = lastDate;

  DateTime selected = initial;

  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (sheetContext) => _sheet(
      toolbar: _toolbar(
        context: sheetContext,
        title: title,
        onConfirm: () => Navigator.of(sheetContext).pop(selected),
      ),
      picker: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: initial,
        minimumDate: firstDate,
        maximumDate: lastDate,
        onDateTimeChanged: (value) => selected = value,
      ),
    ),
  );
}

/// 전화 예약처럼 시각만 고르는 경우.
///
/// TimeOfDay를 주고받지만 CupertinoDatePicker는 DateTime만 다뤄서 임의의 날짜에
/// 시각을 얹어 넘기고, 돌려받을 때 다시 시/분만 꺼낸다. 날짜 부분은 쓰이지 않는다.
Future<TimeOfDay?> showKoTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String title = '시간 선택',
}) {
  final base = DateTime(2000, 1, 1, initialTime.hour, initialTime.minute);
  DateTime selected = base;

  return showCupertinoModalPopup<TimeOfDay>(
    context: context,
    builder: (sheetContext) => _sheet(
      toolbar: _toolbar(
        context: sheetContext,
        title: title,
        onConfirm: () => Navigator.of(sheetContext)
            .pop(TimeOfDay(hour: selected.hour, minute: selected.minute)),
      ),
      picker: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        initialDateTime: base,
        // 어르신 대상 서비스라 24시간제보다 오전/오후가 읽기 쉽다.
        use24hFormat: false,
        // minuteInterval은 두지 않는다. 5분 단위로 묶으면 이미 저장된 10:22 같은
        // 시각을 열었다 닫는 것만으로 바꿔버리고, 초기값이 배수가 아니면
        // CupertinoDatePicker가 예외를 던진다.
        onDateTimeChanged: (value) => selected = value,
      ),
    ),
  );
}
