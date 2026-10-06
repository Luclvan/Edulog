import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/grade_appeal_validator.dart';
import '../../domain/models/grade_appeal_model.dart';
import '../providers/grade_appeal_provider.dart';
import '../widgets/appeal_date_picker_field.dart';

class CreateAppealScreen extends ConsumerStatefulWidget {
  final DateTime? mockCurrentDate; // For deterministic testing of past/future dates & deadlines
  final String? forcedAccountName; // For cross-validation testing [5E6]
  final String? forcedAccountId;   // For cross-validation testing [6E4]

  const CreateAppealScreen({
    super.key,
    this.mockCurrentDate,
    this.forcedAccountName,
    this.forcedAccountId,
  });

  @override
  ConsumerState<CreateAppealScreen> createState() => _CreateAppealScreenState();
}

class _CreateAppealScreenState extends ConsumerState<CreateAppealScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _scoreController = TextEditingController();
  final _dateController = TextEditingController();
  final _subjectController = TextEditingController();
  final _shiftController = TextEditingController();
  final _reasonController = TextEditingController();

  String? _selectedSubjectCode;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(gradeAppealNotifierProvider);
      if (_nameController.text.isEmpty) {
        _nameController.text = state.currentStudentName;
      }
      if (_studentIdController.text.isEmpty) {
        _studentIdController.text = state.currentStudentId;
      }
      if (_emailController.text.isEmpty) {
        _emailController.text = state.currentStudentEmail;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _scoreController.dispose();
    _dateController.dispose();
    _subjectController.dispose();
    _shiftController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _onSubjectSelected(AppealSubjectItem subject) {
    setState(() {
      _subjectController.text = subject.name;
      _selectedSubjectCode = subject.code;
      if (subject.actualExamDate.isNotEmpty) {
        _dateController.text = subject.actualExamDate;
      }
      if (subject.assignedShift.isNotEmpty) {
        _shiftController.text = subject.assignedShift;
      }
      if (subject.publishedScore != null) {
        _scoreController.text = subject.publishedScore.toString();
      }
    });
  }

  void _onShiftSelected(String shift) {
    setState(() {
      _shiftController.text = shift;
    });
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng kiểm tra lại các thông tin chưa hợp lệ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    final studentId = _studentIdController.text.trim();
    final email = _emailController.text.trim();
    final score = double.tryParse(_scoreController.text.trim()) ?? 0.0;
    final date = _dateController.text.trim();
    final subject = _subjectController.text.trim();
    final shift = _shiftController.text.trim();
    final reason = _reasonController.text.trim();

    final notifier = ref.read(gradeAppealNotifierProvider.notifier);

    final success = await notifier.submitAppeal(
      studentName: name,
      studentId: studentId,
      studentEmail: email,
      currentScore: score,
      examDate: date,
      subjectName: subject,
      subjectCode: _selectedSubjectCode,
      examShift: shift,
      reason: reason.isNotEmpty ? reason : null,
      now: widget.mockCurrentDate,
      forcedAccountName: widget.forcedAccountName,
      forcedAccountId: widget.forcedAccountId,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final state = ref.read(gradeAppealNotifierProvider);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(state.successMessage ?? 'Tạo đơn phúc khảo thành công!'),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      Navigator.of(context).maybePop(true);
    } else {
      final error = state.errorMessage ?? 'Có lỗi xảy ra khi gửi đơn phúc khảo';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(error)),
            ],
          ),
          backgroundColor: const Color(0xFFD32F2F),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appealState = ref.watch(gradeAppealNotifierProvider);
    final accountName = widget.forcedAccountName ?? appealState.currentStudentName;
    final accountId = widget.forcedAccountId ?? appealState.currentStudentId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Tạo Đơn Phúc Khảo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info banner
                Card(
                  elevation: 0,
                  color: const Color(0xFFE3F2FD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF1565C0)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sinh viên kiểm tra kỹ thông tin trước khi gửi. Đơn chỉ được tiếp nhận trong vòng 15 ngày kể từ ngày thi theo quy chế đào tạo.',
                            style: TextStyle(
                              color: Color(0xFF0D47A1),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Error Banner if error in state
                if (appealState.errorMessage != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            appealState.errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFC62828),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ==================== 1. HỌ VÀ TÊN ====================
                const Text(
                  '1. Họ và tên *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('student_name_field'),
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Nguyễn Thị Cẩm Ly',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: (val) => GradeAppealValidator.validateFullName(
                    val,
                    accountFullName: accountName,
                  ),
                ),
                const SizedBox(height: 18),

                // ==================== 2. MÃ SINH VIÊN ====================
                const Text(
                  '2. Mã sinh viên (10 chữ số) *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('student_id_field'),
                  controller: _studentIdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '2351170568',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: (val) => GradeAppealValidator.validateStudentId(
                    val,
                    accountStudentId: accountId,
                  ),
                ),
                const SizedBox(height: 18),

                // ==================== 3. EMAIL SINH VIÊN ====================
                const Text(
                  '3. Email sinh viên (@e.tlu.edu.vn) *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('student_email_field'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: '2351170568@e.tlu.edu.vn',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: GradeAppealValidator.validateEmail,
                ),
                const SizedBox(height: 18),

                // ==================== 4. ĐIỂM THI HIỆN TẠI ====================
                const Text(
                  '4. Điểm thi hiện tại (0.0 - 10.0) *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('current_score_field'),
                  controller: _scoreController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: 6.5',
                    prefixIcon: const Icon(Icons.grade_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: GradeAppealValidator.validateCurrentScore,
                ),
                const SizedBox(height: 18),

                // ==================== 5. NGÀY THI ====================
                const Text(
                  '5. Ngày thi (DD/MM/YYYY) *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                AppealDatePickerField(
                  fieldKey: const Key('exam_date_field'),
                  controller: _dateController,
                  validator: (val) => GradeAppealValidator.validateExamDate(
                    val,
                    now: widget.mockCurrentDate,
                  ),
                ),
                const SizedBox(height: 18),

                // ==================== 6. MÔN THI ====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '6. Môn thi *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (appealState.availableSubjects.isNotEmpty)
                      PopupMenuButton<AppealSubjectItem>(
                        tooltip: 'Chọn môn thi',
                        icon: const Icon(Icons.menu_book_outlined,
                            size: 18, color: Color(0xFF1976D2)),
                        onSelected: _onSubjectSelected,
                        itemBuilder: (context) => appealState.availableSubjects
                            .map((s) => PopupMenuItem(
                                  value: s,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      Text(
                                        'Mã: ${s.code} | Điểm: ${s.publishedScore != null ? s.publishedScore.toString() : "Chưa có"} | Ca: ${s.assignedShift}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('subject_name_field'),
                  controller: _subjectController,
                  decoration: InputDecoration(
                    hintText: 'Kiểm thử phần mềm',
                    prefixIcon: const Icon(Icons.subject_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: GradeAppealValidator.validateSubjectName,
                ),
                const SizedBox(height: 18),

                // ==================== 7. CA THI ====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '7. Ca thi *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Chọn ca thi',
                      icon: const Icon(Icons.access_time_outlined,
                          size: 18, color: Color(0xFF1976D2)),
                      onSelected: _onShiftSelected,
                      itemBuilder: (context) => GradeAppealValidator.validExamShifts
                          .map((shift) => PopupMenuItem(
                                value: shift,
                                child: Text(shift, style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('exam_shift_field'),
                  controller: _shiftController,
                  decoration: InputDecoration(
                    hintText: 'Ca 1, Ca 2 hoặc 4-6',
                    prefixIcon: const Icon(Icons.schedule_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: GradeAppealValidator.validateExamShift,
                ),
                const SizedBox(height: 18),

                // ==================== LÝ DO PHÚC KHẢO (OPTIONAL) ====================
                const Text(
                  'Lý do phúc khảo (Tùy chọn)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('appeal_reason_field'),
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Trình bày lý do hoặc câu hỏi cần chấm lại...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ==================== ACTION BUTTON ====================
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    key: const Key('submit_appeal_button'),
                    onPressed: (_isSubmitting || appealState.isLoading) ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: (_isSubmitting || appealState.isLoading)
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Gửi đơn phúc khảo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
