import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/exam_session_validator.dart';
import '../../domain/models/exam_session_model.dart';
import '../providers/exam_session_provider.dart';
import '../widgets/exam_date_picker_field.dart';
import '../widgets/exam_time_range_picker.dart';

class AddExamSessionScreen extends ConsumerStatefulWidget {
  final DateTime? mockCurrentDate; // For deterministic unit/widget testing of past dates

  const AddExamSessionScreen({
    super.key,
    this.mockCurrentDate,
  });

  @override
  ConsumerState<AddExamSessionScreen> createState() => _AddExamSessionScreenState();
}

class _AddExamSessionScreenState extends ConsumerState<AddExamSessionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _examTermController = TextEditingController();
  final _courseNameController = TextEditingController();
  final _creditsController = TextEditingController();
  final _examDateController = TextEditingController();
  final _periodController = TextEditingController();
  final _examTimeController = TextEditingController();
  final _roomCodeController = TextEditingController();
  final _teacherController = TextEditingController();

  String? _selectedTeacherId;
  String? _selectedCourseCode;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _examTermController.dispose();
    _courseNameController.dispose();
    _creditsController.dispose();
    _examDateController.dispose();
    _periodController.dispose();
    _examTimeController.dispose();
    _roomCodeController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // 1. Run synchronous form validations
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng kiểm tra lại các trường thông tin chưa hợp lệ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final term = _examTermController.text.trim();
    final course = _courseNameController.text.trim();
    final credits = int.tryParse(_creditsController.text.trim()) ?? 0;
    final date = _examDateController.text.trim();
    final period = _periodController.text.trim();
    final time = _examTimeController.text.trim();
    final room = _roomCodeController.text.trim();
    final teacher = _teacherController.text.trim();

    final notifier = ref.read(examSessionNotifierProvider.notifier);

    final success = await notifier.createExamSession(
      examTermName: term,
      courseName: course,
      credits: credits,
      examDate: date,
      sessionPeriod: period,
      examTime: time,
      roomCode: room,
      teacherName: teacher,
      teacherId: _selectedTeacherId,
      courseCode: _selectedCourseCode,
      now: widget.mockCurrentDate,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final state = ref.read(examSessionNotifierProvider);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(state.successMessage ?? 'Tạo ca thi thành công!'),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32), // Green
        ),
      );

      // Return to previous screen or clear form
      Navigator.of(context).maybePop(true);
    } else {
      final error = state.errorMessage ?? 'Có lỗi xảy ra khi tạo ca thi';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(error)),
            ],
          ),
          backgroundColor: const Color(0xFFD32F2F), // Red
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _onCourseSelected(String name, String code, int credits) {
    setState(() {
      _courseNameController.text = name;
      _selectedCourseCode = code;
      _creditsController.text = credits.toString();
    });
  }

  void _onRoomSelected(String roomCode) {
    setState(() {
      _roomCodeController.text = roomCode;
    });
  }

  void _onTeacherSelected(String name, String id) {
    setState(() {
      _teacherController.text = name;
      _selectedTeacherId = id;
    });
  }

  void _onExamTermSelected(String termName) {
    setState(() {
      _examTermController.text = termName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(examSessionNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Thêm Ca Thi Mới',
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
                // Header Information Card
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
                            'Điền đầy đủ thông tin ca thi theo chuẩn kiểm thử phần mềm. Hệ thống sẽ kiểm tra đối chiếu lịch trùng và tính hợp lệ.',
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

                // Error Banner if state has error
                if (sessionState.errorMessage != null) ...[
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
                            sessionState.errorMessage!,
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

                // ==================== 1. TÊN ĐỢT THI ====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '1. Tên đợt thi *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (sessionState.examTerms.isNotEmpty)
                      PopupMenuButton<String>(
                        tooltip: 'Gợi ý đợt thi',
                        icon: const Icon(Icons.arrow_drop_down_circle_outlined,
                            size: 18, color: Color(0xFF1976D2)),
                        onSelected: _onExamTermSelected,
                        itemBuilder: (context) => sessionState.examTerms
                            .map((t) => PopupMenuItem(
                                  value: t.name,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(t.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      Text(
                                        'Hiệu lực: ${t.startDate.day.toString().padLeft(2, '0')}/${t.startDate.month.toString().padLeft(2, '0')}/${t.startDate.year} - ${t.endDate.day.toString().padLeft(2, '0')}/${t.endDate.month.toString().padLeft(2, '0')}/${t.endDate.year}',
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
                  key: const Key('exam_term_field'),
                  controller: _examTermController,
                  decoration: InputDecoration(
                    hintText: 'K65_Lich_Thi_HK2_GĐ1_NH_2025-2026',
                    prefixIcon: const Icon(Icons.campaign_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: ExamSessionValidator.validateExamTermName,
                  onChanged: (_) => setState(() {}),
                ),
                // Hiển thị khoảng thời gian hiệu lực của đợt thi nếu khớp
                Builder(builder: (context) {
                  final termName = _examTermController.text.trim();
                  final matched = sessionState.examTerms.where((t) => t.name.trim() == termName);
                  if (matched.isEmpty) return const SizedBox.shrink();
                  final t = matched.first;
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month, size: 16, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 6),
                        Text(
                          'Hiệu lực: ${t.startDate.day.toString().padLeft(2, '0')}/${t.startDate.month.toString().padLeft(2, '0')}/${t.startDate.year} - ${t.endDate.day.toString().padLeft(2, '0')}/${t.endDate.month.toString().padLeft(2, '0')}/${t.endDate.year}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 18),

                // ==================== 2. TÊN MÔN HỌC ====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '2. Tên môn học *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (sessionState.courses.isNotEmpty)
                      PopupMenuButton<CourseCatalogItem>(
                        tooltip: 'Chọn từ danh mục môn học',
                        icon: const Icon(Icons.list_alt, size: 18, color: Color(0xFF1976D2)),
                        onSelected: (course) => _onCourseSelected(course.name, course.code, course.credits),
                        itemBuilder: (context) => sessionState.courses
                            .map((c) => PopupMenuItem(
                                  value: c,
                                  child: Text('${c.name} (${c.code} - ${c.credits}TC)',
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('course_name_field'),
                  controller: _courseNameController,
                  decoration: InputDecoration(
                    hintText: 'Kiểm thử phần mềm',
                    prefixIcon: const Icon(Icons.book_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: ExamSessionValidator.validateCourseName,
                ),
                const SizedBox(height: 18),

                // ==================== 3. SỐ TÍN CHỈ ====================
                const Text(
                  '3. Số tín chỉ (1 - 5) *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('credits_field'),
                  controller: _creditsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '1 - 5',
                    prefixIcon: const Icon(Icons.numbers_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: ExamSessionValidator.validateCredits,
                ),
                const SizedBox(height: 18),

                // ==================== 4. NGÀY THI ====================
                const Text(
                  '4. Ngày thi (DD/MM/YYYY) *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Builder(builder: (context) {
                  final termName = _examTermController.text.trim();
                  final matched = sessionState.examTerms.where((t) => t.name.trim() == termName);
                  final t = matched.isNotEmpty ? matched.first : null;
                  return ExamDatePickerField(
                    fieldKey: const Key('exam_date_field'),
                    controller: _examDateController,
                    firstDate: t?.startDate,
                    lastDate: t?.endDate,
                    validator: (val) => ExamSessionValidator.validateExamDate(
                      val,
                      now: widget.mockCurrentDate,
                      termStartDate: t?.startDate,
                      termEndDate: t?.endDate,
                    ),
                  );
                }),
                const SizedBox(height: 18),

                // ==================== 5. CA THI (TIẾT HỌC) ====================
                const Text(
                  '5. Ca thi / Tiết thi *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('session_period_field'),
                  controller: _periodController,
                  decoration: InputDecoration(
                    hintText: '4-6 hoặc 1-3',
                    prefixIcon: const Icon(Icons.timer_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: ExamSessionValidator.validateSessionPeriod,
                  onChanged: (_) {
                    // Revalidate time field if already entered
                    if (_examTimeController.text.isNotEmpty) {
                      _formKey.currentState?.validate();
                    }
                  },
                ),
                const SizedBox(height: 18),

                // ==================== 6. GIỜ THI ====================
                const Text(
                  '6. Giờ thi (HH:mm - HH:mm) *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                ExamTimeRangePickerField(
                  fieldKey: const Key('exam_time_field'),
                  controller: _examTimeController,
                  validator: (val) => ExamSessionValidator.validateExamTime(
                    val,
                    sessionPeriod: _periodController.text,
                  ),
                ),
                const SizedBox(height: 18),

                // ==================== 7. PHÒNG THI ====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '7. Phòng thi *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (sessionState.rooms.isNotEmpty)
                      PopupMenuButton<String>(
                        tooltip: 'Chọn phòng thi',
                        icon: const Icon(Icons.meeting_room_outlined,
                            size: 18, color: Color(0xFF1976D2)),
                        onSelected: _onRoomSelected,
                        itemBuilder: (context) => sessionState.rooms
                            .map((r) => PopupMenuItem(
                                  value: r.code,
                                  child: Text(
                                    '${r.code} (Nhà ${r.building})${r.isUnderMaintenance ? " [Bảo trì]" : ""}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: r.isUnderMaintenance ? Colors.red : Colors.black87,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('room_code_field'),
                  controller: _roomCodeController,
                  decoration: InputDecoration(
                    hintText: '131-A2',
                    prefixIcon: const Icon(Icons.room_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: ExamSessionValidator.validateRoomCode,
                ),
                const SizedBox(height: 18),

                // ==================== 8. GIẢNG VIÊN CHẤM THI ====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '8. Giảng viên chấm thi *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (sessionState.teachers.isNotEmpty)
                      PopupMenuButton<TeacherRegistryItem>(
                        tooltip: 'Chọn giảng viên',
                        icon: const Icon(Icons.person_search_outlined,
                            size: 18, color: Color(0xFF1976D2)),
                        onSelected: (t) => _onTeacherSelected(t.name, t.id),
                        itemBuilder: (context) => sessionState.teachers
                            .map((t) => PopupMenuItem(
                                  value: t,
                                  child: Text('${t.name} (${t.id} - ${t.department})',
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('teacher_field'),
                  controller: _teacherController,
                  decoration: InputDecoration(
                    hintText: 'TS. Lê Văn Lực',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: ExamSessionValidator.validateTeacher,
                ),
                const SizedBox(height: 32),

                // ==================== 9. ACTION BUTTON ====================
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    key: const Key('create_session_button'),
                    onPressed: (_isSubmitting || sessionState.isLoading)
                        ? null
                        : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0), // Darker blue
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: (_isSubmitting || sessionState.isLoading)
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Tạo ca thi',
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
