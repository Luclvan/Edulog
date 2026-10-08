import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/absence_form_validator.dart';
import '../../domain/models/absence_request_model.dart';
import '../../domain/models/exam_subject_option.dart';
import '../controllers/absence_request_controller.dart';

class CreateAbsenceRequestScreen extends ConsumerStatefulWidget {
  const CreateAbsenceRequestScreen({super.key});

  @override
  ConsumerState<CreateAbsenceRequestScreen> createState() =>
      _CreateAbsenceRequestScreenState();
}

class _CreateAbsenceRequestScreenState
    extends ConsumerState<CreateAbsenceRequestScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // TextEditingControllers - 100% disposed in dispose()
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _reasonController;
  late final TextEditingController _proofUrlController;

  late final TabController _tabController;

  ExamSubjectOption? _selectedSubject;
  String? _dropdownCustomError;
  String? _loggedInStudentName;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _reasonController = TextEditingController();
    _proofUrlController = TextEditingController();

    _tabController = TabController(length: 2, vsync: this);

    _loadStudentInitialInfo();
  }

  @override
  void dispose() {
    // 100% Dispose controllers to avoid memory leaks
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _reasonController.dispose();
    _proofUrlController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadStudentInitialInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final email = user.email ?? '';
      _emailController.text = email;

      final studentId = user.uid;
      final profile = await ref
          .read(absenceRequestRepositoryProvider)
          .getStudentProfile(studentId);

      if (mounted && profile != null) {
        final name = profile['name'] as String? ?? user.displayName ?? '';
        final phone = profile['phone'] as String? ?? profile['so_dien_thoai'] as String? ?? '';
        setState(() {
          _loggedInStudentName = name;
          if (_fullNameController.text.isEmpty) {
            _fullNameController.text = name;
          }
          if (_phoneController.text.isEmpty && phone.isNotEmpty) {
            _phoneController.text = phone;
          }
        });
      } else if (mounted) {
        setState(() {
          _loggedInStudentName = user.displayName ?? '';
          if (_fullNameController.text.isEmpty) {
            _fullNameController.text = user.displayName ?? '';
          }
        });
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute, $day/$month/$year';
  }

  void _handleSubmit() async {
    setState(() {
      _dropdownCustomError = null;
    });

    // 1. Validate Dropdown selection (20E1)
    final subjectErr = AbsenceFormValidator.validateSubjectSelected(
      _selectedSubject?.subjectId,
    );
    if (subjectErr != null) {
      setState(() {
        _dropdownCustomError = subjectErr;
      });
      return;
    }

    final selected = _selectedSubject!;

    // 2. Validate Student enrolled in exam list (20E2)
    final enrollmentErr = AbsenceFormValidator.validateStudentInExamList(
      isInExamList: selected.isStudentEnrolled,
    );
    if (enrollmentErr != null) {
      setState(() {
        _dropdownCustomError = enrollmentErr;
      });
      return;
    }

    // 3. Validate Exam deadline (20E3)
    final deadlineErr = AbsenceFormValidator.validateExamDeadline(
      examTime: selected.examTime,
    );
    if (deadlineErr != null) {
      setState(() {
        _dropdownCustomError = deadlineErr;
      });
      return;
    }

    // 4. Validate Form fields (15E1-15E4, 16E1-16E4, 17E1-17E4, 18E1-18E3, 19E1-19E4)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? 'student_demo_id';

    final request = AbsenceRequestModel(
      id: '',
      studentId: currentUserId,
      studentName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      subjectId: selected.subjectId,
      subjectName: '${selected.subjectName} (${selected.subjectCode})',
      examShiftId: selected.examShiftId,
      examTime: selected.examTime,
      reason: _reasonController.text.trim(),
      proofUrl: _proofUrlController.text.trim(),
      status: 'pending',
      createdAt: DateTime.now(),
    );

    final success = await ref
        .read(absenceRequestControllerProvider.notifier)
        .submitRequest(request);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text('Nộp đơn xin vắng / hoãn thi thành công!'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Reset form
      _reasonController.clear();
      _proofUrlController.clear();
      setState(() {
        _selectedSubject = null;
        _dropdownCustomError = null;
      });

      // Switch to history tab
      _tabController.animateTo(1);
    } else {
      final errorMsg =
          ref.read(absenceRequestControllerProvider).errorMessage ??
          'Không thể gửi đơn. Vui lòng thử lại.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMsg)),
            ],
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? 'student_demo_id';
    final submitState = ref.watch(absenceRequestControllerProvider);
    final subjectsAsync = ref.watch(availableExamSubjectsProvider(currentUserId));
    final historyAsync =
        ref.watch(studentAbsenceRequestsStreamProvider(currentUserId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Đơn xin vắng / hoãn thi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E65D0),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.post_add, size: 20), text: 'Tạo đơn mới'),
            Tab(icon: Icon(Icons.history, size: 20), text: 'Lịch sử nộp đơn'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Tạo đơn mới
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner hướng dẫn quy định
                  _buildNoticeBanner(),
                  const SizedBox(height: 16),

                  // Section 1: Thông tin sinh viên
                  _buildStudentInfoSection(),
                  const SizedBox(height: 16),

                  // Section 2: Môn học & Ca thi
                  _buildSubjectSelectionSection(subjectsAsync),
                  const SizedBox(height: 16),

                  // Section 3: Lý do & Tài liệu minh chứng
                  _buildReasonAndProofSection(),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: submitState.isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E65D0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: submitState.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Nộp đơn xin vắng / hoãn thi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Tab 2: Lịch sử nộp đơn
          _buildHistoryTab(historyAsync),
        ],
      ),
    );
  }

  Widget _buildNoticeBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF1E65D0), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Quy định: Đơn xin vắng/hoãn thi phải nộp trước giờ thi hoặc trong vòng tối đa 48 giờ kể từ khi ca thi kết thúc. Minh chứng cần rõ ràng (Google Drive hoặc file ảnh/PDF).',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1E3A8A),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfoSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person_pin, color: Color(0xFF1E65D0), size: 22),
                SizedBox(width: 8),
                Text(
                  '1. Thông tin sinh viên',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Họ và tên
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Họ và tên *',
                hintText: 'Nhập họ và tên đầy đủ',
                prefixIcon: const Icon(Icons.badge_outlined),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
              validator: (val) => AbsenceFormValidator.validateFullName(
                val,
                loggedInStudentName: _loggedInStudentName,
              ),
            ),
            const SizedBox(height: 14),

            // Số điện thoại
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Số điện thoại *',
                hintText: 'Ví dụ: 0912345678',
                prefixIcon: const Icon(Icons.phone_outlined),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
              validator: AbsenceFormValidator.validatePhoneNumber,
            ),
            const SizedBox(height: 14),

            // Email trường
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email trường (@e.tlu.edu.vn) *',
                hintText: 'sinhvien@e.tlu.edu.vn',
                prefixIcon: const Icon(Icons.alternate_email),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
              validator: AbsenceFormValidator.validateEmail,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSelectionSection(
    AsyncValue<List<ExamSubjectOption>> subjectsAsync,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.event_note_outlined,
                    color: Color(0xFF1E65D0), size: 22),
                SizedBox(width: 8),
                Text(
                  '2. Môn học & Ca thi xin vắng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            subjectsAsync.when(
              data: (subjects) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<ExamSubjectOption>(
                      initialValue: _selectedSubject,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Chọn môn học & lịch thi *',
                        prefixIcon: const Icon(Icons.school_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        errorText: _dropdownCustomError,
                      ),
                      hint: const Text('Chọn môn học cần xin vắng thi'),
                      items: subjects.map((opt) {
                        return DropdownMenuItem<ExamSubjectOption>(
                          value: opt,
                          child: Text(
                            '${opt.subjectName} (${opt.subjectCode})',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedSubject = val;
                          _dropdownCustomError = null;

                          if (val != null) {
                            // Check 20E2: Enrollment
                            final enrollErr =
                                AbsenceFormValidator.validateStudentInExamList(
                              isInExamList: val.isStudentEnrolled,
                            );
                            if (enrollErr != null) {
                              _dropdownCustomError = enrollErr;
                              return;
                            }

                            // Check 20E3: Deadline
                            final deadlineErr =
                                AbsenceFormValidator.validateExamDeadline(
                              examTime: val.examTime,
                            );
                            if (deadlineErr != null) {
                              _dropdownCustomError = deadlineErr;
                            }
                          }
                        });
                      },
                      validator: (val) =>
                          AbsenceFormValidator.validateSubjectSelected(
                        val?.subjectId,
                      ),
                    ),

                    if (_selectedSubject != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 16, color: Color(0xFF475569)),
                                const SizedBox(width: 6),
                                Text(
                                  'Ca thi: ${_selectedSubject!.examShiftName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16, color: Color(0xFF475569)),
                                const SizedBox(width: 6),
                                Text(
                                  'Thời gian: ${_formatDateTime(_selectedSubject!.examTime)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            if (_selectedSubject!.room != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.meeting_room_outlined,
                                      size: 16, color: Color(0xFF475569)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Phòng thi: ${_selectedSubject!.room}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined,
                                    size: 16, color: Color(0xFFDC2626)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Hạn nộp đơn: ${_formatDateTime(_selectedSubject!.examTime.add(const Duration(hours: 48)))}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFDC2626),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Text(
                'Lỗi tải danh sách môn thi: $err',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonAndProofSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description_outlined,
                    color: Color(0xFF1E65D0), size: 22),
                SizedBox(width: 8),
                Text(
                  '3. Lý do & Minh chứng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Lý do vắng thi (10 - 500 ký tự)
            TextFormField(
              controller: _reasonController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Lý do xin vắng thi *',
                hintText:
                    'Nhập lý do chi tiết (từ 10 đến 500 ký tự). Ví dụ: Nhập viện điều trị, có giấy xác nhận y tế...',
                alignLabelWithHint: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
              validator: AbsenceFormValidator.validateReason,
            ),
            const SizedBox(height: 14),

            // Link tài liệu minh chứng
            TextFormField(
              controller: _proofUrlController,
              decoration: InputDecoration(
                labelText: 'Đường dẫn tài liệu minh chứng (URL) *',
                hintText:
                    'https://drive.google.com/file/d/... hoặc file ảnh/PDF',
                prefixIcon: const Icon(Icons.attachment_rounded),
                helperText:
                    'Chấp nhận link Google Drive hoặc file trực tiếp (.jpg, .png, .pdf)',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
              validator: AbsenceFormValidator.validateProofUrl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(
    AsyncValue<List<AbsenceRequestModel>> historyAsync,
  ) {
    return historyAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_late_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có đơn xin vắng thi nào',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Các đơn xin vắng hoặc hoãn thi bạn gửi sẽ xuất hiện và cập nhật trạng thái tại đây.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return _buildRequestHistoryCard(req);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text(
          'Lỗi khi tải lịch sử: $err',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildRequestHistoryCard(AbsenceRequestModel req) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (req.status.toLowerCase()) {
      case 'approved':
        statusColor = const Color(0xFF2E7D32);
        statusText = 'Đã duyệt';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'rejected':
        statusColor = const Color(0xFFD32F2F);
        statusText = 'Từ chối';
        statusIcon = Icons.cancel_outlined;
        break;
      case 'pending':
      default:
        statusColor = const Color(0xFFED6C02);
        statusText = 'Chờ duyệt';
        statusIcon = Icons.hourglass_top_outlined;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      color: Colors.white,
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
                    req.subjectName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Lịch thi: ${_formatDateTime(req.examTime)}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.chat_bubble_outline,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lý do: ${req.reason}',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ngày gửi: ${_formatDateTime(req.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (req.proofUrl.isNotEmpty)
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Minh chứng: ${req.proofUrl}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.link, size: 14, color: Color(0xFF1E65D0)),
                        SizedBox(width: 4),
                        Text(
                          'Xem minh chứng',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1E65D0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
