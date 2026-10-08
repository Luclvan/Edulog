class ExamSubjectOption {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String examShiftId;
  final String examShiftName;
  final DateTime examTime;
  final bool isStudentEnrolled;
  final String? room;

  const ExamSubjectOption({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.examShiftId,
    required this.examShiftName,
    required this.examTime,
    required this.isStudentEnrolled,
    this.room,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExamSubjectOption &&
        other.subjectId == subjectId &&
        other.examShiftId == examShiftId;
  }

  @override
  int get hashCode => subjectId.hashCode ^ examShiftId.hashCode;
}
