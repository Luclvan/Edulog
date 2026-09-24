import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GroupValidationException implements Exception {
  final String message;
  final String? field; // 'name', 'github', 'docs'

  GroupValidationException(this.message, {this.field});

  @override
  String toString() => message;
}

class GroupValidator {
  static final RegExp _groupNamePattern = RegExp(
    r'^[a-zA-Z0-9\s\-_.'
    r'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ'
    r'ÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ'
    r']+$',
  );

  static final RegExp _githubStructurePattern = RegExp(
    r'^https:\/\/github\.com\/([a-zA-Z0-9_-]+)\/([a-zA-Z0-9_.-]+)\/?$',
  );

  static final RegExp _docsPattern = RegExp(
    r'^https:\/\/(?:docs\.google\.com\/document|drive\.google\.com\/file)\/d\/([a-zA-Z0-9_-]+)',
  );

  // ==================== 1. GROUP NAME SYNCHRONOUS CHECKS ====================

  /// Validates group name synchronously (1E2 - 1E5)
  static String? validateGroupName(String? value) {
    // [1E2] Empty check
    if (value == null || value.trim().isEmpty) {
      return "Tên nhóm không được để trống";
    }
    final trimmed = value.trim();

    // [1E3] Min length (< 3 chars)
    if (trimmed.length < 3) {
      return "Tên nhóm phải có độ dài tối thiểu 3 ký tự";
    }

    // [1E4] Max length (> 50 chars)
    if (trimmed.length > 50) {
      return "Tên nhóm không được vượt quá 50 ký tự";
    }

    // [1E5] Special character check
    if (!_groupNamePattern.hasMatch(trimmed)) {
      return "Tên nhóm chứa ký tự đặc biệt không hợp lệ";
    }

    return null;
  }

  // ==================== 2. GITHUB URL SYNCHRONOUS CHECKS ====================

  /// Validates GitHub URL synchronously (2E2 - 2E5)
  static String? validateGithubUrl(String? value) {
    // [2E2] Empty check
    if (value == null || value.isEmpty) {
      return "Đường dẫn GitHub không được để trống";
    }

    // [2E5] Whitespace check
    if (value.contains(RegExp(r'\s'))) {
      return "Đường dẫn GitHub chứa ký tự không hợp lệ";
    }

    // [2E3] Protocol & Domain check
    if (!value.startsWith('https://github.com/')) {
      return "Đường dẫn phải bắt đầu bằng https://github.com/";
    }

    // [2E4] Structure check
    final match = _githubStructurePattern.firstMatch(value);
    if (match == null) {
      return "Đường dẫn kho GitHub không đúng cấu trúc (thiếu chủ sở hữu hoặc tên repo)";
    }
    final owner = match.group(1)!;
    if (owner.startsWith('-') || owner.endsWith('-')) {
      return "Đường dẫn kho GitHub không đúng cấu trúc (thiếu chủ sở hữu hoặc tên repo)";
    }

    return null;
  }

  // ==================== 3. GOOGLE DOCS URL SYNCHRONOUS CHECKS ====================

  /// Validates Google Docs URL synchronously (3E2 - 3E4)
  static String? validateDocsUrl(String? value) {
    // [3E2] Empty check
    if (value == null || value.trim().isEmpty) {
      return "Đường dẫn Google Docs không được để trống";
    }
    final trimmed = value.trim();

    // [3E3] Domain check
    if (!trimmed.startsWith('https://docs.google.com/document/d/') &&
        !trimmed.startsWith('https://drive.google.com/file/d/')) {
      return "Đường dẫn phải thuộc tên miền Google Docs hoặc Google Drive";
    }

    // [3E4] Document ID check
    final match = _docsPattern.firstMatch(trimmed);
    if (match == null) {
      return "Đường dẫn không chứa mã tài liệu hợp lệ";
    }
    final docId = match.group(1)!;
    if (docId.length < 10 || docId.length > 50) {
      return "Đường dẫn không chứa mã tài liệu hợp lệ";
    }

    return null;
  }

  // ==================== ASYNCHRONOUS ACCESSIBILITY CHECKS ====================

  /// [2E6] Accessibility check via GitHub API / repo URL
  static Future<String?> checkGithubAccessibility(
    String githubUrl, {
    http.Client? client,
  }) async {
    final info = extractGithubOwnerRepo(githubUrl);
    if (info == null) {
      return "Đường dẫn kho GitHub không đúng cấu trúc (thiếu chủ sở hữu hoặc tên repo)";
    }

    final owner = info['owner']!;
    var repo = info['repo']!;
    if (repo.endsWith('.git')) {
      repo = repo.substring(0, repo.length - 4);
    }

    final httpClient = client ?? http.Client();
    final shouldClose = client == null;

    try {
      // 1. Send GET request to GitHub API
      final apiUrl = Uri.parse('https://api.github.com/repos/$owner/$repo');
      final response = await httpClient.get(
        apiUrl,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Edulog-App',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return null;
      }

      if (response.statusCode == 404) {
        return "Không thể truy cập kho GitHub. Vui lòng kiểm tra quyền công khai hoặc tồn tại của repo";
      }

      // If rate limited or forbidden on API, fallback to direct repo URL
      if (response.statusCode == 403) {
        final webUrl = Uri.parse('https://github.com/$owner/$repo');
        final webResponse = await httpClient.get(
          webUrl,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ).timeout(const Duration(seconds: 8));

        if (webResponse.statusCode == 200) {
          return null;
        }
        return "Không thể truy cập kho GitHub. Vui lòng kiểm tra quyền công khai hoặc tồn tại của repo";
      }

      return "Không thể truy cập kho GitHub. Vui lòng kiểm tra quyền công khai hoặc tồn tại của repo";
    } catch (e) {
      if (kIsWeb && e.toString().contains('XMLHttpRequest')) {
        return null;
      }
      return "Không thể truy cập kho GitHub. Vui lòng kiểm tra quyền công khai hoặc tồn tại của repo";
    } finally {
      if (shouldClose) {
        httpClient.close();
      }
    }
  }

