import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/exam_session_model.dart';
import '../../data/repositories/exam_session_repository.dart';
import '../../../../core/utils/exam_session_validator.dart';

class ExamSessionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final List<ExamSessionModel> sessions;
  final List<CourseCatalogItem> courses;
  final List<RoomCatalogItem> rooms;
  final List<TeacherRegistryItem> teachers;
  final List<ExamTermCatalogItem> examTerms;

  const ExamSessionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.sessions = const [],
    this.courses = const [],
    this.rooms = const [],
    this.teachers = const [],
    this.examTerms = const [],
  });

  ExamSessionState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    List<ExamSessionModel>? sessions,
    List<CourseCatalogItem>? courses,
    List<RoomCatalogItem>? rooms,
    List<TeacherRegistryItem>? teachers,
    List<ExamTermCatalogItem>? examTerms,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ExamSessionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      sessions: sessions ?? this.sessions,
      courses: courses ?? this.courses,
      rooms: rooms ?? this.rooms,
      teachers: teachers ?? this.teachers,
      examTerms: examTerms ?? this.examTerms,
    );
  }
}

class ExamSessionNotifier extends Notifier<ExamSessionState> {
  ExamSessionRepository get _repository => ref.read(examSessionRepositoryProvider);

  @override
  ExamSessionState build() {
    Future.microtask(() => loadInitialData());
    return const ExamSessionState();
  }

  /// Load catalog data and existing sessions
  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final courses = await _repository.getCurriculumCourses();
      final rooms = await _repository.getRooms();
      final teachers = await _repository.getTeachers();
      final terms = await _repository.getExamTerms();
      final sessions = await _repository.getExamSessions();

