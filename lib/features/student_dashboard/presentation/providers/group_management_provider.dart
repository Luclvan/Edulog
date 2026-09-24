import 'package:flutter/material.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/member_entity.dart';
import '../../domain/entities/class_entity.dart';

import '../../domain/repositories/student_dashboard_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/group_validator.dart';

class GroupManagementProvider extends ChangeNotifier {
  final StudentDashboardRepository repository;
  
  final MemberEntity currentUser;

  GroupManagementProvider({
    required this.repository,
    MemberEntity? currentUser,
  }) : currentUser = currentUser ??
            MemberEntity(
              id: _safeCurrentUid(),
              name: 'Sinh viên',
              studentId: 'N/A',
            );

  static String _safeCurrentUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void selectGroup(GroupEntity group) {
    _currentGroup = group;
    notifyListeners();
  }

  List<GroupEntity> _groups = [];
  GroupEntity? _currentGroup;
  final Map<String, bool> _joinRequests = {};

  List<GroupEntity> get groups => _groups;
  GroupEntity? get currentGroup => _currentGroup;

  bool hasRequestedToJoin(String groupId) {
    return _joinRequests[groupId] ?? false;
  }

  Future<GroupEntity?> checkUserHasGroup(String classId, String uid) async {
    try {
      final fetchedGroups = await repository.getGroupsByClass(classId);
      return fetchedGroups.firstWhere((g) => g.members.any((m) => m.id == uid));
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchGroups(String classId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _groups = await repository.getGroupsByClass(classId);
      
      // Check if current user is in any group
      try {
        _currentGroup = _groups.firstWhere(
          (g) => g.members.any((m) => m.id == currentUser.id)
        );
      } catch (_) {
        _currentGroup = null;
      }
      
      if (_currentGroup != null) {
        final memberUids = _currentGroup!.members.map((e) => e.id).toList();
        final requestUids = _currentGroup!.joinRequests.map((e) => e.id).toList();
        
        final fetchedMembers = await repository.getUsersByUids(memberUids);
        final fetchedRequests = await repository.getUsersByUids(requestUids);
        
        if (fetchedMembers.isNotEmpty) {
          fetchedMembers[0] = MemberEntity(
            id: fetchedMembers[0].id,
            name: fetchedMembers[0].name,
            studentId: fetchedMembers[0].studentId,
            isLeader: true,
          );
        }
        
        _currentGroup = _currentGroup!.copyWith(
          members: fetchedMembers,
          joinRequests: fetchedRequests,
        );
      }
      
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initForClass(ClassEntity classItem) async {
    await fetchGroups(classItem.id);
  }

  Future<void> requestJoin(String groupId) async {
    try {
      await repository.requestJoinGroup(groupId);
      _joinRequests[groupId] = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<GroupEntity> createGroup(String classId, String name, String github, String docs) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final trimmedName = name.trim();
      final trimmedGithub = github.trim();
      final trimmedDocs = docs.trim();

      // [1E1] Uniqueness per class check for group name
      final nameExists = await repository.checkGroupNameExists(classId, trimmedName);
      if (nameExists) {
        throw GroupValidationException('Tên nhóm đã tồn tại trong lớp học này', field: 'name');
      }

      // [2E1] Uniqueness per class check for GitHub URL
      final githubExists = await repository.checkGithubUrlExists(classId, trimmedGithub);
      if (githubExists) {
        throw GroupValidationException('Repository GitHub này đã được nộp bởi nhóm khác', field: 'github');
      }

      // [2E6] Accessibility check via GitHub API
      final githubAccessError = await GroupValidator.checkGithubAccessibility(trimmedGithub);
      if (githubAccessError != null) {
        throw GroupValidationException(githubAccessError, field: 'github');
      }

      // [3E1] Uniqueness per class check for Google Docs URL
      final docsExists = await repository.checkDocsUrlExists(classId, trimmedDocs);
      if (docsExists) {
        throw GroupValidationException('Tài liệu Google Docs này đã được sử dụng bởi nhóm khác', field: 'docs');
      }

      // [3E5] Public access check for Google Docs URL
      final docsAccessError = await GroupValidator.checkDocsPublicAccess(trimmedDocs);
      if (docsAccessError != null) {
        throw GroupValidationException(docsAccessError, field: 'docs');
      }

      final newGroup = await repository.createGroup(
        classId,
        trimmedName,
        trimmedGithub.isEmpty ? null : trimmedGithub,
        trimmedDocs.isEmpty ? null : trimmedDocs,
      );
      // Wait for fetchGroups to update the list, although we just return the new group
      return newGroup;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateGroupLinksWithValidation(String groupId, String classId, String github, String docs) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final trimmedGithub = github.trim();
      final trimmedDocs = docs.trim();

      if (trimmedGithub.isNotEmpty) {
        // [2E1] Uniqueness check for GitHub URL
        final githubExists = await repository.checkGithubUrlExists(classId, trimmedGithub, excludeGroupId: groupId);
        if (githubExists) {
          throw GroupValidationException('Repository GitHub này đã được nộp bởi nhóm khác', field: 'github');
        }
        // [2E6] Accessibility check
        final githubAccessError = await GroupValidator.checkGithubAccessibility(trimmedGithub);
        if (githubAccessError != null) {
          throw GroupValidationException(githubAccessError, field: 'github');
        }
      }

      if (trimmedDocs.isNotEmpty) {
        // [3E1] Uniqueness check for Google Docs URL
        final docsExists = await repository.checkDocsUrlExists(classId, trimmedDocs, excludeGroupId: groupId);
        if (docsExists) {
          throw GroupValidationException('Tài liệu Google Docs này đã được sử dụng bởi nhóm khác', field: 'docs');
        }
        // [3E5] Public access check
        final docsAccessError = await GroupValidator.checkDocsPublicAccess(trimmedDocs);
        if (docsAccessError != null) {
          throw GroupValidationException(docsAccessError, field: 'docs');
        }
      }

      await repository.updateGroupLinks(groupId, trimmedGithub, trimmedDocs);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void approveRequest(String userId) {
    if (_currentGroup == null) return;
    
    final request = _currentGroup!.joinRequests.firstWhere((req) => req.id == userId);
    final updatedRequests = _currentGroup!.joinRequests.where((req) => req.id != userId).toList();
    final updatedMembers = List<MemberEntity>.from(_currentGroup!.members)..add(request);
    
    _currentGroup = _currentGroup!.copyWith(
      joinRequests: updatedRequests,
      members: updatedMembers,
      isFull: updatedMembers.length >= _currentGroup!.maxMembers,
    );
    notifyListeners();
  }

  void rejectRequest(String userId) {
    if (_currentGroup == null) return;

    final updatedRequests = _currentGroup!.joinRequests.where((req) => req.id != userId).toList();
    _currentGroup = _currentGroup!.copyWith(
      joinRequests: updatedRequests,
    );
    notifyListeners();
  }

  void leaveGroup() {
    _currentGroup = null;
    notifyListeners();
  }

  Future<void> approveRequestAsync(BuildContext context, String userId) async {
    if (_currentGroup == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await repository.acceptJoinRequest(_currentGroup!.id, userId);
      approveRequest(userId);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã duyệt yêu cầu')));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> rejectRequestAsync(BuildContext context, String userId) async {
    if (_currentGroup == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await repository.rejectJoinRequest(_currentGroup!.id, userId);
      rejectRequest(userId);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã từ chối yêu cầu')));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> leaveGroupAsync(BuildContext context, String classId) async {
    if (_currentGroup == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await repository.leaveGroup(_currentGroup!.id, currentUser.id);
      leaveGroup(); // reset state
      await fetchGroups(classId); // refetch
      if (context.mounted) {
        Navigator.pop(context); // Hide loading
        Navigator.pop(context); // Pop back to dashboard
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }
}
