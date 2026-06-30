import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/transaction.dart';
import '../../auth/providers/auth_provider.dart';
import '../../history/providers/history_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phone = context.read<AuthProvider>().phone ?? '';
      context.read<HistoryProvider>().loadHistory(phone);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: Consumer<HistoryProvider>(
        builder: (_, history, _) {
          if (history.state == HistoryState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (history.state == HistoryState.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                    const SizedBox(height: 12),
                    Text(
                      history.errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final phone = context.read<AuthProvider>().phone ?? '';
                        history.loadHistory(phone);
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (history.transactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucune transaction',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final phone = context.read<AuthProvider>().phone ?? '';
              await history.loadHistory(phone);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.transactions.length,
              itemBuilder: (_, i) =>
                  _HistoryTile(transaction: history.transactions[i]),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Transaction transaction;

  const _HistoryTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final color = isCredit ? AppTheme.success : AppTheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        Formatters.formatDate(transaction.date),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (transaction.recipient != null ||
                          transaction.sender != null) ...[
                        const Text(
                          '  •  ',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            isCredit
                                ? (transaction.sender ?? '')
                                : (transaction.recipient ?? ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'}${Formatters.formatAmount(transaction.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCredit ? 'Reçu' : 'Envoyé',
                    style: TextStyle(
                      fontSize: 9,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
