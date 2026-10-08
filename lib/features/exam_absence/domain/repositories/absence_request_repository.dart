import '../models/absence_request_model.dart';
import '../models/exam_subject_option.dart';

abstract class AbsenceRequestRepository {
  /// Submit a new absence request
  Future<void> submitAbsenceRequest(AbsenceRequestModel request);

  /// Check if a pending absence request exists for this student and subject (20E4)
  Future<bool> hasPendingRequest({
    required String studentId,
    required String subjectId,
  });

  /// Get list of absence requests submitted by student
  Future<List<AbsenceRequestModel>> getStudentAbsenceRequests(String studentId);

  /// Real-time stream of absence requests for student
  Stream<List<AbsenceRequestModel>> streamStudentAbsenceRequests(String studentId);

  /// Get list of subjects/exams that the student can select
  Future<List<ExamSubjectOption>> getAvailableExamSubjects(String studentId);

  /// Get student profile info from Firestore
  Future<Map<String, dynamic>?> getStudentProfile(String studentId);
}
