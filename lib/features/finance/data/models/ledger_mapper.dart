import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/finance/domain/models/ledger_entry_model.dart';

extension LedgerEntryFirestoreX on DocumentSnapshot {
  LedgerEntryModel toLedgerEntryModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('LedgerEntry data is null');

    return LedgerEntryModel.fromJson({
      'status': 'cleared',
      'type': 'debit',
      ...data,
      'id': id,
      if (data['due_date'] is Timestamp)
        'due_date': (data['due_date'] as Timestamp).toDate().toIso8601String(),
      if (data['dueDate'] is Timestamp)
        'due_date': (data['dueDate'] as Timestamp).toDate().toIso8601String(),
    });
  }
}
