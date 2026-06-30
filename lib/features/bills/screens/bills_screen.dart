import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../../bills/providers/bills_provider.dart';

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BillsProvider>(
      builder: (_, bills, _) {
        return PopScope(
          canPop: bills.state == BillsState.initial,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) bills.goBackToProviders();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                bills.state == BillsState.initial
                    ? 'Paiement de factures'
                    : 'Factures ${bills.selectedProvider.toUpperCase()}',
              ),
              leading: bills.state != BillsState.initial
                  ? BackButton(onPressed: bills.goBackToProviders)
                  : const BackButton(),
            ),
            body: bills.state == BillsState.initial
                ? const _ProviderGrid()
                : const _BillsList(),
          ),
        );
      },
    );
  }
}

// ─── Provider Grid ─────────────────────────────────────────────────────────────

class _ProviderGrid extends StatelessWidget {
  const _ProviderGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisissez un fournisseur',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.15,
              ),
              itemCount: BillsProvider.providers.length,
              itemBuilder: (context, i) {
                final p = BillsProvider.providers[i];
                return _ProviderCard(provider: p);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final Map<String, Object> provider;

  const _ProviderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final phone = context.read<AuthProvider>().phone ?? '';
        context.read<BillsProvider>().loadBills(
              provider['code'] as String,
              phone,
            );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                provider['icon'] as IconData,
                size: 28,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              provider['name'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bills List ───────────────────────────────────────────────────────────────

class _BillsList extends StatelessWidget {
  const _BillsList();

  @override
  Widget build(BuildContext context) {
    return Consumer2<BillsProvider, AuthProvider>(
      builder: (_, bills, auth, _) {
        if (bills.state == BillsState.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (bills.state == BillsState.error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                  const SizedBox(height: 12),
                  Text(
                    bills.errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => bills.loadBills(
                      bills.selectedProvider,
                      auth.phone ?? '',
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        if (bills.bills.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 56, color: AppTheme.success),
                SizedBox(height: 12),
                Text(
                  'Aucune facture impayée',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                itemCount: bills.bills.length,
                itemBuilder: (_, i) {
                  final bill = bills.bills[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CheckboxListTile(
                      value: bill.isSelected,
                      onChanged: (_) => bills.toggleBillSelection(bill.id),
                      title: Text(
                        bill.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Réf : ${bill.reference}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      secondary: Text(
                        Formatters.formatAmount(bill.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accent,
                          fontSize: 13,
                        ),
                      ),
                      activeColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (bills.selectedBills.isNotEmpty)
              _PayBar(bills: bills, phone: auth.phone ?? ''),
          ],
        );
      },
    );
  }
}

class _PayBar extends StatelessWidget {
  final BillsProvider bills;
  final String phone;

  const _PayBar({required this.bills, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${bills.selectedBills.length} facture(s) sélectionnée(s)',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                Formatters.formatAmount(bills.totalSelected),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: bills.paymentState == PaymentState.loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () async {
                      final success = await bills.paySelectedBills(phone);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Paiement effectué avec succès !'
                                : bills.errorMessage,
                          ),
                          backgroundColor:
                              success ? AppTheme.success : AppTheme.error,
                        ),
                      );
                      if (success) bills.goBackToProviders();
                    },
                    child: const Text('Payer les factures sélectionnées'),
                  ),
          ),
        ],
      ),
    );
  }
}