  /// [3E5] Public access check for Google Docs / Drive URL
  static Future<String?> checkDocsPublicAccess(
    String docsUrl, {
    http.Client? client,
  }) async {
    final trimmed = docsUrl.trim();
    final docId = extractDocId(trimmed);
    if (docId == null) {
      return "Đường dẫn không chứa mã tài liệu hợp lệ";
    }

    // On Flutter Web, browser CORS blocks direct requests to docs.google.com with XMLHttpRequest error.
    // When on Web and using default client, allow the request if the URL and Document ID are valid.
    if (kIsWeb && client == null) {
      return null;
    }

    final httpClient = client ?? http.Client();
    final shouldClose = client == null;

    try {
      // 1. Determine check endpoint: for Google Docs, export?format=txt directly confirms public read access
      final isGoogleDoc = trimmed.startsWith('https://docs.google.com/document/d/');
      final checkUrl = isGoogleDoc
          ? 'https://docs.google.com/document/d/$docId/export?format=txt'
          : trimmed;

      final uri = Uri.parse(checkUrl);
      final response = await httpClient.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 8));

      // If status is not 200
      if (response.statusCode != 200) {
        return "Tài liệu chưa được cấp quyền xem công khai (Anyone with the link can view)";
      }

      // If followed redirect to accounts login
      final finalUrl = response.request?.url;
      if (finalUrl != null) {
        if (finalUrl.host.contains('accounts.google.com') ||
            finalUrl.path.contains('ServiceLogin') ||
            finalUrl.path.contains('signin')) {
          return "Tài liệu chưa được cấp quyền xem công khai (Anyone with the link can view)";
        }
      }

      // Check response body for sign-in or access denied strings
      final bodyLower = response.body.toLowerCase();
      if (bodyLower.contains('accounts.google.com/servicelogin') ||
          bodyLower.contains('accounts.google.com/v3/signin') ||
          bodyLower.contains('action="https://accounts.google.com') ||
          bodyLower.contains('google docs - access denied') ||
          bodyLower.contains('you need access') ||
          bodyLower.contains('bạn cần có quyền truy cập')) {
        return "Tài liệu chưa được cấp quyền xem công khai (Anyone with the link can view)";
      }

      return null;
    } catch (e) {
      // Gracefully handle browser CORS XMLHttpRequest errors on web
      if (kIsWeb || e.toString().contains('XMLHttpRequest')) {
        return null;
      }
      return "Tài liệu chưa được cấp quyền xem công khai (Anyone with the link can view)";
    } finally {
      if (shouldClose) {
        httpClient.close();
      }
    }
  }

  // ==================== HELPER METHODS ====================

  /// Extracts GitHub owner and repo name from URL
  static Map<String, String>? extractGithubOwnerRepo(String url) {
    final match = _githubStructurePattern.firstMatch(url.trim());
    if (match == null) return null;
    final owner = match.group(1)!;
    final repo = match.group(2)!;
    if (owner.startsWith('-') || owner.endsWith('-')) return null;
    return {'owner': owner, 'repo': repo};
  }

  /// Extracts Document ID from Google Docs or Drive URL
  static String? extractDocId(String url) {
    final match = _docsPattern.firstMatch(url.trim());
    if (match == null) return null;
    final docId = match.group(1)!;
    if (docId.length < 10 || docId.length > 50) return null;
    return docId;
  }

  /// Checks if two GitHub URLs refer to the same repository
  static bool areGithubUrlsEqual(String url1, String url2) {
    final info1 = extractGithubOwnerRepo(url1);
    final info2 = extractGithubOwnerRepo(url2);
    if (info1 != null && info2 != null) {
      var repo1 = info1['repo']!.toLowerCase();
      var repo2 = info2['repo']!.toLowerCase();
      if (repo1.endsWith('.git')) repo1 = repo1.substring(0, repo1.length - 4);
      if (repo2.endsWith('.git')) repo2 = repo2.substring(0, repo2.length - 4);
      return info1['owner']!.toLowerCase() == info2['owner']!.toLowerCase() &&
          repo1 == repo2;
    }
    return url1.trim().toLowerCase() == url2.trim().toLowerCase();
  }

  /// Checks if two Google Docs/Drive URLs refer to the same document
  static bool areDocsUrlsEqual(String url1, String url2) {
    final id1 = extractDocId(url1);
    final id2 = extractDocId(url2);
    if (id1 != null && id2 != null) {
      return id1 == id2;
    }
    return url1.trim() == url2.trim();
  }
}
