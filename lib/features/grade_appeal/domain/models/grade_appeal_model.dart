import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a Grade Appeal (Đơn phúc khảo)
enum GradeAppealStatus {
  pending('Chờ xử lý'),
  approved('Đã duyệt'),
  rejected('Từ chối');

  final String label;
  const GradeAppealStatus(this.label);
}

/// Model representing a Grade Appeal (Đơn phúc khảo) in EduLog
class GradeAppealModel {
  final String? id;
  final String studentName;   // [5E1 - 5E6] Họ và tên
  final String studentId;     // [6E1 - 6E5] Mã sinh viên (10 số, khóa 18-26)
  final String studentEmail;  // [7E1 - 7E4] Email sinh viên (@e.tlu.edu.vn)
  final double currentScore;  // [8E1 - 8E5] Điểm thi hiện tại (0.0 - 10.0, step 0.1)
  final String examDate;      // [9E1 - 9E5] Ngày thi (DD/MM/YYYY)
  final String subjectName;   // [10E1 - 10E6] Tên môn thi
  final String? subjectCode;  // Mã môn thi
  final String examShift;     // [11E1 - 11E3] Ca thi (Ca 1 - Ca 6 hoặc 1-3, 4-6...)
  final String? reason;       // Lý do xin phúc khảo
  final GradeAppealStatus status;
  final DateTime? createdAt;

  const GradeAppealModel({
    this.id,
    required this.studentName,
    required this.studentId,
    required this.studentEmail,
    required this.currentScore,
    required this.examDate,
    required this.subjectName,
    this.subjectCode,
    required this.examShift,
    this.reason,
    this.status = GradeAppealStatus.pending,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'ho_va_ten': studentName,
      'ma_sinh_vien': studentId,
      'email': studentEmail,
      'diem_hien_tai': currentScore,
      'ngay_thi': examDate,
      'mon_thi': subjectName,
      'ma_mon': subjectCode,
      'ca_thi': examShift,
      'ly_do': reason,
      'trang_thai': status.name,
      'ngay_tao': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory GradeAppealModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime? parsedDate;
    final rawDate = map['ngay_tao'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    final rawStatus = map['trang_thai'] as String? ?? 'pending';
    final status = GradeAppealStatus.values.firstWhere(
      (s) => s.name == rawStatus,
      orElse: () => GradeAppealStatus.pending,
    );

    return GradeAppealModel(
      id: id ?? map['id'] as String?,
      studentName: map['ho_va_ten'] as String? ?? map['studentName'] as String? ?? '',
      studentId: map['ma_sinh_vien'] as String? ?? map['studentId'] as String? ?? '',
      studentEmail: map['email'] as String? ?? map['studentEmail'] as String? ?? '',
      currentScore: (map['diem_hien_tai'] as num? ?? map['currentScore'] as num? ?? 0.0).toDouble(),
      examDate: map['ngay_thi'] as String? ?? map['examDate'] as String? ?? '',
      subjectName: map['mon_thi'] as String? ?? map['subjectName'] as String? ?? '',
      subjectCode: map['ma_mon'] as String? ?? map['subjectCode'] as String?,
      examShift: map['ca_thi'] as String? ?? map['examShift'] as String? ?? '',
      reason: map['ly_do'] as String? ?? map['reason'] as String?,
      status: status,
      createdAt: parsedDate,
    );
  }

  GradeAppealModel copyWith({
    String? id,
    String? studentName,
    String? studentId,
    String? studentEmail,
    double? currentScore,
    String? examDate,
    String? subjectName,
    String? subjectCode,
    String? examShift,
    String? reason,
    GradeAppealStatus? status,
    DateTime? createdAt,
  }) {
    return GradeAppealModel(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      studentId: studentId ?? this.studentId,
      studentEmail: studentEmail ?? this.studentEmail,
      currentScore: currentScore ?? this.currentScore,
      examDate: examDate ?? this.examDate,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      examShift: examShift ?? this.examShift,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Subject information for student appeal eligibility check
class AppealSubjectItem {
  final String code;
  final String name;
  final String actualExamDate;      // DD/MM/YYYY
  final String assignedShift;       // e.g. "Ca 2" or "4-6"
  final double? publishedScore;     // null if score not published yet [10E6]
  final bool isRegistered;          // Student is in roster [10E4]
  final bool hasExamOrganized;      // Course has exam in term [10E3]
  final bool existsInCurriculum;    // Course in curriculum [10E2]

  const AppealSubjectItem({
    required this.code,
    required this.name,
    required this.actualExamDate,
    required this.assignedShift,
    this.publishedScore,
    this.isRegistered = true,
    this.hasExamOrganized = true,
    this.existsInCurriculum = true,
  });

  factory AppealSubjectItem.fromMap(Map<String, dynamic> map) {
    return AppealSubjectItem(
      code: map['ma_mon'] as String? ?? map['code'] as String? ?? '',
      name: map['ten_mon'] as String? ?? map['name'] as String? ?? '',
      actualExamDate: map['ngay_thi'] as String? ?? map['actualExamDate'] as String? ?? '',
      assignedShift: map['ca_thi'] as String? ?? map['assignedShift'] as String? ?? '',
      publishedScore: (map['diem_thi'] as num? ?? map['publishedScore'] as num?)?.toDouble(),
      isRegistered: map['da_dang_ky'] as bool? ?? map['isRegistered'] as bool? ?? true,
      hasExamOrganized: map['co_to_chuc_thi'] as bool? ?? map['hasExamOrganized'] as bool? ?? true,
      existsInCurriculum: map['thuoc_ctdt'] as bool? ?? map['existsInCurriculum'] as bool? ?? true,
    );
  }
}