      state = state.copyWith(
        isLoading: false,
        courses: courses,
        rooms: rooms,
        teachers: teachers,
        examTerms: terms,
        sessions: sessions,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Comprehensive validation check and creation of Exam Session
  Future<bool> createExamSession({
    required String examTermName,
    required String courseName,
    required int credits,
    required String examDate,
    required String sessionPeriod,
    required String examTime,
    required String roomCode,
    required String teacherName,
    String? teacherId,
    String? courseCode,
    DateTime? now, // For test mocking of current time
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      // 1. Synchronous Field-level Validations
      // Field 1: Tên đợt thi [21E1 - 21E4]
      final termErr = ExamSessionValidator.validateExamTermName(examTermName);
      if (termErr != null) {
        throw Exception(termErr);
      }

      // Field 2: Tên môn học [22E1]
      final courseErr = ExamSessionValidator.validateCourseName(courseName);
      if (courseErr != null) {
        throw Exception(courseErr);
      }

      // Field 3: Số tín chỉ [23E1 - 23E2]
      final creditsErr = ExamSessionValidator.validateCredits(credits.toString());
      if (creditsErr != null) {
        throw Exception(creditsErr);
      }

      // Field 4: Ngày thi [24E1 - 24E3]
      final dateErr = ExamSessionValidator.validateExamDate(examDate, now: now);
      if (dateErr != null) {
        throw Exception(dateErr);
      }

      // Field 5: Ca thi [25E1 - 25E4]
      final periodErr = ExamSessionValidator.validateSessionPeriod(sessionPeriod);
      if (periodErr != null) {
        throw Exception(periodErr);
      }

      // Field 6: Giờ thi & Compatibility [26E1 - 26E5]
      final timeErr = ExamSessionValidator.validateExamTime(
        examTime,
        sessionPeriod: sessionPeriod,
      );
      if (timeErr != null) {
        throw Exception(timeErr);
      }

      // Field 7: Phòng thi format [27E1 - 27E2]
      final roomErr = ExamSessionValidator.validateRoomCode(roomCode);
      if (roomErr != null) {
        throw Exception(roomErr);
      }

      // Field 8: Giảng viên [28E1]
      final teacherErr = ExamSessionValidator.validateTeacher(teacherName);
      if (teacherErr != null) {
        throw Exception(teacherErr);
      }

      // 2. Asynchronous / Data Catalogue Validations
      // Ensure catalog data is ready
      if (state.courses.isEmpty || state.rooms.isEmpty || state.teachers.isEmpty) {
        await loadInitialData();
      }

      // [22E2] System existence check for course
      CourseCatalogItem? matchedCourse;
      for (final c in state.courses) {
        if (c.name.trim().toLowerCase() == courseName.trim().toLowerCase() ||
            c.code.trim().toUpperCase() == (courseCode ?? '').trim().toUpperCase()) {
          matchedCourse = c;
          break;
        }
      }
      if (matchedCourse == null) {
        throw Exception("Môn học không tồn tại trong hệ thống đào tạo");
      }

      // [22E3] Curriculum batch matching (Cohort check)
      final cohortErr = ExamSessionValidator.validateCourseCohortMatching(
        examTermName: examTermName,
        courseApplicableCohorts: matchedCourse.applicableCohorts,
      );
      if (cohortErr != null) {
        throw Exception(cohortErr);
      }

      // [23E3] Curriculum credit sync check
      final creditSyncErr = ExamSessionValidator.validateCreditSync(
        enteredCredits: credits,
        standardCredits: matchedCourse.credits,
      );
      if (creditSyncErr != null) {
        throw Exception(creditSyncErr);
      }

      // [24E4] Exam term timeframe check
      ExamTermCatalogItem? matchedTerm;
      for (final t in state.examTerms) {
        if (t.name.trim() == examTermName.trim()) {
          matchedTerm = t;
          break;
        }
      }
      if (matchedTerm != null) {
        final termTimeframeErr = ExamSessionValidator.validateExamDate(
          examDate,
          now: now,
          termStartDate: matchedTerm.startDate,
          termEndDate: matchedTerm.endDate,
        );
        if (termTimeframeErr != null) {
          throw Exception(termTimeframeErr);
        }
      }

      // [27E2] Facility catalogue room check
      RoomCatalogItem? matchedRoom;
      for (final r in state.rooms) {
        if (r.code.trim().toUpperCase() == roomCode.trim().toUpperCase()) {
          matchedRoom = r;
          break;
        }
      }
      if (matchedRoom == null) {
        throw Exception("Phòng thi không tồn tại trong danh mục cơ sở vật chất của trường");
      }

      // [27E4] Maintenance status check
      if (matchedRoom.isUnderMaintenance) {
        throw Exception("Phòng thi hiện đang bảo trì, không thể xếp lịch");
      }

      // [27E3] Room schedule conflict check
      final roomConflictErr = await _repository.checkRoomConflict(
        roomCode: roomCode,
        examDate: examDate,
        examTime: examTime,
      );
      if (roomConflictErr != null) {
        throw Exception(roomConflictErr);
      }

      // [28E2] Staff registry existence check
      TeacherRegistryItem? matchedTeacher;
      for (final t in state.teachers) {
        if (t.name.trim().toLowerCase() == teacherName.trim().toLowerCase() ||
            t.id.trim().toUpperCase() == (teacherId ?? teacherName).trim().toUpperCase()) {
          matchedTeacher = t;
          break;
        }
      }
      if (matchedTeacher == null || !matchedTeacher.isActive) {
        throw Exception("Giáo viên không tồn tại trong hệ thống cán bộ của trường");
      }

      // [28E3] Teacher schedule conflict check
      final teacherConflictErr = await _repository.checkTeacherConflict(
        teacherIdentifier: matchedTeacher.id,
        examDate: examDate,
        examTime: examTime,
      );
      if (teacherConflictErr != null) {
        throw Exception(teacherConflictErr);
      }

      // 3. Save to Repository / Firestore
      final newSession = ExamSessionModel(
        examTermName: examTermName.trim(),
        courseName: matchedCourse.name,
        courseCode: matchedCourse.code,
        credits: credits,
        examDate: examDate.trim(),
        sessionPeriod: sessionPeriod.trim(),
        examTime: examTime.trim(),
        roomCode: matchedRoom.code,
        teacherName: matchedTeacher.name,
        teacherId: matchedTeacher.id,
        createdAt: DateTime.now(),
      );

      final created = await _repository.createExamSession(newSession);

      state = state.copyWith(
        isLoading: false,
        sessions: [...state.sessions, created],
        successMessage: "Tạo ca thi thành công!",
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final examSessionNotifierProvider =
    NotifierProvider<ExamSessionNotifier, ExamSessionState>(() {
  return ExamSessionNotifier();
});
