import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await context.read<AuthProvider>().savePhone(_controller.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 36),
                const Text(
                  'Bienvenue !',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Entrez votre numéro pour accéder\nà votre portefeuille',
                  style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone',
                    hintText: '77 XXX XX XX',
                    prefixIcon: Icon(Icons.phone_outlined),
                    prefixText: '+221  ',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    if (v.length < 9) return 'Numéro invalide (9 chiffres requis)';
                    return null;
                  },
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _proceed,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Continuer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
