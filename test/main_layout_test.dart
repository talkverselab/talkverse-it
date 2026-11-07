import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:italian_universe/data/db/app_database.dart';
import 'package:italian_universe/main.dart';
import 'package:italian_universe/screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    appDb = AppDatabase.forTesting(NativeDatabase.memory());
  });

  testWidgets('메뉴 개편: 폰·아이패드에서 탭 전부 넘치지 않고 레일에 앱 소개가 있다', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1180, 820);
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: MainScreen()));
    for (var i = 0; i < 20; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await t.pump(const Duration(milliseconds: 30));
    }
    expect(t.takeException(), isNull);
    expect(find.byIcon(Icons.info_outline), findsWidgets);
    expect(find.text('프로필'), findsWidgets);
    for (final label in ['복습', '탐색', '프로필', '배우기']) {
      await t.tap(find.text(label).first);
      await t.pump(const Duration(milliseconds: 300));
      expect(t.takeException(), isNull, reason: label);
    }
    await t.tap(find.text('앱 소개').first);
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('1. 단어 기준'), findsOneWidget);
    expect(t.takeException(), isNull);

    t.view.physicalSize = const Size(390, 844);
    await t.pump(const Duration(milliseconds: 300));
    expect(t.takeException(), isNull);
    for (final label in ['프로필', '탐색', '복습', '배우기']) {
      await t.tap(find.text(label).last);
      await t.pump(const Duration(milliseconds: 300));
      expect(t.takeException(), isNull, reason: '폰 $label');
    }
  });
}
