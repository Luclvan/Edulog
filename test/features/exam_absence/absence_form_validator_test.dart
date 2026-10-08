import 'package:flutter_test/flutter_test.dart';
import 'package:edulog/core/utils/absence_request_validator.dart';
import 'package:edulog/features/exam_absence/domain/models/absence_request_model.dart';

void main() {
  group('AbsenceRequestValidator - Field 1: Họ và tên', () {
    test('[15E1] Empty / Whitespace only check', () {
      expect(AbsenceRequestValidator.validateFullName(null), 'Họ và tên không được để trống');
      expect(AbsenceRequestValidator.validateFullName(''), 'Họ và tên không được để trống');
      expect(AbsenceRequestValidator.validateFullName('   '), 'Họ và tên không được để trống');
    });

    test('[15E3] Contains digits or special characters', () {
      expect(AbsenceRequestValidator.validateFullName('Nguyễn Văn A 123'), 'Họ và tên không được chứa chữ số hoặc ký tự đặc biệt');
      expect(AbsenceRequestValidator.validateFullName('Trần Thị @B'), 'Họ và tên không được chứa chữ số hoặc ký tự đặc biệt');
      expect(AbsenceRequestValidator.validateFullName('Lê-Văn-C'), 'Họ và tên không được chứa chữ số hoặc ký tự đặc biệt');
    });

    test('[15E2] Min length (< 2) and Max length (> 50)', () {
      expect(AbsenceRequestValidator.validateFullName('A'), 'Họ và tên sinh viên phải từ 2 đến 50 ký tự');
      final longName = 'A' * 51;
      expect(AbsenceRequestValidator.validateFullName(longName), 'Họ và tên sinh viên phải từ 2 đến 50 ký tự');
    });

    test('[15E4] Cross-validation with account name', () {
      expect(
        AbsenceRequestValidator.validateFullName('Trần Văn B', accountFullName: 'Nguyễn Thị Cẩm Ly'),
        'Họ và tên không khớp với thông tin sinh viên đăng nhập',
      );
      expect(
        AbsenceRequestValidator.validateFullName('Nguyễn Thị Cẩm Ly', accountFullName: 'Nguyễn Thị Cẩm Ly'),
        isNull,
      );
    });

    test('Valid Vietnamese and English Full Names', () {
      expect(AbsenceRequestValidator.validateFullName('Nguyễn Thị Cẩm Ly'), isNull);
      expect(AbsenceRequestValidator.validateFullName('Lê Văn Lực'), isNull);
      expect(AbsenceRequestValidator.validateFullName('John Smith'), isNull);
    });
  });

  group('AbsenceRequestValidator - Field 2: Số điện thoại', () {
    test('[16E1] Empty / Whitespace only check', () {
      expect(AbsenceRequestValidator.validatePhone(null), 'Số điện thoại không được để trống');
      expect(AbsenceRequestValidator.validatePhone(''), 'Số điện thoại không được để trống');
      expect(AbsenceRequestValidator.validatePhone('   '), 'Số điện thoại không được để trống');
    });

    test('[16E4] Contains letters, spaces, or special characters', () {
      expect(AbsenceRequestValidator.validatePhone('091234567a'), 'Số điện thoại chỉ được chứa các chữ số');
      expect(AbsenceRequestValidator.validatePhone('0912 34567'), 'Số điện thoại chỉ được chứa các chữ số');
      expect(AbsenceRequestValidator.validatePhone('0912-345-678'), 'Số điện thoại chỉ được chứa các chữ số');
      expect(AbsenceRequestValidator.validatePhone('+84912345678'), 'Số điện thoại chỉ được chứa các chữ số');
    });

    test('[16E2] Length != 10 digits', () {
      expect(AbsenceRequestValidator.validatePhone('091234567'), 'Số điện thoại phải gồm đúng 10 chữ số'); // 9 digits
      expect(AbsenceRequestValidator.validatePhone('09123456789'), 'Số điện thoại phải gồm đúng 10 chữ số'); // 11 digits
    });

    test('[16E3] Invalid VN network prefix or not starting with 0', () {
      expect(AbsenceRequestValidator.validatePhone('0123456789'), 'Số điện thoại không hợp lệ');
      expect(AbsenceRequestValidator.validatePhone('0212345678'), 'Số điện thoại không hợp lệ');
      expect(AbsenceRequestValidator.validatePhone('0412345678'), 'Số điện thoại không hợp lệ');
      expect(AbsenceRequestValidator.validatePhone('0612345678'), 'Số điện thoại không hợp lệ');
    });

    test('Valid VN phone numbers (03, 05, 07, 08, 09)', () {
      expect(AbsenceRequestValidator.validatePhone('0321234567'), isNull); // Viettel
      expect(AbsenceRequestValidator.validatePhone('0561234567'), isNull); // Vietnamobile
      expect(AbsenceRequestValidator.validatePhone('0701234567'), isNull); // Mobifone
      expect(AbsenceRequestValidator.validatePhone('0861234567'), isNull); // Viettel
      expect(AbsenceRequestValidator.validatePhone('0912345678'), isNull); // Vinaphone
    });
  });

  group('AbsenceRequestValidator - Field 3: Email', () {
    test('[17E1] Empty / Whitespace check', () {
      expect(AbsenceRequestValidator.validateEmail(null), 'Email không được để trống');
      expect(AbsenceRequestValidator.validateEmail(''), 'Email không được để trống');
      expect(AbsenceRequestValidator.validateEmail('   '), 'Email không được để trống');
    });

    test('[17E4] Whitespace inside email', () {
      expect(AbsenceRequestValidator.validateEmail('2351170568 @e.tlu.edu.vn'), 'Email không được chứa khoảng trắng');
      expect(AbsenceRequestValidator.validateEmail('235117 0568@e.tlu.edu.vn'), 'Email không được chứa khoảng trắng');
    });

    test('[17E2] Invalid RFC email format', () {
      expect(AbsenceRequestValidator.validateEmail('invalid-email'), 'Định dạng email không hợp lệ');
      expect(AbsenceRequestValidator.validateEmail('test@.com'), 'Định dạng email không hợp lệ');
      expect(AbsenceRequestValidator.validateEmail('@e.tlu.edu.vn'), 'Định dạng email không hợp lệ');
    });

    test('[17E3] Domain outside TLU', () {
      expect(AbsenceRequestValidator.validateEmail('student@gmail.com'), 'Vui lòng sử dụng email trường (@e.tlu.edu.vn)');
      expect(AbsenceRequestValidator.validateEmail('student@hust.edu.vn'), 'Vui lòng sử dụng email trường (@e.tlu.edu.vn)');
      expect(AbsenceRequestValidator.validateEmail('student@vnu.edu.vn'), 'Vui lòng sử dụng email trường (@e.tlu.edu.vn)');
    });

    test('Valid TLU emails (@e.tlu.edu.vn and @tlu.edu.vn)', () {
      expect(AbsenceRequestValidator.validateEmail('2351170568@e.tlu.edu.vn'), isNull);
      expect(AbsenceRequestValidator.validateEmail('lyntc@e.tlu.edu.vn'), isNull);
      expect(AbsenceRequestValidator.validateEmail('giaovien@tlu.edu.vn'), isNull);
    });
  });

  group('AbsenceRequestValidator - Field 4: Lý do vắng thi', () {
    test('[18E1] Empty / Whitespace only check', () {
      expect(AbsenceRequestValidator.validateReason(null), 'Vui lòng nhập lý do xin vắng thi');
      expect(AbsenceRequestValidator.validateReason(''), 'Vui lòng nhập lý do xin vắng thi');
      expect(AbsenceRequestValidator.validateReason('   '), 'Vui lòng nhập lý do xin vắng thi');
    });

    test('[18E2] Length < 10 characters', () {
      expect(AbsenceRequestValidator.validateReason('Bị ốm'), 'Lý do xin vắng thi phải từ 10 ký tự trở lên');
      expect(AbsenceRequestValidator.validateReason('123456789'), 'Lý do xin vắng thi phải từ 10 ký tự trở lên');
    });

    test('[18E3] Length > 500 characters', () {
      final longReason = 'A' * 501;
      expect(AbsenceRequestValidator.validateReason(longReason), 'Lý do xin vắng thi không được vượt quá 500 ký tự');
    });

    test('Valid reasons (10 - 500 characters)', () {
      expect(AbsenceRequestValidator.validateReason('Bị sốt xuất huyết phải nhập viện điều trị'), isNull);
      expect(AbsenceRequestValidator.validateReason('Em có lịch phẫu thuật đột xuất theo chỉ định của bác sĩ tại bệnh viện Bạch Mai'), isNull);
    });
  });

  group('AbsenceRequestValidator - Field 5: Tài liệu minh chứng', () {
    test('[19E1] Empty check', () {
      expect(AbsenceRequestValidator.validateProofUrl(null), 'Bắt buộc cung cấp đường dẫn tài liệu minh chứng');
      expect(AbsenceRequestValidator.validateProofUrl(''), 'Bắt buộc cung cấp đường dẫn tài liệu minh chứng');
      expect(AbsenceRequestValidator.validateProofUrl('   '), 'Bắt buộc cung cấp đường dẫn tài liệu minh chứng');
    });

    test('[19E4] Contains whitespace', () {
      expect(AbsenceRequestValidator.validateProofUrl('https://drive.google.com/file/d/ 12345'), 'Đường dẫn không được chứa khoảng trắng');
      expect(AbsenceRequestValidator.validateProofUrl('https://example.com/ my_proof.pdf'), 'Đường dẫn không được chứa khoảng trắng');
    });

    test('[19E2] Does not start with https://', () {
      expect(AbsenceRequestValidator.validateProofUrl('http://drive.google.com/file/d/12345'), 'Đường dẫn minh chứng phải bắt đầu bằng https://');
      expect(AbsenceRequestValidator.validateProofUrl('ftp://example.com/file.pdf'), 'Đường dẫn minh chứng phải bắt đầu bằng https://');
      expect(AbsenceRequestValidator.validateProofUrl('drive.google.com/file/d/12345'), 'Đường dẫn minh chứng phải bắt đầu bằng https://');
    });

    test('[19E3] Invalid source (Not Google Drive and not direct JPG/JPEG/PNG/PDF)', () {
      expect(AbsenceRequestValidator.validateProofUrl('https://facebook.com/photo/123'), 'Đường dẫn minh chứng phải là link Google Drive hoặc tệp ảnh/PDF trực tiếp');
      expect(AbsenceRequestValidator.validateProofUrl('https://dropbox.com/s/12345'), 'Đường dẫn minh chứng phải là link Google Drive hoặc tệp ảnh/PDF trực tiếp');
      expect(AbsenceRequestValidator.validateProofUrl('https://example.com/file.docx'), 'Đường dẫn minh chứng phải là link Google Drive hoặc tệp ảnh/PDF trực tiếp');
    });

    test('Valid Google Drive URLs (with drive/u/0/folders/file/d patterns)', () {
      expect(AbsenceRequestValidator.validateProofUrl('https://drive.google.com/file/d/1A2B3C4D5E6F7G8H9I0/view'), isNull);
      expect(AbsenceRequestValidator.validateProofUrl('https://drive.google.com/drive/folders/1aBcDeFgHiJkLmNoPqRsTuVwXyZ'), isNull);
      expect(AbsenceRequestValidator.validateProofUrl('https://drive.google.com/drive/u/0/folders/1234567890abcdef'), isNull);
      expect(AbsenceRequestValidator.validateProofUrl('https://drive.google.com/u/1/file/d/ABC123XYZ/view?usp=sharing'), isNull);
      expect(AbsenceRequestValidator.validateProofUrl('https://drive.google.com/folders/123456'), isNull);
    });

    test('Valid direct image and PDF files', () {
      expect(AbsenceRequestValidator.validateProofUrl('https://res.cloudinary.com/demo/image/upload/sample.jpg'), isNull);
      expect(AbsenceRequestValidator.validateProofUrl('https://storage.googleapis.com/edulog/minhchung.jpeg'), isNull);
      expect(AbsenceRequestValidator.validateProofUrl('https://cdn.school.edu.vn/giay_ra_vien.png'), isNull);
      expect(AbsenceRequestValidator.validateProofUrl('https://hospital.vn/records/doc123.pdf'), isNull);
      expect(AbsenceRequestValidator.validateProofUrl('https://hospital.vn/records/doc123.pdf?token=abc'), isNull);
    });
  });

  group('AbsenceRequestValidator - Field 6: Môn học & Ca thi', () {
    final now = DateTime(2026, 10, 8, 10, 0);

    test('[20E1] Subject not selected (null)', () {
      expect(AbsenceRequestValidator.validateSubjectSelection(null), 'Vui lòng chọn môn học xin vắng thi');
    });

    test('[20E2] Student not in roster (isRegistered == false)', () {
      final subjectUnregistered = ExamSubjectItem(
        subjectId: 'INT4001',
        subjectName: 'Trí tuệ nhân tạo',
        examShiftId: 'SHIFT_05',
        examShiftName: 'Ca 4',
        examTime: now.add(const Duration(days: 2)),
        isRegistered: false,
      );
      expect(
        AbsenceRequestValidator.validateSubjectSelection(subjectUnregistered, now: now),
        'Bạn không thuộc danh sách dự thi của môn học này',
      );
    });

    test('[20E3] Submission deadline expired (> 48 hours after exam end)', () {
      final subjectExpired = ExamSubjectItem(
        subjectId: 'INT2100',
        subjectName: 'Cơ sở dữ liệu',
        examShiftId: 'SHIFT_04',
        examShiftName: 'Ca 1',
        examTime: now.subtract(const Duration(days: 4)),
        examEndTime: now.subtract(const Duration(days: 4, hours: -2)),
        isRegistered: true,
      );
      expect(
        AbsenceRequestValidator.validateSubjectSelection(subjectExpired, now: now),
        'Đã hết thời hạn nộp đơn xin vắng thi cho môn học này (quá 48 giờ kể từ ca thi)',
      );
    });

    test('Valid subject selection before exam and within 48h after exam', () {
      // Before exam
      final subjectFuture = ExamSubjectItem(
        subjectId: 'INT3134',
        subjectName: 'Kiểm thử phần mềm',
        examShiftId: 'SHIFT_01',
        examShiftName: 'Ca 2',
        examTime: now.add(const Duration(days: 2)),
        examEndTime: now.add(const Duration(days: 2, hours: 2)),
        isRegistered: true,
      );
      expect(AbsenceRequestValidator.validateSubjectSelection(subjectFuture, now: now), isNull);

      // Within 48 hours after exam
      final subjectRecent = ExamSubjectItem(
        subjectId: 'INT3110',
        subjectName: 'Kiến trúc phần mềm',
        examShiftId: 'SHIFT_03',
        examShiftName: 'Ca 3',
        examTime: now.subtract(const Duration(hours: 24)),
        examEndTime: now.subtract(const Duration(hours: 22)),
        isRegistered: true,
      );
      expect(AbsenceRequestValidator.validateSubjectSelection(subjectRecent, now: now), isNull);
    });

    test('[20E4] Duplicate pending request check', () {
      expect(
        AbsenceRequestValidator.validateDuplicateRequest(true),
        'Bạn đã gửi đơn xin vắng thi cho môn này và đang chờ duyệt',
      );
      expect(AbsenceRequestValidator.validateDuplicateRequest(false), isNull);
    });
  });
}
