import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/user/domain/models/user_model.dart';

extension UserFirestoreX on DocumentSnapshot {
  UserModel toUserModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('User data is null');

    return UserModel.fromJson({
      ...data,
      'id': id,
      if (data['createdAt'] is Timestamp)
        'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      if (data['lastLogin'] is Timestamp)
        'lastLogin': (data['lastLogin'] as Timestamp).toDate().toIso8601String(),
    });
  }
}
