import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/exam_session_model.dart';
import '../../../../core/utils/exam_session_validator.dart';

final examSessionRepositoryProvider = Provider<ExamSessionRepository>((ref) {
  return ExamSessionRepository();
});

/// Repository for Exam Sessions, Curriculum Courses, Rooms, and Faculty Registry
class ExamSessionRepository {
  final FirebaseFirestore? _firestore;

  ExamSessionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (kIsWeb || !kDebugMode ? FirebaseFirestore.instance : null);

  // In-memory fallback and mock data for offline support and clean testing
  static final List<CourseCatalogItem> defaultCurriculumCourses = [
    const CourseCatalogItem(
      id: 'c1',
      name: 'Kiểm thử phần mềm',
      code: 'INT3134',
      credits: 3,
      applicableCohorts: ['K65', 'K64'],
    ),
    const CourseCatalogItem(
      id: 'c2',
      name: 'Lập trình thiết bị di động',
      code: 'INT3120',
      credits: 3,
      applicableCohorts: ['K65'],
    ),
    const CourseCatalogItem(
      id: 'c3',
      name: 'Cơ sở dữ liệu',
      code: 'INT2100',
      credits: 4,
      applicableCohorts: ['K65', 'K66'],
    ),
    const CourseCatalogItem(
      id: 'c4',
      name: 'Giải tích 1',
      code: 'MTH1101',
      credits: 3,
      applicableCohorts: ['K64', 'K63'],
    ),
    const CourseCatalogItem(
      id: 'c5',
      name: 'Đồ án tốt nghiệp',
      code: 'INT4900',
      credits: 5,
      applicableCohorts: ['K65'],
    ),
    const CourseCatalogItem(
      id: 'c6',
      name: 'Nhập môn lập trình',
      code: 'INT1001',
      credits: 2,
      applicableCohorts: ['K66'],
    ),
    const CourseCatalogItem(
      id: 'c7',
      name: 'Kỹ năng mềm',
      code: 'GEN1001',
      credits: 1,
      applicableCohorts: ['K65', 'K66'],
    ),
  ];

  static final List<RoomCatalogItem> defaultRooms = [
    const RoomCatalogItem(code: '131-A2', building: 'A2', capacity: 50, isUnderMaintenance: false),
    const RoomCatalogItem(code: '205-B5', building: 'B5', capacity: 45, isUnderMaintenance: false),
    const RoomCatalogItem(code: '302-A1', building: 'A1', capacity: 60, isUnderMaintenance: false),
    const RoomCatalogItem(code: '101-C1', building: 'C1', capacity: 40, isUnderMaintenance: false),
    const RoomCatalogItem(code: '404-B3', building: 'B3', capacity: 35, isUnderMaintenance: true), // Under maintenance
  ];

  static final List<TeacherRegistryItem> defaultTeachers = [
    const TeacherRegistryItem(
      id: 'GV001',
      name: 'TS. Lê Văn Lực',
      email: 'luc.lv@tlu.edu.vn',
      department: 'KTPM',
      isActive: true,
    ),
    const TeacherRegistryItem(
      id: 'GV002',
      name: 'ThS. Đỗ Đình An',
      email: 'an.dd@tlu.edu.vn',
      department: 'KTPM',
      isActive: true,
    ),
    const TeacherRegistryItem(
      id: 'GV003',
      name: 'TS. Nguyễn Văn A',
      email: 'a.nv@tlu.edu.vn',
      department: 'CNTT',
      isActive: true,
    ),
    const TeacherRegistryItem(
      id: 'GV004',
      name: 'ThS. Trần Thị B',
      email: 'b.tt@tlu.edu.vn',
      department: 'KHMT',
      isActive: true,
    ),
  ];

