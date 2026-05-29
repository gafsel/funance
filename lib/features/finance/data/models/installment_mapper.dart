import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';

extension InstallmentFirestoreX on DocumentSnapshot {
  InstallmentModel toInstallmentModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Installment data is null');

    return InstallmentModel.fromJson({
      ...data,
      'id': id,
      if (data['dueDate'] is Timestamp)
        'dueDate': (data['dueDate'] as Timestamp).toDate().toIso8601String(),
      if (data['paidDate'] is Timestamp)
        'paidDate': (data['paidDate'] as Timestamp).toDate().toIso8601String(),
    });
  }
}
