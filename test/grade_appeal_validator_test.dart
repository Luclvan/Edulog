import 'package:flutter_test/flutter_test.dart';
import 'package:edulog/core/utils/grade_appeal_validator.dart';

void main() {
  group('GradeAppealValidator - Field 1: Họ và tên (Full Name)', () {
    test('[5E1] Empty check', () {
      expect(GradeAppealValidator.validateFullName(null), "Họ và tên không được để trống");
      expect(GradeAppealValidator.validateFullName(''), "Họ và tên không được để trống");
      expect(GradeAppealValidator.validateFullName('   '), "Họ và tên không được để trống");
    });

    test('[5E4] Numeric check (no digits 0-9)', () {
      expect(GradeAppealValidator.validateFullName('Cẩm Ly 123'), "Họ và tên không được chứa chữ số");
      expect(GradeAppealValidator.validateFullName('Nguyễn 2'), "Họ và tên không được chứa chữ số");
    });

    test('[5E5] Special character check', () {
      expect(GradeAppealValidator.validateFullName('Cẩm Ly @!'), "Họ và tên không được chứa ký tự đặc biệt");
      expect(GradeAppealValidator.validateFullName('Cẩm Ly - Lee'), "Họ và tên không được chứa ký tự đặc biệt");
    });

    test('[5E2] Min length (< 2 chars)', () {
      expect(GradeAppealValidator.validateFullName('A'), "Họ và tên sinh viên tối thiểu từ 2 ký tự");
    });

    test('[5E3] Max length (> 50 chars)', () {
      final longName = 'A' * 51;
      expect(GradeAppealValidator.validateFullName(longName), "Họ và tên sinh viên không được vượt quá 50 ký tự");
    });

    test('[5E6] Account match check (Cross-validation)', () {
      expect(
        GradeAppealValidator.validateFullName(
          'Trần Thị B',
          accountFullName: 'Nguyễn Thị Cẩm Ly',
        ),
        "Họ và tên không khớp với thông tin tài khoản đăng nhập",
      );

      expect(
        GradeAppealValidator.validateFullName(
          'Nguyễn Thị Cẩm Ly',
          accountFullName: 'Nguyễn Thị Cẩm Ly',
        ),
        isNull,
      );
    });

    test('Valid Full Names', () {
      expect(GradeAppealValidator.validateFullName('Nguyễn Thị Cẩm Ly'), isNull);
      expect(GradeAppealValidator.validateFullName('Lê Văn Lực'), isNull);
      expect(GradeAppealValidator.validateFullName('John Doe'), isNull);
    });
  });

  group('GradeAppealValidator - Field 2: Mã Sinh Viên (Student ID)', () {
    test('[6E1] Empty check', () {
      expect(GradeAppealValidator.validateStudentId(null), "Mã sinh viên không được để trống");
      expect(GradeAppealValidator.validateStudentId(''), "Mã sinh viên không được để trống");
      expect(GradeAppealValidator.validateStudentId('   '), "Mã sinh viên không được để trống");
    });

    test('[6E3] Numeric only check', () {
      expect(GradeAppealValidator.validateStudentId('235117056A'), "Mã sinh viên chỉ bao gồm các chữ số");
      expect(GradeAppealValidator.validateStudentId('MSV1234567'), "Mã sinh viên chỉ bao gồm các chữ số");
    });

    test('[6E2] Exact length check (must be 10 digits)', () {
      expect(GradeAppealValidator.validateStudentId('235117'), "Mã sinh viên phải có độ dài chính xác 10 chữ số");
      expect(GradeAppealValidator.validateStudentId('235117056899'), "Mã sinh viên phải có độ dài chính xác 10 chữ số");
    });

    test('[6E5] Cohort check (first 2 digits must be in [18, 26])', () {
      expect(GradeAppealValidator.validateStudentId('1751170568'), "Khóa tuyển sinh không hợp lệ trong hệ thống");
      expect(GradeAppealValidator.validateStudentId('2751170568'), "Khóa tuyển sinh không hợp lệ trong hệ thống");
    });

    test('[6E4] Account match check (Cross-validation)', () {
      expect(
        GradeAppealValidator.validateStudentId(
          '2351170001',
          accountStudentId: '2351170568',
        ),
        "Mã sinh viên không khớp với tài khoản đang đăng nhập",
      );

      expect(
        GradeAppealValidator.validateStudentId(
          '2351170568',
          accountStudentId: '2351170568',
        ),
        isNull,
      );
    });

    test('Valid Student IDs', () {
      expect(GradeAppealValidator.validateStudentId('2351170568'), isNull); // K65
      expect(GradeAppealValidator.validateStudentId('1851170001'), isNull); // K60
      expect(GradeAppealValidator.validateStudentId('2651179999'), isNull); // K68
    });
  });

  group('GradeAppealValidator - Field 3: Email sinh viên (Institutional Email)', () {
    test('[7E1] Empty check', () {
      expect(GradeAppealValidator.validateEmail(null), "Email không được để trống");
      expect(GradeAppealValidator.validateEmail(''), "Email không được để trống");
      expect(GradeAppealValidator.validateEmail('   '), "Email không được để trống");
    });

    test('[7E4] Whitespace check', () {
      expect(GradeAppealValidator.validateEmail('ly @e.tlu.edu.vn'), "Email không được chứa khoảng trắng");
      expect(GradeAppealValidator.validateEmail('ly@e.tlu.edu.vn '), "Email không được chứa khoảng trắng");
    });

    test('[7E2] Standard format check', () {
      expect(GradeAppealValidator.validateEmail('invalid-email'), "Định dạng email không hợp lệ");
      expect(GradeAppealValidator.validateEmail('@e.tlu.edu.vn'), "Định dạng email không hợp lệ");
    });

    test('[7E3] Domain restriction (@e.tlu.edu.vn)', () {
      expect(GradeAppealValidator.validateEmail('student@gmail.com'), "Chỉ chấp nhận email sinh viên trường ĐH Thủy Lợi (@e.tlu.edu.vn)");
      expect(GradeAppealValidator.validateEmail('student@hust.edu.vn'), "Chỉ chấp nhận email sinh viên trường ĐH Thủy Lợi (@e.tlu.edu.vn)");
      expect(GradeAppealValidator.validateEmail('teacher@tlu.edu.vn'), "Chỉ chấp nhận email sinh viên trường ĐH Thủy Lợi (@e.tlu.edu.vn)");
    });

    test('Valid Student Emails', () {
      expect(GradeAppealValidator.validateEmail('2351170568@e.tlu.edu.vn'), isNull);
      expect(GradeAppealValidator.validateEmail('ly.ntc@e.tlu.edu.vn'), isNull);
    });
  });

  group('GradeAppealValidator - Field 4: Điểm thi hiện tại (Current Score)', () {
    test('[8E1] Empty check', () {
      expect(GradeAppealValidator.validateCurrentScore(null), "Vui lòng nhập điểm số hiện tại cần phúc khảo");
      expect(GradeAppealValidator.validateCurrentScore(''), "Vui lòng nhập điểm số hiện tại cần phúc khảo");
      expect(GradeAppealValidator.validateCurrentScore('   '), "Vui lòng nhập điểm số hiện tại cần phúc khảo");
    });

    test('[8E2] Lower bound check (< 0.0)', () {
      expect(GradeAppealValidator.validateCurrentScore('-1'), "Điểm số không được nhỏ hơn 0.0");
      expect(GradeAppealValidator.validateCurrentScore('-0.5'), "Điểm số không được nhỏ hơn 0.0");
    });

    test('[8E3] Upper bound check (> 10.0)', () {
      expect(GradeAppealValidator.validateCurrentScore('10.5'), "Điểm số không được vượt quá 10.0");
      expect(GradeAppealValidator.validateCurrentScore('11'), "Điểm số không được vượt quá 10.0");
    });

    test('[8E4] Precision step check (max 1 decimal place, step 0.1)', () {
      expect(GradeAppealValidator.validateCurrentScore('7.25'), "Điểm số chỉ được làm tròn đến 1 chữ số thập phân (bước nhảy 0.1)");
      expect(GradeAppealValidator.validateCurrentScore('8.125'), "Điểm số chỉ được làm tròn đến 1 chữ số thập phân (bước nhảy 0.1)");
    });

    test('Valid Scores', () {
      expect(GradeAppealValidator.validateCurrentScore('0'), isNull);
      expect(GradeAppealValidator.validateCurrentScore('0.0'), isNull);
      expect(GradeAppealValidator.validateCurrentScore('6.5'), isNull);
      expect(GradeAppealValidator.validateCurrentScore('10.0'), isNull);
      expect(GradeAppealValidator.validateCurrentScore('10'), isNull);
    });

    test('[8E5] System score match', () {
      expect(
        GradeAppealValidator.validateSystemScoreMatch(
          enteredScore: 7.0,
          recordedScore: 6.5,
        ),
        "Điểm số nhập vào không khớp với điểm thi đã ghi nhận trên hệ thống",
      );

      expect(
        GradeAppealValidator.validateSystemScoreMatch(
          enteredScore: 6.5,
          recordedScore: 6.5,
        ),
        isNull,
      );
    });
  });

  group('GradeAppealValidator - Field 5: Ngày thi (Exam Date)', () {
    final fixedNow = DateTime(2026, 10, 6);

    test('[9E1] Empty check', () {
      expect(GradeAppealValidator.validateExamDate(null), "Vui lòng chọn ngày thi đã tham gia");
      expect(GradeAppealValidator.validateExamDate(''), "Vui lòng chọn ngày thi đã tham gia");
      expect(GradeAppealValidator.validateExamDate('   '), "Vui lòng chọn ngày thi đã tham gia");
    });

    test('[9E2] Valid calendar date', () {
      expect(GradeAppealValidator.validateExamDate('31/02/2026', now: fixedNow), "Ngày thi không hợp lệ theo lịch");
      expect(GradeAppealValidator.validateExamDate('30/02/2026', now: fixedNow), "Ngày thi không hợp lệ theo lịch");
      expect(GradeAppealValidator.validateExamDate('31/04/2026', now: fixedNow), "Ngày thi không hợp lệ theo lịch");
      expect(GradeAppealValidator.validateExamDate('2026-10-01', now: fixedNow), "Ngày thi không hợp lệ theo lịch");
    });

    test('[9E3] Future date check', () {
      expect(
        GradeAppealValidator.validateExamDate('07/10/2026', now: fixedNow),
        "Ngày thi không thể là ngày trong tương lai",
      );
      expect(
        GradeAppealValidator.validateExamDate('06/10/2026', now: fixedNow),
        isNull,
      );
      expect(
        GradeAppealValidator.validateExamDate('01/10/2026', now: fixedNow),
        isNull,
      );
    });

    test('[9E4] Schedule sync check', () {
      expect(
        GradeAppealValidator.validateScheduleSync(
          enteredDate: '02/10/2026',
          actualExamDate: '01/10/2026',
        ),
        "Ngày thi không khớp với lịch thi thực tế của môn học này",
      );

      expect(
        GradeAppealValidator.validateScheduleSync(
          enteredDate: '01/10/2026',
          actualExamDate: '01/10/2026',
        ),
        isNull,
      );
    });

    test('[9E5] Deadline expiration check (> 15 days)', () {
      // 10/09/2026 to 06/10/2026 is 26 days (> 15 days)
      expect(
        GradeAppealValidator.validateAppealDeadline(
          examDateStr: '10/09/2026',
          now: fixedNow,
        ),
        "Đã hết thời hạn gửi đơn phúc khảo cho môn thi này (quá 15 ngày theo quy chế)",
      );

      // 25/09/2026 to 06/10/2026 is 11 days (<= 15 days)
      expect(
        GradeAppealValidator.validateAppealDeadline(
          examDateStr: '25/09/2026',
          now: fixedNow,
        ),
        isNull,
      );
    });
  });

  group('GradeAppealValidator - Field 6: Môn thi (Subject Entity)', () {
    test('[10E1] Empty / Null check', () {
      expect(GradeAppealValidator.validateSubjectName(null), "Vui lòng chọn môn thi cần phúc khảo");
      expect(GradeAppealValidator.validateSubjectName(''), "Vui lòng chọn môn thi cần phúc khảo");
      expect(GradeAppealValidator.validateSubjectName('   '), "Vui lòng chọn môn thi cần phúc khảo");
      expect(GradeAppealValidator.validateSubjectName('Kiểm thử phần mềm'), isNull);
    });

    test('[10E2] System existence check', () {
      expect(
        GradeAppealValidator.validateSubjectExistence(existsInCurriculum: false),
        "Môn học không tồn tại trong hệ thống đào tạo",
      );
      expect(
        GradeAppealValidator.validateSubjectExistence(existsInCurriculum: true),
        isNull,
      );
    });

    test('[10E3] Term availability check', () {
      expect(
        GradeAppealValidator.validateSubjectTermAvailability(hasExamOrganized: false),
        "Môn học không được tổ chức thi trong đợt thi này",
      );
      expect(
        GradeAppealValidator.validateSubjectTermAvailability(hasExamOrganized: true),
        isNull,
      );
    });

    test('[10E4] Enrollment check', () {
      expect(
        GradeAppealValidator.validateStudentEnrollment(isRegistered: false),
        "Bạn không có tên trong danh sách dự thi môn học này",
      );
      expect(
        GradeAppealValidator.validateStudentEnrollment(isRegistered: true),
        isNull,
      );
    });

    test('[10E5] Pending duplicate check', () {
      expect(
        GradeAppealValidator.validateNoPendingAppeal(hasPendingAppeal: true),
        "Bạn đã gửi đơn phúc khảo cho môn học này và đang chờ xử lý, không thể gửi trùng lặp",
      );
      expect(
        GradeAppealValidator.validateNoPendingAppeal(hasPendingAppeal: false),
        isNull,
      );
    });

    test('[10E6] Published score check', () {
      expect(
        GradeAppealValidator.validatePublishedScore(publishedScore: null),
        "Môn học chưa công bố điểm thi, chưa thể tạo đơn phúc khảo",
      );
      expect(
        GradeAppealValidator.validatePublishedScore(publishedScore: 6.5),
        isNull,
      );
    });
  });

  group('GradeAppealValidator - Field 7: Ca thi (Exam Shift / Period)', () {
    test('[11E1] Empty check', () {
      expect(GradeAppealValidator.validateExamShift(null), "Vui lòng chọn ca thi đã tham gia");
      expect(GradeAppealValidator.validateExamShift(''), "Vui lòng chọn ca thi đã tham gia");
      expect(GradeAppealValidator.validateExamShift('   '), "Vui lòng chọn ca thi đã tham gia");
    });

    test('[11E2] Whitelist check', () {
      expect(GradeAppealValidator.validateExamShift('Ca 10'), "Ca thi không hợp lệ trong hệ thống");
      expect(GradeAppealValidator.validateExamShift('Buổi sáng'), "Ca thi không hợp lệ trong hệ thống");
      expect(GradeAppealValidator.validateExamShift('Ca 1'), isNull);
      expect(GradeAppealValidator.validateExamShift('Ca 2'), isNull);
      expect(GradeAppealValidator.validateExamShift('4-6'), isNull);
    });

    test('[11E3] Roster assignment check', () {
      expect(
        GradeAppealValidator.validateRosterAssignment(
          enteredShift: 'Ca 1',
          assignedShift: 'Ca 2',
        ),
        "Ca thi không khớp với ca thi được xếp lịch của bạn",
      );

      expect(
        GradeAppealValidator.validateRosterAssignment(
          enteredShift: 'Ca 2',
          assignedShift: 'Ca 2',
        ),
        isNull,
      );
    });
  });
}
