import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage =
      FirebaseStorage.instance;

  Future<String> uploadImage(
    File file,
    String folder,
  ) async {
    final fileName =
        const Uuid().v4();

    final ref = _storage
        .ref()
        .child(folder)
        .child(fileName);

    final uploadTask =
        await ref.putFile(file);

    return await uploadTask.ref
        .getDownloadURL();
  }
}