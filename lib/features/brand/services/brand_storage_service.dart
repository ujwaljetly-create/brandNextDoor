  import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

  class BrandStorageService {
    final FirebaseStorage _storage =
        FirebaseStorage.instance;

    Future<String> uploadLogo({
      required String brandId,
      required Uint8List bytes,
    }) async {

      final ref = _storage
          .ref()
          .child(
            'brands/$brandId/logo.png',
          );

      await ref.putData(bytes);

      return await ref.getDownloadURL();
    }
  }