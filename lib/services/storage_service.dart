import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProductImage(XFile image, String productId) async {
    final ref = _storage
        .ref()
        .child('${AppConstants.storageProducts}/$productId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploadTask = ref.putData(
      await image.readAsBytes(),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<List<String>> uploadProductImages(
      List<XFile> images, String productId) async {
    final urls = <String>[];
    for (final image in images) {
      final url = await uploadProductImage(image, productId);
      urls.add(url);
    }
    return urls;
  }

  Future<String> uploadAvatar(XFile image, String uid) async {
    final ref = _storage
        .ref()
        .child('${AppConstants.storageAvatars}/$uid.jpg');
    final uploadTask = ref.putData(
      await image.readAsBytes(),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // ignore if delete fails
    }
  }

  Future<void> deleteProductImages(List<String> urls) async {
    for (final url in urls) {
      await deleteImage(url);
    }
  }
}
