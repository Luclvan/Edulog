import 'package:flutter/material.dart';

class ExamTimeRangePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Key? fieldKey;

  const ExamTimeRangePickerField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
    this.fieldKey,
  });

  Future<void> _pickTimeRange(BuildContext context) async {
    // Pick start time
    final pickedStart = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'CHỌN GIỜ BẮT ĐẦU',
      confirmText: 'TIẾP TỤC',
      cancelText: 'HỦY',
    );

    if (pickedStart == null || !context.mounted) return;

    // Pick end time
    final defaultEndMinute = (pickedStart.minute + 90) % 60;
    final defaultEndHour = (pickedStart.hour + ((pickedStart.minute + 90) ~/ 60)) % 24;

    final pickedEnd = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: defaultEndHour, minute: defaultEndMinute),
      helpText: 'CHỌN GIỜ KẾT THÚC',
      confirmText: 'XÁC NHẬN',
      cancelText: 'HỦY',
    );

    if (pickedEnd == null) return;

    final startStr =
        '${pickedStart.hour.toString().padLeft(2, '0')}:${pickedStart.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${pickedEnd.hour.toString().padLeft(2, '0')}:${pickedEnd.minute.toString().padLeft(2, '0')}';

    final formatted = '$startStr - $endStr';
    controller.text = formatted;
    if (onChanged != null) {
      onChanged!(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Giờ thi (HH:mm - HH:mm) *',
        hintText: '09:45 - 12:25',
        prefixIcon: const Icon(Icons.access_time_outlined),
        suffixIcon: IconButton(
          icon: const Icon(Icons.access_time_filled, color: Color(0xFF1976D2)),
          onPressed: () => _pickTimeRange(context),
          tooltip: 'Chọn khung giờ bắt đầu và kết thúc',
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
      ),
      keyboardType: TextInputType.text,
      validator: validator,
      onChanged: onChanged,
    );
  }
}
