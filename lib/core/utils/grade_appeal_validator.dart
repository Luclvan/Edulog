/// Business logic and validation constraints for "Tạo đơn phúc khảo" (Grade Appeal) module.
///
/// Implements error codes [5E1] to [11E3] according to Nguyễn Thị Cẩm Ly's Software Testing specification.
class GradeAppealValidator {
  // Vietnamese letter character set + English letters + whitespace
  static final RegExp _fullNamePattern = RegExp(
    r'^[a-zA-Z\s'
    r'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ'
    r'ÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ'
    r']+$',
  );

  static final RegExp _emailFormatPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _datePattern = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');

  static const List<String> validExamShifts = [
    'Ca 1',
    'Ca 2',
    'Ca 3',
    'Ca 4',
    'Ca 5',
    'Ca 6',
    'Tiết 1-3',
    'Tiết 4-6',
    'Tiết 7-9',
    'Tiết 10-12',
    '1-3',
    '4-6',
    '7-9',
    '10-12',
  ];

  // ==================== FIELD 1: HỌ VÀ TÊN ====================

  /// Validates Field 1: Họ và tên
  /// [5E1] Empty check
  /// [5E2] Min length (< 2 chars)
  /// [5E3] Max length (> 50 chars)
  /// [5E4] Numeric check (must not contain digits 0-9)
  /// [5E5] Special character check
  /// [5E6] Account match check (Cross-validation)
  static String? validateFullName(
    String? value, {
    String? accountFullName,
  }) {
    // [5E1] Empty check
    if (value == null || value.trim().isEmpty) {
      return "Họ và tên không được để trống";
    }

    final trimmed = value.trim();

    // [5E4] Numeric check (check before length/specials if digits are present)
    if (trimmed.contains(RegExp(r'[0-9]'))) {
      return "Họ và tên không được chứa chữ số";
    }

    // [5E5] Special character check
    if (!_fullNamePattern.hasMatch(trimmed)) {
      return "Họ và tên không được chứa ký tự đặc biệt";
    }

    // [5E2] Min length (< 2 chars)
    if (trimmed.length < 2) {
      return "Họ và tên sinh viên tối thiểu từ 2 ký tự";
    }

    // [5E3] Max length (> 50 chars)
    if (trimmed.length > 50) {
      return "Họ và tên sinh viên không được vượt quá 50 ký tự";
    }

    // [5E6] Account match check (Cross-validation)
    if (accountFullName != null && accountFullName.trim().isNotEmpty) {
      if (trimmed.toLowerCase() != accountFullName.trim().toLowerCase()) {
        return "Họ và tên không khớp với thông tin tài khoản đăng nhập";
      }
    }

    return null;
  }

  // ==================== FIELD 2: MÃ SINH VIÊN ====================

  /// Validates Field 2: Mã sinh viên
  /// [6E1] Empty check
  /// [6E3] Numeric only check
  /// [6E2] Exact length check (must be exactly 10 digits)
  /// [6E5] Cohort check (first 2 digits must be between 18 and 26)
  /// [6E4] Account match check (Cross-validation)
  static String? validateStudentId(
    String? value, {
    String? accountStudentId,
  }) {
    // [6E1] Empty check
    if (value == null || value.trim().isEmpty) {
      return "Mã sinh viên không được để trống";
    }

    final trimmed = value.trim();

    // [6E3] Numeric only check
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
      return "Mã sinh viên chỉ bao gồm các chữ số";
    }

    // [6E2] Exact length check
    if (trimmed.length != 10) {
      return "Mã sinh viên phải có độ dài chính xác 10 chữ số";
    }

    // [6E5] Cohort check (first 2 digits in [18, 26])
    final prefix = int.tryParse(trimmed.substring(0, 2));
    if (prefix == null || prefix < 18 || prefix > 26) {
      return "Khóa tuyển sinh không hợp lệ trong hệ thống";
    }

    // [6E4] Account match check (Cross-validation)
    if (accountStudentId != null && accountStudentId.trim().isNotEmpty) {
      if (trimmed != accountStudentId.trim()) {
        return "Mã sinh viên không khớp với tài khoản đang đăng nhập";
      }
    }

