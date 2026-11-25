
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';


class PickedImg{
  final File file;
  final String url;
  PickedImg({required this.file, required this.url});
}

class Crud {
  final CollectionReference<Map<String, dynamic>> items = FirebaseFirestore.instance.collection('items');

  final CloudinaryPublic _cloudinary = CloudinaryPublic('pdcjg21t', 'flutter_task_10', cache: false);

  final ImagePicker _imgpic = ImagePicker();

  Future<PickedImg?> pickImgForAddItem() async {
    final pickedFile = await _imgpic.pickImage(source: ImageSource.gallery);

    if(pickedFile == null) return null;

    final file = File(pickedFile.path);

    final response = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        resourceType: CloudinaryResourceType.Image,
      )
    );
    return PickedImg(file: file, url: response.secureUrl);
  }

  // CREATE
  Future<String> add(String name, int quantity, String? imageUrl) async {
    final doc = await items.add({
      'name': name,
      'quantity': quantity,
      'image_url': imageUrl,
      'created_at': Timestamp.now()
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
