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
    // Upload in parallel for speed
    final futures = images.map((img) => uploadProductImage(img, productId));
    return Future.wait(futures);
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

  /// Upload a payment method icon image to Firebase Storage
  Future<String> uploadPaymentMethodIcon(XFile image, String methodId) async {
    final ref = _storage
        .ref()
        .child('${AppConstants.storagePaymentMethods}/$methodId/icon_${DateTime.now().millisecondsSinceEpoch}.jpg');
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
    } catch (e) {
      // Log but don't throw — deletion failures are non-critical
      debugPrint('StorageService.deleteImage failed: $e');
    }
  }

  Future<void> deleteProductImages(List<String> urls) async {
    // Delete in parallel
    await Future.wait(urls.map((url) => deleteImage(url)));
  }
}

void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}
