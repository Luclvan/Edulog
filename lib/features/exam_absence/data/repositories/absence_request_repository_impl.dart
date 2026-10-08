import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/absence_request_model.dart';
import '../../domain/repositories/absence_request_repository.dart';

/// Implementation of AbsenceRequestRepository using Firebase Firestore
class AbsenceRequestRepositoryImpl implements AbsenceRequestRepository {
  final FirebaseFirestore? _firestore;

  AbsenceRequestRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (kIsWeb || !kDebugMode ? FirebaseFirestore.instance : null);

  // In-memory fallback dataset for exam subjects
  static final List<ExamSubjectItem> defaultExamSubjects = [
    ExamSubjectItem(
      subjectId: 'INT3134',
      subjectName: 'Kiểm thử phần mềm',
      examShiftId: 'SHIFT_01',
      examShiftName: 'Ca 2 (09:30 - 11:30)',
      examTime: DateTime.now().add(const Duration(days: 3)),
      examEndTime: DateTime.now().add(const Duration(days: 3, hours: 2)),
      isRegistered: true,
    ),
    ExamSubjectItem(
      subjectId: 'INT3120',
      subjectName: 'Lập trình thiết bị di động',
      examShiftId: 'SHIFT_02',
      examShiftName: 'Ca 1 (07:00 - 09:00)',
      examTime: DateTime.now().add(const Duration(days: 5)),
      examEndTime: DateTime.now().add(const Duration(days: 5, hours: 2)),
      isRegistered: true,
    ),
    ExamSubjectItem(
      subjectId: 'INT3110',
      subjectName: 'Kiến trúc và Thiết kế phần mềm',
      examShiftId: 'SHIFT_03',
      examShiftName: 'Ca 3 (13:30 - 15:30)',
      examTime: DateTime.now().subtract(const Duration(hours: 12)), // Within 48h deadline
      examEndTime: DateTime.now().subtract(const Duration(hours: 10)),
      isRegistered: true,
    ),
    ExamSubjectItem(
      subjectId: 'INT2100',
      subjectName: 'Cơ sở dữ liệu',
      examShiftId: 'SHIFT_04',
      examShiftName: 'Ca 1 (07:00 - 09:00)',
      examTime: DateTime.now().subtract(const Duration(days: 5)), // Expired deadline (>48h)
      examEndTime: DateTime.now().subtract(const Duration(days: 5, hours: -2)),
      isRegistered: true,
    ),
    ExamSubjectItem(
      subjectId: 'INT4001',
      subjectName: 'Trí tuệ nhân tạo',
      examShiftId: 'SHIFT_05',
      examShiftName: 'Ca 4 (15:45 - 17:45)',
      examTime: DateTime.now().add(const Duration(days: 2)),
      examEndTime: DateTime.now().add(const Duration(days: 2, hours: 2)),
      isRegistered: false, // [20E2] Not in roster
    ),
  ];

  // In-memory cache for absence requests
  final List<AbsenceRequestModel> _localRequests = [
    AbsenceRequestModel(
      id: 'mock_req_pending_1',
      studentId: '2351170568',
      studentName: 'Nguyễn Thị Cẩm Ly',
      phone: '0912345678',
      email: '2351170568@e.tlu.edu.vn',
      subjectId: 'INT3900',
      subjectName: 'Đồ án chuyên ngành',
      examShiftId: 'SHIFT_06',
      examTime: DateTime.now().add(const Duration(days: 4)),
      reason: 'Bị sốt xuất huyết phải nhập viện điều trị theo chỉ định bác sĩ',
      proofUrl: 'https://drive.google.com/file/d/1A2B3C4D5E6F7G8H9I0/view',
      status: AbsenceRequestStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Future<List<ExamSubjectItem>> getStudentExamSubjects(String studentId) async {
    try {
      if (_firestore != null) {
        final querySnapshot = await _firestore
            .collection('classes')
            .where('students', arrayContains: studentId)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final subjects = <ExamSubjectItem>[];
          for (final doc in querySnapshot.docs) {
            final data = doc.data();
            subjects.add(ExamSubjectItem.fromMap(data));
          }
          return subjects;
        }
      }
    } catch (e) {
      debugPrint('Firestore fetch exam subjects failed, using fallback: $e');
    }
    return defaultExamSubjects;
  }

  @override
  Future<bool> hasPendingAbsenceRequest({
    required String studentId,
    required String subjectId,
  }) async {
    try {
      if (_firestore != null) {
        final querySnapshot = await _firestore
            .collection('absence_requests')
            .where('studentId', isEqualTo: studentId)
            .where('subjectId', isEqualTo: subjectId)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('Firestore check pending absence request error: $e');
    }

    // Fallback in-memory check
    return _localRequests.any(
      (req) =>
          req.studentId == studentId &&
          req.subjectId == subjectId &&
          req.status == AbsenceRequestStatus.pending,
    );
  }

  @override
  Future<void> submitAbsenceRequest(AbsenceRequestModel request) async {
    // Check pending duplicate
    final isDuplicate = await hasPendingAbsenceRequest(
      studentId: request.studentId,
      subjectId: request.subjectId,
    );

    if (isDuplicate) {
      throw Exception('Bạn đã gửi đơn xin vắng thi cho môn này và đang chờ duyệt');
    }

    try {
      if (_firestore != null) {
        final docRef = await _firestore.collection('absence_requests').add(request.toMap());
        final newReq = request.copyWith(id: docRef.id);
        _localRequests.insert(0, newReq);
        return;
      }
    } catch (e) {
      debugPrint('Firestore write absence request error: $e');
    }

    // Fallback in-memory save
    final generatedId = 'req_${DateTime.now().millisecondsSinceEpoch}';
    _localRequests.insert(0, request.copyWith(id: generatedId));
  }

  @override
  Future<List<AbsenceRequestModel>> getStudentAbsenceRequests(String studentId) async {
    try {
      if (_firestore != null) {
        final querySnapshot = await _firestore
            .collection('absence_requests')
            .where('studentId', isEqualTo: studentId)
            .orderBy('createdAt', descending: true)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs.map((doc) => AbsenceRequestModel.fromMap(doc.data(), doc.id)).toList();
        }
      }
    } catch (e) {
      debugPrint('Firestore fetch absence requests error: $e');
    }

    return _localRequests.where((req) => req.studentId == studentId).toList();
  }
}
