import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return ClassRepository();
});

class ClassRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createClass({
    required String className,
    required String subjectCode,
    required String teacherUid,
    String semester = 'HK1-2025',
  }) async {
    try {
      final inviteCode = _generateInviteCode(subjectCode);
      await _firestore.collection('classes').add({
        'ten_lop': className,
        'ma_mon': subjectCode,
        'ma_moi': inviteCode,
        'hoc_ky': semester,
        'giang_vien_id': teacherUid,
        'danh_sach_sinh_vien': [],
        'ngay_tao': FieldValue.serverTimestamp(),
      });
      debugPrint('Class created successfully: $className');
    } catch (e) {
      debugPrint('Error creating class: $e');
      rethrow;
    }
  }

  /// [5E1] Check duplicate subject name for this teacher in the given semester
  Future<bool> isSubjectDuplicate({
    required String teacherUid,
    required String subjectName,
    required String semester,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('classes')
          .where('giang_vien_id', isEqualTo: teacherUid)
          .get();

      final cleanName = subjectName.trim().toLowerCase();
      final cleanSemester = semester.trim().toLowerCase();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final existingName = (data['ten_lop'] as String? ?? '').trim().toLowerCase();
        final existingSemester = (data['hoc_ky'] as String? ?? data['semester'] as String? ?? '').trim().toLowerCase();

        if (existingName == cleanName && (existingSemester.isEmpty || existingSemester == cleanSemester)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking duplicate subject: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getClassesForTeacher(String teacherUid) async {
    try {
      final querySnapshot = await _firestore
          .collection('classes')
          .where('giang_vien_id', isEqualTo: teacherUid)
          .get();

      final List<Map<String, dynamic>> classesData = [];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id; // Inject the Document ID
        
        final countQuery = await _firestore
            .collection('groups')
            .where('ma_lop', isEqualTo: doc.id)
            .count()
            .get();
        data['groupCount'] = countQuery.count;
        
        classesData.add(data);
      }
      return classesData;
    } catch (e) {
      debugPrint('Error getting classes for teacher ($teacherUid): $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getClassesForStudent(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('classes')
          .where('danh_sach_sinh_vien', arrayContains: studentId)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Inject the Document ID
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting classes for student ($studentId): $e');
      rethrow;
    }
  }

  Future<void> joinClass(String classId, String studentId) async {
    try {
      await _firestore.collection('classes').doc(classId).update({
        'danh_sach_sinh_vien': FieldValue.arrayUnion([studentId]),
      });
      debugPrint('Student $studentId joined class $classId successfully');
    } catch (e) {
      debugPrint('Error joining class ($classId): $e');
      rethrow;
    }
  }

  String _generateInviteCode(String subjectCode) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final randomString = String.fromCharCodes(Iterable.generate(
      6,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
    final formattedSubject = subjectCode.toUpperCase().replaceAll(' ', '-');
    return '$formattedSubject-$randomString';
  }
}
