import '../../features/exam_absence/domain/models/absence_request_model.dart';

/// Business logic and validation constraints for "Tạo đơn xin vắng / hoãn thi" (Exam Absence Request) module.
///
/// Implements error codes [15E1] to [20E4] according to Software Testing specification.
class AbsenceRequestValidator {
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

  // VN phone number prefixes: 03, 05, 07, 08, 09
  static final RegExp _phoneVNPattern = RegExp(r'^(03|05|07|08|09)[0-9]{8}$');

  // Google Drive regex pattern
  static final RegExp _googleDrivePattern = RegExp(
    r'^https://drive\.google\.com/(?:drive/)?(?:u/\d+/)?(?:folders/|file/d/|folders|file/d)[a-zA-Z0-9_/-]*',
    caseSensitive: false,
  );

  // Direct image/PDF file link regex
  static final RegExp _directFilePattern = RegExp(
    r'^https://[^\s]+\.(jpg|jpeg|png|pdf)(\?.*)?$',
    caseSensitive: false,
  );

  // ==================== FIELD 1: HỌ VÀ TÊN ====================

  /// Validates Field 1: Họ và tên
  /// [15E1] Trống: "Họ và tên không được để trống"
  /// [15E3] Chứa số/ký tự lạ: "Họ và tên không được chứa chữ số hoặc ký tự đặc biệt"
  /// [15E2] Ngoài 2-50 ký tự: "Họ và tên sinh viên phải từ 2 đến 50 ký tự"
  /// [15E4] Khác tên tài khoản: "Họ và tên không khớp với thông tin sinh viên đăng nhập"
  static String? validateFullName(
    String? value, {
    String? accountFullName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return "Họ và tên không được để trống";
    }

    final trimmed = value.trim();

    // Check digits or special characters
    if (!_fullNamePattern.hasMatch(trimmed)) {
      return "Họ và tên không được chứa chữ số hoặc ký tự đặc biệt";
    }

    // Check length (2 - 50 chars)
    if (trimmed.length < 2 || trimmed.length > 50) {
      return "Họ và tên sinh viên phải từ 2 đến 50 ký tự";
    }

    // Cross-validation with logged in account name
    if (accountFullName != null && accountFullName.trim().isNotEmpty) {
      if (trimmed.toLowerCase() != accountFullName.trim().toLowerCase()) {
        return "Họ và tên không khớp với thông tin sinh viên đăng nhập";
      }
    }

    return null;
  }

  // ==================== FIELD 2: SỐ ĐIỆN THOẠI ====================

