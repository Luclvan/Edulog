import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/absence_request_validator.dart';
import '../../data/repositories/absence_request_repository_impl.dart';
import '../../domain/models/absence_request_model.dart';
import '../../domain/repositories/absence_request_repository.dart';

final absenceRequestRepositoryProvider = Provider<AbsenceRequestRepository>((ref) {
  return AbsenceRequestRepositoryImpl();
});

/// State for Exam Absence Request module
class AbsenceRequestState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final String currentStudentName;
  final String currentStudentId;
  final String currentStudentEmail;
  final List<ExamSubjectItem> availableSubjects;
  final List<AbsenceRequestModel> requests;

  const AbsenceRequestState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.currentStudentName = 'Nguyễn Thị Cẩm Ly',
    this.currentStudentId = '2351170568',
    this.currentStudentEmail = '2351170568@e.tlu.edu.vn',
    this.availableSubjects = const [],
    this.requests = const [],
  });

  AbsenceRequestState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    String? currentStudentName,
    String? currentStudentId,
    String? currentStudentEmail,
    List<ExamSubjectItem>? availableSubjects,
    List<AbsenceRequestModel>? requests,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AbsenceRequestState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      currentStudentName: currentStudentName ?? this.currentStudentName,
      currentStudentId: currentStudentId ?? this.currentStudentId,
      currentStudentEmail: currentStudentEmail ?? this.currentStudentEmail,
      availableSubjects: availableSubjects ?? this.availableSubjects,
      requests: requests ?? this.requests,
    );
  }
}

/// Controller / Notifier managing Exam Absence Request state and operations
class AbsenceRequestNotifier extends Notifier<AbsenceRequestState> {
  AbsenceRequestRepository get _repository => ref.read(absenceRequestRepositoryProvider);

  @override
  AbsenceRequestState build() {
    Future.microtask(() => loadInitialData());
    return const AbsenceRequestState();
  }

  /// Load current student info, subjects, and previous requests
  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      String studentName = 'Nguyễn Thị Cẩm Ly';
      String studentId = '2351170568';
      String studentEmail = '2351170568@e.tlu.edu.vn';

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          if (user.displayName != null && user.displayName!.isNotEmpty) {
            studentName = user.displayName!;
          }
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
                if (data['name'] != null && (data['name'] as String).isNotEmpty) {
                  studentName = data['name'];
                }
                if (data['studentId'] != null && (data['studentId'] as String).isNotEmpty) {
                  studentId = data['studentId'];
                } else if (data['student_id'] != null && (data['student_id'] as String).isNotEmpty) {
                  studentId = data['student_id'];
                }
              }
            }
          } catch (_) {}
        }
      } catch (_) {
        // Ignored when running tests or without Firebase
      }

      final subjects = await _repository.getStudentExamSubjects(studentId);
      final requests = await _repository.getStudentAbsenceRequests(studentId);

      state = state.copyWith(
        isLoading: false,
        currentStudentName: studentName,
        currentStudentId: studentId,
        currentStudentEmail: studentEmail,
        availableSubjects: subjects,
        requests: requests,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Submit and validate an Exam Absence Request
  Future<bool> submitAbsenceRequest({
    required String studentName,
    required String phone,
    required String email,
    required ExamSubjectItem? selectedSubject,
    required String reason,
    required String proofUrl,
    String? forcedAccountName,
    DateTime? now,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final effectiveAccountName = forcedAccountName ?? state.currentStudentName;

      // 1. Validation Field 1: Họ và tên [15E1 - 15E4]
      final nameErr = AbsenceRequestValidator.validateFullName(
        studentName,
        accountFullName: effectiveAccountName,
      );
      if (nameErr != null) {
        throw Exception(nameErr);
      }

      // 2. Validation Field 2: Số điện thoại [16E1 - 16E4]
      final phoneErr = AbsenceRequestValidator.validatePhone(phone);
      if (phoneErr != null) {
        throw Exception(phoneErr);
      }

      // 3. Validation Field 3: Email [17E1 - 17E4]
      final emailErr = AbsenceRequestValidator.validateEmail(email);
      if (emailErr != null) {
        throw Exception(emailErr);
      }

      // 4. Validation Field 6: Môn học & Ca thi [20E1 - 20E3]
      final subjectErr = AbsenceRequestValidator.validateSubjectSelection(
        selectedSubject,
        now: now,
      );
      if (subjectErr != null) {
        throw Exception(subjectErr);
      }

      // 5. Validation Field 4: Lý do vắng thi [18E1 - 18E3]
      final reasonErr = AbsenceRequestValidator.validateReason(reason);
      if (reasonErr != null) {
        throw Exception(reasonErr);
      }

      // 6. Validation Field 5: Tài liệu minh chứng [19E1 - 19E4]
      final proofErr = AbsenceRequestValidator.validateProofUrl(proofUrl);
      if (proofErr != null) {
        throw Exception(proofErr);
      }

      // 7. Check Duplicate Pending Request [20E4]
      final isDuplicate = await _repository.hasPendingAbsenceRequest(
        studentId: state.currentStudentId,
        subjectId: selectedSubject!.subjectId,
      );
      final duplicateErr = AbsenceRequestValidator.validateDuplicateRequest(isDuplicate);
      if (duplicateErr != null) {
        throw Exception(duplicateErr);
      }

      // 8. Construct Model and Submit
      final requestModel = AbsenceRequestModel(
        studentId: state.currentStudentId,
        studentName: studentName.trim(),
        phone: phone.trim(),
        email: email.trim(),
        subjectId: selectedSubject.subjectId,
        subjectName: selectedSubject.subjectName,
        examShiftId: selectedSubject.examShiftId,
        examTime: selectedSubject.examTime,
        reason: reason.trim(),
        proofUrl: proofUrl.trim(),
        status: AbsenceRequestStatus.pending,
        createdAt: now ?? DateTime.now(),
      );

      await _repository.submitAbsenceRequest(requestModel);

      final updatedList = await _repository.getStudentAbsenceRequests(state.currentStudentId);

      state = state.copyWith(
        isLoading: false,
        requests: updatedList,
        successMessage: 'Gửi đơn xin vắng / hoãn thi thành công!',
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

final absenceRequestControllerProvider =
    NotifierProvider<AbsenceRequestNotifier, AbsenceRequestState>(() {
  return AbsenceRequestNotifier();
});
