import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_management_provider.dart';
import '../widgets/member_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/member_entity.dart';
import '../../../../core/widgets/exam_result_bottom_sheet.dart';
import '../../../../core/utils/group_validator.dart';

class GroupDetailScreen extends StatelessWidget {
  final String classId;

  const GroupDetailScreen({super.key, required this.classId});

  void _showLeaveGroupDialog(BuildContext context, GroupManagementProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rời nhóm'),
        content: const Text('Bạn có chắc chắn muốn rời khỏi nhóm này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.leaveGroupAsync(context, classId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Có, rời nhóm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showExamResultDetails(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ExamResultBottomSheet(data: data),
    );
  }

  void _showEditLinksDialog(BuildContext context, GroupEntity group) {
    final formKey = GlobalKey<FormState>();
    final githubController = TextEditingController(text: group.githubUrl);
    final docsController = TextEditingController(text: group.docsUrl);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cập nhật Link'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: githubController,
                    validator: GroupValidator.validateGithubUrl,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      labelText: 'GitHub Link *',
                      hintText: 'https://github.com/user/repo',
                      prefixIcon: Icon(Icons.code),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: docsController,
                    validator: GroupValidator.validateDocsUrl,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      labelText: 'Google Docs Link *',
                      hintText: 'https://docs.google.com/document/d/...',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);
                      try {
                        final provider = context.read<GroupManagementProvider>();
                        await provider.updateGroupLinksWithValidation(
                          group.id,
                          classId,
                          githubController.text.trim(),
                          docsController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã cập nhật link thành công')),
                          );
                          provider.fetchGroups(classId); // Refresh
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (context.mounted) {
                          final msg = e.toString().replaceFirst('Exception: ', '');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi: $msg'),
                              backgroundColor: Colors.red.shade700,
                            ),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteModal(BuildContext context, GroupManagementProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _InviteMemberSheet(classId: classId, provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupManagementProvider>(
      builder: (context, provider, child) {
        final group = provider.currentGroup;

        if (group == null) {
          return const Scaffold(body: Center(child: Text('Không tìm thấy nhóm')));
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1976D2),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHI TIẾT NHÓM',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  group.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                iconSize: 22,
                padding: const EdgeInsets.all(8),
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => _showEditLinksDialog(context, group),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {},
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(child: _buildHeaderAction(context, Icons.code, 'GitHub', group.githubUrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildHeaderAction(context, Icons.description_outlined, 'Google Docs', group.docsUrl)),
                  ],
                ),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 1. Danh sách thành viên
              _buildSectionCard(
                title: 'Thành viên (${group.members.length}/${group.maxMembers})',
                icon: Icons.people_outline,
                action: ElevatedButton.icon(
                  onPressed: group.isFull ? null : () => _showInviteModal(context, provider),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Mời vào nhóm', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 32),
                  ),
                ),
                content: Column(
                  children: group.members.map((m) => MemberItem(member: m)).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Yêu cầu tham gia
              if (group.joinRequests.isNotEmpty)
                _buildSectionCard(
                  title: 'Yêu cầu tham gia',
                  icon: Icons.access_time,
                  badgeCount: group.joinRequests.length,
                  content: Column(
                    children: group.joinRequests.map((req) => MemberItem(
                      member: req,
                      showActions: true,
                      onApprove: () => provider.approveRequestAsync(context, req.id),
                      onReject: () => provider.rejectRequestAsync(context, req.id),
                    )).toList(),
                  ),
                ),
              if (group.joinRequests.isNotEmpty)
                const SizedBox(height: 16),


              // 3. Kết quả Vấn đáp
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('exam_results').doc('${group.id}_${FirebaseAuth.instance.currentUser?.uid}').get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
                  if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
                  
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final finalScore = data['finalScore']?.toString() ?? 'N/A';
                  
                  return Column(
                    children: [
                      _buildSectionCard(
                        title: 'Kết quả Vấn đáp',
                        icon: Icons.military_tech_outlined,
                        content: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Điểm tổng', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      finalScore,
                                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                                    ),
                                    Text(
                                      ' /10',
                                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('Đã chấm điểm', style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: () {
                                    _showExamResultDetails(context, data);
                                  },
                                  child: Row(
                                    children: const [
                                      Text('Xem chi tiết', style: TextStyle(color: Color(0xFF1976D2), fontSize: 13, fontWeight: FontWeight.w600)),
                                      Icon(Icons.chevron_right, size: 16, color: Color(0xFF1976D2)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
              
              // 4. Rời nhóm
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLeaveGroupDialog(context, provider),
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Rời nhóm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderAction(BuildContext context, IconData icon, String label, String? url) {
    return InkWell(
      onTap: () async {
        if (url == null || url.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa có link, hãy bấm nút sửa')));
          return;
        }
        final uri = Uri.parse(url);
        final canLaunch = await canLaunchUrl(uri);
        
        if (!context.mounted) return;

        if (canLaunch) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở link')));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new, color: Colors.white, size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
    Widget? action,
    int? badgeCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF1976D2), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  if (badgeCount != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        badgeCount.toString(),
                        style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }
}

class _InviteMemberSheet extends StatefulWidget {
  final String classId;
  final GroupManagementProvider provider;
  const _InviteMemberSheet({required this.classId, required this.provider});

  @override
  State<_InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<_InviteMemberSheet> {
  bool _isLoading = true;
  List<MemberEntity> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final students = await widget.provider.repository.getStudentsWithoutGroup(widget.classId);
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mời vào nhóm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? const Center(child: Text('Không có sinh viên nào chưa có nhóm'))
                    : ListView.builder(
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(student.name.substring(0, 1).toUpperCase()),
                            ),
                            title: Text(student.name),
                            subtitle: Text(student.studentId),
                            trailing: OutlinedButton(
                              onPressed: () async {
                                final group = widget.provider.currentGroup;
                                if (group != null) {
                                  try {
                                    await widget.provider.repository.sendGroupInvite(
                                      student.id, 
                                      group.id, 
                                      group.name
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Đã gửi lời mời')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Lỗi: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                              child: const Text('Mời'),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}



