import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import '../../../core/utils/auth_validator.dart';

class RegisterScreen extends StatefulWidget {
  final bool isMicrosoftAccount; 
  final String? initialEmail;
  final String? initialName;

  const RegisterScreen({
    super.key, 
    this.isMicrosoftAccount = false,
    this.initialEmail,
    this.initialName,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final IAuthService _authService = AuthService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  String _selectedRole = 'sinh_vien';
  bool _isLoading = false;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _studentIdError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _studentIdController.dispose();
    _classController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _studentIdError = null;
    });

    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Async uniqueness check for Student ID
      if (_selectedRole == 'sinh_vien') {
        final idTaken = await AuthValidator.isStudentIdRegistered(_studentIdController.text.trim());
        if (idTaken) {
          setState(() {
            _studentIdError = "Mã sinh viên đã được đăng ký";
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mã sinh viên đã được đăng ký'), backgroundColor: Colors.red),
            );
          }
          return;
        }
      }

      // Async uniqueness check for Email in Firestore
      if (!widget.isMicrosoftAccount) {
        final emailTaken = await AuthValidator.isEmailRegisteredInFirestore(_emailController.text.trim());
        if (emailTaken) {
          setState(() {
            _emailError = "Email này đã được đăng ký tài khoản";
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email này đã được đăng ký tài khoản'), backgroundColor: Colors.red),
            );
          }
          return;
        }
      }

      if (widget.isMicrosoftAccount) {
        await _authService.saveMicrosoftUserProfile(
          role: _selectedRole,
          studentId: _selectedRole == 'sinh_vien' ? _studentIdController.text.trim() : null,
          classId: _selectedRole == 'sinh_vien' ? _classController.text.trim() : null,
          department: _selectedRole == 'giang_vien' ? _departmentController.text.trim() : null,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật hồ sơ thành công!'), backgroundColor: Colors.green),
        );
      } else {
        await _authService.registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          role: _selectedRole,
          studentId: _selectedRole == 'sinh_vien' ? _studentIdController.text.trim() : null,
          classId: _selectedRole == 'sinh_vien' ? _classController.text.trim() : null,
          department: _selectedRole == 'giang_vien' ? _departmentController.text.trim() : null,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công! Vui lòng kiểm tra email trường (kể cả hộp thư rác) để xác thực tài khoản.'), 
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
      Navigator.pop(context); 
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        setState(() {
          if (msg.contains('Email này đã được đăng ký')) {
            _emailError = 'Email này đã được đăng ký tài khoản';
          }
          if (msg.contains('Mã sinh viên đã được đăng ký')) {
            _studentIdError = 'Mã sinh viên đã được đăng ký';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.isMicrosoftAccount ? 'Bổ sung thông tin' : 'Đăng ký tài khoản'),
        backgroundColor: const Color(0xFF1E65D0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.isMicrosoftAccount)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                  child: const Text(
                    'Đăng nhập Outlook thành công! Vui lòng chọn phân quyền để hoàn tất hồ sơ EduLog.',
                    style: TextStyle(color: Color(0xFF1E65D0)),
                  ),
                ),

              const Text('Bạn là:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'sinh_vien', label: Text('Sinh viên')),
                  ButtonSegment(value: 'giang_vien', label: Text('Giảng viên')),
                ],
                selected: {_selectedRole},
                onSelectionChanged: (Set<String> newSelection) => setState(() => _selectedRole = newSelection.first),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: 'Họ và tên (VD: Đỗ Đình An)',
                  border: const OutlineInputBorder(),
                  errorText: _nameError,
                  errorMaxLines: 2,
                ),
                validator: AuthValidator.validateFullName,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),
              const SizedBox(height: 16),

              if (!widget.isMicrosoftAccount) ...[
                TextFormField(
                  controller: _emailController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email trường (@e.tlu.edu.vn)',
                    border: const OutlineInputBorder(),
                    errorText: _emailError,
                    errorMaxLines: 2,
                  ),
                  validator: AuthValidator.validateEmail,
                  onChanged: (_) {
                    if (_emailError != null) setState(() => _emailError = null);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    border: const OutlineInputBorder(),
                    errorText: _passwordError,
                    errorMaxLines: 2,
                  ),
                  validator: AuthValidator.validatePassword,
                  onChanged: (_) {
                    if (_passwordError != null) setState(() => _passwordError = null);
                  },
                ),
                const SizedBox(height: 16),
              ],

              if (_selectedRole == 'sinh_vien') ...[
                TextFormField(
                  controller: _studentIdController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Mã sinh viên (VD: 2351170568)',
                    border: const OutlineInputBorder(),
                    errorText: _studentIdError,
                    errorMaxLines: 2,
                  ),
                  validator: (val) {
                    if (_selectedRole == 'sinh_vien') {
                      return AuthValidator.validateStudentId(val);
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (_studentIdError != null) setState(() => _studentIdError = null);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _classController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(labelText: 'Lớp sinh hoạt (VD: KTPM K65)', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập Lớp' : null,
                ),
              ] else ...[
                TextFormField(
                  controller: _departmentController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(labelText: 'Khoa / Bộ môn', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập Khoa' : null,
                ),
              ],
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E65D0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.isMicrosoftAccount ? 'HOÀN TẤT HỒ SƠ' : 'ĐĂNG KÝ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}