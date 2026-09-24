import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/class_model.dart';
import '../data/repositories/class_repository.dart';

final classControllerProvider = AsyncNotifierProvider<ClassController, List<ClassModel>>(() {
  return ClassController();
});

class ClassController extends AsyncNotifier<List<ClassModel>> {
  String get _teacherUid => FirebaseAuth.instance.currentUser?.email ?? 'default_teacher@example.com';

  @override
  FutureOr<List<ClassModel>> build() async {
    return _fetchClasses();
  }

  Future<List<ClassModel>> _fetchClasses() async {
    final repository = ref.read(classRepositoryProvider);
    final classesData = await repository.getClassesForTeacher(_teacherUid);
    return classesData.map((data) => ClassModel.fromMap(data)).toList();
  }

  Future<void> addClass(String name, String subjectCode, {String semester = 'HK1-2025'}) async {
    state = const AsyncValue.loading();
    
    try {
      final repository = ref.read(classRepositoryProvider);

      // [5E1] Uniqueness per Semester per Teacher (Async)
      final isDuplicate = await repository.isSubjectDuplicate(
        teacherUid: _teacherUid,
        subjectName: name,
        semester: semester,
      );
      if (isDuplicate) {
        throw Exception("Môn học này đã tồn tại trong học kỳ");
      }

      await repository.createClass(
        className: name,
        subjectCode: subjectCode,
        teacherUid: _teacherUid,
        semester: semester,
      );
      
      // Re-fetch classes after adding
      final updatedClasses = await _fetchClasses();
      state = AsyncValue.data(updatedClasses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void removeClass(String id) {
    // Note: We are currently only removing locally. For full integration,
    // this would call repository.deleteClass(id) then re-fetch.
    final currentClasses = state.value ?? [];
    state = AsyncValue.data(
      currentClasses.where((c) => c.id != id).toList(),
    );
  }
}
