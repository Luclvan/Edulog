import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/group_validator.dart';
import '../providers/group_management_provider.dart';
import '../screens/group_detail_screen.dart';

class CreateGroupBottomSheet extends StatefulWidget {
  final String classId;

  const CreateGroupBottomSheet({super.key, required this.classId});

  @override
  State<CreateGroupBottomSheet> createState() => _CreateGroupBottomSheetState();
}

class _CreateGroupBottomSheetState extends State<CreateGroupBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _githubController = TextEditingController();
  final _docsController = TextEditingController();

  bool _isCreating = false;
  String? _nameError;
  String? _githubError;
  String? _docsError;
  String? _generalError;

  @override
  void dispose() {
    _nameController.dispose();
    _githubController.dispose();
    _docsController.dispose();
    super.dispose();
  }

  void _onCreate() async {
    // Clear previous async errors
    setState(() {
      _nameError = null;
      _githubError = null;
      _docsError = null;
      _generalError = null;
    });

    // Run synchronous validations (1E2-1E5, 2E2-2E5, 3E2-3E4)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    if (mounted) {
      final provider = context.read<GroupManagementProvider>();
      final navigator = Navigator.of(context);
      try {
        // Run asynchronous checks (1E1, 2E1, 2E6, 3E1, 3E5) and create group
        final newGroup = await provider.createGroup(
          widget.classId,
          _nameController.text.trim(),
          _githubController.text.trim(),
          _docsController.text.trim(),
        );

        // 1. Fetch updated group list and set current group
        await provider.fetchGroups(widget.classId);
        provider.selectGroup(newGroup);

        // 2. Close bottom sheet
        navigator.pop();

        // 3. Navigate to group detail screen
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => GroupDetailScreen(classId: widget.classId),
          ),
        );
      } on GroupValidationException catch (e) {
        if (mounted) {
          setState(() {
            _isCreating = false;
            _generalError = e.message;
            if (e.field == 'name') _nameError = e.message;
            if (e.field == 'github') _githubError = e.message;
            if (e.field == 'docs') _docsError = e.message;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isCreating = false;
            _generalError = e.toString().replaceFirst('Exception: ', '');
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $_generalError'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tạo Nhóm',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              if (_generalError != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _generalError!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildInputLabel('TÊN NHÓM *'),
              _buildTextFormField(
                controller: _nameController,
                hintText: 'Ví dụ: Nhóm 6 - App EduLog',
                icon: Icons.people_outline,
                validator: GroupValidator.validateGroupName,
                errorText: _nameError,
                onChanged: (_) {
                  if (_nameError != null) {
                    setState(() {
                      _nameError = null;
                      _generalError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildInputLabel('GITHUB REPOSITORY *'),
              _buildTextFormField(
                controller: _githubController,
                hintText: 'https://github.com/user/repo',
                icon: Icons.code,
                validator: GroupValidator.validateGithubUrl,
                errorText: _githubError,
                onChanged: (_) {
                  if (_githubError != null) {
                    setState(() {
                      _githubError = null;
                      _generalError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildInputLabel('GOOGLE DOCS *'),
              _buildTextFormField(
                controller: _docsController,
                hintText: 'https://docs.google.com/document/d/...',
                icon: Icons.description_outlined,
                validator: GroupValidator.validateDocsUrl,
                errorText: _docsError,
                onChanged: (_) {
                  if (_docsError != null) {
                    setState(() {
                      _docsError = null;
                      _generalError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCreating ? null : _onCreate,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add),
                  label: Text(
                    _isCreating ? 'Đang kiểm tra & tạo nhóm...' : 'Tạo nhóm',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String?)? validator,
    String? errorText,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
        errorText: errorText,
        errorMaxLines: 3,
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }
}
