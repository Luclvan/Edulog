import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of an Exam Absence Request (Đơn xin vắng / hoãn thi)
enum AbsenceRequestStatus {
  pending('Chờ duyệt'),
  approved('Đã duyệt'),
  rejected('Từ chối');

  final String label;
  const AbsenceRequestStatus(this.label);
}

/// Model representing an Exam Subject available for absence request
class ExamSubjectItem {
  final String subjectId;
  final String subjectName;
  final String examShiftId;
  final String examShiftName;
  final DateTime examTime;
  final DateTime? examEndTime;
  final bool isRegistered;

  const ExamSubjectItem({
    required this.subjectId,
    required this.subjectName,
    required this.examShiftId,
    required this.examShiftName,
    required this.examTime,
    this.examEndTime,
    this.isRegistered = true,
  });

  factory ExamSubjectItem.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ExamSubjectItem(
      subjectId: map['subjectId'] as String? ?? map['ma_mon'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? map['ten_mon'] as String? ?? '',
      examShiftId: map['examShiftId'] as String? ?? map['ca_thi_id'] as String? ?? '',
      examShiftName: map['examShiftName'] as String? ?? map['ca_thi'] as String? ?? '',
      examTime: parseDate(map['examTime'] ?? map['ngay_thi']),
      examEndTime: map['examEndTime'] != null ? parseDate(map['examEndTime']) : null,
      isRegistered: map['isRegistered'] as bool? ?? map['da_dang_ky'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectId': subjectId,
      'subjectName': subjectName,
      'examShiftId': examShiftId,
      'examShiftName': examShiftName,
      'examTime': Timestamp.fromDate(examTime),
      'examEndTime': examEndTime != null ? Timestamp.fromDate(examEndTime!) : null,
      'isRegistered': isRegistered,
    };
  }
}

/// Model representing an Exam Absence Request (Đơn xin vắng / hoãn thi) in EduLog
class AbsenceRequestModel {
  final String? id;
  final String studentId;
  final String studentName;
  final String phone;
  final String email;
  final String subjectId;
  final String subjectName;
  final String examShiftId;
  final DateTime examTime;
  final String reason;
  final String proofUrl;
  final AbsenceRequestStatus status;
  final DateTime? createdAt;

  const AbsenceRequestModel({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.phone,
    required this.email,
    required this.subjectId,
    required this.subjectName,
    required this.examShiftId,
    required this.examTime,
    required this.reason,
    required this.proofUrl,
    this.status = AbsenceRequestStatus.pending,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'phone': phone,
      'email': email,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'examShiftId': examShiftId,
      'examTime': Timestamp.fromDate(examTime),
      'reason': reason,
      'proofUrl': proofUrl,
      'status': status.name,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory AbsenceRequestModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime parsedExamTime = DateTime.now();
    final rawExamTime = map['examTime'] ?? map['ngay_thi'];
    if (rawExamTime is Timestamp) {
      parsedExamTime = rawExamTime.toDate();
    } else if (rawExamTime is String) {
      parsedExamTime = DateTime.tryParse(rawExamTime) ?? DateTime.now();
    } else if (rawExamTime is DateTime) {
      parsedExamTime = rawExamTime;
    }

    DateTime? parsedCreatedAt;
    final rawCreatedAt = map['createdAt'] ?? map['ngay_tao'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    } else if (rawCreatedAt is DateTime) {
      parsedCreatedAt = rawCreatedAt;
    }

    final rawStatus = map['status'] as String? ?? map['trang_thai'] as String? ?? 'pending';
    final status = AbsenceRequestStatus.values.firstWhere(
      (s) => s.name == rawStatus,
      orElse: () => AbsenceRequestStatus.pending,
    );

    return AbsenceRequestModel(
      id: id ?? map['id'] as String?,
      studentId: map['studentId'] as String? ?? map['ma_sinh_vien'] as String? ?? '',
      studentName: map['studentName'] as String? ?? map['ho_va_ten'] as String? ?? '',
      phone: map['phone'] as String? ?? map['so_dien_thoai'] as String? ?? '',
      email: map['email'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? map['ma_mon'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? map['ten_mon'] as String? ?? '',
      examShiftId: map['examShiftId'] as String? ?? map['ca_thi_id'] as String? ?? '',
      examTime: parsedExamTime,
      reason: map['reason'] as String? ?? map['ly_do'] as String? ?? '',
      proofUrl: map['proofUrl'] as String? ?? map['minh_chung_url'] as String? ?? '',
      status: status,
      createdAt: parsedCreatedAt,
    );
  }

  AbsenceRequestModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? phone,
    String? email,
    String? subjectId,
    String? subjectName,
    String? examShiftId,
    DateTime? examTime,
    String? reason,
    String? proofUrl,
    AbsenceRequestStatus? status,
    DateTime? createdAt,
  }) {
    return AbsenceRequestModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      examShiftId: examShiftId ?? this.examShiftId,
      examTime: examTime ?? this.examTime,
      reason: reason ?? this.reason,
      proofUrl: proofUrl ?? this.proofUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
