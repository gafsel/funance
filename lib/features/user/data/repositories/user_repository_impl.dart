import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:funances/core/files/picked_document.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/core/firestore/write_failures.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/user/domain/repositories/user_repository.dart';
import 'package:uuid/uuid.dart';

class UserRepositoryImpl implements IUserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _collection => _firestore.collection('users');

  @override
  Stream<UserModel?> watchUser(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return UserModel.fromJson({
        ...data,
        'id': doc.id,
        'createdAt': (data['createdAt'] as Timestamp)
            .toDate()
            .toIso8601String(),
        'lastLogin': data['lastLogin'] != null
            ? (data['lastLogin'] as Timestamp).toDate().toIso8601String()
            : null,
      });
    });
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson({
      ...data,
      'id': doc.id,
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'lastLogin': data['lastLogin'] != null
          ? (data['lastLogin'] as Timestamp).toDate().toIso8601String()
          : null,
    });
  }

  @override
  Future<void> createUser(UserModel user) async {
    final data = user.toJson();
    data['createdAt'] = Timestamp.fromDate(user.createdAt);
    if (user.lastLogin != null) {
      data['lastLogin'] = Timestamp.fromDate(user.lastLogin!);
    }

    await settleWrite(
      _collection.doc(user.id).set(data),
      entity: WriteEntity.profile,
    );
  }

  @override
  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    final updateData = Map<String, dynamic>.from(data);

    if (data.containsKey('createdAt') && data['createdAt'] is DateTime) {
      updateData['createdAt'] = Timestamp.fromDate(
        data['createdAt'] as DateTime,
      );
    }
    if (data.containsKey('lastLogin') && data['lastLogin'] is DateTime) {
      updateData['lastLogin'] = Timestamp.fromDate(
        data['lastLogin'] as DateTime,
      );
    }

    await settleWrite(
      _collection.doc(id).update(updateData),
      entity: WriteEntity.profile,
    );
  }

  @override
  Future<String> uploadUserAvatar(String userId, PickedDocument image) async {
    final String extension = image.extension.isEmpty ? 'jpg' : image.extension;
    final String fileName = '${const Uuid().v4()}.$extension';
    final String path = 'users/$userId/avatar/$fileName';

    final ref = _storage.ref().child(path);
    // `putData` em vez de `putFile`: na web o recorte devolve um blob, e o
    // `putFile` só sabe falar com `dart:io.File`.
    await ref.putData(
      image.bytes,
      SettableMetadata(contentType: _avatarContentType(extension)),
    );
    return await ref.getDownloadURL();
  }

  /// Sem `contentType` o Storage marca o avatar como
  /// `application/octet-stream` e o navegador baixa o arquivo em vez de
  /// exibi-lo na tag `img`.
  static String _avatarContentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
  }
}
