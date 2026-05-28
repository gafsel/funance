import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';

extension OrderFirestoreX on DocumentSnapshot {
  OrderModel toOrderModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Order data is null');

    return OrderModel.fromJson({
      ...data,
      if (data['metadata'] is Map) ...data['metadata'] as Map<String, dynamic>,
      'id': id,
      'status': data['status'] ?? 'active',
      'total_amount': (data['total_amount'] ?? data['totalAmount'] ?? 0.0).toDouble(),
      'installments_count': data['installments_count'] ?? data['installmentsCount'] ?? 1,
      'planning_id': data['planning_id'] ?? data['planningId'],
      if (data['date'] is Timestamp)
        'date': (data['date'] as Timestamp).toDate().toIso8601String(),
    });
  }
}
