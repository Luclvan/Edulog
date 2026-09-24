import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/auth_validator.dart';

abstract class IAuthService {
  Future<String> loginWithEmail({required String email, required String password});
  Future<String> loginWithMicrosoft();
  Future<void> logout();
  
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
    String? studentId,
    String? classId,
    String? department,
  });
  
  Future<void> saveMicrosoftUserProfile({
    required String role,
    String? studentId,
    String? classId,
    String? department,
  });
}

class AuthService implements IAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  @override
  Future<String> loginWithEmail({required String email, required String password}) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = userCredential.user;
      
      // Chặn nếu chưa xác thực email
      if (user != null && !user.emailVerified) {
        await _firebaseAuth.signOut();
        throw Exception('Vui lòng kiểm tra hộp thư email trường và bấm link xác thực trước khi đăng nhập!');
      }

      final doc = await _firebaseFirestore.collection('users').doc(user!.uid).get();
      final role = doc.data()?['role'] as String?;
      if (role == null) throw Exception('Không tìm thấy dữ liệu phân quyền trong hệ thống');
      
      return role;
    } catch (e) {
      throw Exception('Đăng nhập thất bại: $e');
    }
  }

  @override
  Future<String> loginWithMicrosoft() async {
    try {
      final microsoftProvider = OAuthProvider('microsoft.com');
      final UserCredential userCredential = await _firebaseAuth.signInWithProvider(microsoftProvider);
      final User? user = userCredential.user;

      if (user == null || user.email == null) {
        throw Exception('Lỗi xác thực Microsoft');
      }

      // Bộ lọc chặn email ngoài
      final email = user.email!.toLowerCase();
      if (!email.endsWith('@e.tlu.edu.vn') && !email.endsWith('@tlu.edu.vn')) {
        await _firebaseAuth.signOut();
        throw Exception('Truy cập bị từ chối! Vui lòng sử dụng tài khoản Outlook của Đại học Thủy Lợi.');
      }

      final doc = await _firebaseFirestore.collection('users').doc(user.uid).get();
      
      // Nếu chưa có data trong database -> yêu cầu bổ sung
      if (!doc.exists) {
        return 'chua_dang_ky_thong_tin'; 
      }

      final role = doc.data()?['role'] as String?;
      if (role == null) throw Exception('Không tìm thấy dữ liệu phân quyền');
      
      return role;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi khi đăng nhập bằng Outlook: $e');
    }
  }

  @override
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
    String? studentId,
    String? classId,
    String? department,
  }) async {
    try {
      final trimmedEmail = email.trim();

      // [15E1] Check if studentId is already registered
      if (role == 'sinh_vien' && studentId != null && studentId.isNotEmpty) {
        final isTaken = await AuthValidator.isStudentIdRegistered(studentId, firestore: _firebaseFirestore);
        if (isTaken) {
          throw Exception('Mã sinh viên đã được đăng ký');
        }
      }

      // [13E1] Check if email is already registered in Firestore
      final isEmailTaken = await AuthValidator.isEmailRegisteredInFirestore(trimmedEmail, firestore: _firebaseFirestore);
      if (isEmailTaken) {
        throw Exception('Email này đã được đăng ký tài khoản');
      }

      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) throw Exception('Không thể khởi tạo tài khoản');

      // Gửi email xác thực
      await user.sendEmailVerification();

      await _saveUserDataToFirestore(
        uid: user.uid,
        email: trimmedEmail,
        name: name,
        role: role,
        studentId: studentId,
        classId: classId,
        department: department,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Email này đã được đăng ký tài khoản');
      }
      throw Exception(e.message ?? 'Lỗi đăng ký tài khoản: ${e.code}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi đăng ký: $e');
    }
  }

  @override
  Future<void> saveMicrosoftUserProfile({
    required String role,
    String? studentId,
    String? classId,
    String? department,
  }) async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('Không tìm thấy phiên đăng nhập Microsoft');

      // [15E1] Check if studentId is already registered
      if (role == 'sinh_vien' && studentId != null && studentId.isNotEmpty) {
        final isTaken = await AuthValidator.isStudentIdRegistered(studentId, firestore: _firebaseFirestore);
        if (isTaken) {
          throw Exception('Mã sinh viên đã được đăng ký');
        }
      }

      await _saveUserDataToFirestore(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? 'Người dùng',
        role: role,
        studentId: studentId,
        classId: classId,
        department: department,
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi khi cập nhật hồ sơ: $e');
    }
  }

  Future<void> _saveUserDataToFirestore({
    required String uid,
    required String email,
    required String name,
    required String role,
    String? studentId,
    String? classId,
    String? department,
  }) async {
    final Map<String, dynamic> userData = {
      'email': email,
      'name': name,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (role == 'sinh_vien') {
      userData['studentId'] = studentId ?? '';
      userData['class'] = classId ?? '';
    } else {
      userData['department'] = department ?? '';
    }

    await _firebaseFirestore.collection('users').doc(uid).set(userData);
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
}