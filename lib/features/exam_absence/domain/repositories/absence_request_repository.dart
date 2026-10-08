import '../models/absence_request_model.dart';

/// Abstract repository interface for Exam Absence Request feature
abstract class AbsenceRequestRepository {
  /// Fetches the list of subjects/exam sessions available for the student
  Future<List<ExamSubjectItem>> getStudentExamSubjects(String studentId);

  /// Checks if there is already a pending absence request for the subject
  Future<bool> hasPendingAbsenceRequest({
    required String studentId,
    required String subjectId,
  });

  /// Submits a new absence request to Firestore
  Future<void> submitAbsenceRequest(AbsenceRequestModel request);

  /// Retrieves list of submitted absence requests for the student
  Future<List<AbsenceRequestModel>> getStudentAbsenceRequests(String studentId);
}
