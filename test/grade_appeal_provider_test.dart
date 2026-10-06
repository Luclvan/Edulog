import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edulog/features/grade_appeal/data/repositories/grade_appeal_repository.dart';
import 'package:edulog/features/grade_appeal/presentation/providers/grade_appeal_provider.dart';

void main() {
  late ProviderContainer container;
  late GradeAppealRepository repository;

  setUp(() {
    repository = GradeAppealRepository(firestore: null);
    repository.resetLocalAppeals();

    container = ProviderContainer(
      overrides: [
        gradeAppealRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('GradeAppealNotifier Async Validations & Business Logic', () {
    test('[5E6] Rejects student name mismatch with account name', () async {
      final notifier = container.read(gradeAppealNotifierProvider.notifier);
      await notifier.loadInitialData();

      final success = await notifier.submitAppeal(
        studentName: 'Trần Văn Sai',
        studentId: '2351170568',
        studentEmail: '2351170568@e.tlu.edu.vn',
        currentScore: 6.5,
        examDate: '01/10/2026',
        subjectName: 'Kiểm thử phần mềm',
        examShift: 'Ca 2',
        now: DateTime(2026, 10, 6),
        forcedAccountName: 'Nguyễn Thị Cẩm Ly',
      );

      expect(success, isFalse);
      final state = container.read(gradeAppealNotifierProvider);
      expect(state.errorMessage, 'Họ và tên không khớp với thông tin tài khoản đăng nhập');
    });

    test('[6E4] Rejects student ID mismatch with logged-in account ID', () async {
      final notifier = container.read(gradeAppealNotifierProvider.notifier);
      await notifier.loadInitialData();

      final success = await notifier.submitAppeal(
        studentName: 'Nguyễn Thị Cẩm Ly',
        studentId: '2351170001',
        studentEmail: '2351170568@e.tlu.edu.vn',
        currentScore: 6.5,
        examDate: '01/10/2026',
        subjectName: 'Kiểm thử phần mềm',
        examShift: 'Ca 2',
        now: DateTime(2026, 10, 6),
        forcedAccountId: '2351170568',
      );

      expect(success, isFalse);
      final state = container.read(gradeAppealNotifierProvider);
      expect(state.errorMessage, 'Mã sinh viên không khớp với tài khoản đang đăng nhập');
    });

    test('[10E2] Rejects subject not existing in curriculum', () async {
      final notifier = container.read(gradeAppealNotifierProvider.notifier);
      await notifier.loadInitialData();

      final success = await notifier.submitAppeal(
        studentName: 'Nguyễn Thị Cẩm Ly',
        studentId: '2351170568',
        studentEmail: '2351170568@e.tlu.edu.vn',
        currentScore: 6.5,
        examDate: '01/10/2026',
        subjectName: 'Môn học không tồn tại',
        examShift: 'Ca 2',
        now: DateTime(2026, 10, 6),
      );

      expect(success, isFalse);
      final state = container.read(gradeAppealNotifierProvider);
      expect(state.errorMessage, 'Môn học không tồn tại trong hệ thống đào tạo');
    });

    test('[10E3] Rejects course not organized for exam this term', () async {
      final notifier = container.read(gradeAppealNotifierProvider.notifier);
      await notifier.loadInitialData();

      // 'Trí tuệ nhân tạo' has hasExamOrganized: false
      final success = await notifier.submitAppeal(
        studentName: 'Nguyễn Thị Cẩm Ly',
        studentId: '2351170568',
        studentEmail: '2351170568@e.tlu.edu.vn',
        currentScore: 6.5,
        examDate: '01/10/2026',
        subjectName: 'Trí tuệ nhân tạo',
        examShift: 'Ca 2',
        now: DateTime(2026, 10, 6),
      );

      expect(success, isFalse);
      final state = container.read(gradeAppealNotifierProvider);
      expect(state.errorMessage, 'Môn học không được tổ chức thi trong đợt thi này');
    });

    test('[10E4] Rejects when student is not in exam list', () async {
      final notifier = container.read(gradeAppealNotifierProvider.notifier);
      await notifier.loadInitialData();

      // 'An toàn thông tin' has isRegistered: false
      final success = await notifier.submitAppeal(
        studentName: 'Nguyễn Thị Cẩm Ly',
        studentId: '2351170568',
        studentEmail: '2351170568@e.tlu.edu.vn',
        currentScore: 6.5,
        examDate: '02/10/2026',
        subjectName: 'An toàn thông tin',
        examShift: 'Ca 4',
        now: DateTime(2026, 10, 6),
      );

      expect(success, isFalse);
      final state = container.read(gradeAppealNotifierProvider);
      expect(state.errorMessage, 'Bạn không có tên trong danh sách dự thi môn học này');
    });

    test('[10E6] Rejects when course scores are not yet published', () async {
      final notifier = container.read(gradeAppealNotifierProvider.notifier);
      await notifier.loadInitialData();

      // 'Cơ sở dữ liệu' has publishedScore: null
      final success = await notifier.submitAppeal(
        studentName: 'Nguyễn Thị Cẩm Ly',
        studentId: '2351170568',
        studentEmail: '2351170568@e.tlu.edu.vn',
        currentScore: 6.5,
        examDate: '04/10/2026',
        subjectName: 'Cơ sở dữ liệu',
        examShift: 'Ca 3',
        now: DateTime(2026, 10, 6),
      );

      expect(success, isFalse);
      final state = container.read(gradeAppealNotifierProvider);
      expect(state.errorMessage, 'Môn học chưa công bố điểm thi, chưa thể tạo đơn phúc khảo');
    });

    test('[8E5] Rejects score mismatch with recorded final score in system', () async {
      final notifier = container.read(gradeAppealNotifierProvider.notifier);
      await notifier.loadInitialData();

      // 'Kiểm thử phần mềm' recorded score is 6.5, entered 8.0
      final success = await notifier.submitAppeal(
        studentName: 'Nguyễn Thị Cẩm Ly',
        studentId: '2351170568',
        studentEmail: '2351170568@e.tlu.edu.vn',
        currentScore: 8.0,
        examDate: '01/10/2026',
        subjectName: 'Kiểm thử phần mềm',
        examShift: 'Ca 2',
        now: DateTime(2026, 10, 6),
      );

      expect(success, isFalse);
      final state = container.read(gradeAppealNotifierProvider);
      expect(state.errorMessage, 'Điểm số nhập vào không khớp với điểm thi đã ghi nhận trên hệ thống');
    });

    test('[9E4] Rejects exam date mismatch with actual exam schedule', () async {
      final notifier = container.read(gradeAppealNotifierProvider.notifier);
      await notifier.loadInitialData();

      // 'Kiểm thử phần mềm' actual exam date is 01/10/2026, entered 02/10/2026
      final success = await notifier.submitAppeal(
        studentName: 'Nguyễn Thị Cẩm Ly',
        studentId: '2351170568',
        studentEmail: '2351170568@e.tlu.edu.vn',
        currentScore: 6.5,
        examDate: '02/10/2026',
        subjectName: 'Kiểm thử phần mềm',
        examShift: 'Ca 2',
        now: DateTime(2026, 10, 6),
      );

      expect(success, isFalse);
      final state = container.read(gradeAppealNotifierProvider);
      expect(state.errorMessage, 'Ngày thi không khớp với lịch thi thực tế của môn học này');
    });

    test('[9E5] Rejects appeal submitted beyond 15 days deadline', () async {
      final notifier = container.read(gradeAppealNotifierProvider.notifier);
      await notifier.loadInitialData();

      // 'Toán rời rạc' exam date was 10/09/2026, current time is 06/10/2026 (26 days > 15 days)
      final success = await notifier.submitAppeal(
        studentName: 'Nguyễn Thị Cẩm Ly',
        studentId: '2351170568',
        studentEmail: '2351170568@e.tlu.edu.vn',
        currentScore: 5.0,
        examDate: '10/09/2026',
        subjectName: 'Toán rời rạc',
        examShift: 'Ca 1',
        now: DateTime(2026, 10, 6),
      );

      expect(success, isFalse);
      final state = container.read(gradeAppealNotifierProvider);
      expect(state.errorMessage, 'Đã hết thời hạn gửi đơn phúc khảo cho môn thi này (quá 15 ngày theo quy chế)');
    });

    test('[11E3] Rejects shift mismatch with student roster assignment', () async {
      final notifier = container.read(gradeAppealNotifierProvider.notifier);
      await notifier.loadInitialData();

      // 'Kiểm thử phần mềm' assigned shift is 'Ca 2', entered 'Ca 1'
      final success = await notifier.submitAppeal(
        studentName: 'Nguyễn Thị Cẩm Ly',
        studentId: '2351170568',
        studentEmail: '2351170568@e.tlu.edu.vn',
        currentScore: 6.5,
        examDate: '01/10/2026',
        subjectName: 'Kiểm thử phần mềm',
        examShift: 'Ca 1',
        now: DateTime(2026, 10, 6),
      );

      expect(success, isFalse);
      final state = container.read(gradeAppealNotifierProvider);
      expect(state.errorMessage, 'Ca thi không khớp với ca thi được xếp lịch của bạn');
    });

    test('[10E5] Rejects duplicate pending appeal for same subject', () async {
      final notifier = container.read(gradeAppealNotifierProvider.notifier);
      await notifier.loadInitialData();

      // 'Đồ án chuyên ngành' already has a pending appeal in repository mock
      final success = await notifier.submitAppeal(
        studentName: 'Nguyễn Thị Cẩm Ly',
        studentId: '2351170568',
        studentEmail: '2351170568@e.tlu.edu.vn',
        currentScore: 5.5,
        examDate: '28/09/2026',
        subjectName: 'Đồ án chuyên ngành',
        examShift: 'Ca 1',
        now: DateTime(2026, 10, 6),
      );

      expect(success, isFalse);
      final state = container.read(gradeAppealNotifierProvider);
      expect(state.errorMessage, 'Bạn đã gửi đơn phúc khảo cho môn học này và đang chờ xử lý, không thể gửi trùng lặp');
    });

    test('Successfully submits appeal when all validations pass', () async {
      final notifier = container.read(gradeAppealNotifierProvider.notifier);
      await notifier.loadInitialData();

      final success = await notifier.submitAppeal(
        studentName: 'Nguyễn Thị Cẩm Ly',
        studentId: '2351170568',
        studentEmail: '2351170568@e.tlu.edu.vn',
        currentScore: 6.5,
        examDate: '01/10/2026',
        subjectName: 'Kiểm thử phần mềm',
        examShift: 'Ca 2',
        reason: 'Xin xem lại điểm phần trắc nghiệm',
        now: DateTime(2026, 10, 6),
      );

      expect(success, isTrue);
      final state = container.read(gradeAppealNotifierProvider);
      expect(state.errorMessage, isNull);
      expect(state.successMessage, 'Tạo đơn phúc khảo thành công!');
      expect(state.appeals.any((a) => a.subjectName == 'Kiểm thử phần mềm'), isTrue);
    });
  });
}
