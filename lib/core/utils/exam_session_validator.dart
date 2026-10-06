/// Business logic and validation constraints for "Add Exam Session" (Thêm ca thi) module.
///
/// Implements error codes [21E1] to [28E3] according to the testing specification.
class ExamSessionValidator {
  // Regex for Exam Term Name: K{Khóa}_Lich_Thi_HK{Kỳ}_GĐ{GiaiĐoạn}_NH_{NămHọc}
  // Example: K65_Lich_Thi_HK2_GĐ1_NH_2025-2026
  static final RegExp examTermPattern = RegExp(
    r'^K\d{2}_Lich_Thi_HK[1-3]_GĐ[1-2]_NH_\d{4}-\d{4}$',
  );

  // Regex for extracting cohort from exam term name
  static final RegExp cohortPattern = RegExp(r'^K(\d{2})_');

  // Regex for Room Code: {SốPhòng}-{TòaNhà} (e.g., 131-A2, 205-B5)
  static final RegExp roomPattern = RegExp(r'^\d{3}-[A-Z]\d?$');

  // Regex for Session Period: {TiếtBắtĐầu}-{TiếtKếtThúc} (e.g., 4-6, 1-3, 5-5)
  static final RegExp sessionPeriodPattern = RegExp(r'^(\d{1,2})-(\d{1,2})$');

  // Regex for Exam Time: HH:mm - HH:mm (24-hour format)
  static final RegExp examTimePattern = RegExp(
    r'^([01]\d|2[0-3]):([0-5]\d)\s*-\s*([01]\d|2[0-3]):([0-5]\d)$',
  );

  // Regex for Date: DD/MM/YYYY
  static final RegExp datePattern = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');

  // ==================== FIELD 1: TÊN ĐỢT THI ====================

  /// Validates Field 1: Tên đợt thi (Exam Term Name)
  /// [21E1] Empty check
  /// [21E2] Length check (10 - 100 characters)
  /// [21E4] Whitespace & Special characters check (disallow whitespace or unsafe special characters outside _ and -)
  /// [21E3] Standard Pattern check
  static String? validateExamTermName(String? value) {
    // [21E1] Empty check
    if (value == null || value.trim().isEmpty) {
      return "Tên đợt thi không được để trống";
    }

    // [21E2] Length: Length must be between 10 and 100 characters
    if (value.length < 10 || value.length > 100) {
      return "Tên đợt thi phải có độ dài từ 10 đến 100 ký tự";
    }

    // [21E4] Whitespace & Special characters: Disallow whitespace or unsafe special characters outside _ and -
    if (value.contains(' ') || RegExp(r'[^a-zA-Z0-9_\-Đđ]').hasMatch(value)) {
      return "Tên đợt thi không được chứa khoảng trắng hoặc ký tự đặc biệt";
    }

    // [21E3] Standard Pattern check
    if (!examTermPattern.hasMatch(value)) {
      return "Tên đợt thi không đúng định dạng chuẩn (Ví dụ: K65_Lich_Thi_HK2_GĐ1_NH_2025-2026)";
    }

    return null;
  }

  /// Extracts cohort string from exam term name (e.g., "K65")
  static String? extractCohort(String? examTermName) {
    if (examTermName == null) return null;
    final match = cohortPattern.firstMatch(examTermName);
    if (match != null) {
      return 'K${match.group(1)}';
    }
    return null;
  }

  // ==================== FIELD 2: TÊN MÔN HỌC ====================

