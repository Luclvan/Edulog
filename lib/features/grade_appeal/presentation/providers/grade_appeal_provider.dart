import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/grade_appeal_model.dart';
import '../../data/repositories/grade_appeal_repository.dart';
import '../../../../core/utils/grade_appeal_validator.dart';

class GradeAppealState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final String currentStudentName;
  final String currentStudentId;
  final String currentStudentEmail;
  final List<AppealSubjectItem> availableSubjects;
  final List<GradeAppealModel> appeals;

  const GradeAppealState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.currentStudentName = 'Nguyễn Thị Cẩm Ly',
    this.currentStudentId = '2351170568',
    this.currentStudentEmail = '2351170568@e.tlu.edu.vn',
    this.availableSubjects = const [],
    this.appeals = const [],
  });

  GradeAppealState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    String? currentStudentName,
    String? currentStudentId,
    String? currentStudentEmail,
    List<AppealSubjectItem>? availableSubjects,
    List<GradeAppealModel>? appeals,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return GradeAppealState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      currentStudentName: currentStudentName ?? this.currentStudentName,
      currentStudentId: currentStudentId ?? this.currentStudentId,
      currentStudentEmail: currentStudentEmail ?? this.currentStudentEmail,
      availableSubjects: availableSubjects ?? this.availableSubjects,
      appeals: appeals ?? this.appeals,
    );
  }
}

class GradeAppealNotifier extends Notifier<GradeAppealState> {
  GradeAppealRepository get _repository => ref.read(gradeAppealRepositoryProvider);

  @override
  GradeAppealState build() {
    Future.microtask(() => loadInitialData());
    return const GradeAppealState();
  }

  /// Load current student info and subjects
  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      String studentName = 'Nguyễn Thị Cẩm Ly';
      String studentId = '2351170568';
      String studentEmail = '2351170568@e.tlu.edu.vn';

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          if (user.email != null && user.email!.isNotEmpty) {
            studentEmail = user.email!;
            final prefix = studentEmail.split('@').first;
            if (RegExp(r'^\d{10}$').hasMatch(prefix)) {
              studentId = prefix;
            }
          }

