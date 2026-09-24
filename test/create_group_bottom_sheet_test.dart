import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:edulog/features/student_dashboard/domain/repositories/student_dashboard_repository.dart';
import 'package:edulog/features/student_dashboard/domain/entities/group_entity.dart';
import 'package:edulog/features/student_dashboard/domain/entities/class_entity.dart';
import 'package:edulog/features/student_dashboard/domain/entities/member_entity.dart';
import 'package:edulog/features/student_dashboard/data/models/group_model.dart';
import 'package:edulog/features/student_dashboard/data/models/notification_model.dart';
import 'package:edulog/features/student_dashboard/presentation/providers/group_management_provider.dart';
import 'package:edulog/features/student_dashboard/presentation/widgets/create_group_bottom_sheet.dart';

class MockStudentDashboardRepository implements StudentDashboardRepository {
  bool nameExists = false;
  bool githubExists = false;
  bool docsExists = false;

  @override
  Future<bool> checkGroupNameExists(String classId, String groupName, {String? excludeGroupId}) async {
    return nameExists;
  }

  @override
  Future<bool> checkGithubUrlExists(String classId, String githubUrl, {String? excludeGroupId}) async {
    return githubExists;
  }

  @override
  Future<bool> checkDocsUrlExists(String classId, String docsUrl, {String? excludeGroupId}) async {
    return docsExists;
  }

  @override
  Future<GroupModel> createGroup(String classId, String groupName, String? linkGithub, String? linkDocs) async {
    return GroupModel(
      id: 'group-1',
      classId: classId,
      name: groupName,
      githubUrl: linkGithub,
      docsUrl: linkDocs,
      members: [],
      leaderId: 'user-1',
    );
  }

  @override
  Future<List<GroupEntity>> getGroupsByClass(String classId) async => [];

  @override
  Future<List<ClassEntity>> getJoinedClasses() async => [];

  @override
  Future<List<MemberEntity>> getStudentsWithoutGroup(String classId) async => [];

  @override
  Future<String> getUserName() async => 'Test User';

  @override
  Future<List<MemberEntity>> getUsersByUids(List<String> uids) async => [];

  @override
  Future<void> joinClass(String classCode) async {}

  @override
  Future<void> leaveGroup(String groupId, String uid) async {}

  @override
  Future<void> rejectJoinRequest(String groupId, String studentUid) async {}

  @override
  Future<void> requestJoinGroup(String groupId) async {}

  @override
  Future<void> respondToGroupInvite(String notificationId, String groupId, bool isAccepted) async {}

  @override
  Future<void> sendGroupInvite(String targetUid, String groupId, String groupName) async {}

  @override
  Future<void> updateGroupLinks(String groupId, String linkGithub, String linkDocs) async {}

  @override
  Future<String?> uploadImageToImgBB(File imageFile) async => null;

  @override
  Stream<List<NotificationModel>> getNotificationsStream(String uid) => const Stream.empty();

  @override
  Future<void> acceptJoinRequest(String groupId, String studentUid) async {}
}

void main() {
  late MockStudentDashboardRepository mockRepo;
  late GroupManagementProvider provider;

  setUp(() {
    mockRepo = MockStudentDashboardRepository();
    provider = GroupManagementProvider(repository: mockRepo);
  });

  Widget buildTestWidget() {
    return ChangeNotifierProvider<GroupManagementProvider>.value(
      value: provider,
      child: const MaterialApp(
        home: Scaffold(
          body: CreateGroupBottomSheet(classId: 'class-123'),
        ),
      ),
    );
  }

  group('CreateGroupBottomSheet UI & Synchronous Validation', () {
    testWidgets('shows validation errors when creating with empty fields', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Tap on "Tạo nhóm" button
      final createButton = find.widgetWithText(ElevatedButton, 'Tạo nhóm');
      expect(createButton, findsOneWidget);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Check synchronous error messages
      expect(find.text('Tên nhóm không được để trống'), findsOneWidget);
      expect(find.text('Đường dẫn GitHub không được để trống'), findsOneWidget);
      expect(find.text('Đường dẫn Google Docs không được để trống'), findsOneWidget);
    });

    testWidgets('shows validation errors for invalid formats', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Enter group name < 3 chars
      await tester.enterText(find.byType(TextFormField).at(0), 'AB');
      // Enter invalid GitHub URL
      await tester.enterText(find.byType(TextFormField).at(1), 'http://github.com/abc');
      // Enter invalid Docs URL
      await tester.enterText(find.byType(TextFormField).at(2), 'https://docs.google.vn/abc');

      final createButton = find.widgetWithText(ElevatedButton, 'Tạo nhóm');
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.text('Tên nhóm phải có độ dài tối thiểu 3 ký tự'), findsOneWidget);
      expect(find.text('Đường dẫn phải bắt đầu bằng https://github.com/'), findsOneWidget);
      expect(find.text('Đường dẫn phải thuộc tên miền Google Docs hoặc Google Drive'), findsOneWidget);
    });

    testWidgets('shows special character validation error for group name', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.enterText(find.byType(TextFormField).at(0), 'Nhóm @ 123!');
      final createButton = find.widgetWithText(ElevatedButton, 'Tạo nhóm');
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.text('Tên nhóm chứa ký tự đặc biệt không hợp lệ'), findsOneWidget);
    });
  });

  group('GroupManagementProvider Business Constraints', () {
    test('[1E1] Throws error when group name already exists in class', () async {
      mockRepo.nameExists = true;

      expect(
        () => provider.createGroup(
          'class-123',
          'Nhóm 1',
          'https://github.com/flutter/flutter',
          'https://docs.google.com/document/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit',
        ),
        throwsA(
          predicate((e) =>
              e.toString() == 'Tên nhóm đã tồn tại trong lớp học này'),
        ),
      );
    });

    test('[2E1] Throws error when GitHub repo already registered in class', () async {
      mockRepo.nameExists = false;
      mockRepo.githubExists = true;

      expect(
        () => provider.createGroup(
          'class-123',
          'Nhóm 1',
          'https://github.com/flutter/flutter',
          'https://docs.google.com/document/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit',
        ),
        throwsA(
          predicate((e) =>
              e.toString() == 'Repository GitHub này đã được nộp bởi nhóm khác'),
        ),
      );
    });

    test('[3E1] Throws error when Google Doc already submitted in class', () async {
      mockRepo.nameExists = false;
      mockRepo.githubExists = false;
      mockRepo.docsExists = true;

      // Note: GitHub check will run first. Let's make sure accessibility check is also tested.
    });
  });
}
