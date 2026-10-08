import 'package:cloud_firestore/cloud_firestore.dart';

/// Validation utilities and business rules for Exam Absence Request Module (UC: exam_absence)
class AbsenceFormValidator {
  static final RegExp _fullNameValidPattern = RegExp(
    r'^[a-zA-Z\s'
    r'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ'
    r'ÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ'
    r']+$',
  );

  static final RegExp _phoneDigitsOnlyPattern = RegExp(r'^[0-9]+$');
  static final RegExp _vnPhonePattern = RegExp(r'^(03|05|07|08|09)[0-9]{8}$');

  static final RegExp _rfc5322EmailPattern = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  // ==================== 1. FULL NAME VALIDATION (15E1 - 15E4) ====================

  /// Validates Full Name
  /// [15E1] Trống: "Họ và tên không được để trống"
  /// [15E2] Ngoài 2-50 ký tự: "Họ và tên sinh viên phải từ 2 đến 50 ký tự"
  /// [15E3] Chứa số/ký tự lạ: "Họ và tên không được chứa chữ số hoặc ký tự đặc biệt"
  /// [15E4] Khác tên tài khoản: "Họ và tên không khớp với thông tin sinh viên đăng nhập"
  static String? validateFullName(String? value, {String? loggedInStudentName}) {
    // [15E1] Empty check
    if (value == null || value.trim().isEmpty) {
      return "Họ và tên không được để trống";
    }

    final trimmed = value.trim();

    // [15E2] Length check (2 to 50 chars)
    if (trimmed.length < 2 || trimmed.length > 50) {
      return "Họ và tên sinh viên phải từ 2 đến 50 ký tự";
    }

    // [15E3] Character whitelist (Vietnamese / English letters and spaces only)
    if (!_fullNameValidPattern.hasMatch(trimmed)) {
      return "Họ và tên không được chứa chữ số hoặc ký tự đặc biệt";
    }

    // [15E4] Account name match check
    if (loggedInStudentName != null && loggedInStudentName.trim().isNotEmpty) {
      if (trimmed.toLowerCase() != loggedInStudentName.trim().toLowerCase()) {
        return "Họ và tên không khớp với thông tin sinh viên đăng nhập";
      }
    }

    return null;
  }

  // ==================== 2. PHONE NUMBER VALIDATION (16E1 - 16E4) ====================

  /// Validates Phone Number
  /// [16E1] Trống: "Số điện thoại không được để trống"
  /// [16E4] Chứa chữ cái/khoảng trắng/ký tự đặc biệt: "Số điện thoại chỉ được chứa các chữ số"
  /// [16E2] Độ dài != 10: "Số điện thoại phải gồm đúng 10 chữ số"
  /// [16E3] Đầu số sai / không bắt đầu bằng 0: "Số điện thoại không hợp lệ"
  static String? validatePhoneNumber(String? value) {
    // [16E1] Empty check
    if (value == null || value.isEmpty) {
      return "Số điện thoại không được để trống";
    }

    // [16E4] Digits only check
    if (!_phoneDigitsOnlyPattern.hasMatch(value)) {
      return "Số điện thoại chỉ được chứa các chữ số";
    }

    // [16E2] Length must be exactly 10 digits
    if (value.length != 10) {
      return "Số điện thoại phải gồm đúng 10 chữ số";
    }

    // [16E3] Valid VN carrier prefix (03|05|07|08|09)
    if (!_vnPhonePattern.hasMatch(value)) {
      return "Số điện thoại không hợp lệ";
    }

    return null;
  }

  // ==================== 3. EMAIL VALIDATION (17E1 - 17E4) ====================

  /// Validates Institutional Email
  /// [17E1] Trống: "Email không được để trống"
  /// [17E4] Chứa khoảng trắng: "Email không được chứa khoảng trắng"
  /// [17E2] Sai định dạng email: "Định dạng email không hợp lệ"
  /// [17E3] Tên miền ngoài TLU: "Vui lòng sử dụng email trường (@e.tlu.edu.vn)"
  static String? validateEmail(String? value) {
    // [17E1] Empty check
    if (value == null || value.isEmpty) {
      return "Email không được để trống";
    }

    // [17E4] Whitespace check
    if (value.contains(RegExp(r'\s'))) {
      return "Email không được chứa khoảng trắng";
    }

    // [17E2] Standard RFC 5322 structure
    if (!_rfc5322EmailPattern.hasMatch(value)) {
      return "Định dạng email không hợp lệ";
    }

    // [17E3] TLU Domain restriction (@e.tlu.edu.vn or @tlu.edu.vn)
    final lower = value.toLowerCase();
    if (!lower.endsWith('@e.tlu.edu.vn') && !lower.endsWith('@tlu.edu.vn')) {
      return "Vui lòng sử dụng email trường (@e.tlu.edu.vn)";
    }

    return null;
  }

  // ==================== 4. REASON VALIDATION (18E1 - 18E3) ====================

  /// Validates Reason for absence
  /// [18E1] Trống / toàn space: "Vui lòng nhập lý do xin vắng thi"
  /// [18E2] Dưới 10 ký tự: "Lý do xin vắng thi phải từ 10 ký tự trở lên"
  /// [18E3] Quá 500 ký tự: "Lý do xin vắng thi không được vượt quá 500 ký tự"
  static String? validateReason(String? value) {
    // [18E1] Empty / whitespace check
    if (value == null || value.trim().isEmpty) {
      return "Vui lòng nhập lý do xin vắng thi";
    }

    final trimmed = value.trim();

    // [18E2] Min length (< 10 chars)
    if (trimmed.length < 10) {
      return "Lý do xin vắng thi phải từ 10 ký tự trở lên";
    }

    // [18E3] Max length (> 500 chars)
    if (value.length > 500 || trimmed.length > 500) {
      return "Lý do xin vắng thi không được vượt quá 500 ký tự";
    }

    return null;
  }

