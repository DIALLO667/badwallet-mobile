import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transfers/providers/transfer_provider.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _recipientCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _step = 0; // 0 = destinataire, 1 = montant, 2 = confirmation

  @override
  void dispose() {
    _recipientCtrl.dispose();
    super.dispose();
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.read<TransferProvider>().reset();
      Navigator.pop(context);
    }
  }

  void _nextFromRecipient() {
    if (!_formKey.currentState!.validate()) return;
    context.read<TransferProvider>().setRecipient(_recipientCtrl.text.trim());
    setState(() => _step = 1);
  }

  void _nextFromAmount() {
    final amount = context.read<TransferProvider>().amount;
    if (amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un montant')),
      );
      return;
    }
    setState(() => _step = 2);
  }

  Future<void> _confirm() async {
    final phone = context.read<AuthProvider>().phone ?? '';
    final success = await context.read<TransferProvider>().sendTransfer(phone);
    if (!mounted) return;
    if (success) {
      context.read<TransferProvider>().reset();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfert effectué avec succès !'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<TransferProvider>().errorMessage),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(['Destinataire', 'Montant', 'Confirmation'][_step]),
          leading: BackButton(onPressed: _back),
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _step == 0
                ? _RecipientStep(formKey: _formKey, ctrl: _recipientCtrl, onNext: _nextFromRecipient)
                : _step == 1
                    ? _AmountStep(onNext: _nextFromAmount)
                    : _ConfirmStep(onConfirm: _confirm),
          ),
        ),
      ),
    );
  }
}

// ─── Step 1 : Destinataire ────────────────────────────────────────────────────

class _RecipientStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController ctrl;
  final VoidCallback onNext;

  const _RecipientStep({
    required this.formKey,
    required this.ctrl,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('recipient'),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Numéro du bénéficiaire',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Entrez le numéro de téléphone',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone',
                hintText: '77 XXX XX XX',
                prefixIcon: Icon(Icons.person_outline),
                prefixText: '+221  ',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Champ requis';
                if (v.length < 9) return 'Numéro invalide (9 chiffres)';
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNext,
                child: const Text('Suivant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2 : Montant ─────────────────────────────────────────────────────────

class _AmountStep extends StatelessWidget {
  final VoidCallback onNext;

  const _AmountStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransferProvider>(
      builder: (_, transfer, _) {
        return Column(
          key: const ValueKey('amount'),
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Montant à envoyer',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    transfer.amount.isEmpty
                        ? '0 FCFA'
                        : Formatters.formatAmount(
                            double.tryParse(transfer.amount) ?? 0,
                          ),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (transfer.amount.isNotEmpty)
                    TextButton(
                      onPressed: transfer.removeDigit,
                      child: const Text(
                        'Effacer le dernier chiffre',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
            _NumPad(transfer: transfer),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  child: const Text('Suivant'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NumPad extends StatelessWidget {
  final TransferProvider transfer;

  const _NumPad({required this.transfer});

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['000', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: _rows.map((row) {
          return Row(
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (key == '⌫') {
                          transfer.removeDigit();
                        } else {
                          for (final c in key.characters) {
                            transfer.addDigit(c);
                          }
                        }
                      },
                      child: SizedBox(
                        height: 58,
                        child: Center(
                          child: Text(
                            key,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Step 3 : Confirmation ────────────────────────────────────────────────────

class _ConfirmStep extends StatelessWidget {
  final Future<void> Function() onConfirm;

  const _ConfirmStep({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransferProvider, AuthProvider>(
      builder: (_, transfer, auth, _) {
        return Padding(
          key: const ValueKey('confirm'),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Récapitulatif',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 32),
              _buildInfoCard(
                items: [
                  _InfoRow(
                    label: 'Expéditeur',
                    value: '+221 ${Formatters.formatPhone(auth.phone ?? '')}',
                  ),
                  _InfoRow(
                    label: 'Bénéficiaire',
                    value: '+221 ${Formatters.formatPhone(transfer.recipient)}',
                  ),
                  _InfoRow(
                    label: 'Montant',
                    value: Formatters.formatAmount(
                      double.tryParse(transfer.amount) ?? 0,
                    ),
                    highlight: true,
                  ),
                ],
              ),
              const Spacer(),
              if (transfer.state == TransferState.loading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    child: const Text('Confirmer le transfert'),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({required List<_InfoRow> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.value.label,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    Text(
                      e.value.value,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: e.value.highlight ? AppTheme.accent : AppTheme.textPrimary,
                        fontSize: e.value.highlight ? 16 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow({required this.label, required this.value, this.highlight = false});
}
