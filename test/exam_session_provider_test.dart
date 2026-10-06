import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edulog/features/exam_session/data/repositories/exam_session_repository.dart';
import 'package:edulog/features/exam_session/presentation/providers/exam_session_provider.dart';

void main() {
  late ProviderContainer container;
  late ExamSessionRepository repository;

  setUp(() {
    repository = ExamSessionRepository(firestore: null);
    repository.resetLocalSessions();

    container = ProviderContainer(
      overrides: [
        examSessionRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ExamSessionNotifier Business Logic & Async Validations', () {
    test('[22E2] Rejects non-existent curriculum course', () async {
      final notifier = container.read(examSessionNotifierProvider.notifier);
      await notifier.loadInitialData();

      final success = await notifier.createExamSession(
        examTermName: 'K65_Lich_Thi_HK2_GĐ1_NH_2025-2026',
        courseName: 'Môn học không có trong hệ thống',
        credits: 3,
        examDate: '20/10/2026',
        sessionPeriod: '4-6',
        examTime: '09:45 - 12:25',
        roomCode: '205-B5',
        teacherName: 'TS. Lê Văn Lực',
        now: DateTime(2026, 10, 6),
      );

      expect(success, isFalse);
      final state = container.read(examSessionNotifierProvider);
      expect(state.errorMessage, 'Môn học không tồn tại trong hệ thống đào tạo');
    });

    test('[22E3] Rejects course from a different cohort', () async {
      final notifier = container.read(examSessionNotifierProvider.notifier);
      await notifier.loadInitialData();

      // 'Giải tích 1' only belongs to K64 and K63, while exam term is K65
      final success = await notifier.createExamSession(
        examTermName: 'K65_Lich_Thi_HK2_GĐ1_NH_2025-2026',
        courseName: 'Giải tích 1',
        credits: 3,
        examDate: '20/10/2026',
        sessionPeriod: '4-6',
        examTime: '09:45 - 12:25',
        roomCode: '205-B5',
        teacherName: 'TS. Lê Văn Lực',
        now: DateTime(2026, 10, 6),
      );

      expect(success, isFalse);
      final state = container.read(examSessionNotifierProvider);
      expect(state.errorMessage, 'Môn học không thuộc khung chương trình đào tạo của đợt thi này');
    });

    test('[23E3] Rejects credit mismatch with course standard credits', () async {
      final notifier = container.read(examSessionNotifierProvider.notifier);
      await notifier.loadInitialData();

      // 'Kiểm thử phần mềm' has standard credits: 3. We enter 4 credits.
      final success = await notifier.createExamSession(
        examTermName: 'K65_Lich_Thi_HK2_GĐ1_NH_2025-2026',
        courseName: 'Kiểm thử phần mềm',
        credits: 4,
        examDate: '20/10/2026',
        sessionPeriod: '4-6',
        examTime: '09:45 - 12:25',
        roomCode: '205-B5',
        teacherName: 'TS. Lê Văn Lực',
        now: DateTime(2026, 10, 6),
      );

      expect(success, isFalse);
      final state = container.read(examSessionNotifierProvider);
      expect(state.errorMessage, 'Số tín chỉ không khớp với thông tin chương trình đào tạo của môn học');
    });

    test('[24E4] Rejects exam date out of exam term timeframe', () async {
      final notifier = container.read(examSessionNotifierProvider.notifier);
      await notifier.loadInitialData();

      // Term timeframe: 01/10/2026 - 30/11/2026. We enter: 05/12/2026
      final success = await notifier.createExamSession(
        examTermName: 'K65_Lich_Thi_HK2_GĐ1_NH_2025-2026',
        courseName: 'Kiểm thử phần mềm',
        credits: 3,
        examDate: '05/12/2026',
        sessionPeriod: '4-6',
        examTime: '09:45 - 12:25',
        roomCode: '205-B5',
        teacherName: 'TS. Lê Văn Lực',
        now: DateTime(2026, 10, 6),
      );

      expect(success, isFalse);
      final state = container.read(examSessionNotifierProvider);
      expect(state.errorMessage, 'Ngày thi phải nằm trong khoảng thời gian hiệu lực của đợt thi');
    });

    test('[27E4] Rejects room under maintenance', () async {
      final notifier = container.read(examSessionNotifierProvider.notifier);
      await notifier.loadInitialData();

      // Room 404-B3 is flagged as under maintenance
      final success = await notifier.createExamSession(
        examTermName: 'K65_Lich_Thi_HK2_GĐ1_NH_2025-2026',
        courseName: 'Kiểm thử phần mềm',
        credits: 3,
        examDate: '20/10/2026',
        sessionPeriod: '4-6',
        examTime: '09:45 - 12:25',
        roomCode: '404-B3',
        teacherName: 'TS. Lê Văn Lực',
        now: DateTime(2026, 10, 6),
      );

      expect(success, isFalse);
      final state = container.read(examSessionNotifierProvider);
      expect(state.errorMessage, 'Phòng thi hiện đang bảo trì, không thể xếp lịch');
    });

    test('[27E3] Rejects room schedule conflict', () async {
      final notifier = container.read(examSessionNotifierProvider.notifier);
      await notifier.loadInitialData();

      // Pre-existing session in mock: Room 131-A2 on 15/10/2026 from 08:00 - 10:00
      // We attempt to book 131-A2 on 15/10/2026 from 09:00 - 11:00 (overlapping!)
      final success = await notifier.createExamSession(
        examTermName: 'K65_Lich_Thi_HK2_GĐ1_NH_2025-2026',
        courseName: 'Lập trình thiết bị di động',
        credits: 3,
        examDate: '15/10/2026',
        sessionPeriod: '1-3',
        examTime: '09:00 - 11:00',
        roomCode: '131-A2',
        teacherName: 'ThS. Đỗ Đình An',
        now: DateTime(2026, 10, 6),
      );

      expect(success, isFalse);
      final state = container.read(examSessionNotifierProvider);
      expect(state.errorMessage, 'Phòng thi đã được xếp cho ca thi khác trong cùng khoảng thời gian này');
    });

    test('[28E3] Rejects teacher schedule conflict across different rooms', () async {
      final notifier = container.read(examSessionNotifierProvider.notifier);
      await notifier.loadInitialData();

      // Pre-existing session: TS. Lê Văn Lực on 15/10/2026 from 08:00 - 10:00 in 131-A2
      // We attempt to assign TS. Lê Văn Lực on 15/10/2026 from 08:30 - 10:30 in 205-B5 (overlapping!)
      final success = await notifier.createExamSession(
        examTermName: 'K65_Lich_Thi_HK2_GĐ1_NH_2025-2026',
        courseName: 'Lập trình thiết bị di động',
        credits: 3,
        examDate: '15/10/2026',
        sessionPeriod: '1-3',
        examTime: '08:30 - 10:30',
        roomCode: '205-B5',
        teacherName: 'TS. Lê Văn Lực',
        now: DateTime(2026, 10, 6),
      );

      expect(success, isFalse);
      final state = container.read(examSessionNotifierProvider);
      expect(state.errorMessage, 'Giảng viên đã có lịch coi thi/chấm thi ở phòng khác trong cùng khoảng thời gian này');
    });

    test('Successfully creates session when all constraints and conflict checks pass', () async {
      final notifier = container.read(examSessionNotifierProvider.notifier);
      await notifier.loadInitialData();

      final success = await notifier.createExamSession(
        examTermName: 'K65_Lich_Thi_HK2_GĐ1_NH_2025-2026',
        courseName: 'Cơ sở dữ liệu',
        credits: 4,
        examDate: '25/10/2026',
        sessionPeriod: '4-6',
        examTime: '09:45 - 12:25',
        roomCode: '302-A1',
        teacherName: 'ThS. Đỗ Đình An',
        now: DateTime(2026, 10, 6),
      );

      expect(success, isTrue);
      final state = container.read(examSessionNotifierProvider);
      expect(state.errorMessage, isNull);
      expect(state.successMessage, 'Tạo ca thi thành công!');
      expect(state.sessions.any((s) => s.roomCode == '302-A1' && s.courseName == 'Cơ sở dữ liệu'), isTrue);
    });
  });
}
