import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:edulog/core/utils/auth_validator.dart';
import 'package:edulog/core/utils/identity_validator.dart';

void main() {
  group('MODULE 1: User Registration Validation', () {
    group('1. Full Name Constraints', () {
      test('[12E1] Empty check', () {
        expect(AuthValidator.validateFullName(null), "Họ và tên không được để trống");
        expect(AuthValidator.validateFullName(""), "Họ và tên không được để trống");
      });

      test('[12E6] Whitespace formatting', () {
        expect(AuthValidator.validateFullName(" Đỗ Đình An"), "Họ và tên không chứa khoảng trắng thừa");
        expect(AuthValidator.validateFullName("Đỗ Đình An "), "Họ và tên không chứa khoảng trắng thừa");
        expect(AuthValidator.validateFullName("Đỗ  Đình An"), "Họ và tên không chứa khoảng trắng thừa");
      });

      test('[12E2] Min length (< 2 chars)', () {
        expect(AuthValidator.validateFullName("A"), "Họ và tên tối thiểu phải từ 2 ký tự");
      });

      test('[12E3] Max length (> 50 chars)', () {
        final longName = 'A' * 51;
        expect(AuthValidator.validateFullName(longName), "Họ và tên tối đa không quá 50 ký tự");
      });

      test('[12E4] Digit check', () {
        expect(AuthValidator.validateFullName("Đỗ Đình An 123"), "Họ và tên không được chứa chữ số");
        expect(AuthValidator.validateFullName("Nguyễn Văn 2"), "Họ và tên không được chứa chữ số");
      });

      test('[12E5] Special character check', () {
        expect(AuthValidator.validateFullName("Đỗ Đình An @!"), "Họ và tên không được chứa ký tự đặc biệt");
        expect(AuthValidator.validateFullName("Đỗ Đình An - Lee"), "Họ và tên không được chứa ký tự đặc biệt");
      });

      test('Valid Full Names', () {
        expect(AuthValidator.validateFullName("Đỗ Đình An"), null);
        expect(AuthValidator.validateFullName("Nguyễn Thị Mai Lan"), null);
        expect(AuthValidator.validateFullName("John Doe"), null);
      });
    });

    group('2. Institutional Email Constraints', () {
      test('[13E2] Empty check', () {
        expect(AuthValidator.validateEmail(null), "Email không được để trống");
        expect(AuthValidator.validateEmail(""), "Email không được để trống");
      });

      test('[13E5] Whitespace check', () {
        expect(AuthValidator.validateEmail("an @e.tlu.edu.vn"), "Email không được chứa khoảng trắng");
        expect(AuthValidator.validateEmail("an@e.tlu.edu.vn "), "Email không được chứa khoảng trắng");
      });

      test('[13E3] Structure check', () {
        expect(AuthValidator.validateEmail("invalid-email"), "Định dạng email không hợp lệ");
        expect(AuthValidator.validateEmail("@e.tlu.edu.vn"), "Định dạng email không hợp lệ");
      });

      test('[13E4] TLU Domain restriction', () {
        expect(AuthValidator.validateEmail("student@gmail.com"), "Chỉ hỗ trợ email của ĐH Thủy Lợi (@e.tlu.edu.vn hoặc @tlu.edu.vn)");
        expect(AuthValidator.validateEmail("student@hust.edu.vn"), "Chỉ hỗ trợ email của ĐH Thủy Lợi (@e.tlu.edu.vn hoặc @tlu.edu.vn)");
      });

      test('Valid TLU Emails', () {
        expect(AuthValidator.validateEmail("2351170568@e.tlu.edu.vn"), null);
        expect(AuthValidator.validateEmail("teacher@tlu.edu.vn"), null);
      });
    });

    group('3. Password Security Constraints', () {
      test('[14E1] Empty check', () {
        expect(AuthValidator.validatePassword(null), "Mật khẩu không được để trống");
        expect(AuthValidator.validatePassword(""), "Mật khẩu không được để trống");
      });

      test('[14E8] Whitespace check', () {
        expect(AuthValidator.validatePassword("Pass word1@"), "Mật khẩu không được chứa khoảng trắng");
      });

      test('[14E2] Min length (< 8 chars)', () {
        expect(AuthValidator.validatePassword("Aa1@"), "Mật khẩu phải chứa ít nhất 8 ký tự");
      });

      test('[14E3] Max length (> 32 chars)', () {
        final longPass = 'Aa1@${'a' * 30}';
        expect(AuthValidator.validatePassword(longPass), "Mật khẩu không được vượt quá 32 ký tự");
      });

      test('[14E4] Uppercase letter check', () {
        expect(AuthValidator.validatePassword("password123@"), "Mật khẩu phải chứa ít nhất một chữ cái in hoa");
      });

      test('[14E5] Lowercase letter check', () {
        expect(AuthValidator.validatePassword("PASSWORD123@"), "Mật khẩu phải chứa ít nhất một chữ cái thường");
      });

      test('[14E6] Numeric digit check', () {
        expect(AuthValidator.validatePassword("Password@!"), "Mật khẩu phải chứa ít nhất một chữ số");
      });

      test('[14E7] Special character check', () {
        expect(AuthValidator.validatePassword("Password123"), "Mật khẩu phải chứa ít nhất một ký tự đặc biệt");
      });

      test('Valid Passwords', () {
        expect(AuthValidator.validatePassword("EduLog@2025"), null);
        expect(AuthValidator.validatePassword("Pass123_Secure"), null);
      });
    });

    group('4. Student ID Constraints', () {
      test('[15E2] Empty check', () {
        expect(AuthValidator.validateStudentId(null), "Mã sinh viên không được để trống");
        expect(AuthValidator.validateStudentId(""), "Mã sinh viên không được để trống");
      });

      test('[15E4] Numeric check', () {
        expect(AuthValidator.validateStudentId("235117056A"), "Mã sinh viên chỉ bao gồm các chữ số");
        expect(AuthValidator.validateStudentId("MSV1234567"), "Mã sinh viên chỉ bao gồm các chữ số");
      });

      test('[15E3] Exact length check', () {
        expect(AuthValidator.validateStudentId("235117"), "Mã sinh viên phải có độ dài chính xác 10 chữ số");
        expect(AuthValidator.validateStudentId("235117056899"), "Mã sinh viên phải có độ dài chính xác 10 chữ số");
      });

      test('[15E5] Cohort prefix check (18 to 26)', () {
        expect(AuthValidator.validateStudentId("1751170568"), "Khóa tuyển sinh không hợp lệ trong hệ thống");
        expect(AuthValidator.validateStudentId("2751170568"), "Khóa tuyển sinh không hợp lệ trong hệ thống");
      });

      test('Valid Student IDs', () {
        expect(AuthValidator.validateStudentId("2351170568"), null); // K65
        expect(AuthValidator.validateStudentId("1851170001"), null); // K60
        expect(AuthValidator.validateStudentId("2651179999"), null); // K68
      });
    });
  });

  group('MODULE 2: Profile & Identity Mapping Validation', () {
    group('1. GitHub Username Constraints', () {
      test('[16E1] Empty check', () {
        expect(IdentityValidator.validateGithubUsername(null), "GitHub Username không được để trống khi liên kết");
        expect(IdentityValidator.validateGithubUsername(""), "GitHub Username không được để trống khi liên kết");
      });

      test('[16E2] Max length (> 39 chars)', () {
        final longUser = 'a' * 40;
        expect(IdentityValidator.validateGithubUsername(longUser), "GitHub Username không được vượt quá 39 ký tự");
      });

      test('[16E3] Hyphen position', () {
        expect(IdentityValidator.validateGithubUsername("-user"), "GitHub Username không được bắt đầu hoặc kết thúc bằng dấu gạch ngang");
        expect(IdentityValidator.validateGithubUsername("user-"), "GitHub Username không được bắt đầu hoặc kết thúc bằng dấu gạch ngang");
      });

      test('[16E4] Consecutive hyphens', () {
        expect(IdentityValidator.validateGithubUsername("user--name"), "GitHub Username không được chứa các dấu gạch ngang liên tiếp");
      });

      test('[16E5] Character whitelist', () {
        expect(IdentityValidator.validateGithubUsername("user name"), "GitHub Username chỉ gồm chữ cái, chữ số và dấu gạch ngang đơn, không chứa khoảng trắng");
        expect(IdentityValidator.validateGithubUsername("user@name"), "GitHub Username chỉ gồm chữ cái, chữ số và dấu gạch ngang đơn, không chứa khoảng trắng");
      });

      test('Valid GitHub Usernames', () {
        expect(IdentityValidator.validateGithubUsername("levanluc"), null);
        expect(IdentityValidator.validateGithubUsername("user-123"), null);
      });

      test('[16E6] Online GitHub API verification (Mock)', () async {
        final client404 = MockClient((request) async {
          return http.Response('{"message": "Not Found"}', 404);
        });
        final res404 = await IdentityValidator.verifyGithubUserExists("nonexistentuser123987", client: client404);
        expect(res404, "Tài khoản GitHub không tồn tại. Vui lòng kiểm tra lại username");

        final client200 = MockClient((request) async {
          return http.Response('{"login": "flutter"}', 200);
        });
        final res200 = await IdentityValidator.verifyGithubUserExists("flutter", client: client200);
        expect(res200, null);
      });
    });

    group('2. Google Docs Display Name Constraints', () {
      test('[17E1] Empty/Whitespace check', () {
        expect(IdentityValidator.validateGoogleDisplayName(null), "Tên hiển thị Google Docs không được để trống");
        expect(IdentityValidator.validateGoogleDisplayName(""), "Tên hiển thị Google Docs không được để trống");
        expect(IdentityValidator.validateGoogleDisplayName("   "), "Tên hiển thị Google Docs không được để trống");
      });

      test('[17E2] Min length (< 2 chars)', () {
        expect(IdentityValidator.validateGoogleDisplayName("A"), "Tên hiển thị Google Docs phải từ 2 ký tự trở lên");
      });

      test('[17E3] Max length (> 50 chars)', () {
        final longName = 'A' * 51;
        expect(IdentityValidator.validateGoogleDisplayName(longName), "Tên hiển thị Google Docs không được vượt quá 50 ký tự");
      });

      test('[17E4] Malicious / Invalid characters', () {
        expect(IdentityValidator.validateGoogleDisplayName("User<script>"), "Tên hiển thị Google Docs chứa ký tự không hợp lệ");
        expect(IdentityValidator.validateGoogleDisplayName('User"Name'), "Tên hiển thị Google Docs chứa ký tự không hợp lệ");
        expect(IdentityValidator.validateGoogleDisplayName("User/Name"), "Tên hiển thị Google Docs chứa ký tự không hợp lệ");
        expect(IdentityValidator.validateGoogleDisplayName(r"User\Name"), "Tên hiển thị Google Docs chứa ký tự không hợp lệ");
      });

      test('Valid Google Docs Display Names', () {
        expect(IdentityValidator.validateGoogleDisplayName("Lực Lê"), null);
        expect(IdentityValidator.validateGoogleDisplayName("Đỗ Đình An (K65)"), null);
      });

      test('[17E] Author revision check (Async)', () async {
        final stats = [
          {'username': 'Lực Lê', 'percentage': 50},
          {'username': 'Đỗ Đình An', 'percentage': 50},
        ];

        // Found author
        final resFound = await IdentityValidator.verifyGoogleDocsAuthor('Lực Lê', docsStats: stats);
        expect(resFound, null);

        // Author not found in revision history
        final resNotFound = await IdentityValidator.verifyGoogleDocsAuthor('Nguyễn Văn Không Có', docsStats: stats);
        expect(resNotFound, "Không tìm thấy đóng góp của tác giả này trong lịch sử chỉnh sửa tài liệu Google Docs");
      });
    });
  });
}
