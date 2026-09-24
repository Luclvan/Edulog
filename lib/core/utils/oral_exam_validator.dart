import 'package:flutter/services.dart';
import '../../features/oral_exam/data/models/exam_question_model.dart';

/// Validation utilities and business rules for Oral Exam Module (UC5)
class OralExamValidator {
  // Allowed photo extensions
  static const List<String> allowedPhotoExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

  // Maximum photo file size: 5.0 MB (5,242,880 bytes)
  static const int maxPhotoSizeBytes = 5 * 1024 * 1024; // 5,242,880 bytes

  // Minimum photo file size: 20 KB (20,480 bytes)
  static const int minPhotoSizeBytes = 20 * 1024; // 20,480 bytes

  // ==================== MODULE 1: STUDENT PHOTO VERIFICATION ====================

  /// [8E1] Maps camera permissions and platform exceptions
  static String mapCameraPlatformException(dynamic error) {
    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      final msg = (error.message ?? '').toLowerCase();
      if (code.contains('camera_access_denied') ||
          code.contains('permission_denied') ||
          msg.contains('permission') ||
          msg.contains('access') ||
          msg.contains('quyền')) {
        return "Ứng dụng cần quyền truy cập máy ảnh để chụp ảnh xác thực sinh viên";
      }
    }
    return "Chưa chụp được ảnh xác thực. Vui lòng thực hiện lại";
  }

  /// [8E3, 8E4] Validates photo format and size
  static String? validatePhoto({
    required String filename,
    required int bytesLength,
  }) {
    // [8E4] Format check
    final lowerName = filename.toLowerCase();
    final hasValidExt = allowedPhotoExtensions.any((ext) => lowerName.endsWith(ext));
    if (!hasValidExt) {
      return "Định dạng ảnh không được hỗ trợ";
    }

    // [8E3] File size max check
    if (bytesLength > maxPhotoSizeBytes) {
      return "Dung lượng ảnh vượt quá giới hạn 5MB";
    }

    // [8E3] File size min check (prevent empty / corrupt files)
    if (bytesLength < minPhotoSizeBytes) {
      return "Dung lượng ảnh quá nhỏ hoặc file bị lỗi";
    }

    return null;
  }

  /// [8E5 - 8E7] Computer Vision / Quality validation (Pre-upload checks)
  static String? validateFaceAndQuality({
    int detectedFaces = 1,
    bool isBlurredOrDark = false,
  }) {
    // [8E5] Face missing
    if (detectedFaces == 0) {
      return "Không phát hiện khuôn mặt trong ảnh chụp. Vui lòng căn chỉnh lại góc chụp";
    }

    // [8E6] Multiple faces detected
    if (detectedFaces >= 2) {
      return "Khung hình điểm danh chỉ được xuất hiện một sinh viên duy nhất";
    }

    // [8E7] Blur / Lighting check
    if (isBlurredOrDark) {
      return "Ảnh quá mờ hoặc thiếu sáng. Vui lòng chụp lại nơi đủ ánh sáng";
    }

    return null;
  }

  // ==================== MODULE 2: ORAL EXAM GRADING ====================

  /// [9E2 - 9E4] Component question score validation
  static String? validateQuestionScore(dynamic score) {
    if (score == null) {
      return "Vui lòng hoàn tất chấm điểm cho tất cả câu hỏi đã chọn";
    }

    // [9E4] Integer check
    if (score is! int && (score is double && score != score.truncateToDouble())) {
      return "Điểm câu hỏi thành phần phải là số nguyên";
    }

    final intVal = (score as num).toInt();

    // [9E2] Lower bound check
    if (intVal < 0) {
      return "Điểm câu hỏi không được nhỏ hơn 0";
    }

    // [9E3] Upper bound check
    if (intVal > 10) {
      return "Điểm câu hỏi không được vượt quá 10";
    }

    return null;
  }

  /// [9E1] Mandatory grading for all selected questions
  static String? validateAllSelectedQuestionsGraded(List<ExamQuestionModel> questions) {
    final selectedQuestions = questions.where((q) => q.isSelected).toList();
    if (selectedQuestions.isEmpty) {
      return "Vui lòng chọn ít nhất một câu hỏi vấn đáp";
    }

    for (final q in selectedQuestions) {
      if (q.score == null) {
        return "Vui lòng hoàn tất chấm điểm cho tất cả câu hỏi đã chọn";
      }
      final err = validateQuestionScore(q.score);
      if (err != null) return err;
    }

    return null;
  }

  // ==================== FINAL OVERALL SCORE ====================

  /// [10E1 - 10E4] Final overall score validation
  static String? validateOverallScore({
    required bool isScoreConfirmed,
    required double score,
    int? wholeScore,
    int? decimalScore,
  }) {
    // [10E1] Confirmation check
    if (!isScoreConfirmed) {
      return "Vui lòng bấm Xác nhận điểm số trước khi lưu kết quả";
    }

    final whole = wholeScore ?? score.floor();
    final decimal = decimalScore ?? ((score - score.floor()) * 10).round();

    // [10E2] Lower bound check
    if (score < 0.0 || whole < 0) {
      return "Điểm số không được nhỏ hơn 0.0";
    }

    // [10E4] Edge constraint: If integer part is 10, decimal part must be 0
    if (whole == 10 && decimal > 0) {
      return "Điểm tối đa là 10.0, không thể có số thập phân";
    }

    // [10E3] Upper bound check
    if (score > 10.0 || whole > 10) {
      return "Điểm số tối đa là 10.0";
    }

    return null;
  }

  // ==================== TEACHER REVIEW / FEEDBACK ====================

  static final RegExp _maliciousTagPattern = RegExp(
    r'<\s*(?:script|iframe)[^>]*>',
    caseSensitive: false,
  );

  /// [11E1 - 11E3] Teacher feedback review validation
  static String? validateTeacherReview(String? review) {
    if (review == null || review.trim().isEmpty) {
      return null; // Feedback is optional if untouched
    }

    final trimmed = review.trim();

    // [11E3] XSS / Malicious tag sanitize check
    if (_maliciousTagPattern.hasMatch(trimmed) ||
        trimmed.toLowerCase().contains('<script') ||
        trimmed.toLowerCase().contains('<iframe') ||
        trimmed.contains(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'))) {
      return "Nội dung nhận xét chứa ký tự không an toàn";
    }

    // [11E1] Min length: If manual feedback text is entered, length must be >= 5 characters
    if (trimmed.length < 5) {
      return "Nội dung nhận xét tối thiểu từ 5 ký tự";
    }

    // [11E2] Max length: Length must not exceed 1000 characters
    if (trimmed.length > 1000) {
      return "Nội dung nhận xét không được vượt quá 1000 ký tự";
    }

    return null;
  }

  /// Available quick tags for assessment review
  static const List<String> quickTags = [
    '[Trả lời lưu loát]',
    '[Chép code]',
    '[Nắm chắc kiến trúc]',
    '[Cần cải thiện]',
    '[Hiểu sâu logic]',
  ];
}