    return null;
  }

  // ==================== FIELD 3: EMAIL SINH VIÊN ====================

  /// Validates Field 3: Email sinh viên
  /// [7E1] Empty check
  /// [7E4] Whitespace check
  /// [7E2] Standard format check
  /// [7E3] Domain restriction (@e.tlu.edu.vn)
  static String? validateEmail(String? value) {
    // [7E1] Empty check
    if (value == null || value.trim().isEmpty) {
      return "Email không được để trống";
    }

    // [7E4] Whitespace check
    if (value.contains(' ')) {
      return "Email không được chứa khoảng trắng";
    }

    final trimmed = value.trim();

    // [7E2] Standard format check
    if (!_emailFormatPattern.hasMatch(trimmed)) {
      return "Định dạng email không hợp lệ";
    }

    // [7E3] Domain restriction (@e.tlu.edu.vn)
    if (!trimmed.toLowerCase().endsWith('@e.tlu.edu.vn')) {
      return "Chỉ chấp nhận email sinh viên trường ĐH Thủy Lợi (@e.tlu.edu.vn)";
    }

    return null;
  }

  // ==================== FIELD 4: ĐIỂM THI HIỆN TẠI ====================

  /// Validates Field 4: Điểm thi hiện tại
  /// [8E1] Empty check
  /// [8E2] Lower bound check (< 0.0)
  /// [8E3] Upper bound check (> 10.0)
  /// [8E4] Precision step check (max 1 decimal place, step 0.1)
  static String? validateCurrentScore(String? value) {
    // [8E1] Empty check
    if (value == null || value.trim().isEmpty) {
      return "Vui lòng nhập điểm số hiện tại cần phúc khảo";
    }

    final trimmed = value.trim();
    final score = double.tryParse(trimmed);

    if (score == null) {
      return "Điểm số không được nhỏ hơn 0.0";
    }

    // [8E2] Lower bound check
    if (score < 0.0) {
      return "Điểm số không được nhỏ hơn 0.0";
    }

    // [8E3] Upper bound check
    if (score > 10.0) {
      return "Điểm số không được vượt quá 10.0";
    }

    // [8E4] Precision step check: Max 1 decimal place
    final parts = trimmed.split('.');
    if (parts.length > 2 || (parts.length == 2 && parts[1].length > 1)) {
      return "Điểm số chỉ được làm tròn đến 1 chữ số thập phân (bước nhảy 0.1)";
    }

    return null;
  }

  /// [8E5] System score match (Async / Data check)
  static String? validateSystemScoreMatch({
    required double enteredScore,
    required double? recordedScore,
  }) {
    if (recordedScore == null) return null;
    if ((enteredScore - recordedScore).abs() > 0.001) {
      return "Điểm số nhập vào không khớp với điểm thi đã ghi nhận trên hệ thống";
    }
    return null;
  }

  // ==================== FIELD 5: NGÀY THI ====================

  /// Validates Field 5: Ngày thi (DD/MM/YYYY)
  /// [9E1] Empty check
  /// [9E2] Valid calendar date
  /// [9E3] Future date check (ExamDate <= CurrentDate)
  static String? validateExamDate(
    String? value, {
    DateTime? now,
  }) {
    // [9E1] Empty check
    if (value == null || value.trim().isEmpty) {
      return "Vui lòng chọn ngày thi đã tham gia";
    }

    final match = _datePattern.firstMatch(value.trim());
    if (match == null) {
      return "Ngày thi không hợp lệ theo lịch";
    }

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);

    if (day == null || month == null || year == null) {
      return "Ngày thi không hợp lệ theo lịch";
    }

    if (month < 1 || month > 12 || year < 1900 || year > 2100) {
      return "Ngày thi không hợp lệ theo lịch";
    }

    final maxDays = daysInMonth(year, month);
    if (day < 1 || day > maxDays) {
      return "Ngày thi không hợp lệ theo lịch";
    }

    final examDate = DateTime(year, month, day);
    final referenceDate = now ?? DateTime.now();
    final today = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);

    // [9E3] Future date check
    if (examDate.isAfter(today)) {
      return "Ngày thi không thể là ngày trong tương lai";
    }

    return null;
  }

  /// [9E4] Schedule sync: Exam date must match actual exam schedule
  static String? validateScheduleSync({
    required String enteredDate,
    required String? actualExamDate,
  }) {
    if (actualExamDate != null && actualExamDate.trim().isNotEmpty) {
      if (enteredDate.trim() != actualExamDate.trim()) {
        return "Ngày thi không khớp với lịch thi thực tế của môn học này";
      }
    }
    return null;
  }

  /// [9E5] Deadline expiration check: Submission date must not exceed 15 days from exam date
  static String? validateAppealDeadline({
    required String examDateStr,
    DateTime? now,
  }) {
    final parsedExamDate = parseDate(examDateStr);
    if (parsedExamDate == null) return null;

    final referenceDate = now ?? DateTime.now();
    final today = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    final examDay = DateTime(parsedExamDate.year, parsedExamDate.month, parsedExamDate.day);

    final diffDays = today.difference(examDay).inDays;
    if (diffDays > 15) {
      return "Đã hết thời hạn gửi đơn phúc khảo cho môn thi này (quá 15 ngày theo quy chế)";
    }
    return null;
  }

  // ==================== FIELD 6: MÔN THI ====================

  /// Validates Field 6: Môn thi synchronously
  /// [10E1] Empty / Null check
  static String? validateSubjectName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Vui lòng chọn môn thi cần phúc khảo";
    }
    return null;
  }

  /// [10E2] System existence check
  static String? validateSubjectExistence({
    required bool existsInCurriculum,
  }) {
    if (!existsInCurriculum) {
      return "Môn học không tồn tại trong hệ thống đào tạo";
    }
    return null;
  }

  /// [10E3] Term availability check
  static String? validateSubjectTermAvailability({
    required bool hasExamOrganized,
  }) {
    if (!hasExamOrganized) {
      return "Môn học không được tổ chức thi trong đợt thi này";
    }
    return null;
  }

  /// [10E4] Enrollment check
  static String? validateStudentEnrollment({
    required bool isRegistered,
  }) {
    if (!isRegistered) {
      return "Bạn không có tên trong danh sách dự thi môn học này";
    }
    return null;
  }

  /// [10E5] Pending duplicate check
  static String? validateNoPendingAppeal({
    required bool hasPendingAppeal,
  }) {
    if (hasPendingAppeal) {
      return "Bạn đã gửi đơn phúc khảo cho môn học này và đang chờ xử lý, không thể gửi trùng lặp";
    }
    return null;
  }

  /// [10E6] Published score check
  static String? validatePublishedScore({
    required double? publishedScore,
  }) {
    if (publishedScore == null) {
      return "Môn học chưa công bố điểm thi, chưa thể tạo đơn phúc khảo";
    }
    return null;
  }

  // ==================== FIELD 7: CA THI ====================

  /// Validates Field 7: Ca thi synchronously
  /// [11E1] Empty check
  /// [11E2] Whitelist check
  static String? validateExamShift(String? value) {
    // [11E1] Empty check
    if (value == null || value.trim().isEmpty) {
      return "Vui lòng chọn ca thi đã tham gia";
    }

    final trimmed = value.trim();

    // [11E2] Whitelist check
    final isMatch = validExamShifts.any(
      (shift) => shift.toLowerCase() == trimmed.toLowerCase(),
    );

    if (!isMatch) {
      return "Ca thi không hợp lệ trong hệ thống";
    }

    return null;
  }

  /// [11E3] Roster assignment check
  static String? validateRosterAssignment({
    required String enteredShift,
    required String? assignedShift,
  }) {
    if (assignedShift != null && assignedShift.trim().isNotEmpty) {
      final s1 = normalizeShift(enteredShift);
      final s2 = normalizeShift(assignedShift);
      if (s1 != s2 && !s1.contains(s2) && !s2.contains(s1)) {
        return "Ca thi không khớp với ca thi được xếp lịch của bạn";
      }
    }
    return null;
  }

  // ==================== UTILITY HELPERS ====================

  static String normalizeShift(String shift) {
    return shift.replaceAll(' ', '').toLowerCase();
  }

  static int daysInMonth(int year, int month) {
    if (month == 2) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeap ? 29 : 28;
    }
    const daysList = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return daysList[month];
  }

  static DateTime? parseDate(String? value) {
    if (value == null) return null;
    final match = _datePattern.firstMatch(value.trim());
    if (match == null) return null;
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > daysInMonth(year, month)) return null;
    return DateTime(year, month, day);
  }
}
