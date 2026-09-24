class ClassModel {
  final String id;
  final String name;
  final String subjectCode;
  final String inviteCode;
  final String semester;
  final int groupCount;

  ClassModel({
    required this.id,
    required this.name,
    required this.subjectCode,
    required this.inviteCode,
    this.semester = 'HK1-2025',
    this.groupCount = 0,
  });

  ClassModel copyWith({
    String? id,
    String? name,
    String? subjectCode,
    String? inviteCode,
    String? semester,
    int? groupCount,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      subjectCode: subjectCode ?? this.subjectCode,
      inviteCode: inviteCode ?? this.inviteCode,
      semester: semester ?? this.semester,
      groupCount: groupCount ?? this.groupCount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'ten_lop': name,
      'ma_mon': subjectCode,
      'ma_moi': inviteCode,
      'hoc_ky': semester,
      'groupCount': groupCount,
    };
  }

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'] as String? ?? '',
      name: map['ten_lop'] as String? ?? 'Chưa có tên',
      subjectCode: map['ma_mon'] as String? ?? '',
      inviteCode: map['ma_moi'] as String? ?? '',
      semester: map['hoc_ky'] as String? ?? map['semester'] as String? ?? 'HK1-2025',
      groupCount: map['groupCount'] as int? ?? 0,
    );
  }
}
