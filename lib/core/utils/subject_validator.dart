import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Validation utilities and business rules for Subject/Class Management
class SubjectValidator {
  // Vietnamese letter character set + digits + safe punctuation (hyphen -, dot ., parentheses ()) + whitespace
  static final RegExp _subjectNamePattern = RegExp(
    r'^[a-zA-Z0-9\s\-.\(\)'
    r'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ'
    r'ÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ'
    r']+$',
  );

  static const List<String> _maliciousSymbols = ['<', '>', ';', '{', '}', r'\'];

  static final RegExp _semesterSchemaPattern = RegExp(r'^HK[1-3]-(20\d{2})$');

  static const List<String> defaultSemesters = [
    'HK1-2024',
    'HK2-2024',
    'HK1-2025',
    'HK2-2025',
    'HK1-2026',
    'HK2-2026',
  ];

  // ==================== 1. SUBJECT NAME VALIDATION ====================

  /// Validates Subject Name synchronously ([5E2] - [5E5])
  static String? validateSubjectName(String? value) {
    // [5E2] Empty check
    if (value == null || value.trim().isEmpty) {
      return "Tên môn học không được để trống";
    }

    // [5E3] Min length (< 3 chars)
    if (value.length < 3) {
      return "Tên môn học phải từ 3 ký tự trở lên";
    }

    // [5E4] Max length (> 100 chars)
    if (value.length > 100) {
      return "Tên môn học không được vượt quá 100 ký tự";
    }

    // [5E5] Special characters & formatting check:
    // - Disallow leading/trailing whitespace or multiple consecutive spaces (`  `)
    if (value.startsWith(' ') || value.endsWith(' ') || value.contains('  ')) {
      return "Tên môn học chứa ký tự không hợp lệ";
    }

    // - Disallow high-risk/malicious symbols (`<`, `>`, `;`, `{`, `}`, `\`)
    for (final symbol in _maliciousSymbols) {
      if (value.contains(symbol)) {
        return "Tên môn học chứa ký tự không hợp lệ";
      }
    }

    // - Only allow Vietnamese letters (with accents), English letters, digits, whitespace, and safe punctuation/separators (hyphen, dot, parentheses)
    if (!_subjectNamePattern.hasMatch(value)) {
      return "Tên môn học chứa ký tự không hợp lệ";
    }

    return null;
  }

  // ==================== 2. SUBJECT CODE VALIDATION ====================

  /// Validates Subject Code synchronously ([6E1] - [6E5])
  static String? validateSubjectCode(String? value) {
    // [6E1] Empty check
    if (value == null || value.trim().isEmpty) {
      return "Mã môn học không được để trống";
    }

    // [6E2] Total length check: Must be between 5 and 10 characters
    if (value.length < 5 || value.length > 10) {
      return "Mã môn học phải từ 5 đến 10 ký tự";
    }

    // [6E5] Character check: Disallow spaces, lowercase letters, and special characters.
    // Must only consist of uppercase letters (A-Z) and digits (0-9).
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value)) {
      return "Mã môn học chỉ gồm chữ in hoa và chữ số, không chứa khoảng trắng";
    }

    // [6E3] Prefix structure check:
    // The first 2 to 4 characters must be the uppercase department/faculty abbreviation (e.g., INT, CSE, SWE, MTH).
    final leadingLettersMatch = RegExp(r'^([A-Z]+)').firstMatch(value);
    if (leadingLettersMatch == null) {
      return "Mã bộ môn/khoa không hợp lệ";
    }
    final letters = leadingLettersMatch.group(1)!;
    if (letters.length < 2) {
      return "Mã bộ môn/khoa không hợp lệ";
    }
    if (letters == value) {
      return "Mã môn học phải kết thúc bằng các chữ số";
    }
    if (letters.length > 4) {
      return "Mã bộ môn/khoa không hợp lệ";
    }

    // [6E4] Suffix structure check:
    // The remaining 3 to 6 characters must be numeric digits identifying the subject (e.g., 3134, 401, 2101).
    // Total full regex: ^[A-Z]{2,4}[0-9]{3,6}$
    final suffix = value.substring(letters.length);
    if (!RegExp(r'^[0-9]+$').hasMatch(suffix) || suffix.length < 3 || suffix.length > 6) {
      return "Mã môn học phải kết thúc bằng các chữ số";
    }

    return null;
  }

  // ==================== 3. SEMESTER VALIDATION ====================

  /// Validates Semester synchronously ([7E1] - [7E2])
  static String? validateSemester(String? value, {List<String>? allowedSemesters}) {
    // [7E1] Null or unselected check
    if (value == null || value.trim().isEmpty) {
      return "Vui lòng chọn học kỳ áp dụng";
    }

    final trimmed = value.trim();

    // [7E2] Enum whitelist validation: Value must strictly follow the system schema HK{Kỳ}-{Năm bắt đầu}
    if (!_semesterSchemaPattern.hasMatch(trimmed)) {
      return "Học kỳ được chọn không hợp lệ trong hệ thống";
    }

    if (allowedSemesters != null && !allowedSemesters.contains(trimmed)) {
      return "Học kỳ được chọn không hợp lệ trong hệ thống";
    }

    return null;
  }

  // ==================== 4. ASYNC VALIDATIONS ====================

  /// [5E1] Uniqueness per Semester per Teacher (Async):
  /// Query Firestore to check if this teacher already has a subject with the exact same name within the selected semester.
  static Future<bool> isSubjectDuplicate({
    required String teacherUid,
    required String subjectName,
    required String semester,
    FirebaseFirestore? firestore,
  }) async {
    try {
      final db = firestore ?? FirebaseFirestore.instance;
      final querySnapshot = await db
          .collection('classes')
          .where('giang_vien_id', isEqualTo: teacherUid)
          .get();

      final cleanName = subjectName.trim().toLowerCase();
      final cleanSemester = semester.trim().toLowerCase();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final existingName = (data['ten_lop'] as String? ?? '').trim().toLowerCase();
        final existingSemester = (data['hoc_ky'] as String? ?? data['semester'] as String? ?? '').trim().toLowerCase();

        // Check duplicate if name matches and semester matches (or if existing subject has no semester assigned yet)
        if (existingName == cleanName && (existingSemester.isEmpty || existingSemester == cleanSemester)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking duplicate subject: $e');
      return false;
    }
  }
}
