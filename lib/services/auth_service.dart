import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await _firestore
          .collection('employees')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw Exception('هذا المستخدم غير مسجل في أي متجر');
      }

      final data = userDoc.data() as Map<String, dynamic>;
      if (data['isActive'] == false) {
        await _auth.signOut();
        throw Exception('هذا الحساب معطل');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    } catch (e) {
      throw Exception('خطأ في تسجيل الدخول: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  Future<String?> getCurrentUserStoreId() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection('employees')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['storeId'] as String?;
    }
    return null;
  }

  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('employees')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['role'] == 'admin';
    }
    return false;
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'البريد الإلكتروني غير مسجل';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'user-disabled':
        return 'هذا الحساب معطل';
      case 'too-many-requests':
        return 'تم إرسال طلبات كثيرة جداً، حاول لاحقاً';
      default:
        return 'خطأ في تسجيل الدخول: ${e.message}';
    }
  }
}
