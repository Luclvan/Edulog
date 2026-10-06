import 'package:flutter/material.dart';

class ExamDatePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Key? fieldKey;

  const ExamDatePickerField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
    this.fieldKey,
  });

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year, now.month, now.day + 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('vi', 'VN'),
      helpText: 'CHỌN NGÀY THI',
      confirmText: 'CHỌN',
      cancelText: 'HỦY',
    );

    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      controller.text = formatted;
      if (onChanged != null) {
        onChanged!(formatted);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Ngày thi (DD/MM/YYYY) *',
        hintText: '15/10/2026',
        prefixIcon: const Icon(Icons.event_outlined),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month, color: Color(0xFF1976D2)),
          onPressed: () => _pickDate(context),
          tooltip: 'Chọn ngày thi từ lịch',
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
      keyboardType: TextInputType.datetime,
      validator: validator,
      onChanged: onChanged,
    );
  }
}
