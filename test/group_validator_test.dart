import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:edulog/core/utils/group_validator.dart';

void main() {
  group('1. Group Name Constraints', () {
    test('[1E2] Empty check', () {
      expect(GroupValidator.validateGroupName(null), "Tên nhóm không được để trống");
      expect(GroupValidator.validateGroupName(""), "Tên nhóm không được để trống");
      expect(GroupValidator.validateGroupName("   "), "Tên nhóm không được để trống");
    });

    test('[1E3] Min length (< 3 chars)', () {
      expect(GroupValidator.validateGroupName("A"), "Tên nhóm phải có độ dài tối thiểu 3 ký tự");
      expect(GroupValidator.validateGroupName("AB"), "Tên nhóm phải có độ dài tối thiểu 3 ký tự");
      expect(GroupValidator.validateGroupName("  12  "), "Tên nhóm phải có độ dài tối thiểu 3 ký tự");
    });

    test('[1E4] Max length (> 50 chars)', () {
      final name50 = 'A' * 50;
      final name51 = 'A' * 51;
      expect(GroupValidator.validateGroupName(name50), null);
      expect(GroupValidator.validateGroupName(name51), "Tên nhóm không được vượt quá 50 ký tự");
    });

    test('[1E5] Special character check', () {
      expect(GroupValidator.validateGroupName("Nhóm @ 1"), "Tên nhóm chứa ký tự đặc biệt không hợp lệ");
      expect(GroupValidator.validateGroupName("Nhóm #1!"), "Tên nhóm chứa ký tự đặc biệt không hợp lệ");
      expect(GroupValidator.validateGroupName("Nhóm (1)"), "Tên nhóm chứa ký tự đặc biệt không hợp lệ");
      expect(GroupValidator.validateGroupName("Nhóm / 1"), "Tên nhóm chứa ký tự đặc biệt không hợp lệ");

      // Valid: Vietnamese letters, English letters, digits, whitespace, and hyphens/underscores/dots (-, _, .)
      expect(GroupValidator.validateGroupName("Nhóm 6 - App EduLog"), null);
      expect(GroupValidator.validateGroupName("Nhom_01.V2"), null);
      expect(GroupValidator.validateGroupName("Đội Tuyển Tin Học"), null);
      expect(GroupValidator.validateGroupName("Nhóm-01_v2.0"), null);
    });
  });

  group('2. GitHub URL Constraints', () {
    test('[2E2] Empty check', () {
      expect(GroupValidator.validateGithubUrl(null), "Đường dẫn GitHub không được để trống");
      expect(GroupValidator.validateGithubUrl(""), "Đường dẫn GitHub không được để trống");
    });

    test('[2E5] Whitespace check', () {
      expect(GroupValidator.validateGithubUrl("https://github.com/ owner/repo"), "Đường dẫn GitHub chứa ký tự không hợp lệ");
      expect(GroupValidator.validateGithubUrl(" https://github.com/owner/repo"), "Đường dẫn GitHub chứa ký tự không hợp lệ");
      expect(GroupValidator.validateGithubUrl("https://github.com/owner/repo "), "Đường dẫn GitHub chứa ký tự không hợp lệ");
      expect(GroupValidator.validateGithubUrl("   "), "Đường dẫn GitHub chứa ký tự không hợp lệ");
    });

    test('[2E3] Protocol & Domain check', () {
      expect(GroupValidator.validateGithubUrl("http://github.com/owner/repo"), "Đường dẫn phải bắt đầu bằng https://github.com/");
      expect(GroupValidator.validateGithubUrl("https://gitlab.com/owner/repo"), "Đường dẫn phải bắt đầu bằng https://github.com/");
      expect(GroupValidator.validateGithubUrl("github.com/owner/repo"), "Đường dẫn phải bắt đầu bằng https://github.com/");
    });

    test('[2E4] Structure check', () {
      expect(GroupValidator.validateGithubUrl("https://github.com/"), "Đường dẫn kho GitHub không đúng cấu trúc (thiếu chủ sở hữu hoặc tên repo)");
      expect(GroupValidator.validateGithubUrl("https://github.com/owner"), "Đường dẫn kho GitHub không đúng cấu trúc (thiếu chủ sở hữu hoặc tên repo)");
      expect(GroupValidator.validateGithubUrl("https://github.com/-owner/repo"), "Đường dẫn kho GitHub không đúng cấu trúc (thiếu chủ sở hữu hoặc tên repo)");
      expect(GroupValidator.validateGithubUrl("https://github.com/owner-/repo"), "Đường dẫn kho GitHub không đúng cấu trúc (thiếu chủ sở hữu hoặc tên repo)");
      expect(GroupValidator.validateGithubUrl("https://github.com/owner/repo/extra"), "Đường dẫn kho GitHub không đúng cấu trúc (thiếu chủ sở hữu hoặc tên repo)");
      
      // Valid URLs
      expect(GroupValidator.validateGithubUrl("https://github.com/owner/repo"), null);
      expect(GroupValidator.validateGithubUrl("https://github.com/owner/repo/"), null);
      expect(GroupValidator.validateGithubUrl("https://github.com/user_1/my-repo.dart"), null);
    });

    test('[2E6] Accessibility check via GitHub API (Mock Client)', () async {
      // 200 OK -> accessible
      final clientOk = MockClient((request) async {
        return http.Response('{"name": "repo"}', 200);
      });
      final resOk = await GroupValidator.checkGithubAccessibility('https://github.com/flutter/flutter', client: clientOk);
      expect(resOk, null);

      // 404 Not Found -> Private or does not exist
      final client404 = MockClient((request) async {
        return http.Response('{"message": "Not Found"}', 404);
      });
      final res404 = await GroupValidator.checkGithubAccessibility('https://github.com/secret/repo', client: client404);
      expect(res404, "Không thể truy cập kho GitHub. Vui lòng kiểm tra quyền công khai hoặc tồn tại của repo");

      // 403 API rate limit fallback to web page 200 OK
      final client403WithWebOk = MockClient((request) async {
        if (request.url.host == 'api.github.com') {
          return http.Response('{"message": "rate limited"}', 403);
        }
        return http.Response('<html>GitHub repo</html>', 200);
      });
      final res403Ok = await GroupValidator.checkGithubAccessibility('https://github.com/owner/repo', client: client403WithWebOk);
      expect(res403Ok, null);

      // Network exception
      final clientError = MockClient((request) async {
        throw Exception("Network failure");
      });
      final resError = await GroupValidator.checkGithubAccessibility('https://github.com/owner/repo', client: clientError);
      expect(resError, "Không thể truy cập kho GitHub. Vui lòng kiểm tra quyền công khai hoặc tồn tại của repo");
    });
  });

  group('3. Google Docs URL Constraints', () {
    test('[3E2] Empty check', () {
      expect(GroupValidator.validateDocsUrl(null), "Đường dẫn Google Docs không được để trống");
      expect(GroupValidator.validateDocsUrl(""), "Đường dẫn Google Docs không được để trống");
      expect(GroupValidator.validateDocsUrl("   "), "Đường dẫn Google Docs không được để trống");
    });

    test('[3E3] Domain check', () {
      expect(GroupValidator.validateDocsUrl("https://docs.google.vn/document/d/123456789012"), "Đường dẫn phải thuộc tên miền Google Docs hoặc Google Drive");
      expect(GroupValidator.validateDocsUrl("https://google.com/document/d/123456789012"), "Đường dẫn phải thuộc tên miền Google Docs hoặc Google Drive");
      expect(GroupValidator.validateDocsUrl("http://docs.google.com/document/d/123456789012"), "Đường dẫn phải thuộc tên miền Google Docs hoặc Google Drive");
    });

    test('[3E4] Document ID check', () {
      expect(GroupValidator.validateDocsUrl("https://docs.google.com/document/d/"), "Đường dẫn không chứa mã tài liệu hợp lệ");
      expect(GroupValidator.validateDocsUrl("https://docs.google.com/document/d/short"), "Đường dẫn không chứa mã tài liệu hợp lệ"); // < 10 chars
      final tooLong = 'A' * 51;
      expect(GroupValidator.validateDocsUrl("https://docs.google.com/document/d/$tooLong"), "Đường dẫn không chứa mã tài liệu hợp lệ");
      
      // Valid URLs
      expect(GroupValidator.validateDocsUrl("https://docs.google.com/document/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit"), null);
      expect(GroupValidator.validateDocsUrl("https://drive.google.com/file/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/view"), null);
    });

    test('[3E5] Public access check (Mock Client)', () async {
      // 200 OK without login -> public
      final clientOk = MockClient((request) async {
        return http.Response('<html><body>Public Document Content</body></html>', 200);
      });
      final resOk = await GroupValidator.checkDocsPublicAccess('https://docs.google.com/document/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit', client: clientOk);
      expect(resOk, null);

      // Redirected to accounts.google.com / signin
      final clientSignIn = MockClient((request) async {
        return http.Response(
          '<html><head><title>Sign in - Google Accounts</title></head><body>accounts.google.com/ServiceLogin</body></html>',
          200,
          request: http.Request('GET', Uri.parse('https://accounts.google.com/ServiceLogin')),
        );
      });
      final resSignIn = await GroupValidator.checkDocsPublicAccess('https://docs.google.com/document/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit', client: clientSignIn);
      expect(resSignIn, "Tài liệu chưa được cấp quyền xem công khai (Anyone with the link can view)");

      // 403 Forbidden
      final client403 = MockClient((request) async {
        return http.Response('Forbidden', 403);
      });
      final res403 = await GroupValidator.checkDocsPublicAccess('https://docs.google.com/document/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit', client: client403);
      expect(res403, "Tài liệu chưa được cấp quyền xem công khai (Anyone with the link can view)");

      // Body contains Access Denied
      final clientDenied = MockClient((request) async {
        return http.Response('<html>Google Docs - Access denied. You need access.</html>', 200);
      });
      final resDenied = await GroupValidator.checkDocsPublicAccess('https://docs.google.com/document/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit', client: clientDenied);
      expect(resDenied, "Tài liệu chưa được cấp quyền xem công khai (Anyone with the link can view)");

      // XMLHttpRequest CORS error on Web -> gracefully allowed
      final clientCors = MockClient((request) async {
        throw http.ClientException('XMLHttpRequest error.', Uri.parse('https://docs.google.com'));
      });
      final resCors = await GroupValidator.checkDocsPublicAccess('https://docs.google.com/document/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit', client: clientCors);
      expect(resCors, null);
    });
  });

  group('Equality and extraction helpers', () {
    test('areGithubUrlsEqual', () {
      expect(
        GroupValidator.areGithubUrlsEqual(
          'https://github.com/flutter/flutter',
          'https://github.com/flutter/flutter/',
        ),
        isTrue,
      );
      expect(
        GroupValidator.areGithubUrlsEqual(
          'https://github.com/Flutter/Flutter.git',
          'https://github.com/flutter/flutter',
        ),
        isTrue,
      );
      expect(
        GroupValidator.areGithubUrlsEqual(
          'https://github.com/user1/repoA',
          'https://github.com/user1/repoB',
        ),
        isFalse,
      );
    });

    test('areDocsUrlsEqual', () {
      expect(
        GroupValidator.areDocsUrlsEqual(
          'https://docs.google.com/document/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit',
          'https://docs.google.com/document/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/view?usp=sharing',
        ),
        isTrue,
      );
      expect(
        GroupValidator.areDocsUrlsEqual(
          'https://docs.google.com/document/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit',
          'https://drive.google.com/file/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/view',
        ),
        isTrue,
      );
      expect(
        GroupValidator.areDocsUrlsEqual(
          'https://docs.google.com/document/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit',
          'https://docs.google.com/document/d/anotherId1234567890/edit',
        ),
        isFalse,
      );
    });
  });
}
