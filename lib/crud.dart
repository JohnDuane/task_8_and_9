
import 'package:cloud_firestore/cloud_firestore.dart';

class Crud {
  final CollectionReference<Map<String, dynamic>> items = FirebaseFirestore.instance.collection('items');

  // CREATE
  Future<String> add(String name, int quantity) async {
    final doc = await items.add({
      'name': name,
      'quantity': quantity,
    });

    return doc.id;
  }

  // READ
  Stream<QuerySnapshot<Map<String, dynamic>>> getItems() {
    return items.snapshots();
  }

  // UPDATE
  Future<void> update(
    String docId,
    String name,
    int quantity,
  ) async {
    await items.doc(docId).update({
      'name': name,
      'quantity': quantity,
    });
  }

  // DELETE
  Future<void> delete(String docId) async {
    await items.doc(docId).delete();
  }

  Future<void> toggleFavorite(String id, bool currentStatus) {
    return items.doc(id).update({'is_favorite': !currentStatus});
  }
}
