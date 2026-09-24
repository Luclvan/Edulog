import 'package:flutter/material.dart';
import '../../data/models/class_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/class_controller.dart';
import 'invite_student_bottom_sheet.dart';
import '../../../group_management/presentation/pages/group_list_screen.dart';

class SubjectCard extends ConsumerWidget {
  final ClassModel classModel;

  const SubjectCard({super.key, required this.classModel});

  void _showInviteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InviteStudentBottomSheet(classModel: classModel),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupListScreen(classModel: classModel),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Dismissible(
          key: Key(classModel.id),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            ref.read(classControllerProvider.notifier).removeClass(classModel.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${classModel.name} đã bị xóa')),
            );
          },
          background: Container(
            color: Colors.red.shade700,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        classModel.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTag(classModel.semester.isNotEmpty ? classModel.semester : 'HK1-2025', const Color(0xFFE3F2FD), const Color(0xFF1976D2)),
                    const SizedBox(width: 8),
                    _buildTag('${classModel.groupCount} NHÓM', const Color(0xFFE0F2F1), const Color(0xFF00796B)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people_alt_outlined, size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          '${classModel.groupCount} nhóm',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _showInviteSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.link, size: 16, color: Color(0xFF1976D2)),
                            SizedBox(width: 6),
                            Text(
                              'Mời SV',
                              style: TextStyle(
                                color: Color(0xFF1976D2),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
