import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing an Exam Session (Ca thi) in EduLog
class ExamSessionModel {
  final String? id;
  final String examTermName; // [21E1-21E4] e.g. K65_Lich_Thi_HK2_GĐ1_NH_2025-2026
  final String courseName;   // [22E1-22E3] e.g. Kiểm thử phần mềm
  final String? courseCode;  // e.g. INT3134
  final int credits;         // [23E1-23E3] 1 - 5
  final String examDate;     // [24E1-24E4] DD/MM/YYYY
  final String sessionPeriod;// [25E1-25E4] e.g. 4-6
  final String examTime;     // [26E1-26E5] HH:mm - HH:mm
  final String roomCode;     // [27E1-27E4] e.g. 131-A2
  final String teacherName;  // [28E1-28E3] e.g. TS. Lê Văn Lực
  final String? teacherId;   // e.g. GV001
  final DateTime? createdAt;

  const ExamSessionModel({
    this.id,
    required this.examTermName,
    required this.courseName,
    this.courseCode,
    required this.credits,
    required this.examDate,
    required this.sessionPeriod,
    required this.examTime,
    required this.roomCode,
    required this.teacherName,
    this.teacherId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'ten_dot_thi': examTermName,
      'ten_mon_hoc': courseName,
      'ma_mon_hoc': courseCode,
      'so_tin_chi': credits,
      'ngay_thi': examDate,
      'ca_thi': sessionPeriod,
      'gio_thi': examTime,
      'phong_thi': roomCode,
      'giang_vien_cham_thi': teacherName,
      'giang_vien_id': teacherId,
      'ngay_tao': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory ExamSessionModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime? parsedDate;
    final rawDate = map['ngay_tao'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    return ExamSessionModel(
      id: id ?? map['id'] as String?,
      examTermName: map['ten_dot_thi'] as String? ?? map['examTermName'] as String? ?? '',
      courseName: map['ten_mon_hoc'] as String? ?? map['courseName'] as String? ?? '',
      courseCode: map['ma_mon_hoc'] as String? ?? map['courseCode'] as String?,
      credits: (map['so_tin_chi'] as num? ?? map['credits'] as num? ?? 3).toInt(),
      examDate: map['ngay_thi'] as String? ?? map['examDate'] as String? ?? '',
      sessionPeriod: map['ca_thi'] as String? ?? map['sessionPeriod'] as String? ?? '',
      examTime: map['gio_thi'] as String? ?? map['examTime'] as String? ?? '',
      roomCode: map['phong_thi'] as String? ?? map['roomCode'] as String? ?? '',
      teacherName: map['giang_vien_cham_thi'] as String? ?? map['teacherName'] as String? ?? '',
      teacherId: map['giang_vien_id'] as String? ?? map['teacherId'] as String?,
      createdAt: parsedDate,
    );
  }

  ExamSessionModel copyWith({
    String? id,
    String? examTermName,
    String? courseName,
    String? courseCode,
    int? credits,
    String? examDate,
    String? sessionPeriod,
    String? examTime,
    String? roomCode,
    String? teacherName,
    String? teacherId,
    DateTime? createdAt,
  }) {
    return ExamSessionModel(
      id: id ?? this.id,
      examTermName: examTermName ?? this.examTermName,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      credits: credits ?? this.credits,
      examDate: examDate ?? this.examDate,
      sessionPeriod: sessionPeriod ?? this.sessionPeriod,
      examTime: examTime ?? this.examTime,
      roomCode: roomCode ?? this.roomCode,
      teacherName: teacherName ?? this.teacherName,
      teacherId: teacherId ?? this.teacherId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Course item in curriculum database
class CourseCatalogItem {
  final String id;
  final String name;
  final String code;
  final int credits;
  final List<String> applicableCohorts;

  const CourseCatalogItem({
    required this.id,
    required this.name,
    required this.code,
    required this.credits,
    required this.applicableCohorts,
  });

  factory CourseCatalogItem.fromMap(Map<String, dynamic> map, [String? id]) {
    return CourseCatalogItem(
      id: id ?? map['id'] as String? ?? '',
      name: map['ten_mon'] as String? ?? map['name'] as String? ?? '',
      code: map['ma_mon'] as String? ?? map['code'] as String? ?? '',
      credits: (map['so_tin_chi'] as num? ?? map['credits'] as num? ?? 3).toInt(),
      applicableCohorts: (map['khoa_ap_dung'] as List<dynamic>? ?? map['applicableCohorts'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// Room item in facility catalogue
class RoomCatalogItem {
  final String code; // e.g. 131-A2
  final String building; // e.g. A2
  final int capacity;
  final bool isUnderMaintenance;

  const RoomCatalogItem({
    required this.code,
    required this.building,
    this.capacity = 50,
    this.isUnderMaintenance = false,
  });

  factory RoomCatalogItem.fromMap(Map<String, dynamic> map) {
    return RoomCatalogItem(
      code: map['ma_phong'] as String? ?? map['code'] as String? ?? '',
      building: map['toa_nha'] as String? ?? map['building'] as String? ?? '',
      capacity: (map['suc_chua'] as num? ?? map['capacity'] as num? ?? 50).toInt(),
      isUnderMaintenance: map['dang_bao_tri'] as bool? ?? map['isUnderMaintenance'] as bool? ?? false,
    );
  }
}

/// Teacher item in faculty registry
class TeacherRegistryItem {
  final String id; // e.g. GV001
  final String name; // e.g. TS. Lê Văn Lực
  final String email;
  final String department;
  final bool isActive;

  const TeacherRegistryItem({
    required this.id,
    required this.name,
    required this.email,
    this.department = 'KTPM',
    this.isActive = true,
  });

  factory TeacherRegistryItem.fromMap(Map<String, dynamic> map, [String? id]) {
    return TeacherRegistryItem(
      id: id ?? map['ma_giang_vien'] as String? ?? map['id'] as String? ?? '',
      name: map['ho_ten'] as String? ?? map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      department: map['bo_mon'] as String? ?? map['department'] as String? ?? 'KTPM',
      isActive: map['hoat_dong'] as bool? ?? map['isActive'] as bool? ?? true,
    );
  }
}

/// Exam term item
class ExamTermCatalogItem {
  final String name; // e.g. K65_Lich_Thi_HK2_GĐ1_NH_2025-2026
  final String cohort; // e.g. K65
  final DateTime startDate;
  final DateTime endDate;

  const ExamTermCatalogItem({
    required this.name,
    required this.cohort,
    required this.startDate,
    required this.endDate,
  });
}
