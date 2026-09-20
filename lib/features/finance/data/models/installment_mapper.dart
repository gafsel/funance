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
        'dueDate': (data['dueDate'] as Timestamp)
            .toDate()
            .toLocal()
            .toIso8601String(),
      if (data['paidDate'] is Timestamp)
        'paidDate': (data['paidDate'] as Timestamp)
            .toDate()
            .toLocal()
            .toIso8601String(),
      // Janela do ciclo da fatura (F1.8): o INSTANTE importa (00:00 e
      // 23:59:59.999 no fuso do produto), então nada de normalizar a hora.
      if (data['cycleStart'] is Timestamp)
        'cycleStart': (data['cycleStart'] as Timestamp)
            .toDate()
            .toLocal()
            .toIso8601String(),
      if (data['cycleEnd'] is Timestamp)
        'cycleEnd': (data['cycleEnd'] as Timestamp)
            .toDate()
            .toLocal()
            .toIso8601String(),
    });
  }
}
