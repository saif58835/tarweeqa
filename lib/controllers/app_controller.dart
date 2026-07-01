import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models.dart';

class AppController extends GetxController {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  
  var store = Rxn<Store>();
  var isLoading = false.obs;
  var dollarRate = 15000.0.obs;
  var employeeName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadStore();
  }

  Future<void> loadStore() async {
    isLoading.value = true;
    try {
      final storeId = await _authService.getCurrentUserStoreId();
      if (storeId != null) {
        final doc = await _databaseService.getStore(storeId);
        if (doc.exists) {
          store.value = Store.fromDocument(doc);
          dollarRate.value = store.value!.dollarRate;
        }
      }
      
      // جلب اسم الموظف
      final user = _authService.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('employees')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          employeeName.value = data['name'] as String? ?? 'موظف';
        }
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحميل بيانات المتجر');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateDollarRate(double newRate) async {
    if (store.value == null) return;
    isLoading.value = true;
    try {
      await _databaseService.updateDollarRate(store.value!.id, newRate);
      dollarRate.value = newRate;
      store.value!.dollarRate = newRate;
      Get.snackbar('نجاح', 'تم تحديث سعر الدولار بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث سعر الدولار');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateEmployeeName(String name) async {
    isLoading.value = true;
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _databaseService.updateEmployeeName(user.uid, name);
        employeeName.value = name;
        Get.snackbar('نجاح', 'تم تحديث اسم الموظف بنجاح');
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث اسم الموظف');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    Get.offAllNamed('/login');
  }
}
