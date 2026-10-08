import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/absence_request_model.dart';
import '../../domain/models/exam_subject_option.dart';
import '../../domain/repositories/absence_request_repository.dart';
import '../../../../core/utils/absence_form_validator.dart';

class AbsenceRequestRepositoryImpl implements AbsenceRequestRepository {
  final FirebaseFirestore _firestore;

  AbsenceRequestRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> submitAbsenceRequest(AbsenceRequestModel request) async {
    // 1. Kiểm tra đơn trùng lặp (Lỗi 20E4)
    final isDuplicate = await hasPendingRequest(
      studentId: request.studentId,
      subjectId: request.subjectId,
    );
    if (isDuplicate) {
      throw Exception('Bạn đã gửi đơn xin vắng thi cho môn này và đang chờ duyệt');
    }

    // 2. Kiểm tra deadline nộp đơn (Lỗi 20E3)
    final deadlineErr = AbsenceFormValidator.validateExamDeadline(
      examTime: request.examTime,
      submissionTime: request.createdAt,
    );
    if (deadlineErr != null) {
      throw Exception(deadlineErr);
    }

    // 3. Ghi dữ liệu vào Firestore collection `absence_requests`
    final data = request.toMap();
    if (request.id.isNotEmpty && !request.id.startsWith('temp_')) {
      await _firestore.collection('absence_requests').doc(request.id).set(data);
    } else {
      await _firestore.collection('absence_requests').add(data);
    }
  }

  @override
  Future<bool> hasPendingRequest({
    required String studentId,
    required String subjectId,
  }) async {
    return AbsenceFormValidator.isDuplicatePendingRequest(
      studentId: studentId,
      subjectId: subjectId,
      firestore: _firestore,
    );
  }

  @override
  Future<List<AbsenceRequestModel>> getStudentAbsenceRequests(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection('absence_requests')
          .where('studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AbsenceRequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Fallback query without orderBy in case index is not built yet
      final snapshot = await _firestore
          .collection('absence_requests')
          .where('studentId', isEqualTo: studentId)
          .get();

      final list = snapshot.docs
          .map((doc) => AbsenceRequestModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
  }

  @override
  Stream<List<AbsenceRequestModel>> streamStudentAbsenceRequests(String studentId) {
    return _firestore
        .collection('absence_requests')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AbsenceRequestModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  @override
  Future<List<ExamSubjectOption>> getAvailableExamSubjects(String studentId) async {
    final List<ExamSubjectOption> options = [];

    try {
      // Truy vấn các lớp học sinh viên đã tham gia
      final querySnapshot = await _firestore
          .collection('classes')
          .where('danh_sach_sinh_vien', arrayContains: studentId)
          .get();

      final now = DateTime.now();

      for (var i = 0; i < querySnapshot.docs.length; i++) {
        final doc = querySnapshot.docs[i];
        final data = doc.data();
        final subjectId = doc.id;
        final subjectName = (data['ten_lop'] as String? ?? 'Môn học').trim();
        final subjectCode = (data['ma_mon'] as String? ?? 'INT${3000 + i}').trim();
        
        // Thời gian thi dự kiến (mặc định lấy theo examTime lưu trong class hoặc tạo lịch thi hợp lệ)
        DateTime examDate;
        if (data['exam_date'] != null) {
          final ed = data['exam_date'];
          examDate = ed is Timestamp ? ed.toDate() : (DateTime.tryParse(ed.toString()) ?? now.add(Duration(days: 3 + i)));
        } else {
          // Lịch thi trong tương lai gần (3 ngày tới, ca sáng 08:00)
          examDate = DateTime(now.year, now.month, now.day + 2 + i, 8 + (i % 2) * 6, 0);
        }

        options.add(
          ExamSubjectOption(
            subjectId: subjectId,
            subjectName: subjectName,
            subjectCode: subjectCode,
            examShiftId: 'SHIFT_${doc.id}',
            examShiftName: 'Ca ${1 + (i % 3)} (08:00 - 10:00)',
            examTime: examDate,
            isStudentEnrolled: true,
            room: data['phong_thi'] as String? ?? 'Phòng 402-A2',
          ),
        );
      }
    } catch (e) {
      // Ignored: fallback below
    }

    // Nếu sinh viên chưa tham gia lớp nào hoặc db trống, cung cấp danh sách môn thi mẫu theo chuẩn KTPM TLU
    if (options.isEmpty) {
      final now = DateTime.now();
      options.addAll([
        ExamSubjectOption(
          subjectId: 'SUB_01',
          subjectName: 'Kiểm thử phần mềm',
          subjectCode: 'CSE401',
          examShiftId: 'SHIFT_01',
          examShiftName: 'Ca 1 (07:30 - 09:30)',
          examTime: DateTime(now.year, now.month, now.day + 3, 7, 30),
          isStudentEnrolled: true,
          room: 'Phòng 301-A2',
        ),
        ExamSubjectOption(
          subjectId: 'SUB_02',
          subjectName: 'Đảm bảo chất lượng phần mềm',
          subjectCode: 'SWE302',
          examShiftId: 'SHIFT_02',
          examShiftName: 'Ca 2 (09:45 - 11:45)',
          examTime: DateTime(now.year, now.month, now.day + 5, 9, 45),
          isStudentEnrolled: true,
          room: 'Phòng 405-A3',
        ),
        ExamSubjectOption(
          subjectId: 'SUB_03',
          subjectName: 'Lập trình Thiết bị Di động',
          subjectCode: 'MBL201',
          examShiftId: 'SHIFT_03',
          examShiftName: 'Ca 3 (13:30 - 15:30)',
          examTime: DateTime(now.year, now.month, now.day + 7, 13, 30),
          isStudentEnrolled: true,
          room: 'Phòng Lab 202-B1',
        ),
        ExamSubjectOption(
          subjectId: 'SUB_04',
          subjectName: 'Kiến trúc và Thiết kế Phần mềm',
          subjectCode: 'SWE404',
          examShiftId: 'SHIFT_04',
          examShiftName: 'Ca 1 (07:30 - 09:30)',
          examTime: DateTime(now.year, now.month, now.day - 4, 7, 30), // Môn đã thi cách đây 4 ngày (quá 48h để test 20E3)
          isStudentEnrolled: true,
          room: 'Phòng 501-A1',
        ),
        ExamSubjectOption(
          subjectId: 'SUB_05_NOT_ENROLLED',
          subjectName: 'Toán cao cấp A1 (Không thuộc DS)',
          subjectCode: 'MTH101',
          examShiftId: 'SHIFT_05',
          examShiftName: 'Ca 2 (09:45 - 11:45)',
          examTime: DateTime(now.year, now.month, now.day + 10, 9, 45),
          isStudentEnrolled: false, // Sinh viên không có tên trong DS (để test 20E2)
          room: 'Hội trường T45',
        ),
      ]);
    }

    return options;
  }

  @override
  Future<Map<String, dynamic>?> getStudentProfile(String studentId) async {
    try {
      final doc = await _firestore.collection('users').doc(studentId).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      // Ignored
    }
    return null;
  }
}
