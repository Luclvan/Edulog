import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edulog/features/class_management/presentation/widgets/add_subject_bottom_sheet.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: AddSubjectBottomSheet(),
        ),
      ),
    );
  }

  group('AddSubjectBottomSheet Form Validation Tests', () {
    testWidgets('shows validation errors when submitting with empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find "Tạo môn học" button and tap
      final createButton = find.widgetWithText(ElevatedButton, 'Tạo môn học');
      expect(createButton, findsOneWidget);

      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // [5E2] Subject Name empty error
      expect(find.text('Tên môn học không được để trống'), findsOneWidget);
      // [6E1] Subject Code empty error
      expect(find.text('Mã môn học không được để trống'), findsOneWidget);
    });

    testWidgets('shows validation errors for invalid subject name formats', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      final nameField = textFields.first;

      // [5E3] Min length < 3 chars
      await tester.enterText(nameField, 'IT');
      await tester.pumpAndSettle();
      expect(find.text('Tên môn học phải từ 3 ký tự trở lên'), findsOneWidget);

      // [5E5] Leading whitespace
      await tester.enterText(nameField, ' Lập trình Web');
      await tester.pumpAndSettle();
      expect(find.text('Tên môn học chứa ký tự không hợp lệ'), findsOneWidget);

      // [5E5] Malicious character
      await tester.enterText(nameField, 'Web <script>');
      await tester.pumpAndSettle();
      expect(find.text('Tên môn học chứa ký tự không hợp lệ'), findsOneWidget);

      // Valid name clears error
      await tester.enterText(nameField, 'Lập trình Thiết bị Di động');
      await tester.pumpAndSettle();
      expect(find.text('Tên môn học chứa ký tự không hợp lệ'), findsNothing);
      expect(find.text('Tên môn học phải từ 3 ký tự trở lên'), findsNothing);
    });

    testWidgets('shows validation errors for invalid subject code formats', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      final codeField = textFields.at(1);

      // [6E2] Length < 5 chars
      await tester.enterText(codeField, 'INT');
      await tester.pumpAndSettle();
      expect(find.text('Mã môn học phải từ 5 đến 10 ký tự'), findsOneWidget);

      // [6E5] Lowercase characters
      await tester.enterText(codeField, 'int3134');
      await tester.pumpAndSettle();
      expect(find.text('Mã môn học chỉ gồm chữ in hoa và chữ số, không chứa khoảng trắng'), findsOneWidget);

      // [6E3] No prefix letters
      await tester.enterText(codeField, '12345');
      await tester.pumpAndSettle();
      expect(find.text('Mã bộ môn/khoa không hợp lệ'), findsOneWidget);

      // [6E4] Suffix not digits / too short
      await tester.enterText(codeField, 'INT12');
      await tester.pumpAndSettle();
      expect(find.text('Mã môn học phải kết thúc bằng các chữ số'), findsOneWidget);

      // Valid code clears error
      await tester.enterText(codeField, 'INT3134');
      await tester.pumpAndSettle();
      expect(find.text('Mã môn học phải kết thúc bằng các chữ số'), findsNothing);
      expect(find.text('Mã môn học chỉ gồm chữ in hoa và chữ số, không chứa khoảng trắng'), findsNothing);
    });
  });
}
