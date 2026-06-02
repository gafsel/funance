import 'package:flutter/material.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/l10n/app_localizations.dart';

enum ReplicationCascadeScenario { update, deletion }

typedef LabelRetrieve = String Function(AppLocalizations l10n);

class ReplicationCascadeDialog extends StatelessWidget {
  final LabelRetrieve title;
  final LabelRetrieve description;

  const ReplicationCascadeDialog({
    super.key,
    required this.title,
    required this.description,
  });

  factory ReplicationCascadeDialog.update() {
    return ReplicationCascadeDialog(
      title: (l10n) => l10n.transactionCascadeTitle,
      description: (l10n) => l10n.transactionCascadeDescription,
    );
  }

  factory ReplicationCascadeDialog.deletion() {
    return ReplicationCascadeDialog(
      title: (l10n) => l10n.transactionDeleteCascadeTitle,
      description: (l10n) => l10n.transactionDeleteCascadeDescription,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(title(l10n)),
      content: Text(description(l10n)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ReplicationCascade.none),
          child: Text(l10n.transactionCascadeOnlyThis),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ReplicationCascade.future),
          child: Text(l10n.transactionCascadeThisAndNext),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ReplicationCascade.all),
          child: Text(l10n.transactionCascadeAll),
        ),
      ],
    );
  }

  static Future<ReplicationCascade?> showDeletion(
    BuildContext context, {
    bool isDeletion = false,
  }) {
    return showDialog<ReplicationCascade>(
      context: context,
      builder: (context) => ReplicationCascadeDialog.deletion(),
    );
  }

  static Future<ReplicationCascade?> showUpdate(
    BuildContext context, {
    bool isDeletion = false,
  }) {
    return showDialog<ReplicationCascade>(
      context: context,
      builder: (context) => ReplicationCascadeDialog.update(),
    );
  }
}