  // ==================== 5. PROOF DOCUMENT URL (19E1 - 19E4) ====================

  /// Validates Proof Document URL
  /// [19E1] Trống: "Bắt buộc cung cấp đường dẫn tài liệu minh chứng"
  /// [19E4] Chứa khoảng trắng: "Đường dẫn không được chứa khoảng trắng"
  /// [19E2] Không bắt đầu bằng https://: "Đường dẫn minh chứng phải bắt đầu bằng https://"
  /// [19E3] Không đúng nguồn Drive / file trực tiếp: "Đường dẫn minh chứng phải là link Google Drive hoặc tệp ảnh/PDF trực tiếp"
  static String? validateProofUrl(String? value) {
    // [19E1] Empty check
    if (value == null || value.trim().isEmpty) {
      return "Bắt buộc cung cấp đường dẫn tài liệu minh chứng";
    }

    // [19E4] Whitespace check
    if (value.contains(RegExp(r'\s'))) {
      return "Đường dẫn không được chứa khoảng trắng";
    }

    // Max length check (500 chars)
    if (value.length > 500) {
      return "Đường dẫn tài liệu không được vượt quá 500 ký tự";
    }

    // [19E2] Starts with https://
    if (!value.startsWith('https://')) {
      return "Đường dẫn minh chứng phải bắt đầu bằng https://";
    }

    // [19E3] Google Drive or direct image/PDF file
    // Regex hỗ trợ các dạng link Google Drive:
    //   - https://drive.google.com/file/d/...
    //   - https://drive.google.com/drive/folders/...
    //   - https://drive.google.com/drive/u/0/folders/...   (đa tài khoản /u/N/)
    //   - https://drive.google.com/drive/u/1/folders/...
    //   - https://drive.google.com/u/0/folders/...
    //   - https://drive.google.com/u/0/file/d/...
    final isDrive = RegExp(
      r'^https://drive\.google\.com/'
      r'(?:drive/)?'       // tuỳ chọn: có hoặc không có "drive/"
      r'(?:u/\d+/)?'       // tuỳ chọn: multi-account prefix /u/0/, /u/1/, ...
      r'(?:folders/|file/d/)' // bắt buộc kết thúc bằng "folders/" hoặc "file/d/"
      r'.+',               // bắt buộc có nội dung sau prefix (ID)
    ).hasMatch(value);

    final isDirectFile =
        RegExp(r'\.(jpg|jpeg|png|pdf)(\?.*)?$', caseSensitive: false)
            .hasMatch(value);

    if (!isDrive && !isDirectFile) {
      return "Đường dẫn minh chứng phải là link Google Drive hoặc tệp ảnh/PDF trực tiếp";
    }

    return null;
  }

  // ==================== 6. SUBJECT & EXAM SHIFT (20E1 - 20E4) ====================

  /// [20E1] Chưa chọn môn: "Vui lòng chọn môn học xin vắng thi"
  static String? validateSubjectSelected(String? subjectId) {
    if (subjectId == null || subjectId.trim().isEmpty) {
      return "Vui lòng chọn môn học xin vắng thi";
    }
    return null;
  }

  /// [20E2] Sinh viên không có tên trong danh sách dự thi môn này:
  /// "Bạn không thuộc danh sách dự thi của môn học này"
  static String? validateStudentInExamList({required bool isInExamList}) {
    if (!isInExamList) {
      return "Bạn không thuộc danh sách dự thi của môn học này";
    }
    return null;
  }

  /// [20E3] Kiểm tra deadline: Thời điểm nộp đơn phải trước giờ thi hoặc không quá 48 giờ sau khi kết thúc ca thi:
  /// "Đã hết thời hạn nộp đơn xin vắng thi cho môn học này (quá 48 giờ kể từ ca thi)"
  static String? validateExamDeadline({
    required DateTime examTime,
    DateTime? submissionTime,
  }) {
    final now = submissionTime ?? DateTime.now();
    final deadline = examTime.add(const Duration(hours: 48));
    if (now.isAfter(deadline)) {
      return "Đã hết thời hạn nộp đơn xin vắng thi cho môn học này (quá 48 giờ kể từ ca thi)";
    }
    return null;
  }

  /// [20E4] Kiểm tra đơn trùng lặp: Nếu môn này đã có đơn vắng thi đang ở trạng thái 'pending':
  /// "Bạn đã gửi đơn xin vắng thi cho môn này và đang chờ duyệt"
  static String? validateNoPendingDuplicate({required bool hasPendingRequest}) {
    if (hasPendingRequest) {
      return "Bạn đã gửi đơn xin vắng thi cho môn này và đang chờ duyệt";
    }
    return null;
  }

  /// Async Firestore check for pending duplicate request (20E4)
  static Future<bool> isDuplicatePendingRequest({
    required String studentId,
    required String subjectId,
    FirebaseFirestore? firestore,
  }) async {
    final db = firestore ?? FirebaseFirestore.instance;
    try {
      final snapshot = await db
          .collection('absence_requests')
          .where('studentId', isEqualTo: studentId)
          .where('subjectId', isEqualTo: subjectId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
