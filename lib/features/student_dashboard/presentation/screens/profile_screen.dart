import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/utils/identity_validator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _user;
  bool _isLoading = true;
  bool _isSaving = false;

  String? _githubError;
  String? _googleDocsError;

  final TextEditingController _githubController = TextEditingController();
  final TextEditingController _googleDocsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _githubController.dispose();
    _googleDocsController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          setState(() {
            _user = UserModel.fromMap(doc.data()!, uid);
            _githubController.text = _user?.githubUsername ?? '';
            _googleDocsController.text = _user?.googleDisplayName ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải hồ sơ: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _githubError = null;
      _googleDocsError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final githubUsername = _githubController.text.trim();
      final googleDisplayName = _googleDocsController.text.trim();

      // [16E6] Online GitHub API verification (Async)
      final ghApiError = await IdentityValidator.verifyGithubUserExists(githubUsername);
      if (ghApiError != null) {
        setState(() {
          _githubError = ghApiError;
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ghApiError), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // [16E7] Uniqueness in Group/Class: Check Firestore if another student claimed this username
      final isClaimed = await IdentityValidator.isGithubUsernameClaimed(
        githubUsername,
        uid,
        classId: _user?.className,
        firestore: _firestore,
      );
      if (isClaimed) {
        const errorMsg = "Tài khoản GitHub này đã được sử dụng bởi thành viên khác";
        setState(() {
          _githubError = errorMsg;
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // [17E] Author revision check (Async): Verify against Google Docs history if group has linked docs
      final groupQuery = await _firestore
          .collection('groups')
          .where('thanh_vien', arrayContains: uid)
          .limit(1)
          .get();

      if (groupQuery.docs.isNotEmpty) {
        final groupData = groupQuery.docs.first.data();
        final docsStats = groupData['docsStats'] as List<dynamic>?;
        final docsLink = groupData['link_docs'] as String?;

        if ((docsStats != null && docsStats.isNotEmpty) || (docsLink != null && docsLink.isNotEmpty)) {
          final authorError = await IdentityValidator.verifyGoogleDocsAuthor(
            googleDisplayName,
            docsStats: docsStats,
            docsLink: docsLink,
          );
          if (authorError != null) {
            setState(() {
              _googleDocsError = authorError;
              _isSaving = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(authorError), backgroundColor: Colors.red),
              );
            }
            return;
          }
        }
      }

      // Save to Firestore
      await _firestore.collection('users').doc(uid).update({
        'github_username': githubUsername,
        'google_display_name': googleDisplayName,
      });

      setState(() {
        _user = _user?.copyWith(
          githubUsername: githubUsername,
          googleDisplayName: googleDisplayName,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF1E65D0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('HỒ SƠ CÁ NHÂN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card with Avatar
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: themeColor.withValues(alpha: 0.1),
                            child: Icon(Icons.person, size: 40, color: themeColor),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _user?.name ?? 'Người dùng',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _user?.email ?? '',
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Information Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'THÔNG TIN HỌC TẬP',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 16),
                          _buildReadOnlyField(
                            label: 'Mã sinh viên',
                            value: _user?.studentId ?? 'N/A',
                            icon: Icons.badge_outlined,
                          ),
                          const Divider(height: 24),
                          _buildReadOnlyField(
                            label: 'Lớp sinh hoạt',
                            value: _user?.className ?? 'N/A',
                            icon: Icons.class_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Identity Mapping Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LIÊN KẾT TÀI KHOẢN (AI & ĐỒNG BỘ)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _githubController,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              labelText: 'GitHub Username',
                              prefixIcon: const Icon(Icons.code),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              hintText: 'Nhập username GitHub của bạn',
                              errorText: _githubError,
                            ),
                            validator: IdentityValidator.validateGithubUsername,
                            onChanged: (_) {
                              if (_githubError != null) {
                                setState(() => _githubError = null);
                              }
                            },
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _googleDocsController,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              labelText: 'Tên hiển thị trên Google Docs',
                              prefixIcon: const Icon(Icons.description_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              hintText: 'Nhập tên của bạn như hiển thị trong Docs history',
                              errorText: _googleDocsError,
                            ),
                            validator: IdentityValidator.validateGoogleDisplayName,
                            onChanged: (_) {
                              if (_googleDocsError != null) {
                                setState(() => _googleDocsError = null);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _isSaving ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'LƯU / CẬP NHẬT',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade500, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}
