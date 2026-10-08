import 'package:cloud_firestore/cloud_firestore.dart';

class AbsenceRequestModel {
  final String id;
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
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime createdAt;
  final String? note; // Ghi chú từ giảng viên/quản trị viên

  const AbsenceRequestModel({
    required this.id,
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
    this.status = 'pending',
    required this.createdAt,
    this.note,
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
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (note != null) 'note': note,
    };
  }

  factory AbsenceRequestModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    return AbsenceRequestModel(
      id: id,
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      examShiftId: map['examShiftId'] as String? ?? '',
      examTime: parseDateTime(map['examTime']),
      reason: map['reason'] as String? ?? '',
      proofUrl: map['proofUrl'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: parseDateTime(map['createdAt']),
      note: map['note'] as String?,
    );
  }

  factory AbsenceRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AbsenceRequestModel.fromMap(data, doc.id);
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
    String? status,
    DateTime? createdAt,
    String? note,
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
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AbsenceRequestModel &&
        other.id == id &&
        other.studentId == studentId &&
        other.subjectId == subjectId &&
        other.status == status;
  }

  @override
  int get hashCode =>
      id.hashCode ^ studentId.hashCode ^ subjectId.hashCode ^ status.hashCode;
}
