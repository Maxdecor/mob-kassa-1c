import 'package:flutter/material.dart';

import '../api.dart';
import '../state.dart';

/// To'lov: chekni to'liq urish yoki otlojenniy qoldirish.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final TextEditingController _received =
      TextEditingController(text: qty(app.total));
  String _method = 'cash';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _received.dispose();
    super.dispose();
  }

  double get _change {
    final r = double.tryParse(_received.text.replaceAll(' ', '').replaceAll(',', '.')) ?? 0;
    return r - app.total;
  }

  Future<void> _submit({required bool deferred}) async {
    if (_busy) return;
    if (!deferred && _method == 'cash' && _change < 0) {
      setState(() => _error = 'Qabul qilingan summa yetarli emas.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await app.api!.createReceipt(
        organization: app.orgId,
        warehouse: app.warehouseId,
        cashRegister: app.kkmId,
        priceType: app.priceTypeId,
        deferred: deferred,
        payment: _method,
        lines: List.of(app.cart),
      );
      app.clearCart();
      if (!mounted) return;
      final nav = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      nav.pop();
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(deferred
              ? 'Chek №${res['number']} otlojenniy qilindi'
              : 'Chek №${res['number']} urildi'),
        ));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('To\'lov')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: Text('To\'lanadigan summa', style: theme.textTheme.bodyMedium)),
            Center(child: Text('${money(app.total)} so\'m', style: theme.textTheme.headlineMedium)),
            const SizedBox(height: 20),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'cash', label: Text('Naqd'), icon: Icon(Icons.payments_outlined)),
                ButtonSegment(value: 'card', label: Text('Karta'), icon: Icon(Icons.credit_card)),
              ],
              selected: {_method},
              onSelectionChanged: (s) => setState(() => _method = s.first),
            ),
            if (_method == 'cash') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _received,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Qabul qilindi',
                  prefixIcon: Icon(Icons.paid_outlined),
                                  ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Qaytim'),
                  Text('${money(_change < 0 ? 0 : _change)} so\'m', style: theme.textTheme.titleMedium),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : () => _submit(deferred: false),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: _busy
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Chekni urish'),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _submit(deferred: true),
              icon: const Icon(Icons.pause_circle_outline),
              label: const Padding(padding: EdgeInsets.all(6), child: Text('Otlojit (otlojenniy chek)')),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: const Text('Orqaga'),
            ),
          ],
        ),
      ),
    );
  }
}
