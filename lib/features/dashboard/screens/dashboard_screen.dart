import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/transaction.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/phone_screen.dart';
import '../../bills/screens/bills_screen.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../history/screens/history_screen.dart';
import '../../transfers/screens/transfer_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final phone = context.read<AuthProvider>().phone ?? '';
    context.read<DashboardProvider>().loadDashboard(phone);
  }

  Future<void> _navigateTo(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: CustomScrollView(
          slivers: [
            _SliverHeader(onNavigate: _navigateTo),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _BalanceCard(),
                  const SizedBox(height: 24),
                  _QuickActions(onNavigate: _navigateTo),
                  const SizedBox(height: 24),
                  const _RecentTransactions(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sliver AppBar ───────────────────────────────────────────────────────────

class _SliverHeader extends StatelessWidget {
  final Future<void> Function(Widget) onNavigate;

  const _SliverHeader({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: AppTheme.primary,
      title: Consumer<AuthProvider>(
        builder: (_, auth, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BadWallet',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              '+221 ${Formatters.formatPhone(auth.phone ?? '')}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          tooltip: 'Déconnexion',
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Déconnexion'),
                content: const Text('Voulez-vous vous déconnecter ?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Déconnecter',
                      style: TextStyle(color: AppTheme.error),
                    ),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const PhoneScreen()),
                  (_) => false,
                );
              }
            }
          },
        ),
      ],
    );
  }
}

// ─── Balance Card ─────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (_, dashboard, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, Color(0xFF1a4a80)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withAlpha(102),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Solde disponible',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: dashboard.toggleBalanceVisibility,
                    child: Icon(
                      dashboard.balanceVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildBalanceContent(dashboard),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.person_outline, color: Colors.white60, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    dashboard.wallet?.name ?? '',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceContent(DashboardProvider dashboard) {
    if (dashboard.state == DashboardState.loading) {
      return const SizedBox(
        height: 36,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ),
        ),
      );
    }
    if (dashboard.state == DashboardState.error) {
      return Text(
        dashboard.errorMessage,
        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
      );
    }
    return Text(
      dashboard.balanceVisible
          ? Formatters.formatAmount(dashboard.wallet?.balance ?? 0)
          : '● ● ● ● ●',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─── Quick Actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final Future<void> Function(Widget) onNavigate;

  const _QuickActions({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          icon: Icons.send_rounded,
          label: 'Transférer',
          onTap: () => onNavigate(const TransferScreen()),
        ),
        const SizedBox(width: 12),
        _ActionButton(
          icon: Icons.receipt_long_rounded,
          label: 'Payer',
          onTap: () => onNavigate(const BillsScreen()),
        ),
        const SizedBox(width: 12),
        _ActionButton(
          icon: Icons.history_rounded,
          label: 'Historique',
          onTap: () => onNavigate(const HistoryScreen()),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.accent, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Recent Transactions ──────────────────────────────────────────────────────

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (_, dashboard, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transactions récentes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(color: AppTheme.accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (dashboard.state == DashboardState.loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (dashboard.recentTransactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune transaction',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...dashboard.recentTransactions.map((t) => _TxTile(tx: t)),
          ],
        );
      },
    );
  }
}

class _TxTile extends StatelessWidget {
  final Transaction tx;

  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.isCredit;
    final color = isCredit ? AppTheme.success : AppTheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
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
                  tx.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  Formatters.formatDate(tx.date),
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}${Formatters.formatAmount(tx.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
