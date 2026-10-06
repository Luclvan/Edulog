import 'package:flutter/material.dart';

class AppealDatePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Key? fieldKey;

  const AppealDatePickerField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
    this.fieldKey,
  });

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: now, // Exam date cannot be in future [9E3]
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
        hintText: '01/10/2026',
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month, color: Color(0xFF1976D2)),
          onPressed: () => _pickDate(context),
          tooltip: 'Chọn ngày thi từ lịch',
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      keyboardType: TextInputType.datetime,
      validator: validator,
      onChanged: onChanged,
    );
  }
}