  /// Validates Field 2: Tên môn học synchronously
  /// [22E1] Empty check
  static String? validateCourseName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Tên môn học không được để trống";
    }
    return null;
  }

  /// [22E2] System existence (Async/Data check)
  static String? validateCourseExistence({
    required String courseName,
    required List<String> availableCourses,
  }) {
    final exists = availableCourses.any(
      (c) => c.trim().toLowerCase() == courseName.trim().toLowerCase(),
    );
    if (!exists) {
      return "Môn học không tồn tại trong hệ thống đào tạo";
    }
    return null;
  }

  /// [22E3] Curriculum batch matching: Course must belong to the curriculum cohort specified in the exam term name.
  static String? validateCourseCohortMatching({
    required String? examTermName,
    required List<String> courseApplicableCohorts,
  }) {
    final cohort = extractCohort(examTermName);
    if (cohort != null && courseApplicableCohorts.isNotEmpty) {
      final matches = courseApplicableCohorts.any(
        (c) => c.trim().toUpperCase() == cohort.trim().toUpperCase(),
      );
      if (!matches) {
        return "Môn học không thuộc khung chương trình đào tạo của đợt thi này";
      }
    }
    return null;
  }

  // ==================== FIELD 3: SỐ TÍN CHỈ ====================

  /// Validates Field 3: Số tín chỉ synchronously
  /// [23E1] Empty check
  /// [23E2] Range & Integer check: Must be integer between 1 and 5
  static String? validateCredits(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Số tín chỉ không được để trống";
    }

    final credits = int.tryParse(value.trim());
    if (credits == null || credits < 1 || credits > 5) {
      return "Số tín chỉ học phần phải từ 1 đến 5";
    }

    return null;
  }

  /// [23E3] Curriculum credit sync: Must match the standard credits defined for the selected course
  static String? validateCreditSync({
    required int? enteredCredits,
    required int? standardCredits,
  }) {
    if (enteredCredits != null && standardCredits != null) {
      if (enteredCredits != standardCredits) {
        return "Số tín chỉ không khớp với thông tin chương trình đào tạo của môn học";
      }
    }
    return null;
  }

  // ==================== FIELD 4: NGÀY THI ====================

  /// Validates Field 4: Ngày thi (DD/MM/YYYY)
  /// [24E1] Empty check
  /// [24E2] Valid calendar date (astronomically valid, e.g. disallow 30/02/2026)
  /// [24E3] Past date check (ExamDate >= CurrentDate)
  /// [24E4] Exam term timeframe
  static String? validateExamDate(
    String? value, {
    DateTime? now,
    DateTime? termStartDate,
    DateTime? termEndDate,
  }) {
    // [24E1] Empty check
    if (value == null || value.trim().isEmpty) {
      return "Vui lòng chọn ngày thi";
    }

    final match = datePattern.firstMatch(value.trim());
    if (match == null) {
      return "Ngày thi không hợp lệ";
    }

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);

    if (day == null || month == null || year == null) {
      return "Ngày thi không hợp lệ";
    }

    if (month < 1 || month > 12 || year < 1900 || year > 2100) {
      return "Ngày thi không hợp lệ";
    }

    // Astronomical validity check
    final maxDays = daysInMonth(year, month);
    if (day < 1 || day > maxDays) {
      return "Ngày thi không hợp lệ";
    }

    final examDate = DateTime(year, month, day);

    // [24E3] Past date check: ExamDate must be >= CurrentDate (comparing dates only)
    final referenceDate = now ?? DateTime.now();
    final today = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    if (examDate.isBefore(today)) {
      return "Ngày thi không được ở trong quá khứ";
    }

    // [24E4] Exam term timeframe
    if (termStartDate != null) {
      final start = DateTime(termStartDate.year, termStartDate.month, termStartDate.day);
      if (examDate.isBefore(start)) {
        return "Ngày thi phải nằm trong khoảng thời gian hiệu lực của đợt thi";
      }
    }

    if (termEndDate != null) {
      final end = DateTime(termEndDate.year, termEndDate.month, termEndDate.day);
      if (examDate.isAfter(end)) {
        return "Ngày thi phải nằm trong khoảng thời gian hiệu lực của đợt thi";
      }
    }

    return null;
  }

  /// Calculates max days in month with leap year logic
  static int daysInMonth(int year, int month) {
    if (month == 2) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeap ? 29 : 28;
    }
    const daysList = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return daysList[month];
  }

  /// Parses DD/MM/YYYY into DateTime or returns null
  static DateTime? parseDate(String? value) {
    if (value == null) return null;
    final match = datePattern.firstMatch(value.trim());
    if (match == null) return null;
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > daysInMonth(year, month)) return null;
    return DateTime(year, month, day);
  }

  // ==================== FIELD 5: CA THI (TIẾT HỌC) ====================

  /// Validates Field 5: Ca thi (Tiết học)
  /// [25E1] Empty check
  /// [25E2] Format check: {TiếtBắtĐầu}-{TiếtKếtThúc} (Regex: ^\d{1,2}-\d{1,2}$)
  /// [25E3] Range check: Both start and end between 1 and 12
  /// [25E4] Logic order check: End period >= Start period
  static String? validateSessionPeriod(String? value) {
    // [25E1] Empty check
    if (value == null || value.trim().isEmpty) {
      return "Ca thi không được để trống";
    }

    // [25E2] Format check
    final match = sessionPeriodPattern.firstMatch(value.trim());
    if (match == null) {
      return "Định dạng ca thi phải theo dạng [Tiết bắt đầu]-[Tiết kết thúc] (Ví dụ: 4-6, 1-3)";
    }

    final start = int.tryParse(match.group(1)!);
    final end = int.tryParse(match.group(2)!);

    // [25E3] Range check: 1 to 12
    if (start == null || end == null || start < 1 || start > 12 || end < 1 || end > 12) {
      return "Tiết thi phải nằm trong khoảng từ tiết 1 đến tiết 12";
    }

    // [25E4] Logic order check: End period >= Start period
    if (end < start) {
      return "Tiết kết thúc phải lớn hơn hoặc bằng tiết bắt đầu";
    }

    return null;
  }

  // ==================== FIELD 6: GIỜ THI ====================

  /// Validates Field 6: Giờ thi (HH:mm - HH:mm)
  /// [26E1] Empty check
  /// [26E2] Format check (24h format HH:mm - HH:mm)
  /// [26E3] Chronological check: End time > Start time
  /// [26E4] Duration check: 15 <= duration <= 240 minutes
  /// [26E5] Period-to-Time compatibility check
  static String? validateExamTime(String? value, {String? sessionPeriod}) {
    // [26E1] Empty check
    if (value == null || value.trim().isEmpty) {
      return "Giờ thi không được để trống";
    }

    // [26E2] Format check
    final match = examTimePattern.firstMatch(value.trim());
    if (match == null) {
      return "Định dạng giờ thi phải là HH:mm - HH:mm (Ví dụ: 09:45 - 12:25)";
    }

    final h1 = int.parse(match.group(1)!);
    final m1 = int.parse(match.group(2)!);
    final h2 = int.parse(match.group(3)!);
    final m2 = int.parse(match.group(4)!);

    final startMinutes = h1 * 60 + m1;
    final endMinutes = h2 * 60 + m2;

    // [26E3] Chronological check
    if (endMinutes <= startMinutes) {
      return "Khung giờ thi không hợp lệ: Giờ kết thúc phải sau giờ bắt đầu";
    }

    // [26E4] Duration check: duration >= 15 min and <= 240 min
    final duration = endMinutes - startMinutes;
    if (duration < 15 || duration > 240) {
      return "Thời lượng ca thi không hợp lệ (tối thiểu 15 phút, tối đa 240 phút)";
    }

    // [26E5] Period-to-Time compatibility check
    if (sessionPeriod != null && sessionPeriod.trim().isNotEmpty) {
      final periodMatch = sessionPeriodPattern.firstMatch(sessionPeriod.trim());
      if (periodMatch != null) {
        final startPeriod = int.tryParse(periodMatch.group(1)!);
        final endPeriod = int.tryParse(periodMatch.group(2)!);

        if (startPeriod != null && endPeriod != null && startPeriod >= 1 && endPeriod <= 12 && endPeriod >= startPeriod) {
          // Morning periods (1-6): must NOT be assigned afternoon hours (13:00+)
          if (endPeriod <= 6) {
            if (startMinutes >= 13 * 60 || endMinutes > 13 * 60) {
              return "Khung giờ thi không tương thích với ca thi (tiết học) đã chọn";
            }
          }
          // Afternoon periods (7-12): must NOT be assigned morning hours (before 12:00)
          else if (startPeriod >= 7) {
            if (startMinutes < 12 * 60 || endMinutes <= 12 * 60) {
              return "Khung giờ thi không tương thích với ca thi (tiết học) đã chọn";
            }
          }
        }
      }
    }

    return null;
  }

  /// Parses "HH:mm - HH:mm" into a pair of minutes from midnight (startMinutes, endMinutes)
  static (int, int)? parseTimeRange(String? value) {
    if (value == null) return null;
    final match = examTimePattern.firstMatch(value.trim());
    if (match == null) return null;
    final h1 = int.parse(match.group(1)!);
    final m1 = int.parse(match.group(2)!);
    final h2 = int.parse(match.group(3)!);
    final m2 = int.parse(match.group(4)!);
    return (h1 * 60 + m1, h2 * 60 + m2);
  }

  /// Helper to test if two time ranges (HH:mm - HH:mm) overlap
  static bool areTimeRangesOverlapping(String timeRangeA, String timeRangeB) {
    final rangeA = parseTimeRange(timeRangeA);
    final rangeB = parseTimeRange(timeRangeB);
    if (rangeA == null || rangeB == null) return false;

    // Overlap condition: max(startA, startB) < min(endA, endB)
    return rangeA.$1 < rangeB.$2 && rangeA.$2 > rangeB.$1;
  }

  // ==================== FIELD 7: PHÒNG THI ====================

  /// Validates Field 7: Phòng thi synchronously
  /// [27E1] Empty check
  /// [27E2] Facility catalogue format check
  static String? validateRoomCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Phòng thi không được để trống";
    }

    if (!roomPattern.hasMatch(value.trim())) {
      return "Phòng thi không tồn tại trong danh mục cơ sở vật chất của trường";
    }

    return null;
  }

  /// [27E2] Async/Catalogue existence check
  static String? validateRoomExistence({
    required String roomCode,
    required List<String> availableRooms,
  }) {
    final exists = availableRooms.any(
      (r) => r.trim().toUpperCase() == roomCode.trim().toUpperCase(),
    );
    if (!exists) {
      return "Phòng thi không tồn tại trong danh mục cơ sở vật chất của trường";
    }
    return null;
  }

  /// [27E4] Maintenance status check
  static String? validateRoomMaintenance({
    required bool isUnderMaintenance,
  }) {
    if (isUnderMaintenance) {
      return "Phòng thi hiện đang bảo trì, không thể xếp lịch";
    }
    return null;
  }

  /// [27E3] Schedule conflict detection for Room
  static String? validateRoomConflict({
    required String roomCode,
    required String examDate,
    required String examTime,
    required List<dynamic> existingSessions,
    String? currentSessionId,
  }) {
    for (final session in existingSessions) {
      final sId = session.id as String?;
      if (currentSessionId != null && sId == currentSessionId) continue;

      final sRoom = session.roomCode as String;
      final sDate = session.examDate as String;
      final sTime = session.examTime as String;

      if (sRoom.trim().toUpperCase() == roomCode.trim().toUpperCase() &&
          sDate.trim() == examDate.trim()) {
        if (areTimeRangesOverlapping(examTime, sTime)) {
          return "Phòng thi đã được xếp cho ca thi khác trong cùng khoảng thời gian này";
        }
      }
    }
    return null;
  }

  // ==================== FIELD 8: GIẢNG VIÊN CHẤM THI ====================

  /// Validates Field 8: Giảng viên chấm thi synchronously
  /// [28E1] Empty check
  static String? validateTeacher(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Vui lòng chọn giáo viên phụ trách ca thi";
    }
    return null;
  }

  /// [28E2] Staff registry existence check
  static String? validateTeacherExistence({
    required String teacherIdentifier,
    required List<String> registeredTeachers,
  }) {
    final clean = teacherIdentifier.trim().toLowerCase();
    final exists = registeredTeachers.any(
      (t) => t.trim().toLowerCase() == clean,
    );
    if (!exists) {
      return "Giáo viên không tồn tại trong hệ thống cán bộ của trường";
    }
    return null;
  }

  /// [28E3] Teacher schedule conflict
  static String? validateTeacherConflict({
    required String teacherIdentifier,
    required String examDate,
    required String examTime,
    required List<dynamic> existingSessions,
    String? currentSessionId,
  }) {
    final cleanTeacher = teacherIdentifier.trim().toLowerCase();

    for (final session in existingSessions) {
      final sId = session.id as String?;
      if (currentSessionId != null && sId == currentSessionId) continue;

      final sTeacherId = (session.teacherId as String? ?? '').trim().toLowerCase();
      final sTeacherName = (session.teacherName as String? ?? '').trim().toLowerCase();
      final sDate = (session.examDate as String).trim();
      final sTime = (session.examTime as String).trim();

      final matchesTeacher = cleanTeacher == sTeacherId ||
          cleanTeacher == sTeacherName ||
          sTeacherName.contains(cleanTeacher) ||
          cleanTeacher.contains(sTeacherName);

      if (matchesTeacher && sDate == examDate.trim()) {
        if (areTimeRangesOverlapping(examTime, sTime)) {
          return "Giảng viên đã có lịch coi thi/chấm thi ở phòng khác trong cùng khoảng thời gian này";
        }
      }
    }
    return null;
  }
}
