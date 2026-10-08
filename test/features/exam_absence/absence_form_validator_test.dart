import 'package:flutter_test/flutter_test.dart';
import 'package:edulog/core/utils/absence_form_validator.dart';

void main() {
  group('AbsenceFormValidator - Feature: exam_absence (Tạo đơn xin vắng / hoãn thi)', () {
    // ==================== 1. HỌ VÀ TÊN (15E1 - 15E4) ====================
    group('1. Full Name Constraints (Họ và tên)', () {
      test('[15E1] Empty / Null / Whitespace check', () {
        expect(
          AbsenceFormValidator.validateFullName(null),
          "Họ và tên không được để trống",
        );
        expect(
          AbsenceFormValidator.validateFullName(""),
          "Họ và tên không được để trống",
        );
        expect(
          AbsenceFormValidator.validateFullName("   "),
          "Họ và tên không được để trống",
        );
      });

      test('[15E2] Min and Max length checks (2 - 50 characters)', () {
        expect(
          AbsenceFormValidator.validateFullName("A"),
          "Họ và tên sinh viên phải từ 2 đến 50 ký tự",
        );
        final longName = "Nguyễn " * 10; // > 50 characters
        expect(
          AbsenceFormValidator.validateFullName(longName),
          "Họ và tên sinh viên phải từ 2 đến 50 ký tự",
        );
      });

      test('[15E3] Numbers and special characters check', () {
        expect(
          AbsenceFormValidator.validateFullName("Nguyễn Văn A 123"),
          "Họ và tên không được chứa chữ số hoặc ký tự đặc biệt",
        );
        expect(
          AbsenceFormValidator.validateFullName("Trần @ Thị B"),
          "Họ và tên không được chứa chữ số hoặc ký tự đặc biệt",
        );
        expect(
          AbsenceFormValidator.validateFullName("Lê Văn <C>"),
          "Họ và tên không được chứa chữ số hoặc ký tự đặc biệt",
        );
        expect(
          AbsenceFormValidator.validateFullName("Phạm_Văn_D"),
          "Họ và tên không được chứa chữ số hoặc ký tự đặc biệt",
        );
      });

      test('[15E4] Account name match check', () {
        expect(
          AbsenceFormValidator.validateFullName(
            "Nguyễn Văn A",
            loggedInStudentName: "Trần Thị B",
          ),
          "Họ và tên không khớp với thông tin sinh viên đăng nhập",
        );
      });

      test('Valid Full Names (Vietnamese, English, case-insensitive match)', () {
        expect(
          AbsenceFormValidator.validateFullName(
            "Nguyễn Văn An",
            loggedInStudentName: "nguyễn văn an",
          ),
          isNull,
        );
        expect(
          AbsenceFormValidator.validateFullName("Trần Thị Thu Trang"),
          isNull,
        );
        expect(
          AbsenceFormValidator.validateFullName("John Doe"),
          isNull,
        );
      });
    });

    // ==================== 2. SỐ ĐIỆN THOẠI (16E1 - 16E4) ====================
    group('2. Phone Number Constraints (Số điện thoại)', () {
      test('[16E1] Empty / Null check', () {
        expect(
          AbsenceFormValidator.validatePhoneNumber(null),
          "Số điện thoại không được để trống",
        );
        expect(
          AbsenceFormValidator.validatePhoneNumber(""),
          "Số điện thoại không được để trống",
        );
      });

      test('[16E4] Non-digit characters (letters, spaces, special chars)', () {
        expect(
          AbsenceFormValidator.validatePhoneNumber("0912abc456"),
          "Số điện thoại chỉ được chứa các chữ số",
        );
        expect(
          AbsenceFormValidator.validatePhoneNumber("0912 345 67"),
          "Số điện thoại chỉ được chứa các chữ số",
        );
        expect(
          AbsenceFormValidator.validatePhoneNumber("0912-345-678"),
          "Số điện thoại chỉ được chứa các chữ số",
        );
        expect(
          AbsenceFormValidator.validatePhoneNumber("0912@34567"),
          "Số điện thoại chỉ được chứa các chữ số",
        );
      });

      test('[16E2] Length != 10 digits check', () {
        expect(
          AbsenceFormValidator.validatePhoneNumber("091234567"), // 9 digits
          "Số điện thoại phải gồm đúng 10 chữ số",
        );
        expect(
          AbsenceFormValidator.validatePhoneNumber("09123456789"), // 11 digits
          "Số điện thoại phải gồm đúng 10 chữ số",
        );
      });

      test('[16E3] Invalid carrier prefix / Not starting with 0', () {
        expect(
          AbsenceFormValidator.validatePhoneNumber("1234567890"), // Not start with 0
          "Số điện thoại không hợp lệ",
        );
        expect(
          AbsenceFormValidator.validatePhoneNumber("0123456789"), // 01 prefix is old/invalid
          "Số điện thoại không hợp lệ",
        );
        expect(
          AbsenceFormValidator.validatePhoneNumber("0243456789"), // Landline prefix
          "Số điện thoại không hợp lệ",
        );
      });

      test('Valid VN Phone Numbers (03, 05, 07, 08, 09)', () {
        expect(AbsenceFormValidator.validatePhoneNumber("0323456789"), isNull);
        expect(AbsenceFormValidator.validatePhoneNumber("0563456789"), isNull);
        expect(AbsenceFormValidator.validatePhoneNumber("0783456789"), isNull);
        expect(AbsenceFormValidator.validatePhoneNumber("0868123456"), isNull);
        expect(AbsenceFormValidator.validatePhoneNumber("0987654321"), isNull);
      });
    });

    // ==================== 3. EMAIL TRƯỜNG (17E1 - 17E4) ====================
    group('3. Institutional Email Constraints (Email)', () {
      test('[17E1] Empty / Null check', () {
        expect(
          AbsenceFormValidator.validateEmail(null),
          "Email không được để trống",
        );
        expect(
          AbsenceFormValidator.validateEmail(""),
          "Email không được để trống",
        );
      });

      test('[17E4] Whitespace check', () {
        expect(
          AbsenceFormValidator.validateEmail("sinhvien @e.tlu.edu.vn"),
          "Email không được chứa khoảng trắng",
        );
        expect(
          AbsenceFormValidator.validateEmail("sinhvien@e.tlu.edu.vn "),
          "Email không được chứa khoảng trắng",
        );
      });

      test('[17E2] Invalid RFC 5322 structure', () {
        expect(
          AbsenceFormValidator.validateEmail("sinhvien.e.tlu.edu.vn"),
          "Định dạng email không hợp lệ",
        );
        expect(
          AbsenceFormValidator.validateEmail("sinhvien@"),
          "Định dạng email không hợp lệ",
        );
        expect(
          AbsenceFormValidator.validateEmail("@e.tlu.edu.vn"),
          "Định dạng email không hợp lệ",
        );
      });

      test('[17E3] Non-TLU Domain restriction', () {
        expect(
          AbsenceFormValidator.validateEmail("sinhvien@gmail.com"),
          "Vui lòng sử dụng email trường (@e.tlu.edu.vn)",
        );
        expect(
          AbsenceFormValidator.validateEmail("sinhvien@hust.edu.vn"),
          "Vui lòng sử dụng email trường (@e.tlu.edu.vn)",
        );
      });

      test('Valid TLU Emails (@e.tlu.edu.vn and @tlu.edu.vn)', () {
        expect(
          AbsenceFormValidator.validateEmail("2051060001@e.tlu.edu.vn"),
          isNull,
        );
        expect(
          AbsenceFormValidator.validateEmail("nguyenvana@e.tlu.edu.vn"),
          isNull,
        );
        expect(
          AbsenceFormValidator.validateEmail("giangvien@tlu.edu.vn"),
          isNull,
        );
      });
    });

    // ==================== 4. LÝ DO VẮNG THI (18E1 - 18E3) ====================
    group('4. Reason Constraints (Lý do vắng thi)', () {
      test('[18E1] Empty / Whitespace-only check', () {
        expect(
          AbsenceFormValidator.validateReason(null),
          "Vui lòng nhập lý do xin vắng thi",
        );
        expect(
          AbsenceFormValidator.validateReason(""),
          "Vui lòng nhập lý do xin vắng thi",
        );
        expect(
          AbsenceFormValidator.validateReason("         "),
          "Vui lòng nhập lý do xin vắng thi",
        );
      });

      test('[18E2] Min length (< 10 chars)', () {
        expect(
          AbsenceFormValidator.validateReason("Bị ốm"),
          "Lý do xin vắng thi phải từ 10 ký tự trở lên",
        );
        expect(
          AbsenceFormValidator.validateReason("Em bị đau"),
          "Lý do xin vắng thi phải từ 10 ký tự trở lên",
        );
      });

      test('[18E3] Max length (> 500 chars)', () {
        final longReason = "Lý do vắng thi chi tiết " * 30; // > 500 chars
        expect(
          AbsenceFormValidator.validateReason(longReason),
          "Lý do xin vắng thi không được vượt quá 500 ký tự",
        );
      });

      test('Valid Reasons (10 to 500 chars)', () {
        expect(
          AbsenceFormValidator.validateReason(
            "Em bị sốt xuất huyết phải nhập viện điều trị tại BV Bạch Mai",
          ),
          isNull,
        );
        expect(
          AbsenceFormValidator.validateReason(
            "Trùng lịch thi sát hạch chứng chỉ quốc tế được nhà trường phê duyệt",
          ),
          isNull,
        );
      });
    });

    // ==================== 5. TÀI LIỆU MINH CHỨNG (19E1 - 19E4) ====================
    group('5. Proof URL Constraints (Tài liệu minh chứng)', () {
      test('[19E1] Empty / Null check', () {
        expect(
          AbsenceFormValidator.validateProofUrl(null),
          "Bắt buộc cung cấp đường dẫn tài liệu minh chứng",
        );
        expect(
          AbsenceFormValidator.validateProofUrl(""),
          "Bắt buộc cung cấp đường dẫn tài liệu minh chứng",
        );
      });

      test('[19E4] Whitespace check', () {
        expect(
          AbsenceFormValidator.validateProofUrl(
            "https://drive.google.com/file/d/1a2b 3c4d",
          ),
          "Đường dẫn không được chứa khoảng trắng",
        );
      });

      test('[19E2] Must start with https://', () {
        expect(
          AbsenceFormValidator.validateProofUrl(
            "http://drive.google.com/file/d/123456789",
          ),
          "Đường dẫn minh chứng phải bắt đầu bằng https://",
        );
        expect(
          AbsenceFormValidator.validateProofUrl(
            "ftp://files.example.com/don_xin.pdf",
          ),
          "Đường dẫn minh chứng phải bắt đầu bằng https://",
        );
      });

      test('[19E3] Invalid source (Not Google Drive and not direct image/PDF)', () {
        expect(
          AbsenceFormValidator.validateProofUrl("https://facebook.com/myphoto"),
          "Đường dẫn minh chứng phải là link Google Drive hoặc tệp ảnh/PDF trực tiếp",
        );
        expect(
          AbsenceFormValidator.validateProofUrl("https://example.com/document.docx"),
          "Đường dẫn minh chứng phải là link Google Drive hoặc tệp ảnh/PDF trực tiếp",
        );
      });

      test('Valid Proof URLs (Google Drive files, folders & direct jpg/jpeg/png/pdf)', () {
        expect(
          AbsenceFormValidator.validateProofUrl(
            "https://drive.google.com/file/d/1a2b3c4d5e/view?usp=sharing",
          ),
          isNull,
        );
        expect(
          AbsenceFormValidator.validateProofUrl(
            "https://drive.google.com/drive/folders/1a2b3c4d5e6f7g8h",
          ),
          isNull,
        );
        expect(
          AbsenceFormValidator.validateProofUrl(
            "https://mycdn.tlu.edu.vn/uploads/giay_ra_vien.jpg",
          ),
          isNull,
        );
        expect(
          AbsenceFormValidator.validateProofUrl(
            "https://mycdn.tlu.edu.vn/uploads/giay_ra_vien.jpeg",
          ),
          isNull,
        );
        expect(
          AbsenceFormValidator.validateProofUrl(
            "https://mycdn.tlu.edu.vn/uploads/minh_chung.png",
          ),
          isNull,
        );
        expect(
          AbsenceFormValidator.validateProofUrl(
            "https://mycdn.tlu.edu.vn/uploads/don_xac_nhan.pdf",
          ),
          isNull,
        );
      });

      test('[19E3_ext] Valid Google Drive multi-account URLs (dạng /u/N/)', () {
        // /drive/u/0/folders/ – pattern phổ biến khi Google Drive mở đa tài khoản
        expect(
          AbsenceFormValidator.validateProofUrl(
            "https://drive.google.com/drive/u/0/folders/1a2b3c4d5e6f7g8h",
          ),
          isNull,
        );
        // /drive/u/1/folders/ – tài khoản thứ hai
        expect(
          AbsenceFormValidator.validateProofUrl(
            "https://drive.google.com/drive/u/1/folders/1a2b3c4d5e6f7g8h",
          ),
          isNull,
        );
        // /u/0/folders/ – không có "drive/" nhưng vẫn hợp lệ
        expect(
          AbsenceFormValidator.validateProofUrl(
            "https://drive.google.com/u/0/folders/1a2b3c4d5e6f7g8h",
          ),
          isNull,
        );
        // /u/0/file/d/ – file đơn lẻ qua multi-account
        expect(
          AbsenceFormValidator.validateProofUrl(
            "https://drive.google.com/u/0/file/d/1a2b3c4d5e/view?usp=sharing",
          ),
          isNull,
        );
        // /drive/u/2/ – số tài khoản bất kỳ
        expect(
          AbsenceFormValidator.validateProofUrl(
            "https://drive.google.com/drive/u/2/folders/XYZ123",
          ),
          isNull,
        );
        // Dạng chuẩn không có /u/N/ vẫn phải pass
        expect(
          AbsenceFormValidator.validateProofUrl(
            "https://drive.google.com/drive/folders/1a2b3c4d5e6f7g8h",
          ),
          isNull,
        );
        expect(
          AbsenceFormValidator.validateProofUrl(
            "https://drive.google.com/file/d/1a2b3c4d5e/view?usp=sharing",
          ),
          isNull,
        );
      });

      test('[19E3_ext] Invalid Drive-like URLs must still fail', () {
        // drive.google.com nhưng thiếu "folders/" hoặc "file/d/"
        expect(
          AbsenceFormValidator.validateProofUrl(
            "https://drive.google.com/u/0/random/abc",
          ),
          "Đường dẫn minh chứng phải là link Google Drive hoặc tệp ảnh/PDF trực tiếp",
        );
        // Tên miền giả mạo
        expect(
          AbsenceFormValidator.validateProofUrl(
            "https://drive.google.vn/drive/u/0/folders/abc123",
          ),
          "Đường dẫn minh chứng phải là link Google Drive hoặc tệp ảnh/PDF trực tiếp",
        );
      });
    });

    // ==================== 6. MÔN HỌC & CA THI (20E1 - 20E4) ====================
    group('6. Subject and Exam Shift Business Constraints', () {
      test('[20E1] Subject not selected', () {
        expect(
          AbsenceFormValidator.validateSubjectSelected(null),
          "Vui lòng chọn môn học xin vắng thi",
        );
        expect(
          AbsenceFormValidator.validateSubjectSelected(""),
          "Vui lòng chọn môn học xin vắng thi",
        );
        expect(
          AbsenceFormValidator.validateSubjectSelected("SUB_01"),
          isNull,
        );
      });

      test('[20E2] Student not enrolled in exam list', () {
        expect(
          AbsenceFormValidator.validateStudentInExamList(isInExamList: false),
          "Bạn không thuộc danh sách dự thi của môn học này",
        );
        expect(
          AbsenceFormValidator.validateStudentInExamList(isInExamList: true),
          isNull,
        );
      });

      test('[20E3] Exam deadline validation (<= 48 hours after exam time)', () {
        final examTime = DateTime(2026, 10, 1, 8, 0);

        // Before exam time -> Valid
        expect(
          AbsenceFormValidator.validateExamDeadline(
            examTime: examTime,
            submissionTime: DateTime(2026, 9, 30, 10, 0),
          ),
          isNull,
        );

        // 24 hours after exam time -> Valid (within 48h)
        expect(
          AbsenceFormValidator.validateExamDeadline(
            examTime: examTime,
            submissionTime: DateTime(2026, 10, 2, 8, 0),
          ),
          isNull,
        );

        // Exactly 48 hours after exam time -> Valid
        expect(
          AbsenceFormValidator.validateExamDeadline(
            examTime: examTime,
            submissionTime: DateTime(2026, 10, 3, 8, 0),
          ),
          isNull,
        );

        // 49 hours after exam time -> Expired (Lỗi 20E3)
        expect(
          AbsenceFormValidator.validateExamDeadline(
            examTime: examTime,
            submissionTime: DateTime(2026, 10, 3, 9, 0),
          ),
          "Đã hết thời hạn nộp đơn xin vắng thi cho môn học này (quá 48 giờ kể từ ca thi)",
        );
      });

      test('[20E4] Duplicate pending request check', () {
        expect(
          AbsenceFormValidator.validateNoPendingDuplicate(
            hasPendingRequest: true,
          ),
          "Bạn đã gửi đơn xin vắng thi cho môn này và đang chờ duyệt",
        );
        expect(
          AbsenceFormValidator.validateNoPendingDuplicate(
            hasPendingRequest: false,
          ),
          isNull,
        );
      });
    });
  });
}
