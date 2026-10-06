import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edulog/features/grade_appeal/presentation/pages/create_appeal_screen.dart';
import 'package:edulog/features/grade_appeal/data/repositories/grade_appeal_repository.dart';

void main() {
  Widget createWidgetUnderTest({
    DateTime? mockCurrentDate,
    String? forcedAccountName,
    String? forcedAccountId,
  }) {
    return ProviderScope(
      overrides: [
        gradeAppealRepositoryProvider.overrideWithValue(
          GradeAppealRepository(firestore: null),
        ),
      ],
      child: MaterialApp(
        home: CreateAppealScreen(
          mockCurrentDate: mockCurrentDate ?? DateTime(2026, 10, 6),
          forcedAccountName: forcedAccountName ?? 'Nguyễn Thị Cẩm Ly',
          forcedAccountId: forcedAccountId ?? '2351170568',
        ),
      ),
    );
  }

  group('CreateAppealScreen Widget Tests', () {
    testWidgets('renders all form fields and submit button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Tạo Đơn Phúc Khảo'), findsOneWidget);
      expect(find.byKey(const Key('student_name_field')), findsOneWidget);
      expect(find.byKey(const Key('student_id_field')), findsOneWidget);
      expect(find.byKey(const Key('student_email_field')), findsOneWidget);
      expect(find.byKey(const Key('current_score_field')), findsOneWidget);
      expect(find.byKey(const Key('exam_date_field')), findsOneWidget);
      expect(find.byKey(const Key('subject_name_field')), findsOneWidget);
      expect(find.byKey(const Key('exam_shift_field')), findsOneWidget);
      expect(find.byKey(const Key('appeal_reason_field')), findsOneWidget);
      expect(find.byKey(const Key('submit_appeal_button')), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Clear autofilled fields
      await tester.enterText(find.byKey(const Key('student_name_field')), '');
      await tester.enterText(find.byKey(const Key('student_id_field')), '');
      await tester.enterText(find.byKey(const Key('student_email_field')), '');

      final submitBtn = find.byKey(const Key('submit_appeal_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Họ và tên không được để trống'), findsOneWidget);
      expect(find.text('Mã sinh viên không được để trống'), findsOneWidget);
      expect(find.text('Email không được để trống'), findsOneWidget);
      expect(find.text('Vui lòng nhập điểm số hiện tại cần phúc khảo'), findsOneWidget);
      expect(find.text('Vui lòng chọn ngày thi đã tham gia'), findsOneWidget);
      expect(find.text('Vui lòng chọn môn thi cần phúc khảo'), findsOneWidget);
      expect(find.text('Vui lòng chọn ca thi đã tham gia'), findsOneWidget);
    });

    testWidgets('shows validation errors for invalid field values', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter invalid data
      await tester.enterText(find.byKey(const Key('student_name_field')), 'Ly 123');
      await tester.enterText(find.byKey(const Key('student_id_field')), '12345');
      await tester.enterText(find.byKey(const Key('student_email_field')), 'ly@gmail.com');
      await tester.enterText(find.byKey(const Key('current_score_field')), '15.0');
      await tester.enterText(find.byKey(const Key('exam_date_field')), '31/02/2026');
      await tester.enterText(find.byKey(const Key('exam_shift_field')), 'Ca 99');

      final submitBtn = find.byKey(const Key('submit_appeal_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Họ và tên không được chứa chữ số'), findsOneWidget);
      expect(find.text('Mã sinh viên phải có độ dài chính xác 10 chữ số'), findsOneWidget);
      expect(find.text('Chỉ chấp nhận email sinh viên trường ĐH Thủy Lợi (@e.tlu.edu.vn)'), findsOneWidget);
      expect(find.text('Điểm số không được vượt quá 10.0'), findsOneWidget);
      expect(find.text('Ngày thi không hợp lệ theo lịch'), findsOneWidget);
      expect(find.text('Ca thi không hợp lệ trong hệ thống'), findsOneWidget);
    });

    testWidgets('submits appeal successfully with valid inputs', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('student_name_field')), 'Nguyễn Thị Cẩm Ly');
      await tester.enterText(find.byKey(const Key('student_id_field')), '2351170568');
      await tester.enterText(find.byKey(const Key('student_email_field')), '2351170568@e.tlu.edu.vn');
      await tester.enterText(find.byKey(const Key('current_score_field')), '6.5');
      await tester.enterText(find.byKey(const Key('exam_date_field')), '01/10/2026');
      await tester.enterText(find.byKey(const Key('subject_name_field')), 'Kiểm thử phần mềm');
      await tester.enterText(find.byKey(const Key('exam_shift_field')), 'Ca 2');

      final submitBtn = find.byKey(const Key('submit_appeal_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Tạo đơn phúc khảo thành công!'), findsOneWidget);
    });
  });
}