  /// Validates Field 2: Số điện thoại
  /// [16E1] Trống: "Số điện thoại không được để trống"
  /// [16E4] Chứa chữ cái/khoảng trắng/ký tự đặc biệt: "Số điện thoại chỉ được chứa các chữ số"
  /// [16E2] Độ dài != 10: "Số điện thoại phải gồm đúng 10 chữ số"
  /// [16E3] Đầu số sai / không bắt đầu bằng 0: "Số điện thoại không hợp lệ"
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Số điện thoại không được để trống";
    }

    final trimmed = value.trim();

    // Check if contains non-digits (or internal whitespace)
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
      return "Số điện thoại chỉ được chứa các chữ số";
    }

    // Check exact length of 10 digits
    if (trimmed.length != 10) {
      return "Số điện thoại phải gồm đúng 10 chữ số";
    }

    // Check valid VN carrier prefix (03, 05, 07, 08, 09)
    if (!_phoneVNPattern.hasMatch(trimmed)) {
      return "Số điện thoại không hợp lệ";
    }

    return null;
  }

  // ==================== FIELD 3: EMAIL ====================

  /// Validates Field 3: Email
  /// [17E1] Trống: "Email không được để trống"
  /// [17E4] Chứa khoảng trắng: "Email không được chứa khoảng trắng"
  /// [17E2] Sai định dạng email: "Định dạng email không hợp lệ"
  /// [17E3] Tên miền ngoài TLU: "Vui lòng sử dụng email trường (@e.tlu.edu.vn)"
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email không được để trống";
    }

    // Check whitespace
    if (value.contains(' ')) {
      return "Email không được chứa khoảng trắng";
    }

    final trimmed = value.trim();

    // Check RFC format
    if (!_emailFormatPattern.hasMatch(trimmed)) {
      return "Định dạng email không hợp lệ";
    }

    // Check TLU domain (@e.tlu.edu.vn or @tlu.edu.vn)
    final lower = trimmed.toLowerCase();
    if (!lower.endsWith('@e.tlu.edu.vn') && !lower.endsWith('@tlu.edu.vn')) {
      return "Vui lòng sử dụng email trường (@e.tlu.edu.vn)";
    }

    return null;
  }

  // ==================== FIELD 4: LÝ DO VẮNG THI ====================

  /// Validates Field 4: Lý do vắng thi
  /// [18E1] Trống / toàn space: "Vui lòng nhập lý do xin vắng thi"
  /// [18E2] Dưới 10 ký tự: "Lý do xin vắng thi phải từ 10 ký tự trở lên"
  /// [18E3] Quá 500 ký tự: "Lý do xin vắng thi không được vượt quá 500 ký tự"
  static String? validateReason(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Vui lòng nhập lý do xin vắng thi";
    }

    final trimmed = value.trim();

    if (trimmed.length < 10) {
      return "Lý do xin vắng thi phải từ 10 ký tự trở lên";
    }

    if (trimmed.length > 500) {
      return "Lý do xin vắng thi không được vượt quá 500 ký tự";
    }

    return null;
  }

  // ==================== FIELD 5: TÀI LIỆU MINH CHỨNG ====================

  /// Validates Field 5: Tài liệu minh chứng (Link Google Drive hoặc Ảnh/PDF trực tiếp)
  /// [19E1] Trống: "Bắt buộc cung cấp đường dẫn tài liệu minh chứng"
  /// [19E4] Chứa khoảng trắng: "Đường dẫn không được chứa khoảng trắng"
  /// [19E2] Không bắt đầu bằng https://: "Đường dẫn minh chứng phải bắt đầu bằng https://"
  /// [19E3] Không đúng nguồn Drive / file trực tiếp: "Đường dẫn minh chứng phải là link Google Drive hoặc tệp ảnh/PDF trực tiếp"
  static String? validateProofUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Bắt buộc cung cấp đường dẫn tài liệu minh chứng";
    }

    // Check whitespace
    if (value.contains(' ')) {
      return "Đường dẫn không được chứa khoảng trắng";
    }

    final trimmed = value.trim();

    // Check https:// scheme
    if (!trimmed.startsWith('https://')) {
      return "Đường dẫn minh chứng phải bắt đầu bằng https://";
    }

    // Check valid source: Google Drive OR direct image/PDF
    final isGoogleDrive = _googleDrivePattern.hasMatch(trimmed);
    final isDirectFile = _directFilePattern.hasMatch(trimmed);

    if (!isGoogleDrive && !isDirectFile) {
      return "Đường dẫn minh chứng phải là link Google Drive hoặc tệp ảnh/PDF trực tiếp";
    }

    return null;
  }

  // ==================== FIELD 6: MÔN HỌC & CA THI ====================

  /// Validates Field 6: Môn học & Ca thi
  /// [20E1] Chưa chọn: "Vui lòng chọn môn học xin vắng thi"
  /// [20E2] Roster check: "Bạn không thuộc danh sách dự thi của môn học này"
  /// [20E3] Deadline check: "Đã hết thời hạn nộp đơn xin vắng thi cho môn học này (quá 48 giờ kể từ ca thi)"
  static String? validateSubjectSelection(
    ExamSubjectItem? subject, {
    DateTime? now,
  }) {
    if (subject == null) {
      return "Vui lòng chọn môn học xin vắng thi";
    }

    if (!subject.isRegistered) {
      return "Bạn không thuộc danh sách dự thi của môn học này";
    }

    final currentTime = now ?? DateTime.now();
    final examEndTime = subject.examEndTime ?? subject.examTime.add(const Duration(hours: 2));

    // Deadline check: submission must be before or within 48h after the exam ends
    if (currentTime.isAfter(examEndTime)) {
      final diff = currentTime.difference(examEndTime);
      if (diff.inHours >= 48) {
        return "Đã hết thời hạn nộp đơn xin vắng thi cho môn học này (quá 48 giờ kể từ ca thi)";
      }
    }

    return null;
  }

  /// [20E4] Duplicate pending request check
  static String? validateDuplicateRequest(bool hasPendingRequest) {
    if (hasPendingRequest) {
      return "Bạn đã gửi đơn xin vắng thi cho môn này và đang chờ duyệt";
    }
    return null;
  }
}
