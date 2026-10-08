import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/absence_request_model.dart';
import '../../domain/models/exam_subject_option.dart';
import '../../domain/repositories/absence_request_repository.dart';
import '../../data/repositories/absence_request_repository_impl.dart';

/// Repository Provider
final absenceRequestRepositoryProvider = Provider<AbsenceRequestRepository>((ref) {
  return AbsenceRequestRepositoryImpl();
});

/// Stream of student's absence requests
final studentAbsenceRequestsStreamProvider =
    StreamProvider.autoDispose.family<List<AbsenceRequestModel>, String>((ref, studentId) {
  final repo = ref.watch(absenceRequestRepositoryProvider);
  return repo.streamStudentAbsenceRequests(studentId);
});

/// Available exam subjects for student
final availableExamSubjectsProvider =
    FutureProvider.autoDispose.family<List<ExamSubjectOption>, String>((ref, studentId) async {
  final repo = ref.watch(absenceRequestRepositoryProvider);
  return repo.getAvailableExamSubjects(studentId);
});

/// Student Profile Provider
final studentProfileProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, studentId) async {
  final repo = ref.watch(absenceRequestRepositoryProvider);
  return repo.getStudentProfile(studentId);
});

/// Form Submission State
enum AbsenceSubmissionStatus { initial, loading, success, error }

class AbsenceRequestState {
  final AbsenceSubmissionStatus status;
  final String? errorMessage;
  final String? successMessage;

  const AbsenceRequestState({
    this.status = AbsenceSubmissionStatus.initial,
    this.errorMessage,
    this.successMessage,
  });

  bool get isLoading => status == AbsenceSubmissionStatus.loading;
  bool get isSuccess => status == AbsenceSubmissionStatus.success;
  bool get isError => status == AbsenceSubmissionStatus.error;

  AbsenceRequestState copyWith({
    AbsenceSubmissionStatus? status,
    String? errorMessage,
    String? successMessage,
  }) {
    return AbsenceRequestState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

/// Absence Request Form Controller using Riverpod Notifier
class AbsenceRequestController extends Notifier<AbsenceRequestState> {
  @override
  AbsenceRequestState build() {
    return const AbsenceRequestState();
  }

  Future<bool> submitRequest(AbsenceRequestModel request) async {
    state = state.copyWith(
      status: AbsenceSubmissionStatus.loading,
      errorMessage: null,
    );

    try {
      final repository = ref.read(absenceRequestRepositoryProvider);
      await repository.submitAbsenceRequest(request);
      state = state.copyWith(
        status: AbsenceSubmissionStatus.success,
        successMessage:
            'Đơn xin vắng thi đã được gửi thành công và đang chờ xét duyệt!',
      );
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(
        status: AbsenceSubmissionStatus.error,
        errorMessage: errorMsg,
      );
      return false;
    }
  }

  void resetState() {
    state = const AbsenceRequestState();
  }
}

/// Controller Provider
final absenceRequestControllerProvider =
    NotifierProvider<AbsenceRequestController, AbsenceRequestState>(() {
  return AbsenceRequestController();
});
