import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // دوال المتجر
  Future<DocumentSnapshot> getStore(String storeId) async {
    return await _firestore.collection('stores').doc(storeId).get();
  }

  Future<void> updateDollarRate(String storeId, double newRate) async {
    await _firestore.collection('stores').doc(storeId).update({
      'dollarRate': newRate,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // دوال الأقسام
  Future<void> addGroup(String storeId, String name) async {
    await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('groups')
        .add({
      'name': name,
      'pending_delete': false,
      'order': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> updateGroup(String storeId, String groupId, String name) async {
    await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('groups')
        .doc(groupId)
        .update({'name': name});
  }

  Future<void> deleteGroup(String storeId, String groupId, String userId) async {
    await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('groups')
        .doc(groupId)
        .update({
      'pending_delete': true,
      'deletedBy': userId,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<QueryDocumentSnapshot>> getGroups(String storeId) async {
    final snapshot = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('groups')
        .where('pending_delete', isEqualTo: false)
        .orderBy('order')
        .get();
    return snapshot.docs;
  }

  // دوال المنتجات
  Future<void> addProduct(
    String storeId,
    String groupId,
    String name,
    String unit,
    double priceUSD,
  ) async {
    await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('groups')
        .doc(groupId)
        .collection('products')
        .add({
      'name': name,
      'unit': unit,
      'priceUSD': priceUSD,
      'pending_delete': false,
      'searchTerms': [name.toLowerCase()],
    });
  }

  Future<void> updateProduct(
    String storeId,
    String groupId,
    String productId,
    String name,
    String unit,
    double priceUSD,
  ) async {
    await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('groups')
        .doc(groupId)
        .collection('products')
        .doc(productId)
        .update({
      'name': name,
      'unit': unit,
      'priceUSD': priceUSD,
      'searchTerms': [name.toLowerCase()],
    });
  }

  // دوال الفواتير
  Future<void> addInvoice(String storeId, Invoice invoice) async {
    await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('invoices')
        .doc(invoice.id)
        .set(invoice.toFirestore());
  }

  Future<PaginatedResult<QueryDocumentSnapshot>> getInvoices(
    String storeId, {
    bool? isPaid,
    DocumentSnapshot? lastDocument,
    int pageSize = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _firestore
        .collection('stores')
        .doc(storeId)
        .collection('invoices')
        .where('pending_delete', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(pageSize);

    if (isPaid != null) {
      query = query.where('isPaid', isEqualTo: isPaid);
    }

    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return PaginatedResult(
      documents: snapshot.docs,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length == pageSize,
    );
  }

  // دوال الموظفين
  Future<void> updateEmployeeName(String userId, String name) async {
    await _firestore.collection('employees').doc(userId).update({
      'name': name,
    });
  }
}

class PaginatedResult<T> {
  final List<T> documents;
  final T? lastDocument;
  final bool hasMore;

  PaginatedResult({
    required this.documents,
    this.lastDocument,
    required this.hasMore,
  });
}
