import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/grade_appeal_model.dart';

final gradeAppealRepositoryProvider = Provider<GradeAppealRepository>((ref) {
  return GradeAppealRepository();
});

/// Repository for handling Grade Appeals (Đơn phúc khảo) and Student Exam Data
class GradeAppealRepository {
  final FirebaseFirestore? _firestore;

  GradeAppealRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (kIsWeb || !kDebugMode ? FirebaseFirestore.instance : null);

  // In-memory mock subjects catalogue for student
  static final List<AppealSubjectItem> defaultStudentSubjects = [
    const AppealSubjectItem(
      code: 'INT3134',
      name: 'Kiểm thử phần mềm',
      actualExamDate: '01/10/2026',
      assignedShift: 'Ca 2',
      publishedScore: 6.5,
      isRegistered: true,
      hasExamOrganized: true,
      existsInCurriculum: true,
    ),
    const AppealSubjectItem(
      code: 'INT3120',
      name: 'Lập trình thiết bị di động',
      actualExamDate: '25/09/2026',
      assignedShift: 'Ca 1',
      publishedScore: 7.0,
      isRegistered: true,
      hasExamOrganized: true,
      existsInCurriculum: true,
    ),
    const AppealSubjectItem(
      code: 'INT2100',
      name: 'Cơ sở dữ liệu',
      actualExamDate: '04/10/2026',
      assignedShift: 'Ca 3',
      publishedScore: null, // [10E6] Chưa công bố điểm
      isRegistered: true,
      hasExamOrganized: true,
      existsInCurriculum: true,
    ),
    const AppealSubjectItem(
      code: 'INT3900',
      name: 'Đồ án chuyên ngành',
      actualExamDate: '28/09/2026',
      assignedShift: 'Ca 1',
      publishedScore: 5.5,
      isRegistered: true,
      hasExamOrganized: true,
      existsInCurriculum: true,
    ),
    const AppealSubjectItem(
      code: 'MTH2001',
      name: 'Toán rời rạc',
      actualExamDate: '10/09/2026', // [9E5] Quá 15 ngày
      assignedShift: 'Ca 1',
      publishedScore: 5.0,
      isRegistered: true,
      hasExamOrganized: true,
      existsInCurriculum: true,
    ),
    const AppealSubjectItem(
      code: 'INT4001',
      name: 'Trí tuệ nhân tạo',
      actualExamDate: '01/10/2026',
      assignedShift: 'Ca 2',
      publishedScore: null,
      isRegistered: false,
      hasExamOrganized: false, // [10E3] Không tổ chức thi
      existsInCurriculum: true,
    ),
    const AppealSubjectItem(
      code: 'INT3300',
      name: 'An toàn thông tin',
      actualExamDate: '02/10/2026',
      assignedShift: 'Ca 4',
      publishedScore: null,
      isRegistered: false, // [10E4] Không có tên trong danh sách
      hasExamOrganized: true,
      existsInCurriculum: true,
    ),
  ];

  // Local storage cache for offline operation and synchronous testing
  final List<GradeAppealModel> _localAppeals = [
    const GradeAppealModel(
      id: 'mock_appeal_pending',
      studentName: 'Nguyễn Thị Cẩm Ly',
      studentId: '2351170568',
      studentEmail: '2351170568@e.tlu.edu.vn',
      currentScore: 5.5,
      examDate: '28/09/2026',
      subjectName: 'Đồ án chuyên ngành',
      subjectCode: 'INT3900',
      examShift: 'Ca 1',
      reason: 'Xin xem lại phần vấn đáp',
      status: GradeAppealStatus.pending,
    ),
  ];

  /// Get list of subjects for student
  Future<List<AppealSubjectItem>> getStudentSubjects(String studentId) async {
    try {
      if (_firestore != null) {
        final snap = await _firestore
            .collection('exam_rosters')
            .where('ma_sinh_vien', isEqualTo: studentId)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((d) => AppealSubjectItem.fromMap(d.data()))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting student subjects from firestore: $e');
    }
    return List.from(defaultStudentSubjects);
  }

  /// Get all appeals for student
  Future<List<GradeAppealModel>> getStudentAppeals(String studentId) async {
    try {
      if (_firestore != null) {
        final snap = await _firestore
            .collection('grade_appeals')
            .where('ma_sinh_vien', isEqualTo: studentId)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((d) => GradeAppealModel.fromMap(d.data(), d.id))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting grade appeals from firestore: $e');
    }
    return _localAppeals.where((a) => a.studentId == studentId).toList();
  }

  /// Check if student has a pending appeal for this subject [10E5]
  Future<bool> hasPendingAppeal(String studentId, String subjectName) async {
    try {
      if (_firestore != null) {
        final snap = await _firestore
            .collection('grade_appeals')
            .where('ma_sinh_vien', isEqualTo: studentId)
            .where('mon_thi', isEqualTo: subjectName)
            .where('trang_thai', isEqualTo: GradeAppealStatus.pending.name)
            .get();
        if (snap.docs.isNotEmpty) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error checking pending appeal from firestore: $e');
    }

    return _localAppeals.any((a) =>
        a.studentId == studentId &&
        a.subjectName.toLowerCase() == subjectName.toLowerCase() &&
        a.status == GradeAppealStatus.pending);
  }

  /// Create new Grade Appeal in Firestore collection 'grade_appeals'
  Future<GradeAppealModel> createAppeal(GradeAppealModel appeal) async {
    try {
      String generatedId = 'appeal_${DateTime.now().millisecondsSinceEpoch}';

      if (_firestore != null) {
        final docRef = await _firestore.collection('grade_appeals').add(appeal.toMap());
        generatedId = docRef.id;
      }

      final saved = appeal.copyWith(
        id: generatedId,
        createdAt: appeal.createdAt ?? DateTime.now(),
      );
      _localAppeals.add(saved);
      return saved;
    } catch (e) {
      debugPrint('Error creating grade appeal in Firestore: $e');
      final fallback = appeal.copyWith(
        id: 'local_appeal_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
      );
      _localAppeals.add(fallback);
      return fallback;
    }
  }

  /// Reset local appeals (for testing)
  void resetLocalAppeals() {
    _localAppeals.clear();
    _localAppeals.add(
      const GradeAppealModel(
        id: 'mock_appeal_pending',
        studentName: 'Nguyễn Thị Cẩm Ly',
        studentId: '2351170568',
        studentEmail: '2351170568@e.tlu.edu.vn',
        currentScore: 5.5,
        examDate: '28/09/2026',
        subjectName: 'Đồ án chuyên ngành',
        subjectCode: 'INT3900',
        examShift: 'Ca 1',
        reason: 'Xin xem lại phần vấn đáp',
        status: GradeAppealStatus.pending,
      ),
    );
  }
}
