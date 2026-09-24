import 'package:cloud_firestore/cloud_firestore.dart';

class AuthValidator {
  static final RegExp _fullNameValidPattern = RegExp(
    r'^[a-zA-Z\s'
    r'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ'
    r'ÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ'
    r']+$',
  );

  static final RegExp _rfc5322EmailPattern = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  // ==================== 1. FULL NAME VALIDATION ====================

  /// Validates Full Name synchronously (12E1 - 12E6)
  static String? validateFullName(String? value) {
    // [12E1] Empty check
    if (value == null || value.isEmpty) {
      return "Họ và tên không được để trống";
    }

    // [12E6] Whitespace formatting (leading/trailing or multiple consecutive spaces)
    if (value.startsWith(' ') || value.endsWith(' ') || value.contains(RegExp(r'\s{2,}'))) {
      return "Họ và tên không chứa khoảng trắng thừa";
    }

    // [12E2] Min length (< 2 chars)
    if (value.length < 2) {
      return "Họ và tên tối thiểu phải từ 2 ký tự";
    }

    // [12E3] Max length (> 50 chars)
    if (value.length > 50) {
      return "Họ và tên tối đa không quá 50 ký tự";
    }

    // [12E4] Digit check
    if (value.contains(RegExp(r'[0-9]'))) {
      return "Họ và tên không được chứa chữ số";
    }

    // [12E5] Special character check
    if (!_fullNameValidPattern.hasMatch(value)) {
      return "Họ và tên không được chứa ký tự đặc biệt";
    }

    return null;
  }

  // ==================== 2. EMAIL VALIDATION ====================

  /// Validates Institutional Email synchronously (13E2 - 13E5)
  static String? validateEmail(String? value) {
    // [13E2] Empty check
    if (value == null || value.isEmpty) {
      return "Email không được để trống";
    }

    // [13E5] Whitespace check
    if (value.contains(RegExp(r'\s'))) {
      return "Email không được chứa khoảng trắng";
    }

    // [13E3] Standard RFC 5322 structure check
    if (!_rfc5322EmailPattern.hasMatch(value)) {
      return "Định dạng email không hợp lệ";
    }

    // [13E4] TLU Domain restriction
    final lower = value.toLowerCase();
    if (!lower.endsWith('@e.tlu.edu.vn') && !lower.endsWith('@tlu.edu.vn')) {
      return "Chỉ hỗ trợ email của ĐH Thủy Lợi (@e.tlu.edu.vn hoặc @tlu.edu.vn)";
    }

    return null;
  }

  // ==================== 3. PASSWORD VALIDATION ====================

  /// Validates Password synchronously (14E1 - 14E8)
  static String? validatePassword(String? value) {
    // [14E1] Empty check
    if (value == null || value.isEmpty) {
      return "Mật khẩu không được để trống";
    }

    // [14E8] Whitespace check
    if (value.contains(RegExp(r'\s'))) {
      return "Mật khẩu không được chứa khoảng trắng";
    }

    // [14E2] Min length (< 8 chars)
    if (value.length < 8) {
      return "Mật khẩu phải chứa ít nhất 8 ký tự";
    }

    // [14E3] Max length (> 32 chars)
    if (value.length > 32) {
      return "Mật khẩu không được vượt quá 32 ký tự";
    }

    // [14E4] Uppercase letter check
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return "Mật khẩu phải chứa ít nhất một chữ cái in hoa";
    }

    // [14E5] Lowercase letter check
    if (!value.contains(RegExp(r'[a-z]'))) {
      return "Mật khẩu phải chứa ít nhất một chữ cái thường";
    }

    // [14E6] Numeric digit check
    if (!value.contains(RegExp(r'[0-9]'))) {
      return "Mật khẩu phải chứa ít nhất một chữ số";
    }

    // [14E7] Special character check
    if (!value.contains(RegExp(r'[^a-zA-Z0-9]'))) {
      return "Mật khẩu phải chứa ít nhất một ký tự đặc biệt";
    }

    return null;
  }

  // ==================== 4. STUDENT ID VALIDATION ====================

  /// Validates Student ID synchronously (15E2 - 15E5)
  static String? validateStudentId(String? value) {
    // [15E2] Empty check
    if (value == null || value.trim().isEmpty) {
      return "Mã sinh viên không được để trống";
    }
    final trimmed = value.trim();

    // [15E4] Numeric check
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
      return "Mã sinh viên chỉ bao gồm các chữ số";
    }

    // [15E3] Exact length
    if (trimmed.length != 10) {
      return "Mã sinh viên phải có độ dài chính xác 10 chữ số";
    }

    // [15E5] Cohort prefix check (intake years 18 to 26)
    final prefix = int.tryParse(trimmed.substring(0, 2)) ?? 0;
    if (prefix < 18 || prefix > 26) {
      return "Khóa tuyển sinh không hợp lệ trong hệ thống";
    }

    return null;
  }

  // ==================== ASYNCHRONOUS FIRESTORE / AUTH CHECKS ====================

  /// [13E1] Check if email is already registered in Firestore users collection
  static Future<bool> isEmailRegisteredInFirestore(
    String email, {
    FirebaseFirestore? firestore,
  }) async {
    final db = firestore ?? FirebaseFirestore.instance;
    final query = await db
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// [15E1] Check if studentId is already registered in Firestore users collection
  static Future<bool> isStudentIdRegistered(
    String studentId, {
    FirebaseFirestore? firestore,
  }) async {
    final db = firestore ?? FirebaseFirestore.instance;
    final trimmed = studentId.trim();
    final query = await db
        .collection('users')
        .where('studentId', isEqualTo: trimmed)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) return true;

    // Check fallback field name if any legacy documents use student_id
    final fallbackQuery = await db
        .collection('users')
        .where('student_id', isEqualTo: trimmed)
        .limit(1)
        .get();
    return fallbackQuery.docs.isNotEmpty;
  }
}
