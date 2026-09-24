import 'package:flutter_test/flutter_test.dart';
import 'package:edulog/core/utils/subject_validator.dart';

void main() {
  group('SubjectValidator - Module: Thêm môn học mới', () {
    group('1. Subject Name Constraints (Tên môn học)', () {
      test('[5E2] Empty check', () {
        expect(SubjectValidator.validateSubjectName(null), "Tên môn học không được để trống");
        expect(SubjectValidator.validateSubjectName(""), "Tên môn học không được để trống");
        expect(SubjectValidator.validateSubjectName("   "), "Tên môn học không được để trống");
      });

      test('[5E3] Min length (< 3 chars)', () {
        expect(SubjectValidator.validateSubjectName("IT"), "Tên môn học phải từ 3 ký tự trở lên");
        expect(SubjectValidator.validateSubjectName("C#"), "Tên môn học phải từ 3 ký tự trở lên");
      });

      test('[5E4] Max length (> 100 chars)', () {
        final longName = 'A' * 101;
        expect(SubjectValidator.validateSubjectName(longName), "Tên môn học không được vượt quá 100 ký tự");
      });

      test('[5E5] Leading/trailing whitespace or multiple spaces', () {
        expect(SubjectValidator.validateSubjectName(" Lập trình Web"), "Tên môn học chứa ký tự không hợp lệ");
        expect(SubjectValidator.validateSubjectName("Lập trình Web "), "Tên môn học chứa ký tự không hợp lệ");
        expect(SubjectValidator.validateSubjectName("Lập  trình Web"), "Tên môn học chứa ký tự không hợp lệ");
      });

      test('[5E5] High-risk and malicious symbols check', () {
        expect(SubjectValidator.validateSubjectName("Web <script>"), "Tên môn học chứa ký tự không hợp lệ");
        expect(SubjectValidator.validateSubjectName("Web > App"), "Tên môn học chứa ký tự không hợp lệ");
        expect(SubjectValidator.validateSubjectName("Web; Drop"), "Tên môn học chứa ký tự không hợp lệ");
        expect(SubjectValidator.validateSubjectName("Web {1}"), "Tên môn học chứa ký tự không hợp lệ");
        expect(SubjectValidator.validateSubjectName(r"Web \ App"), "Tên môn học chứa ký tự không hợp lệ");
      });

      test('[5E5] Disallowed symbols check', () {
        expect(SubjectValidator.validateSubjectName("Lập trình @1"), "Tên môn học chứa ký tự không hợp lệ");
        expect(SubjectValidator.validateSubjectName("Lập trình #1"), "Tên môn học chứa ký tự không hợp lệ");
        expect(SubjectValidator.validateSubjectName(r"Lập trình $1"), "Tên môn học chứa ký tự không hợp lệ");
      });

      test('[5E5] Valid subject names with Vietnamese, English, digits, safe separators', () {
        expect(SubjectValidator.validateSubjectName("Lập trình Web"), isNull);
        expect(SubjectValidator.validateSubjectName("Cơ sở Dữ liệu"), isNull);
        expect(SubjectValidator.validateSubjectName("Toán rời rạc - Nâng cao"), isNull);
        expect(SubjectValidator.validateSubjectName("Nhập môn Lập trình (K65)"), isNull);
        expect(SubjectValidator.validateSubjectName("Kỹ thuật Phần mềm v1.0"), isNull);
      });
    });

    group('2. Subject Code Constraints (Mã môn học)', () {
      test('[6E1] Empty check', () {
        expect(SubjectValidator.validateSubjectCode(null), "Mã môn học không được để trống");
        expect(SubjectValidator.validateSubjectCode(""), "Mã môn học không được để trống");
        expect(SubjectValidator.validateSubjectCode("   "), "Mã môn học không được để trống");
      });

      test('[6E2] Total length check (< 5 or > 10 chars)', () {
        expect(SubjectValidator.validateSubjectCode("INT1"), "Mã môn học phải từ 5 đến 10 ký tự");
        expect(SubjectValidator.validateSubjectCode("IT01"), "Mã môn học phải từ 5 đến 10 ký tự");
        expect(SubjectValidator.validateSubjectCode("INT12345678"), "Mã môn học phải từ 5 đến 10 ký tự"); // 11 chars
      });

      test('[6E5] Character check (only uppercase letters and digits, no spaces, no special)', () {
        expect(SubjectValidator.validateSubjectCode("int3134"), "Mã môn học chỉ gồm chữ in hoa và chữ số, không chứa khoảng trắng");
        expect(SubjectValidator.validateSubjectCode("INT 3134"), "Mã môn học chỉ gồm chữ in hoa và chữ số, không chứa khoảng trắng");
        expect(SubjectValidator.validateSubjectCode("INT-3134"), "Mã môn học chỉ gồm chữ in hoa và chữ số, không chứa khoảng trắng");
        expect(SubjectValidator.validateSubjectCode("INT_3134"), "Mã môn học chỉ gồm chữ in hoa và chữ số, không chứa khoảng trắng");
        expect(SubjectValidator.validateSubjectCode("INT@3134"), "Mã môn học chỉ gồm chữ in hoa và chữ số, không chứa khoảng trắng");
      });

      test('[6E3] Prefix structure check (2 to 4 uppercase letters)', () {
        expect(SubjectValidator.validateSubjectCode("12345"), "Mã bộ môn/khoa không hợp lệ");
        expect(SubjectValidator.validateSubjectCode("I1234"), "Mã bộ môn/khoa không hợp lệ");
        expect(SubjectValidator.validateSubjectCode("ABCDE123"), "Mã bộ môn/khoa không hợp lệ");
      });

      test('[6E4] Suffix structure check (3 to 6 digits)', () {
        expect(SubjectValidator.validateSubjectCode("INT12"), "Mã môn học phải kết thúc bằng các chữ số"); // only 2 digits
        expect(SubjectValidator.validateSubjectCode("INT12A4"), "Mã môn học phải kết thúc bằng các chữ số");
        expect(SubjectValidator.validateSubjectCode("INTABCD"), "Mã môn học phải kết thúc bằng các chữ số");
      });

      test('Valid Subject Codes', () {
        expect(SubjectValidator.validateSubjectCode("INT3134"), isNull);
        expect(SubjectValidator.validateSubjectCode("CSE401"), isNull);
        expect(SubjectValidator.validateSubjectCode("SWE2101"), isNull);
        expect(SubjectValidator.validateSubjectCode("IT101"), isNull);
        expect(SubjectValidator.validateSubjectCode("MTH1001"), isNull);
      });
    });

    group('3. Semester Constraints (Học kỳ)', () {
      test('[7E1] Null or unselected check', () {
        expect(SubjectValidator.validateSemester(null), "Vui lòng chọn học kỳ áp dụng");
        expect(SubjectValidator.validateSemester(""), "Vui lòng chọn học kỳ áp dụng");
        expect(SubjectValidator.validateSemester("   "), "Vui lòng chọn học kỳ áp dụng");
      });

      test('[7E2] Enum whitelist / schema validation', () {
        expect(SubjectValidator.validateSemester("Summer-2025"), "Học kỳ được chọn không hợp lệ trong hệ thống");
        expect(SubjectValidator.validateSemester("HK4-2025"), "Học kỳ được chọn không hợp lệ trong hệ thống");
        expect(SubjectValidator.validateSemester("HK1_2025"), "Học kỳ được chọn không hợp lệ trong hệ thống");
        expect(SubjectValidator.validateSemester("HK1-25"), "Học kỳ được chọn không hợp lệ trong hệ thống");
        expect(SubjectValidator.validateSemester("HK1-1999"), "Học kỳ được chọn không hợp lệ trong hệ thống");
      });

      test('[7E2] Whitelist array validation', () {
        final allowed = ['HK1-2025', 'HK2-2024'];
        expect(SubjectValidator.validateSemester("HK1-2025", allowedSemesters: allowed), isNull);
        expect(SubjectValidator.validateSemester("HK2-2024", allowedSemesters: allowed), isNull);
        expect(SubjectValidator.validateSemester("HK1-2026", allowedSemesters: allowed), "Học kỳ được chọn không hợp lệ trong hệ thống");
      });

      test('Valid Semesters', () {
        expect(SubjectValidator.validateSemester("HK1-2024"), isNull);
        expect(SubjectValidator.validateSemester("HK2-2024"), isNull);
        expect(SubjectValidator.validateSemester("HK1-2025"), isNull);
        expect(SubjectValidator.validateSemester("HK2-2025"), isNull);
        expect(SubjectValidator.validateSemester("HK1-2026"), isNull);
      });
    });
  });
}
