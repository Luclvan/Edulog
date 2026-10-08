import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/student_dashboard_provider.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/class_list_item.dart';
import '../data/repositories/firebase_student_repository_impl.dart';
import '../domain/usecases/join_class_usecase.dart';
import '../../exam_absence/presentation/pages/create_absence_request_screen.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StudentDashboardProvider>(
      create: (_) {
        final repository = FirebaseStudentRepositoryImpl();
        return StudentDashboardProvider(
          repository: repository,
          joinClassUseCase: JoinClassUseCase(repository),
        )..loadJoinedClasses();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA), // Light background color
        body: Column(
          children: [
            const DashboardHeader(),
            Expanded(
              child: Consumer<StudentDashboardProvider>(
                builder: (context, provider, child) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      await provider.loadJoinedClasses();
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20.0),
                    children: [
                      // Quick Action: Xin vắng / hoãn thi
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateAbsenceRequestScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E65D0), Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E65D0).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.assignment_late_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Đơn xin vắng / hoãn thi',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Nộp đơn xin nghỉ thi, hoãn thi môn học',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lớp học của tôi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${provider.classes.length} lớp',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (provider.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (provider.classes.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Text(
                              'Chưa có dữ liệu',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else
                      ...provider.classes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final classItem = entry.value;
                        // Cycle through some colors for the top border
                        final colors = [
                          const Color(0xFF1E65D0), // Blue
                          const Color(0xFF009688), // Teal
                          const Color(0xFF9C27B0), // Purple
                          const Color(0xFFFF5722), // Orange
                        ];
                        final color = colors[index % colors.length];

                        return ClassListItem(
                          classItem: classItem,
                          topBorderColor: color,
                        );
                      }),
                    ],
                  ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
