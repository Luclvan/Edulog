import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class IdentityValidator {
  // ==================== 1. GITHUB USERNAME VALIDATION ====================

  /// Validates GitHub Username synchronously (16E1 - 16E5)
  static String? validateGithubUsername(String? value) {
    // [16E1] Empty check
    if (value == null || value.trim().isEmpty) {
      return "GitHub Username không được để trống khi liên kết";
    }

    final trimmed = value.trim();

    // [16E2] Max length (> 39 chars)
    if (trimmed.length > 39) {
      return "GitHub Username không được vượt quá 39 ký tự";
    }

    // [16E3] Hyphen position (Must not start or end with a hyphen)
    if (trimmed.startsWith('-') || trimmed.endsWith('-')) {
      return "GitHub Username không được bắt đầu hoặc kết thúc bằng dấu gạch ngang";
    }

    // [16E4] Consecutive hyphens
    if (trimmed.contains('--')) {
      return "GitHub Username không được chứa các dấu gạch ngang liên tiếp";
    }

    // [16E5] Character whitelist (alphanumeric and single hyphen, no whitespace)
    if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(trimmed) || trimmed.contains(RegExp(r'\s'))) {
      return "GitHub Username chỉ gồm chữ cái, chữ số và dấu gạch ngang đơn, không chứa khoảng trắng";
    }

    return null;
  }

  /// [16E6] Online GitHub API verification (Async)
  static Future<String?> verifyGithubUserExists(
    String username, {
    http.Client? client,
  }) async {
    final trimmed = username.trim();
    final httpClient = client ?? http.Client();
    final shouldClose = client == null;

    try {
      final url = Uri.parse('https://api.github.com/users/$trimmed');
      final response = await httpClient.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Edulog-App',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return null;
      }

      if (response.statusCode == 404) {
        return "Tài khoản GitHub không tồn tại. Vui lòng kiểm tra lại username";
      }

      // If rate limited (403), fallback to direct web page check
      if (response.statusCode == 403) {
        final webUrl = Uri.parse('https://github.com/$trimmed');
        final webResponse = await httpClient.get(
          webUrl,
          headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
        ).timeout(const Duration(seconds: 8));

        if (webResponse.statusCode == 200) {
          return null;
        }
        if (webResponse.statusCode == 404) {
          return "Tài khoản GitHub không tồn tại. Vui lòng kiểm tra lại username";
        }
      }

      return null;
    } catch (e) {
      if (kIsWeb && e.toString().contains('XMLHttpRequest')) {
        return null;
      }
      return null;
    } finally {
      if (shouldClose) {
        httpClient.close();
      }
    }
  }

  /// [16E7] Uniqueness in Group/Class: Check Firestore if another student claimed this username
  static Future<bool> isGithubUsernameClaimed(
    String username,
    String currentUserId, {
    String? classId,
    FirebaseFirestore? firestore,
  }) async {
    final db = firestore ?? FirebaseFirestore.instance;
    final trimmedLower = username.trim().toLowerCase();

    // Query users collection
    final snapshot = await db.collection('users').get();
    for (final doc in snapshot.docs) {
      if (doc.id == currentUserId) continue;

      final data = doc.data();
      final existingUsername = (data['github_username'] as String? ?? '').trim().toLowerCase();

      if (existingUsername == trimmedLower) {
        // If classId is specified, check if they belong to the same class
        if (classId != null && classId.isNotEmpty) {
          final userClass = data['class'] as String? ?? data['classId'] as String? ?? '';
          if (userClass == classId) {
            return true;
          }
        } else {
          return true;
        }
      }
    }

    return false;
  }

  // ==================== 2. GOOGLE DOCS DISPLAY NAME VALIDATION ====================

  /// Validates Google Docs Display Name synchronously (17E1 - 17E4)
  static String? validateGoogleDisplayName(String? value) {
    // [17E1] Empty/Whitespace-only check
    if (value == null || value.trim().isEmpty) {
      return "Tên hiển thị Google Docs không được để trống";
    }

    final trimmed = value.trim();

    // [17E2] Min length (< 2 chars)
    if (trimmed.length < 2) {
      return "Tên hiển thị Google Docs phải từ 2 ký tự trở lên";
    }

    // [17E3] Max length (> 50 chars)
    if (trimmed.length > 50) {
      return "Tên hiển thị Google Docs không được vượt quá 50 ký tự";
    }

    // [17E4] Malicious / Invalid characters: Disallow <, >, ", ', /, \
    const invalidChars = ['<', '>', '"', "'", '/', r'\'];
    if (invalidChars.any((c) => trimmed.contains(c))) {
      return "Tên hiển thị Google Docs chứa ký tự không hợp lệ";
    }

    return null;
  }

  /// [17E] Author revision check (Async)
  /// Checks if the author name exists in document contribution history
  static Future<String?> verifyGoogleDocsAuthor(
    String authorName, {
    List<dynamic>? docsStats,
    String? docsLink,
    http.Client? client,
  }) async {
    final trimmedAuthor = authorName.trim().toLowerCase();
    if (trimmedAuthor.isEmpty) {
      return "Tên hiển thị Google Docs không được để trống";
    }

    // 1. Check in provided docsStats list
    if (docsStats != null && docsStats.isNotEmpty) {
      final found = docsStats.any((stat) {
        if (stat is Map) {
          final name = (stat['username'] ?? stat['author'] ?? stat['name'])?.toString().trim().toLowerCase() ?? '';
          return name == trimmedAuthor || name.contains(trimmedAuthor) || trimmedAuthor.contains(name);
        }
        return false;
      });

      if (!found) {
        return "Không tìm thấy đóng góp của tác giả này trong lịch sử chỉnh sửa tài liệu Google Docs";
      }
      return null;
    }

    // 2. If docsLink is provided and stats are not cached yet, fetch from API
    if (docsLink != null && docsLink.isNotEmpty) {
      final httpClient = client ?? http.Client();
      final shouldClose = client == null;
      try {
        final url = Uri.parse(
          'https://script.google.com/macros/s/AKfycbymBwuQYj_WrRiRkWegkU_3qaPfyp8Uu7kLLfnWmGtsdz2IbCtQYK9qqPpGk7kQnQaO_Q/exec?docsLink=${Uri.encodeComponent(docsLink)}',
        );
        final response = await httpClient.get(url).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          List<dynamic>? data;
          if (decoded is Map<String, dynamic>) {
            data = decoded['data'] as List<dynamic>?;
          }
          if (data != null && data.isNotEmpty) {
            final found = data.any((stat) {
              if (stat is Map) {
                final name = (stat['username'] ?? stat['author'] ?? stat['name'])?.toString().trim().toLowerCase() ?? '';
                return name == trimmedAuthor || name.contains(trimmedAuthor) || trimmedAuthor.contains(name);
              }
              return false;
            });
            if (!found) {
              return "Không tìm thấy đóng góp của tác giả này trong lịch sử chỉnh sửa tài liệu Google Docs";
            }
          }
        }
      } catch (e) {
        // Network or CORS issue on web, do not block
        if (kIsWeb && e.toString().contains('XMLHttpRequest')) {
          return null;
        }
      } finally {
        if (shouldClose) httpClient.close();
      }
    }

    return null;
  }
}