          try {
            final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
            if (doc.exists) {
              final data = doc.data();
              if (data != null) {
                if (data['name'] != null) studentName = data['name'];
                if (data['student_id'] != null) studentId = data['student_id'];
                if (data['studentId'] != null) studentId = data['studentId'];
              }
            }
          } catch (_) {}
        }
      } catch (_) {
        // Firebase not initialized in tests
      }

      final subjects = await _repository.getStudentSubjects(studentId);
      final appeals = await _repository.getStudentAppeals(studentId);

      state = state.copyWith(
        isLoading: false,
        currentStudentName: studentName,
        currentStudentId: studentId,
        currentStudentEmail: studentEmail,
        availableSubjects: subjects,
        appeals: appeals,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Submits and validates a Grade Appeal
  Future<bool> submitAppeal({
    required String studentName,
    required String studentId,
    required String studentEmail,
    required double currentScore,
    required String examDate,
    required String subjectName,
    String? subjectCode,
    required String examShift,
    String? reason,
    DateTime? now, // For deterministic date/time testing
    String? forcedAccountName, // For testing cross-validation [5E6]
    String? forcedAccountId,   // For testing cross-validation [6E4]
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final effectiveAccountName = forcedAccountName ?? state.currentStudentName;
      final effectiveAccountId = forcedAccountId ?? state.currentStudentId;

      // 1. Synchronous Validations
      // Field 1: Họ và tên [5E1 - 5E5] & [5E6] Account Match
      final nameErr = GradeAppealValidator.validateFullName(
        studentName,
        accountFullName: effectiveAccountName,
      );
      if (nameErr != null) {
        throw Exception(nameErr);
      }

      // Field 2: Mã sinh viên [6E1 - 6E3, 6E5] & [6E4] Account Match
      final idErr = GradeAppealValidator.validateStudentId(
        studentId,
        accountStudentId: effectiveAccountId,
      );
      if (idErr != null) {
        throw Exception(idErr);
      }

      // Field 3: Email sinh viên [7E1 - 7E4]
      final emailErr = GradeAppealValidator.validateEmail(studentEmail);
      if (emailErr != null) {
        throw Exception(emailErr);
      }

      // Field 4: Điểm thi hiện tại [8E1 - 8E4]
      final scoreErr = GradeAppealValidator.validateCurrentScore(currentScore.toString());
      if (scoreErr != null) {
        throw Exception(scoreErr);
      }

      // Field 5: Ngày thi [9E1 - 9E3]
      final dateErr = GradeAppealValidator.validateExamDate(examDate, now: now);
      if (dateErr != null) {
        throw Exception(dateErr);
      }

      // Field 6: Môn thi [10E1]
      final subjectErr = GradeAppealValidator.validateSubjectName(subjectName);
      if (subjectErr != null) {
        throw Exception(subjectErr);
      }

      // Field 7: Ca thi [11E1 - 11E2]
      final shiftErr = GradeAppealValidator.validateExamShift(examShift);
      if (shiftErr != null) {
        throw Exception(shiftErr);
      }

      // 2. Asynchronous & Data Catalogue Validations
      if (state.availableSubjects.isEmpty) {
        await loadInitialData();
      }

      // [10E2] System existence check
      AppealSubjectItem? matchedSubject;
      for (final s in state.availableSubjects) {
        if (s.name.trim().toLowerCase() == subjectName.trim().toLowerCase() ||
            s.code.trim().toUpperCase() == (subjectCode ?? '').trim().toUpperCase()) {
          matchedSubject = s;
          break;
        }
      }

      if (matchedSubject == null || !matchedSubject.existsInCurriculum) {
        throw Exception("Môn học không tồn tại trong hệ thống đào tạo");
      }

      // [10E3] Term availability check: Course must have had an exam organized this term
      if (!matchedSubject.hasExamOrganized) {
        throw Exception("Môn học không được tổ chức thi trong đợt thi này");
      }

      // [10E4] Enrollment check: Student must be in exam list
      if (!matchedSubject.isRegistered) {
        throw Exception("Bạn không có tên trong danh sách dự thi môn học này");
      }

      // [10E6] Published score check: Course must have officially published scores
      if (matchedSubject.publishedScore == null) {
        throw Exception("Môn học chưa công bố điểm thi, chưa thể tạo đơn phúc khảo");
      }

      // [8E5] Score match check
      final scoreMatchErr = GradeAppealValidator.validateSystemScoreMatch(
        enteredScore: currentScore,
        recordedScore: matchedSubject.publishedScore,
      );
      if (scoreMatchErr != null) {
        throw Exception(scoreMatchErr);
      }

      // [9E4] Schedule sync: Exam date must match actual exam schedule
      final scheduleErr = GradeAppealValidator.validateScheduleSync(
        enteredDate: examDate,
        actualExamDate: matchedSubject.actualExamDate,
      );
      if (scheduleErr != null) {
        throw Exception(scheduleErr);
      }

      // [9E5] Deadline expiration check: Submission must not exceed 15 days from exam date
      final deadlineErr = GradeAppealValidator.validateAppealDeadline(
        examDateStr: examDate,
        now: now,
      );
      if (deadlineErr != null) {
        throw Exception(deadlineErr);
      }

      // [11E3] Roster assignment check: Shift must match assigned shift
      final rosterErr = GradeAppealValidator.validateRosterAssignment(
        enteredShift: examShift,
        assignedShift: matchedSubject.assignedShift,
      );
      if (rosterErr != null) {
        throw Exception(rosterErr);
      }

      // [10E5] Pending duplicate check: No pending appeal for same subject
      final isPending = await _repository.hasPendingAppeal(studentId, matchedSubject.name);
      if (isPending) {
        throw Exception("Bạn đã gửi đơn phúc khảo cho môn học này và đang chờ xử lý, không thể gửi trùng lặp");
      }

      // 3. Create Appeal Model & Commit
      final appealModel = GradeAppealModel(
        studentName: studentName.trim(),
        studentId: studentId.trim(),
        studentEmail: studentEmail.trim(),
        currentScore: currentScore,
        examDate: examDate.trim(),
        subjectName: matchedSubject.name,
        subjectCode: matchedSubject.code,
        examShift: examShift.trim(),
        reason: reason?.trim(),
        status: GradeAppealStatus.pending,
        createdAt: DateTime.now(),
      );

      final created = await _repository.createAppeal(appealModel);

      state = state.copyWith(
        isLoading: false,
        appeals: [...state.appeals, created],
        successMessage: "Tạo đơn phúc khảo thành công!",
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

final gradeAppealNotifierProvider =
    NotifierProvider<GradeAppealNotifier, GradeAppealState>(() {
  return GradeAppealNotifier();
});
