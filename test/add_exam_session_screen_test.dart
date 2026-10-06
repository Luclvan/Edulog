import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edulog/features/exam_session/presentation/pages/add_exam_session_screen.dart';
import 'package:edulog/features/exam_session/data/repositories/exam_session_repository.dart';

void main() {
  Widget createWidgetUnderTest({DateTime? mockCurrentDate}) {
    return ProviderScope(
      overrides: [
        examSessionRepositoryProvider.overrideWithValue(
          ExamSessionRepository(firestore: null),
        ),
      ],
      child: MaterialApp(
        home: AddExamSessionScreen(
          mockCurrentDate: mockCurrentDate ?? DateTime(2026, 10, 6),
        ),
      ),
    );
  }

  group('AddExamSessionScreen Widget & Form Tests', () {
    testWidgets('renders all 8 required form fields and action button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Thêm Ca Thi Mới'), findsOneWidget);
      expect(find.byKey(const Key('exam_term_field')), findsOneWidget);
      expect(find.byKey(const Key('course_name_field')), findsOneWidget);
      expect(find.byKey(const Key('credits_field')), findsOneWidget);
      expect(find.byKey(const Key('exam_date_field')), findsOneWidget);
      expect(find.byKey(const Key('session_period_field')), findsOneWidget);
      expect(find.byKey(const Key('exam_time_field')), findsOneWidget);
      expect(find.byKey(const Key('room_code_field')), findsOneWidget);
      expect(find.byKey(const Key('teacher_field')), findsOneWidget);
      expect(find.byKey(const Key('create_session_button')), findsOneWidget);
    });

    testWidgets('shows validation errors when submitting with empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final createButton = find.byKey(const Key('create_session_button'));
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // [21E1] Exam term empty
      expect(find.text('Tên đợt thi không được để trống'), findsOneWidget);
      // [22E1] Course empty
      expect(find.text('Tên môn học không được để trống'), findsOneWidget);
      // [23E1] Credits empty
      expect(find.text('Số tín chỉ không được để trống'), findsOneWidget);
      // [24E1] Exam date empty
      expect(find.text('Vui lòng chọn ngày thi'), findsOneWidget);
      // [25E1] Session period empty
      expect(find.text('Ca thi không được để trống'), findsOneWidget);
      // [26E1] Exam time empty
      expect(find.text('Giờ thi không được để trống'), findsOneWidget);
      // [27E1] Room empty
      expect(find.text('Phòng thi không được để trống'), findsOneWidget);
      // [28E1] Teacher empty
      expect(find.text('Vui lòng chọn giáo viên phụ trách ca thi'), findsOneWidget);
    });

    testWidgets('shows validation errors for invalid field values', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter invalid exam term pattern [21E3]
      await tester.enterText(find.byKey(const Key('exam_term_field')), 'K65_Lich_Thi_Invalid_NH_2025');
      // Enter invalid credits [23E2]
      await tester.enterText(find.byKey(const Key('credits_field')), '9');
      // Enter invalid period [25E2]
      await tester.enterText(find.byKey(const Key('session_period_field')), 'Tiết 1 đến 3');
      // Enter invalid room code [27E2]
      await tester.enterText(find.byKey(const Key('room_code_field')), 'Phong-101');

      final createButton = find.byKey(const Key('create_session_button'));
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Tên đợt thi không đúng định dạng chuẩn (Ví dụ: K65_Lich_Thi_HK2_GĐ1_NH_2025-2026)'),
        findsOneWidget,
      );
      expect(find.text('Số tín chỉ học phần phải từ 1 đến 5'), findsOneWidget);
      expect(
        find.text('Định dạng ca thi phải theo dạng [Tiết bắt đầu]-[Tiết kết thúc] (Ví dụ: 4-6, 1-3)'),
        findsOneWidget,
      );
      expect(
        find.text('Phòng thi không tồn tại trong danh mục cơ sở vật chất của trường'),
        findsOneWidget,
      );
    });

    testWidgets('successful submission with valid inputs', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter valid form data
      await tester.enterText(find.byKey(const Key('exam_term_field')), 'K65_Lich_Thi_HK2_GĐ1_NH_2025-2026');
      await tester.enterText(find.byKey(const Key('course_name_field')), 'Lập trình thiết bị di động');
      await tester.enterText(find.byKey(const Key('credits_field')), '3');
      await tester.enterText(find.byKey(const Key('exam_date_field')), '20/10/2026');
      await tester.enterText(find.byKey(const Key('session_period_field')), '4-6');
      await tester.enterText(find.byKey(const Key('exam_time_field')), '09:45 - 12:25');
      await tester.enterText(find.byKey(const Key('room_code_field')), '205-B5');
      await tester.enterText(find.byKey(const Key('teacher_field')), 'ThS. Đỗ Đình An');

      final createButton = find.byKey(const Key('create_session_button'));
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.text('Tạo ca thi thành công!'), findsOneWidget);
    });
  });
}
