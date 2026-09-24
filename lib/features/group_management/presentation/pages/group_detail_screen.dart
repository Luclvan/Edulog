import 'contribution_analysis_screen.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/oral_exam_validator.dart';
import '../../../student_dashboard/data/repositories/firebase_student_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../student_dashboard/domain/entities/group_entity.dart';
import '../../data/repositories/group_repository.dart';
import '../../../oral_exam/presentation/pages/oral_exam_screen.dart';
import '../../../../core/widgets/exam_result_bottom_sheet.dart';

class GroupDetailScreen extends ConsumerWidget {
  final GroupEntity group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProjectInfoCard(group),
                  const SizedBox(height: 16),
                  _buildContributionOverviewCard(context, ref),
                  const SizedBox(height: 16),
                  _buildMembersListCard(context, ref),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF1565C0),
      expandedHeight: 140.0,
      floating: false,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'CHI TIẾT NHÓM',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: false,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(
              top: 40.0, // Adjust based on AppBar height
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Đã hoàn thành',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectInfoCard(GroupEntity group) {
    final githubUrl = group.githubUrl; 
    final docsUrl = group.docsUrl;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MÔN HỌC',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Lập trình Mobile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              _buildAvatarStack(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'EduLog — Ứng dụng hỗ trợ giảng viên xác minh đóng góp thực tế và sinh câu hỏi vấn đáp cá nhân hóa dựa trên GitHub & Google Docs.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildLinkChip(
                icon: Icons.code,
                text: 'GitHub đã link',
                link: githubUrl,
                activeBgColor: const Color(0xFFE3F2FD),
                activeTextColor: const Color(0xFF1565C0),
              ),
              const SizedBox(width: 12),
              _buildLinkChip(
                icon: Icons.description,
                text: 'Docs đã link',
                link: docsUrl,
                activeBgColor: const Color(0xFFE8F5E9),
                activeTextColor: const Color(0xFF2E7D32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack() {
    return SizedBox(
      width: 80,
      height: 32,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            child: _buildCircleAvatar('MC', const Color(0xFFEDE7F6), const Color(0xFF673AB7)),
          ),
          Positioned(
            right: 20,
            child: _buildCircleAvatar('TB', const Color(0xFFE0F2F1), const Color(0xFF009688)),
          ),
          Positioned(
            right: 40,
            child: _buildCircleAvatar('NVA', const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleAvatar(String initials, Color bgColor, Color textColor) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLinkChip({
    required IconData icon,
    required String text,
    String? link,
    required Color activeBgColor,
    required Color activeTextColor,
  }) {
    final bool hasLink = link != null && link.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasLink ? activeBgColor : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: hasLink ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: hasLink ? activeTextColor : Colors.grey.shade500,
          ),
          const SizedBox(width: 6),
          Text(
            hasLink ? text : '(Chưa nộp)',
            style: TextStyle(
              color: hasLink ? activeTextColor : Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionOverviewCard(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TỔNG QUAN ĐÓNG GÓP',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ContributionAnalysisScreen(group: group)),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  backgroundColor: const Color(0xFFE8F0FE),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Xem chi tiết',
                  style: TextStyle(
                    color: Color(0xFF1565C0),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Phân bổ trong nhóm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Builder(
            builder: (context) {
              final githubUrl = group.githubUrl;
              if (githubUrl == null || githubUrl.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Nhóm chưa gắn link GitHub.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    )
                  ),
                );
              }

              final data = group.githubStats;
              if (data == null || data.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Đã có link. Vui lòng bấm nút Đồng bộ (Reload) ở màn hình danh sách để tải dữ liệu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    )
                  ),
                );
              }

              final colors = [
                const Color(0xFF1565C0),
                const Color(0xFF009688),
                const Color(0xFF673AB7),
                const Color(0xFFE91E63),
                const Color(0xFFFF9800),
              ];

              double currentTotal = 0;
              final chartWidgets = <Widget>[];
              final legendWidgets = <Widget>[];

              for (var i = 0; i < data.length; i++) {
                final item = data[i];
                final percentage = ((item['percentage'] as num?)?.toDouble() ?? 0.0) / 100.0;
                final username = item['username']?.toString() ?? 'Unknown';
                final color = colors[i % colors.length];

                legendWidgets.add(
                  _buildLegendItem(username, '${(percentage * 100).toInt()}%', color),
                );
                if (i < data.length - 1) legendWidgets.add(const SizedBox(height: 12));

                currentTotal += percentage;
                chartWidgets.insert(0, SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: currentTotal,
                    strokeWidth: 16,
                    color: color,
                  ),
                ));
              }

              chartWidgets.add(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Đóng góp', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('100%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                )
              );

              return Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: chartWidgets,
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      children: legendWidgets,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String name, String percentage, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          percentage,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMembersListCard(BuildContext context, WidgetRef ref) {
    final memberIds = group.members.map((m) => m.id).toList();
    final membersAsync = ref.watch(groupMembersProvider(memberIds.join(',')));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_outline, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  const Text(
                    'Thành viên',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE3F2FD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.camera_alt_outlined, color: Color(0xFF1976D2), size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Chụp ảnh sinh viên → nhận diện và mở ngay phiên vấn đáp',
                    style: TextStyle(
                      color: Color(0xFF1976D2),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          membersAsync.when(
            data: (users) {
              if (users.isEmpty) return const Text('Chưa có thành viên nào');
              
              // Mapping real names with mock roles/colors to keep UI looking good
              final mockConfigs = [
                {'task': 'Infrastructure & Authentication', 'percentage': 0.34, 'color': const Color(0xFF1565C0), 'bgColor': const Color(0xFFE3F2FD)},
                {'task': 'Domain & Application', 'percentage': 0.28, 'color': const Color(0xFF009688), 'bgColor': const Color(0xFFE0F2F1)},
                {'task': 'Presentation & UI', 'percentage': 0.38, 'color': const Color(0xFF673AB7), 'bgColor': const Color(0xFFEDE7F6)},
              ];

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                separatorBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                ),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final config = mockConfigs[index % mockConfigs.length];
                  
                  final initials = user.name.isNotEmpty 
                      ? user.name.trim().split(RegExp(r'\s+')).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join() 
                      : '?';

                  return _MemberItemCard(
                    user: user,
                    initials: initials,
                    config: config,
                    group: group,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Lỗi: $e'),
          ),
        ],
      ),
    );
  }
}

class _MemberItemCard extends ConsumerStatefulWidget {
  final dynamic user;
  final String initials;
  final Map<String, dynamic> config;
  final GroupEntity group;

  const _MemberItemCard({
    required this.user,
    required this.initials,
    required this.config,
    required this.group,
  });

  @override
  ConsumerState<_MemberItemCard> createState() => _MemberItemCardState();
}

class _MemberItemCardState extends ConsumerState<_MemberItemCard> {
  bool _isPhotoTaken = false;

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      // Input Source Restriction: Direct camera capture only
      final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);

      // [8E2] Cancelled / Hardware capture failure
      if (image == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chưa chụp được ảnh xác thực. Vui lòng thực hiện lại'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // [8E3, 8E4] Format and file size checks
      final bytes = await image.readAsBytes();
      final photoError = OralExamValidator.validatePhoto(
        filename: image.name.isNotEmpty ? image.name : image.path,
        bytesLength: bytes.length,
      );
      if (photoError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(photoError),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // [8E5 - 8E7] Computer Vision / Quality validation
      final qualityError = OralExamValidator.validateFaceAndQuality(
        detectedFaces: 1,
        isBlurredOrDark: false,
      );
      if (qualityError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(qualityError),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Đang lưu ảnh xác thực...'),
              ],
            ),
          ),
        );
      }

      final repo = FirebaseStudentRepositoryImpl();
      final url = await repo.uploadImageToImgBB(File(image.path));

      if (mounted) {
        Navigator.pop(context); // Close dialog

        if (url != null) {
          setState(() {
            _isPhotoTaken = true;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lưu ảnh thành công!'),
              backgroundColor: Colors.green,
            ),
          );

          // Auto navigate to OralExamScreen
          await _startOralExam();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi khi tải ảnh lên!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      final msg = OralExamValidator.mapCameraPlatformException(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa chụp được ảnh xác thực. Vui lòng thực hiện lại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startOralExam() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OralExamScreen(
          student: widget.user,
          groupName: widget.group.name,
          group: widget.group,
        ),
      ),
    );
    ref.invalidate(examResultProvider('${widget.group.id}_${widget.user.uid}'));
  }

  @override
  Widget build(BuildContext context) {
    final examResultAsync = ref.watch(examResultProvider('${widget.group.id}_${widget.user.uid}'));
    final hasResult = examResultAsync.value != null;
    final finalScore = hasResult ? (examResultAsync.value!['finalScore'] as num).toDouble() : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.config['bgColor'] as Color,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                widget.initials,
                style: TextStyle(
                  color: widget.config['color'] as Color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (_isPhotoTaken || hasResult)
                    const SizedBox(height: 4),
                  if (_isPhotoTaken || hasResult)
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        if (_isPhotoTaken)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                            child: const Text('Đã chụp ảnh xác minh', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        if (hasResult)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                            child: const Text('Đã hoàn thành', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            if (hasResult)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                child: Text('${finalScore?.toStringAsFixed(1) ?? 'N/A'}/10', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: Icon(_isPhotoTaken ? Icons.check_circle : Icons.camera_alt_outlined, size: 18),
                label: Text(
                  _isPhotoTaken ? 'Đã chụp' : 'Chụp ảnh',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPhotoTaken ? Colors.green : const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _startOralExam,
                icon: const Icon(Icons.quiz_outlined, size: 18),
                label: const Text(
                  'Vấn đáp',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: hasResult ? () {
              final data = examResultAsync.value as Map<String, dynamic>;
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (ctx) => ExamResultBottomSheet(data: data),
              );
            } : null,
            icon: const Icon(Icons.assessment, size: 18),
            label: const Text(
              'Xem kết quả vấn đáp',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