  static final List<ExamTermCatalogItem> defaultExamTerms = [
    ExamTermCatalogItem(
      name: 'K65_Lich_Thi_HK2_GĐ1_NH_2025-2026',
      cohort: 'K65',
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 11, 30),
    ),
    ExamTermCatalogItem(
      name: 'K65_Lich_Thi_HK1_GĐ1_NH_2026-2027',
      cohort: 'K65',
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 12, 31),
    ),
    ExamTermCatalogItem(
      name: 'K65_Lich_Thi_HK1_GĐ1_NH_2025-2026',
      cohort: 'K65',
      startDate: DateTime(2025, 11, 1),
      endDate: DateTime(2025, 12, 30),
    ),
  ];

  // Local storage cache for offline operation and synchronous testing
  final List<ExamSessionModel> _localSessions = [
    const ExamSessionModel(
      id: 'mock_session_1',
      examTermName: 'K65_Lich_Thi_HK2_GĐ1_NH_2025-2026',
      courseName: 'Kiểm thử phần mềm',
      courseCode: 'INT3134',
      credits: 3,
      examDate: '15/10/2026',
      sessionPeriod: '1-3',
      examTime: '08:00 - 10:00',
      roomCode: '131-A2',
      teacherName: 'TS. Lê Văn Lực',
      teacherId: 'GV001',
    ),
  ];

  /// Get list of all curriculum courses
  Future<List<CourseCatalogItem>> getCurriculumCourses() async {
    try {
      if (_firestore != null) {
        final snap = await _firestore.collection('courses').get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((d) => CourseCatalogItem.fromMap(d.data(), d.id))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting courses from firestore: $e');
    }
    return List.from(defaultCurriculumCourses);
  }

  /// Get list of all rooms in facility catalogue
  Future<List<RoomCatalogItem>> getRooms() async {
    try {
      if (_firestore != null) {
        final snap = await _firestore.collection('rooms').get();
        if (snap.docs.isNotEmpty) {
          return snap.docs.map((d) => RoomCatalogItem.fromMap(d.data())).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting rooms from firestore: $e');
    }
    return List.from(defaultRooms);
  }

  /// Get list of teachers from faculty registry
  Future<List<TeacherRegistryItem>> getTeachers() async {
    try {
      if (_firestore != null) {
        final snap = await _firestore.collection('teachers').get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((d) => TeacherRegistryItem.fromMap(d.data(), d.id))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting teachers from firestore: $e');
    }
    return List.from(defaultTeachers);
  }

  /// Get list of available exam terms
  Future<List<ExamTermCatalogItem>> getExamTerms() async {
    return List.from(defaultExamTerms);
  }

  /// Get all exam sessions
  Future<List<ExamSessionModel>> getExamSessions() async {
    try {
      if (_firestore != null) {
        final snap = await _firestore.collection('exam_sessions').get();
        if (snap.docs.isNotEmpty) {
          final sessions = snap.docs
              .map((doc) => ExamSessionModel.fromMap(doc.data(), doc.id))
              .toList();
          return sessions;
        }
      }
    } catch (e) {
      debugPrint('Error getting exam sessions from firestore: $e');
    }
    return List.from(_localSessions);
  }

  /// Check room schedule conflict asynchronously [27E3]
  Future<String?> checkRoomConflict({
    required String roomCode,
    required String examDate,
    required String examTime,
    String? currentSessionId,
  }) async {
    final allSessions = await getExamSessions();
    return ExamSessionValidator.validateRoomConflict(
      roomCode: roomCode,
      examDate: examDate,
      examTime: examTime,
      existingSessions: allSessions,
      currentSessionId: currentSessionId,
    );
  }

  /// Check teacher schedule conflict asynchronously [28E3]
  Future<String?> checkTeacherConflict({
    required String teacherIdentifier,
    required String examDate,
    required String examTime,
    String? currentSessionId,
  }) async {
    final allSessions = await getExamSessions();
    return ExamSessionValidator.validateTeacherConflict(
      teacherIdentifier: teacherIdentifier,
      examDate: examDate,
      examTime: examTime,
      existingSessions: allSessions,
      currentSessionId: currentSessionId,
    );
  }

  /// Save new exam session into Firestore collection 'exam_sessions'
  Future<ExamSessionModel> createExamSession(ExamSessionModel session) async {
    try {
      String generatedId = 'session_${DateTime.now().millisecondsSinceEpoch}';

      if (_firestore != null) {
        final docRef = await _firestore.collection('exam_sessions').add(session.toMap());
        generatedId = docRef.id;
      }

      final savedSession = session.copyWith(
        id: generatedId,
        createdAt: session.createdAt ?? DateTime.now(),
      );

      _localSessions.add(savedSession);
      return savedSession;
    } catch (e) {
      debugPrint('Error creating exam session in Firestore: $e');
      // Save locally as fallback
      final fallbackSession = session.copyWith(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
      );
      _localSessions.add(fallbackSession);
      return fallbackSession;
    }
  }

  /// Clear or reset local sessions (useful for tests)
  void resetLocalSessions() {
    _localSessions.clear();
    _localSessions.add(
      const ExamSessionModel(
        id: 'mock_session_1',
        examTermName: 'K65_Lich_Thi_HK2_GĐ1_NH_2025-2026',
        courseName: 'Kiểm thử phần mềm',
        courseCode: 'INT3134',
        credits: 3,
        examDate: '15/10/2026',
        sessionPeriod: '1-3',
        examTime: '08:00 - 10:00',
        roomCode: '131-A2',
        teacherName: 'TS. Lê Văn Lực',
        teacherId: 'GV001',
      ),
    );
  }
}
