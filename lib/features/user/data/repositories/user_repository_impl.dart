import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/user/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements IUserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('users');

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
    
    await _collection.doc(user.id).set(data);
  }

  @override
  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    final updateData = Map<String, dynamic>.from(data);
    
    if (data.containsKey('createdAt') && data['createdAt'] is DateTime) {
      updateData['createdAt'] = Timestamp.fromDate(data['createdAt'] as DateTime);
    }
    if (data.containsKey('lastLogin') && data['lastLogin'] is DateTime) {
      updateData['lastLogin'] = Timestamp.fromDate(data['lastLogin'] as DateTime);
    }

    await _collection.doc(id).update(updateData);
  }
}
