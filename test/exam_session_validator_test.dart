import 'package:flutter_test/flutter_test.dart';
import 'package:edulog/core/utils/exam_session_validator.dart';
import 'package:edulog/features/exam_session/domain/models/exam_session_model.dart';

void main() {
  group('ExamSessionValidator - Field 1: Tên đợt thi (Exam Term Name)', () {
    test('[21E1] Empty check', () {
      expect(ExamSessionValidator.validateExamTermName(null), "Tên đợt thi không được để trống");
      expect(ExamSessionValidator.validateExamTermName(''), "Tên đợt thi không được để trống");
      expect(ExamSessionValidator.validateExamTermName('   '), "Tên đợt thi không được để trống");
    });

    test('[21E2] Length check (10 to 100 characters)', () {
      expect(ExamSessionValidator.validateExamTermName('K65_Lich'), "Tên đợt thi phải có độ dài từ 10 đến 100 ký tự");
      expect(ExamSessionValidator.validateExamTermName('A' * 101), "Tên đợt thi phải có độ dài từ 10 đến 100 ký tự");
    });

    test('[21E4] Whitespace & Special characters check', () {
      // Contains whitespace
      expect(
        ExamSessionValidator.validateExamTermName('K65_Lich Thi_HK2_GĐ1_NH_2025-2026'),
        "Tên đợt thi không được chứa khoảng trắng hoặc ký tự đặc biệt",
      );
      // Contains unsafe special character '@'
      expect(
        ExamSessionValidator.validateExamTermName('K65_Lich_Thi_HK2@GĐ1_NH_2025-2026'),
        "Tên đợt thi không được chứa khoảng trắng hoặc ký tự đặc biệt",
      );
      // Contains unsafe special character '#'
      expect(
        ExamSessionValidator.validateExamTermName('K65_Lich_Thi#HK2_GĐ1_NH_2025-2026'),
        "Tên đợt thi không được chứa khoảng trắng hoặc ký tự đặc biệt",
      );
    });

    test('[21E3] Standard Pattern check', () {
      // HK5 is invalid (must be HK1-3)
      expect(
        ExamSessionValidator.validateExamTermName('K65_Lich_Thi_HK5_GĐ1_NH_2025-2026'),
        "Tên đợt thi không đúng định dạng chuẩn (Ví dụ: K65_Lich_Thi_HK2_GĐ1_NH_2025-2026)",
      );
      // GĐ3 is invalid (must be GĐ1-2)
      expect(
        ExamSessionValidator.validateExamTermName('K65_Lich_Thi_HK2_GĐ3_NH_2025-2026'),
        "Tên đợt thi không đúng định dạng chuẩn (Ví dụ: K65_Lich_Thi_HK2_GĐ1_NH_2025-2026)",
      );
      // Invalid year format
      expect(
        ExamSessionValidator.validateExamTermName('K65_Lich_Thi_HK2_GĐ1_NH_25-26'),
        "Tên đợt thi không đúng định dạng chuẩn (Ví dụ: K65_Lich_Thi_HK2_GĐ1_NH_2025-2026)",
      );

      // Valid format
      expect(
        ExamSessionValidator.validateExamTermName('K65_Lich_Thi_HK2_GĐ1_NH_2025-2026'),
        isNull,
      );
      expect(
        ExamSessionValidator.validateExamTermName('K66_Lich_Thi_HK1_GĐ2_NH_2024-2025'),
        isNull,
      );
    });

    test('extractCohort helper extracts correct cohort', () {
      expect(ExamSessionValidator.extractCohort('K65_Lich_Thi_HK2_GĐ1_NH_2025-2026'), 'K65');
      expect(ExamSessionValidator.extractCohort('K64_Lich_Thi_HK1_GĐ1_NH_2024-2025'), 'K64');
      expect(ExamSessionValidator.extractCohort('Invalid'), isNull);
    });
  });

  group('ExamSessionValidator - Field 2: Tên môn học (Course Name)', () {
    test('[22E1] Empty check', () {
      expect(ExamSessionValidator.validateCourseName(null), "Tên môn học không được để trống");
      expect(ExamSessionValidator.validateCourseName(''), "Tên môn học không được để trống");
      expect(ExamSessionValidator.validateCourseName('   '), "Tên môn học không được để trống");
      expect(ExamSessionValidator.validateCourseName('Kiểm thử phần mềm'), isNull);
    });

    test('[22E2] System existence (Async/Data check)', () {
      final availableCourses = ['Kiểm thử phần mềm', 'Lập trình thiết bị di động', 'Cơ sở dữ liệu'];

      expect(
        ExamSessionValidator.validateCourseExistence(
          courseName: 'Môn học không tồn tại',
          availableCourses: availableCourses,
        ),
        "Môn học không tồn tại trong hệ thống đào tạo",
      );

      expect(
        ExamSessionValidator.validateCourseExistence(
          courseName: 'Kiểm thử phần mềm',
          availableCourses: availableCourses,
        ),
        isNull,
      );
    });

    test('[22E3] Curriculum batch matching (Cohort check)', () {
      const termName = 'K65_Lich_Thi_HK2_GĐ1_NH_2025-2026';

      // Course only belongs to K64
      expect(
        ExamSessionValidator.validateCourseCohortMatching(
          examTermName: termName,
          courseApplicableCohorts: ['K64', 'K63'],
        ),
        "Môn học không thuộc khung chương trình đào tạo của đợt thi này",
      );

      // Course belongs to K65
      expect(
        ExamSessionValidator.validateCourseCohortMatching(
          examTermName: termName,
          courseApplicableCohorts: ['K65', 'K64'],
        ),
        isNull,
      );
    });
  });

  group('ExamSessionValidator - Field 3: Số tín chỉ (Credits)', () {
    test('[23E1] Empty check', () {
      expect(ExamSessionValidator.validateCredits(null), "Số tín chỉ không được để trống");
      expect(ExamSessionValidator.validateCredits(''), "Số tín chỉ không được để trống");
      expect(ExamSessionValidator.validateCredits('   '), "Số tín chỉ không được để trống");
    });

    test('[23E2] Range & Integer check (1 to 5)', () {
      expect(ExamSessionValidator.validateCredits('0'), "Số tín chỉ học phần phải từ 1 đến 5");
      expect(ExamSessionValidator.validateCredits('6'), "Số tín chỉ học phần phải từ 1 đến 5");
      expect(ExamSessionValidator.validateCredits('abc'), "Số tín chỉ học phần phải từ 1 đến 5");
      expect(ExamSessionValidator.validateCredits('3.5'), "Số tín chỉ học phần phải từ 1 đến 5");

      for (int i = 1; i <= 5; i++) {
        expect(ExamSessionValidator.validateCredits(i.toString()), isNull);
      }
    });

    test('[23E3] Curriculum credit sync check', () {
      // Mismatch: entered 4 credits while standard is 3 credits
      expect(
        ExamSessionValidator.validateCreditSync(
          enteredCredits: 4,
          standardCredits: 3,
        ),
        "Số tín chỉ không khớp với thông tin chương trình đào tạo của môn học",
      );

      // Match: entered 3 credits and standard is 3 credits
      expect(
        ExamSessionValidator.validateCreditSync(
          enteredCredits: 3,
          standardCredits: 3,
        ),
        isNull,
      );
    });
  });

  group('ExamSessionValidator - Field 4: Ngày thi (Exam Date: DD/MM/YYYY)', () {
    final fixedNow = DateTime(2026, 10, 6);

    test('[24E1] Empty check', () {
      expect(ExamSessionValidator.validateExamDate(null), "Vui lòng chọn ngày thi");
      expect(ExamSessionValidator.validateExamDate(''), "Vui lòng chọn ngày thi");
      expect(ExamSessionValidator.validateExamDate('   '), "Vui lòng chọn ngày thi");
    });

    test('[24E2] Valid calendar date (astronomical validity)', () {
      // Invalid leap year date (Feb 30)
      expect(ExamSessionValidator.validateExamDate('30/02/2026', now: fixedNow), "Ngày thi không hợp lệ");
      // Feb 29 in non-leap year 2025
      expect(ExamSessionValidator.validateExamDate('29/02/2025', now: fixedNow), "Ngày thi không hợp lệ");
      // Invalid day for 30-day month (April 31)
      expect(ExamSessionValidator.validateExamDate('31/04/2026', now: fixedNow), "Ngày thi không hợp lệ");
      // Invalid month
      expect(ExamSessionValidator.validateExamDate('15/13/2026', now: fixedNow), "Ngày thi không hợp lệ");
      // Invalid format
      expect(ExamSessionValidator.validateExamDate('2026-10-15', now: fixedNow), "Ngày thi không hợp lệ");
    });

    test('[24E3] Past date check', () {
      // Yesterday
      expect(
        ExamSessionValidator.validateExamDate('05/10/2026', now: fixedNow),
        "Ngày thi không được ở trong quá khứ",
      );
      // Today (allowed >= currentDate)
      expect(
        ExamSessionValidator.validateExamDate('06/10/2026', now: fixedNow),
        isNull,
      );
      // Future date
      expect(
        ExamSessionValidator.validateExamDate('15/10/2026', now: fixedNow),
        isNull,
      );
    });

    test('[24E4] Exam term timeframe check', () {
      final termStart = DateTime(2026, 10, 10);
      final termEnd = DateTime(2026, 10, 30);

      // Before term start
      expect(
        ExamSessionValidator.validateExamDate(
          '08/10/2026',
          now: fixedNow,
          termStartDate: termStart,
          termEndDate: termEnd,
        ),
        "Ngày thi phải nằm trong khoảng thời gian hiệu lực của đợt thi",
      );

      // After term end
      expect(
        ExamSessionValidator.validateExamDate(
          '05/11/2026',
          now: fixedNow,
          termStartDate: termStart,
          termEndDate: termEnd,
        ),
        "Ngày thi phải nằm trong khoảng thời gian hiệu lực của đợt thi",
      );

      // Within term timeframe
      expect(
        ExamSessionValidator.validateExamDate(
          '15/10/2026',
          now: fixedNow,
          termStartDate: termStart,
          termEndDate: termEnd,
        ),
        isNull,
      );
    });
  });

  group('ExamSessionValidator - Field 5: Ca thi (Period / Tiết học)', () {
    test('[25E1] Empty check', () {
      expect(ExamSessionValidator.validateSessionPeriod(null), "Ca thi không được để trống");
      expect(ExamSessionValidator.validateSessionPeriod(''), "Ca thi không được để trống");
      expect(ExamSessionValidator.validateSessionPeriod('   '), "Ca thi không được để trống");
    });

    test('[25E2] Format check (Pattern: [Tiết bắt đầu]-[Tiết kết thúc])', () {
      expect(
        ExamSessionValidator.validateSessionPeriod('4'),
        "Định dạng ca thi phải theo dạng [Tiết bắt đầu]-[Tiết kết thúc] (Ví dụ: 4-6, 1-3)",
      );
      expect(
        ExamSessionValidator.validateSessionPeriod('4_6'),
        "Định dạng ca thi phải theo dạng [Tiết bắt đầu]-[Tiết kết thúc] (Ví dụ: 4-6, 1-3)",
      );
      expect(
        ExamSessionValidator.validateSessionPeriod('Tiết 4-6'),
        "Định dạng ca thi phải theo dạng [Tiết bắt đầu]-[Tiết kết thúc] (Ví dụ: 4-6, 1-3)",
      );
    });

    test('[25E3] Range check (1 to 12)', () {
      expect(ExamSessionValidator.validateSessionPeriod('0-3'), "Tiết thi phải nằm trong khoảng từ tiết 1 đến tiết 12");
      expect(ExamSessionValidator.validateSessionPeriod('10-13'), "Tiết thi phải nằm trong khoảng từ tiết 1 đến tiết 12");
    });

    test('[25E4] Logic order check: End period >= Start period', () {
      expect(
        ExamSessionValidator.validateSessionPeriod('6-4'),
        "Tiết kết thúc phải lớn hơn hoặc bằng tiết bắt đầu",
      );
      expect(ExamSessionValidator.validateSessionPeriod('4-6'), isNull);
      expect(ExamSessionValidator.validateSessionPeriod('5-5'), isNull);
    });
  });

  group('ExamSessionValidator - Field 6: Giờ thi (Time Range: HH:mm - HH:mm)', () {
    test('[26E1] Empty check', () {
      expect(ExamSessionValidator.validateExamTime(null), "Giờ thi không được để trống");
      expect(ExamSessionValidator.validateExamTime(''), "Giờ thi không được để trống");
      expect(ExamSessionValidator.validateExamTime('   '), "Giờ thi không được để trống");
    });

    test('[26E2] Format check (HH:mm - HH:mm 24h format)', () {
      expect(
        ExamSessionValidator.validateExamTime('9:45 - 12:25'),
        "Định dạng giờ thi phải là HH:mm - HH:mm (Ví dụ: 09:45 - 12:25)",
      );
      expect(
        ExamSessionValidator.validateExamTime('25:00 - 26:00'),
        "Định dạng giờ thi phải là HH:mm - HH:mm (Ví dụ: 09:45 - 12:25)",
      );
      expect(
        ExamSessionValidator.validateExamTime('09:45 to 12:25'),
        "Định dạng giờ thi phải là HH:mm - HH:mm (Ví dụ: 09:45 - 12:25)",
      );
    });

    test('[26E3] Chronological check: End time > Start time', () {
      expect(
        ExamSessionValidator.validateExamTime('10:00 - 09:00'),
        "Khung giờ thi không hợp lệ: Giờ kết thúc phải sau giờ bắt đầu",
      );
      expect(
        ExamSessionValidator.validateExamTime('10:00 - 10:00'),
        "Khung giờ thi không hợp lệ: Giờ kết thúc phải sau giờ bắt đầu",
      );
    });

    test('[26E4] Duration check (15 minutes <= duration <= 240 minutes)', () {
      // 10 minutes duration (< 15)
      expect(
        ExamSessionValidator.validateExamTime('09:00 - 09:10'),
        "Thời lượng ca thi không hợp lệ (tối thiểu 15 phút, tối đa 240 phút)",
      );
      // 300 minutes duration (> 240)
      expect(
        ExamSessionValidator.validateExamTime('08:00 - 13:00'),
        "Thời lượng ca thi không hợp lệ (tối thiểu 15 phút, tối đa 240 phút)",
      );
      // Valid duration (90 min)
      expect(ExamSessionValidator.validateExamTime('08:00 - 09:30'), isNull);
    });

    test('[26E5] Period-to-Time compatibility check', () {
      // Morning period (1-6) assigned afternoon hours (13:00+)
      expect(
        ExamSessionValidator.validateExamTime('14:00 - 16:00', sessionPeriod: '4-6'),
        "Khung giờ thi không tương thích với ca thi (tiết học) đã chọn",
      );

      // Afternoon period (7-12) assigned morning hours (< 12:00)
      expect(
        ExamSessionValidator.validateExamTime('08:00 - 10:00', sessionPeriod: '7-9'),
        "Khung giờ thi không tương thích với ca thi (tiết học) đã chọn",
      );

      // Morning period with morning time -> Valid
      expect(
        ExamSessionValidator.validateExamTime('09:45 - 12:25', sessionPeriod: '4-6'),
        isNull,
      );

      // Afternoon period with afternoon time -> Valid
      expect(
        ExamSessionValidator.validateExamTime('13:30 - 15:30', sessionPeriod: '7-9'),
        isNull,
      );
    });
  });

  group('ExamSessionValidator - Field 7: Phòng thi (Room Code)', () {
    test('[27E1] Empty check', () {
      expect(ExamSessionValidator.validateRoomCode(null), "Phòng thi không được để trống");
      expect(ExamSessionValidator.validateRoomCode(''), "Phòng thi không được để trống");
      expect(ExamSessionValidator.validateRoomCode('   '), "Phòng thi không được để trống");
    });

    test('[27E2] Facility catalogue format check', () {
      expect(ExamSessionValidator.validateRoomCode('Phòng 101'), "Phòng thi không tồn tại trong danh mục cơ sở vật chất của trường");
      expect(ExamSessionValidator.validateRoomCode('131'), "Phòng thi không tồn tại trong danh mục cơ sở vật chất của trường");
      expect(ExamSessionValidator.validateRoomCode('131-A2'), isNull);
    });

    test('[27E2] Async/Catalogue existence check', () {
      final availableRooms = ['131-A2', '205-B5', '302-A1'];
      expect(
        ExamSessionValidator.validateRoomExistence(
          roomCode: '999-Z9',
          availableRooms: availableRooms,
        ),
        "Phòng thi không tồn tại trong danh mục cơ sở vật chất của trường",
      );
      expect(
        ExamSessionValidator.validateRoomExistence(
          roomCode: '131-A2',
          availableRooms: availableRooms,
        ),
        isNull,
      );
    });

    test('[27E4] Maintenance status check', () {
      expect(
        ExamSessionValidator.validateRoomMaintenance(isUnderMaintenance: true),
        "Phòng thi hiện đang bảo trì, không thể xếp lịch",
      );
      expect(
        ExamSessionValidator.validateRoomMaintenance(isUnderMaintenance: false),
        isNull,
      );
    });

    test('[27E3] Schedule conflict detection for Room', () {
      final existingSessions = [
        const ExamSessionModel(
          id: 's1',
          examTermName: 'K65_Lich_Thi_HK2_GĐ1_NH_2025-2026',
          courseName: 'Kiểm thử phần mềm',
          credits: 3,
          examDate: '15/10/2026',
          sessionPeriod: '1-3',
          examTime: '08:00 - 10:00',
          roomCode: '131-A2',
          teacherName: 'TS. Lê Văn Lực',
          teacherId: 'GV001',
        ),
      ];

      // Overlapping session on same date & room (09:00 - 11:00 overlaps 08:00 - 10:00)
      expect(
        ExamSessionValidator.validateRoomConflict(
          roomCode: '131-A2',
          examDate: '15/10/2026',
          examTime: '09:00 - 11:00',
          existingSessions: existingSessions,
        ),
        "Phòng thi đã được xếp cho ca thi khác trong cùng khoảng thời gian này",
      );

      // Non-overlapping (after 10:00)
      expect(
        ExamSessionValidator.validateRoomConflict(
          roomCode: '131-A2',
          examDate: '15/10/2026',
          examTime: '10:00 - 12:00',
          existingSessions: existingSessions,
        ),
        isNull,
      );

      // Different room
      expect(
        ExamSessionValidator.validateRoomConflict(
          roomCode: '205-B5',
          examDate: '15/10/2026',
          examTime: '09:00 - 11:00',
          existingSessions: existingSessions,
        ),
        isNull,
      );

      // Different date
      expect(
        ExamSessionValidator.validateRoomConflict(
          roomCode: '131-A2',
          examDate: '16/10/2026',
          examTime: '09:00 - 11:00',
          existingSessions: existingSessions,
        ),
        isNull,
      );
    });
  });

  group('ExamSessionValidator - Field 8: Giảng viên chấm thi (Teacher Entity)', () {
    test('[28E1] Empty check', () {
      expect(ExamSessionValidator.validateTeacher(null), "Vui lòng chọn giáo viên phụ trách ca thi");
      expect(ExamSessionValidator.validateTeacher(''), "Vui lòng chọn giáo viên phụ trách ca thi");
      expect(ExamSessionValidator.validateTeacher('   '), "Vui lòng chọn giáo viên phụ trách ca thi");
      expect(ExamSessionValidator.validateTeacher('TS. Lê Văn Lực'), isNull);
    });

    test('[28E2] Staff registry check', () {
      final activeTeachers = ['TS. Lê Văn Lực', 'ThS. Đỗ Đình An', 'GV001', 'GV002'];
      expect(
        ExamSessionValidator.validateTeacherExistence(
          teacherIdentifier: 'Người ngoài trường',
          registeredTeachers: activeTeachers,
        ),
        "Giáo viên không tồn tại trong hệ thống cán bộ của trường",
      );
      expect(
        ExamSessionValidator.validateTeacherExistence(
          teacherIdentifier: 'TS. Lê Văn Lực',
          registeredTeachers: activeTeachers,
        ),
        isNull,
      );
    });

    test('[28E3] Teacher schedule conflict', () {
      final existingSessions = [
        const ExamSessionModel(
          id: 's1',
          examTermName: 'K65_Lich_Thi_HK2_GĐ1_NH_2025-2026',
          courseName: 'Kiểm thử phần mềm',
          credits: 3,
          examDate: '15/10/2026',
          sessionPeriod: '1-3',
          examTime: '08:00 - 10:00',
          roomCode: '131-A2',
          teacherName: 'TS. Lê Văn Lực',
          teacherId: 'GV001',
        ),
      ];

      // Same teacher in different room overlapping time
      expect(
        ExamSessionValidator.validateTeacherConflict(
          teacherIdentifier: 'TS. Lê Văn Lực',
          examDate: '15/10/2026',
          examTime: '09:00 - 11:00',
          existingSessions: existingSessions,
        ),
        "Giảng viên đã có lịch coi thi/chấm thi ở phòng khác trong cùng khoảng thời gian này",
      );

      // Same teacher with teacher ID 'GV001'
      expect(
        ExamSessionValidator.validateTeacherConflict(
          teacherIdentifier: 'GV001',
          examDate: '15/10/2026',
          examTime: '08:30 - 10:00',
          existingSessions: existingSessions,
        ),
        "Giảng viên đã có lịch coi thi/chấm thi ở phòng khác trong cùng khoảng thời gian này",
      );

      // Non-overlapping time for same teacher
      expect(
        ExamSessionValidator.validateTeacherConflict(
          teacherIdentifier: 'TS. Lê Văn Lực',
          examDate: '15/10/2026',
          examTime: '10:00 - 11:30',
          existingSessions: existingSessions,
        ),
        isNull,
      );

      // Different teacher during same time
      expect(
        ExamSessionValidator.validateTeacherConflict(
          teacherIdentifier: 'ThS. Đỗ Đình An',
          examDate: '15/10/2026',
          examTime: '08:00 - 10:00',
          existingSessions: existingSessions,
        ),
        isNull,
      );
    });
  });
}
