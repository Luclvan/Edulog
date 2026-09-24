import 'dart:io';
import '../entities/class_entity.dart';
import '../entities/group_entity.dart';
import '../entities/member_entity.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/group_model.dart';

abstract class StudentDashboardRepository {
  Future<List<ClassEntity>> getJoinedClasses();
  Future<void> joinClass(String classCode);
  Future<List<GroupEntity>> getGroupsByClass(String classId);
  Future<GroupModel> createGroup(String classId, String groupName, String? linkGithub, String? linkDocs);
  Future<void> updateGroupLinks(String groupId, String linkGithub, String linkDocs);
  Future<void> requestJoinGroup(String groupId);
  Future<String> getUserName();
  Future<List<MemberEntity>> getUsersByUids(List<String> uids);
  Future<void> acceptJoinRequest(String groupId, String studentUid);
  Future<void> rejectJoinRequest(String groupId, String studentUid);
  Future<void> leaveGroup(String groupId, String uid);
  Future<List<MemberEntity>> getStudentsWithoutGroup(String classId);
  Future<void> sendGroupInvite(String targetUid, String groupId, String groupName);
  Stream<List<NotificationModel>> getNotificationsStream(String uid);
  Future<void> respondToGroupInvite(String notificationId, String groupId, bool isAccepted);
  Future<String?> uploadImageToImgBB(File imageFile);
  Future<bool> checkGroupNameExists(String classId, String groupName, {String? excludeGroupId});
  Future<bool> checkGithubUrlExists(String classId, String githubUrl, {String? excludeGroupId});
  Future<bool> checkDocsUrlExists(String classId, String docsUrl, {String? excludeGroupId});
}
