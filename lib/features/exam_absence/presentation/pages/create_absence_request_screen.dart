import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/absence_request_validator.dart';
import '../../domain/models/absence_request_model.dart';
import '../controllers/absence_request_controller.dart';

/// Screen for creating an Exam Absence Request (Đơn xin vắng / hoãn thi)
class CreateAbsenceRequestScreen extends ConsumerStatefulWidget {
  final DateTime? mockCurrentDate;
  final String? forcedAccountName;
  final String? forcedStudentId;

  const CreateAbsenceRequestScreen({
    super.key,
    this.mockCurrentDate,
    this.forcedAccountName,
    this.forcedStudentId,
  });

  @override
  ConsumerState<CreateAbsenceRequestScreen> createState() =>
      _CreateAbsenceRequestScreenState();
}

class _CreateAbsenceRequestScreenState
    extends ConsumerState<CreateAbsenceRequestScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields - 100% disposed in dispose()
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _reasonController = TextEditingController();
  final _proofUrlController = TextEditingController();

  ExamSubjectItem? _selectedSubject;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(absenceRequestControllerProvider);
      if (_nameController.text.isEmpty) {
        _nameController.text =
            widget.forcedAccountName ?? state.currentStudentName;
      }
      if (_emailController.text.isEmpty) {
        _emailController.text = state.currentStudentEmail;
      }
      if (_phoneController.text.isEmpty) {
        _phoneController.text = '0987654321';
      }
    });
  }

  @override
  void dispose() {
    // 100% dispose all controllers
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _reasonController.dispose();
    _proofUrlController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Vui lòng kiểm tra và sửa các thông tin chưa hợp lệ'),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final notifier = ref.read(absenceRequestControllerProvider.notifier);
    final success = await notifier.submitAbsenceRequest(
      studentName: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      selectedSubject: _selectedSubject,
      reason: _reasonController.text,
      proofUrl: _proofUrlController.text,
      forcedAccountName: widget.forcedAccountName,
      now: widget.mockCurrentDate,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Nộp đơn xin vắng / hoãn thi thành công!'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Reset form and switch to history tab
      _reasonController.clear();
      _proofUrlController.clear();
      setState(() {
        _selectedSubject = null;
      });
      _tabController.animateTo(1);
    } else {
      final state = ref.read(absenceRequestControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.errorMessage ?? 'Không thể gửi đơn, vui lòng thử lại',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[800],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(absenceRequestControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Đơn Xin Vắng / Hoãn Thi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(
              icon: Icon(Icons.edit_document),
              text: 'Tạo đơn mới',
            ),
            Tab(
              icon: const Icon(Icons.history_edu),
              text: 'Lịch sử đơn (${state.requests.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: FORM TẠO ĐƠN
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner hướng dẫn
                  _buildNoticeBanner(),
                  const SizedBox(height: 16),

                  // Section 1: Thông tin sinh viên
                  _buildStudentInfoSection(state),
                  const SizedBox(height: 16),

                  // Section 2: Môn học và ca thi
                  _buildExamSelectionSection(state),
                  const SizedBox(height: 16),

                  // Section 3: Lý do & Minh chứng
                  _buildReasonAndProofSection(),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: state.isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'GỬI ĐƠN XIN VẮNG THI',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
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

          // TAB 2: LỊCH SỬ ĐƠN ĐÃ GỬI
          _buildRequestHistoryTab(state, theme),
        ],
      ),
    );
  }

  Widget _buildNoticeBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue[800], size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Quy định: Đơn xin vắng/hoãn thi phải được nộp trước giờ thi hoặc không quá 48 giờ sau khi kết thúc ca thi kèm theo minh chứng hợp lệ (Google Drive / Ảnh / PDF).',
              style: TextStyle(
                color: Colors.blue[900],
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfoSection(AbsenceRequestState state) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.blue[800]),
                const SizedBox(width: 8),
                const Text(
                  'Thông tin sinh viên',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Field 1: Họ và tên
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Họ và tên *',
                hintText: 'Nhập họ và tên sinh viên',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              validator: (val) => AbsenceRequestValidator.validateFullName(
                val,
                accountFullName:
                    widget.forcedAccountName ?? state.currentStudentName,
              ),
            ),
            const SizedBox(height: 14),

            // Field 2: Số điện thoại
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Số điện thoại liên hệ *',
                hintText: 'VD: 0912345678',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              validator: AbsenceRequestValidator.validatePhone,
            ),
            const SizedBox(height: 14),

            // Field 3: Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email trường (@e.tlu.edu.vn) *',
                hintText: 'VD: 2351170568@e.tlu.edu.vn',
                prefixIcon: const Icon(Icons.mail_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              validator: AbsenceRequestValidator.validateEmail,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamSelectionSection(AbsenceRequestState state) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_outlined, color: Colors.blue[800]),
                const SizedBox(width: 8),
                const Text(
                  'Môn học & Ca thi xin vắng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Dropdown chọn môn học
            DropdownButtonFormField<ExamSubjectItem>(
              initialValue: _selectedSubject,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Chọn môn học xin vắng thi *',
                prefixIcon: const Icon(Icons.menu_book_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              items: state.availableSubjects.map((subject) {
                return DropdownMenuItem<ExamSubjectItem>(
                  value: subject,
                  child: Text(
                    '${subject.subjectName} (${subject.subjectId})',
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (item) {
                setState(() {
                  _selectedSubject = item;
                });
              },
              validator: (item) => AbsenceRequestValidator.validateSubjectSelection(
                item,
                now: widget.mockCurrentDate,
              ),
            ),

            if (_selectedSubject != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.schedule,
                      'Ca thi:',
                      _selectedSubject!.examShiftName,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      Icons.event,
                      'Thời gian thi:',
                      '${_selectedSubject!.examTime.day.toString().padLeft(2, '0')}/${_selectedSubject!.examTime.month.toString().padLeft(2, '0')}/${_selectedSubject!.examTime.year} ${_selectedSubject!.examTime.hour.toString().padLeft(2, '0')}:${_selectedSubject!.examTime.minute.toString().padLeft(2, '0')}',
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      Icons.verified_user_outlined,
                      'Trạng thái dự thi:',
                      _selectedSubject!.isRegistered
                          ? 'Đã đăng ký trong danh sách'
                          : 'Chưa có tên trong danh sách',
                      valueColor: _selectedSubject!.isRegistered
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReasonAndProofSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attachment_outlined, color: Colors.blue[800]),
                const SizedBox(width: 8),
                const Text(
                  'Lý do & Tài liệu minh chứng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Field 4: Lý do vắng thi
            TextFormField(
              controller: _reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Lý do xin vắng thi *',
                hintText: 'Nhập chi tiết lý do (10 - 500 ký tự)...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
              validator: AbsenceRequestValidator.validateReason,
            ),
            const SizedBox(height: 14),

            // Field 5: Link minh chứng
            TextFormField(
              controller: _proofUrlController,
              decoration: InputDecoration(
                labelText: 'Đường dẫn minh chứng (Google Drive / Ảnh / PDF) *',
                hintText: 'https://drive.google.com/file/d/... hoặc link ảnh/pdf',
                prefixIcon: const Icon(Icons.link),
                helperText:
                    'Chấp nhận link Google Drive hoặc file trực tiếp (.jpg, .jpeg, .png, .pdf)',
                helperMaxLines: 2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              validator: AbsenceRequestValidator.validateProofUrl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestHistoryTab(AbsenceRequestState state, ThemeData theme) {
    if (state.requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Chưa có đơn xin vắng thi nào được gửi',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.requests.length,
      itemBuilder: (context, index) {
        final req = state.requests[index];
        final badgeColor = req.status == AbsenceRequestStatus.approved
            ? Colors.green
            : req.status == AbsenceRequestStatus.rejected
                ? Colors.red
                : Colors.orange;

        return Card(
          elevation: 1.5,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        req.status.label,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Lý do: ${req.reason}',
                  style: TextStyle(fontSize: 13.5, color: Colors.grey[800]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.link, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        req.proofUrl,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (req.createdAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Ngày tạo: ${req.createdAt!.day.toString().padLeft(2, '0')}/${req.createdAt!.month.toString().padLeft(2, '0')}/${req.createdAt!.year}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
