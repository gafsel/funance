import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';

extension OrderFirestoreX on DocumentSnapshot {
  OrderModel toOrderModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Order data is null');

    return OrderModel.fromJson({
      ...data,
      'id': id,
    });
  }
}
